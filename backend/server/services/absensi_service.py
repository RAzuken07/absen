# server/services/absensi_service.py

from database.db import query_db, execute_db # Menggunakan fungsi utility DB
from utils.geolocation import calculate_distance
from services.face_service import verify_face # Asumsi fungsi ini ada
from datetime import datetime, timedelta
# Import untuk model User dan bcrypt jika logic login ditaruh di sini (Seperti yang kita bahas sebelumnya)
# from utils.auth_model import User 
# import bcrypt

class AbsensiService:
    # Asumsi: Tidak perlu self.conn jika menggunakan query_db/execute_db global

    # --- Utilitas Login (Disarankan berada di sini jika tidak ada auth_service.py) ---
    # ... (def authenticate_user(self, username, password) - logika login)

    # --- Logika Absensi ---

    def submit_absensi(self, nim, id_sesi, metode, lokasi_lat, lokasi_long, image_base64=None, verification_code=None):
        """Mencatat absensi mahasiswa dengan validasi waktu, lokasi, dan metode (Wajah/QR)."""
        
        # 1. Ambil Data Sesi Aktif
        sesi_data = query_db("""
            SELECT s.id_sesi, s.id_pertemuan, s.lokasi_lat, s.lokasi_long, s.radius_meter, s.waktu_buka, s.durasi_menit
            FROM sesi_absensi s
            WHERE s.id_sesi = %s AND s.status_sesi = 'aktif'
        """, (id_sesi,), fetchone=True)

        if not sesi_data:
            return False, "Sesi absensi tidak ditemukan atau sudah ditutup."

        # 2. Cek apakah sudah kadaluarsa
        waktu_tutup_seharusnya = sesi_data['waktu_buka'] + timedelta(minutes=sesi_data['durasi_menit'])
        if datetime.now() > waktu_tutup_seharusnya:
            # PENTING: Set status_sesi='selesai' secara otomatis agar tidak perlu lagi dicek
            # Ini mencegah mahasiswa absen setelah waktu berakhir
            execute_db("UPDATE sesi_absensi SET status_sesi = 'selesai' WHERE id_sesi = %s", (id_sesi,))
            return False, "Sesi absensi sudah berakhir."

        # 3. Cek apakah Mahasiswa sudah absen di pertemuan ini
        sudah_absen = query_db("""
            SELECT id_absensi FROM absensi WHERE nim = %s AND id_pertemuan = %s
        """, (nim, sesi_data['id_pertemuan']), fetchone=True)
        
        if sudah_absen:
            return False, "Anda sudah melakukan absensi untuk pertemuan ini."

        # 4. Validasi GPS (Haversine)
        dosen_lat = float(sesi_data['lokasi_lat'])
        dosen_long = float(sesi_data['lokasi_long'])
        
        jarak_meter = calculate_distance(
            float(lokasi_lat), float(lokasi_long), 
            dosen_lat, dosen_long
        )
        
        radius = sesi_data['radius_meter']
        
        if jarak_meter > radius:
            return False, f"Anda berada di luar radius lokasi absensi ({round(jarak_meter)}m). Radius maksimal {radius}m."

        # 5. Validasi Metode (Face Recognition / QR Code)
        confidence_score = 0.0
        
        if metode == 'face_recognition':
            if not image_base64:
                 return False, "Diperlukan data gambar wajah untuk verifikasi."
                 
            match, confidence_score, face_message = verify_face(nim, image_base64)
            
            # Log aktivitas scan wajah
            log_query = "INSERT INTO face_scan_log (user_type, user_id, action, confidence_score, lokasi_lat, lokasi_long) VALUES (%s, %s, %s, %s, %s, %s)"
            action_log = 'verify' if match else 'failed'
            execute_db(log_query, ('mahasiswa', nim, action_log, confidence_score, lokasi_lat, lokasi_long))
            
            if not match:
                return False, f"Verifikasi wajah gagal. {face_message}"
        
        elif metode == 'qr_code':
            # --- PENTING: Logika Validasi QR Code ---
            if not verification_code:
                return False, "Diperlukan kode QR untuk verifikasi."
            
            # Cek status kode QR di tabel `barcode` atau `sesi_absensi`
            # Asumsi: `verification_code` adalah `kode_barcode` dari tabel `barcode`
            barcode_valid = query_db("""
                SELECT id_barcode FROM barcode 
                WHERE kode_barcode = %s AND id_sesi = %s AND status = 'aktif' AND waktu_kadaluarsa > NOW()
            """, (verification_code, id_sesi), fetchone=True)
            
            if not barcode_valid:
                return False, "Kode QR tidak valid atau sudah kadaluarsa."
            
            # Set confidence_score menjadi 1.0 (100%) untuk absensi QR yang sukses
            confidence_score = 1.0 
        
        # NOTE: Jika metode adalah 'manual', tidak ada validasi tambahan selain lokasi/waktu.

        # 6. Insert ke tabel absensi
        query = """
            INSERT INTO absensi (nim, id_pertemuan, id_sesi, status, metode, confidence_score, lokasi_lat, lokasi_long)
            VALUES (%s, %s, %s, 'hadir', %s, %s, %s, %s)
        """
        params = (nim, sesi_data['id_pertemuan'], id_sesi, metode, confidence_score, lokasi_lat, lokasi_long)
        
        if execute_db(query, params):
            return True, "Absensi berhasil dicatat."
        else:
            return False, "Terjadi kesalahan database saat mencatat absensi."


    def get_absensi_history(self, nim):
        """Mengambil riwayat absensi lengkap seorang mahasiswa."""
        
        # Memanfaatkan view v_rekap_kehadiran untuk mendapatkan status total
        # atau query gabungan untuk mendapatkan detail per absensi
        query = """
            SELECT 
                a.id_absensi, a.waktu_absen, a.status, a.metode, a.confidence_score, a.keterangan,
                p.pertemuan_ke, p.tanggal, p.topik,
                k.nama_kelas,
                mk.nama_matakuliah, mk.kode_mk
            FROM absensi a
            JOIN pertemuan p ON a.id_pertemuan = p.id_pertemuan
            JOIN kelas k ON p.id_kelas = k.id_kelas
            JOIN matakuliah mk ON k.id_matakuliah = mk.id_matakuliah
            WHERE a.nim = %s
            ORDER BY p.tanggal DESC, p.pertemuan_ke DESC
        """
        history = query_db(query, (nim,), fetchone=False)
        return history


# Inisialisasi service untuk digunakan di routes
absensi_service = AbsensiService()