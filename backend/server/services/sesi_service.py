# server/services/sesi_service.py

import uuid
from datetime import datetime, timedelta
from database.db import query_db, execute_db

def open_sesi(id_pertemuan, nip_dosen, durasi_menit, lokasi_lat, lokasi_long, radius_meter):
    # Cek apakah pertemuan sudah memiliki sesi aktif
    check_query = """
        SELECT s.id_sesi FROM sesi_absensi s
        JOIN pertemuan p ON s.id_pertemuan = p.id_pertemuan
        WHERE p.id_pertemuan = %s AND s.status_sesi = 'aktif'
    """
    if query_db(check_query, (id_pertemuan,), fetchone=True):
        return None, "Pertemuan ini sudah memiliki sesi aktif."

    waktu_buka = datetime.now()
    waktu_tutup = waktu_buka + timedelta(minutes=durasi_menit)
    
    insert_query = """
        INSERT INTO sesi_absensi (id_pertemuan, nip_dosen, waktu_buka, waktu_tutup, durasi_menit, lokasi_lat, lokasi_long, radius_meter, status_sesi)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, 'aktif')
    """
    params = (id_pertemuan, nip_dosen, waktu_buka, waktu_tutup, durasi_menit, lokasi_lat, lokasi_long, radius_meter)
    id_sesi = execute_db(insert_query, params) # Mengembalikan lastrowid
    
    if id_sesi:
        # Trigger tr_after_sesi_opened di SQL dump akan mengirim notifikasi
        return id_sesi, "Sesi absensi berhasil dibuka."
    else:
        return None, "Gagal membuka sesi absensi (Database Error)."

def generate_barcode(id_sesi, nip_dosen, durasi_menit=10):
    # Cek kepemilikan sesi
    sesi_data = query_db("SELECT * FROM sesi_absensi WHERE id_sesi = %s AND nip_dosen = %s", (id_sesi, nip_dosen), fetchone=True)
    if not sesi_data:
        return None, "Sesi tidak ditemukan atau bukan milik dosen ini."
        
    # Buat kode barcode unik (misalnya 8 karakter pertama UUID)
    kode_barcode = str(uuid.uuid4())[:8].upper()
    waktu_kadaluarsa = datetime.now() + timedelta(minutes=durasi_menit)
    
    insert_query = """
        INSERT INTO barcode (kode_barcode, id_sesi, nip_dosen, waktu_kadaluarsa, status)
        VALUES (%s, %s, %s, %s, 'aktif')
    """
    if execute_db(insert_query, (kode_barcode, id_sesi, nip_dosen, waktu_kadaluarsa)):
        return kode_barcode, "Barcode berhasil dibuat."
    else:
        return None, "Gagal menyimpan barcode ke database."

def get_rekap_kehadiran(id_kelas):
    # Mengambil data dari view v_rekap_kehadiran yang telah dibuat di SQL dump
    # Filter mahasiswa berdasarkan kelas
    rekap_query = """
        SELECT m.nim, m.nama, rk.*
        FROM mahasiswa m
        JOIN kelas k ON m.id_kelas = k.id_kelas
        LEFT JOIN v_rekap_kehadiran rk ON m.nim = rk.nim
        WHERE k.id_kelas = %s
    """
    rekap_data = query_db(rekap_query, (id_kelas,))
    return rekap_data

def get_sesi_kehadiran_realtime(id_sesi):
    # Mengambil daftar mahasiswa di kelas tersebut, dan status absensinya (realtime)
    query = """
        SELECT m.nim, m.nama, a.status, a.waktu_absen, a.metode, a.confidence_score
        FROM mahasiswa m
        JOIN pertemuan p ON m.id_kelas = p.id_kelas
        JOIN sesi_absensi s ON p.id_pertemuan = s.id_pertemuan
        LEFT JOIN absensi a ON m.nim = a.nim AND a.id_sesi = s.id_sesi
        WHERE s.id_sesi = %s
    """
    kehadiran_data = query_db(query, (id_sesi,))
    return kehadiran_data

def get_sesi_aktif_mahasiswa(nim):
    # Mengambil sesi aktif dari view v_sesi_aktif, difilter berdasarkan kelas mahasiswa
    query = """
        SELECT v.* FROM v_sesi_aktif v
        JOIN pertemuan p ON v.id_pertemuan = p.id_pertemuan
        JOIN mahasiswa m ON p.id_kelas = m.id_kelas
        WHERE m.nim = %s
    """
    sesi_aktif = query_db(query, (nim,))
    return sesi_aktif

def verify_barcode_absensi(nim, kode_barcode):
    # 1. Cek keberadaan, status, dan waktu kadaluarsa barcode
    barcode_data = query_db("""
        SELECT b.id_sesi, b.waktu_kadaluarsa, p.id_pertemuan, m.id_kelas
        FROM barcode b
        JOIN sesi_absensi s ON b.id_sesi = s.id_sesi
        JOIN pertemuan p ON s.id_pertemuan = p.id_pertemuan
        JOIN mahasiswa m ON p.id_kelas = m.id_kelas
        WHERE b.kode_barcode = %s AND m.nim = %s AND b.status = 'aktif'
    """, (kode_barcode, nim), fetchone=True)
    
    if not barcode_data:
        return None, "Barcode tidak valid atau bukan untuk kelas Anda."

    # 2. Cek kadaluarsa waktu barcode
    if datetime.now() > barcode_data['waktu_kadaluarsa']:
        execute_db("UPDATE barcode SET status = 'kadaluarsa' WHERE kode_barcode = %s", (kode_barcode,))
        return None, "Barcode sudah kadaluarsa berdasarkan waktu yang ditentukan dosen."

    # 3. Cek apakah sesi utama masih aktif
    sesi_aktif = query_db("SELECT status_sesi FROM sesi_absensi WHERE id_sesi = %s", (barcode_data['id_sesi'],), fetchone=True)
    if sesi_aktif['status_sesi'] != 'aktif':
        return None, "Sesi absensi utama sudah ditutup."

    return {
        "id_sesi": barcode_data['id_sesi'],
        "id_pertemuan": barcode_data['id_pertemuan']
    }, "Barcode berhasil diverifikasi."