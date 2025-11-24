# backend/services/admin_service.py

from database.db import get_db_connection
from utils.auth_model import User # Asumsi model User terdefinisi
import bcrypt

class AdminService:
    def __init__(self):
        self.conn = get_db_connection()

    # --- Utilitas ---
    def _hash_password(self, password):
        """Mengenkripsi password menggunakan bcrypt."""
        # Asumsi: Password harus di-encode ke bytes sebelum hashing
        return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

    # --- CRUD Matakuliah ---
    def get_all_matakuliah(self):
        cursor = self.conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM matakuliah")
        matakuliah = cursor.fetchall()
        cursor.close()
        return matakuliah

    def create_matakuliah(self, kode_mk, nama_matakuliah, sks, nip_dosen=None):
        cursor = self.conn.cursor()
        query = "INSERT INTO matakuliah (kode_mk, nama_matakuliah, sks, nip_dosen) VALUES (%s, %s, %s, %s)"
        cursor.execute(query, (kode_mk, nama_matakuliah, sks, nip_dosen))
        self.conn.commit()
        cursor.close()
        return "Matakuliah berhasil ditambahkan"

    def update_matakuliah(self, id_matakuliah, kode_mk, nama_matakuliah, sks, nip_dosen=None):
        cursor = self.conn.cursor()
        query = "UPDATE matakuliah SET kode_mk=%s, nama_matakuliah=%s, sks=%s, nip_dosen=%s WHERE id_matakuliah=%s"
        cursor.execute(query, (kode_mk, nama_matakuliah, sks, nip_dosen, id_matakuliah))
        self.conn.commit()
        cursor.close()
        return "Matakuliah berhasil diperbarui"

    def delete_matakuliah(self, id_matakuliah):
        cursor = self.conn.cursor()
        cursor.execute("DELETE FROM matakuliah WHERE id_matakuliah = %s", (id_matakuliah,))
        self.conn.commit()
        cursor.close()
        return "Matakuliah berhasil dihapus"

    # --- CRUD Dosen ---

    def get_all_dosen(self):
        cursor = self.conn.cursor(dictionary=True)
        # Join dengan users untuk mendapatkan username/level
        query = """
            SELECT d.*, u.username 
            FROM dosen d 
            LEFT JOIN users u ON d.nip = u.nip AND u.level = 'dosen'
        """
        cursor.execute(query)
        dosen_list = cursor.fetchall()
        cursor.close()
        return dosen_list

    def create_dosen(self, nip, nama, email, no_hp, username, password):
        # Transaksi untuk Dosen dan User
        try:
            cursor = self.conn.cursor()
            
            # 1. Tambah ke tabel dosen
            cursor.execute("INSERT INTO dosen (nip, nama, email, no_hp) VALUES (%s, %s, %s, %s)",
                           (nip, nama, email, no_hp))
            
            # 2. Tambah ke tabel users
            # Asumsi: Password di-hash sebelum disimpan (menggunakan bcrypt)
            hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
            cursor.execute("INSERT INTO users (username, password, nama, level, nip) VALUES (%s, %s, %s, 'dosen', %s)",
                        (username, hashed_password, nama, nip))
            
            self.conn.commit()
            cursor.close()
            return "Dosen dan Akun berhasil ditambahkan"
        except Exception as e:
            self.conn.rollback()
            raise e

    # -- CRUD Mahasiswa ---
    def get_all_mahasiswa(self):
        cursor = self.conn.cursor(dictionary=True)
        query = """
            SELECT m.*, u.username, k.nama_kelas
            FROM mahasiswa m
            LEFT JOIN users u ON m.nim = u.nim AND u.level = 'mahasiswa'
            LEFT JOIN kelas k ON m.id_kelas = k.id_kelas
            ORDER BY m.nim
        """
        cursor.execute(query)
        mahasiswa_list = cursor.fetchall()
        cursor.close()
        return mahasiswa_list

    def create_mahasiswa(self, nim, nama, email, angkatan, id_kelas, username, password):
        if not all([nim, nama, username, password, angkatan]): raise ValueError("Data wajib diisi.")
        try:
            cursor = self.conn.cursor()
            
            # 1. Tambah ke tabel mahasiswa
            cursor.execute("INSERT INTO mahasiswa (nim, nama, email, angkatan, id_kelas, face_registered) VALUES (%s, %s, %s, %s, %s, 0)",
                           (nim, nama, email, angkatan, id_kelas))
            
            # 2. Tambah ke tabel users
            hashed_password = self._hash_password(password)
            cursor.execute("INSERT INTO users (username, password, nama, level, nim) VALUES (%s, %s, %s, 'mahasiswa', %s)",
                           (username, hashed_password, nama, nim))
            
            self.conn.commit()
            cursor.close()
            return "Mahasiswa dan Akun berhasil ditambahkan"
        except Exception as e:
            self.conn.rollback()
            raise e

    def update_mahasiswa(self, nim, data):
        try:
            cursor = self.conn.cursor()
            
            # 1. Update data mahasiswa
            mhs_data = {k: v for k, v in data.items() if k in ['nama', 'email', 'angkatan', 'id_kelas', 'face_registered']}
            if mhs_data:
                set_mhs = ', '.join([f"{key} = %s" for key in mhs_data.keys()])
                params_mhs = list(mhs_data.values()) + [nim]
                cursor.execute(f"UPDATE mahasiswa SET {set_mhs} WHERE nim = %s", tuple(params_mhs))

            # 2. Update password/username di tabel users
            if 'password' in data:
                hashed_password = self._hash_password(data['password'])
                cursor.execute("UPDATE users SET password = %s WHERE nim = %s AND level = 'mahasiswa'", (hashed_password, nim))
            
            if 'username' in data:
                 cursor.execute("UPDATE users SET username = %s WHERE nim = %s AND level = 'mahasiswa'", (data['username'], nim))
            
            self.conn.commit()
            cursor.close()
            return "Data Mahasiswa berhasil diperbarui"
        except Exception as e:
            self.conn.rollback()
            raise e

    def delete_mahasiswa(self, nim):
        try:
            cursor = self.conn.cursor()
            # Hapus dari users dan mahasiswa
            cursor.execute("DELETE FROM users WHERE nim = %s AND level = 'mahasiswa'", (nim,))
            cursor.execute("DELETE FROM mahasiswa WHERE nim = %s", (nim,))
            self.conn.commit()
            cursor.close()
            return "Mahasiswa berhasil dihapus"
        except Exception as e:
            self.conn.rollback()
            raise e


    # -----------------------------------------------------------------------------------
    # --- CRUD Kelas ---
    # -----------------------------------------------------------------------------------

    def get_all_kelas(self):
        cursor = self.conn.cursor(dictionary=True)
        query = """
            SELECT k.*, mk.kode_mk, mk.nama_matakuliah, mk.nip_dosen
            FROM kelas k
            JOIN matakuliah mk ON k.id_matakuliah = mk.id_matakuliah
            ORDER BY k.nama_kelas
        """
        cursor.execute(query)
        kelas_list = cursor.fetchall()
        cursor.close()
        return kelas_list

    def create_kelas(self, nama_kelas, ruangan, hari, jam_mulai, jam_selesai, id_matakuliah):
        cursor = self.conn.cursor()
        query = "INSERT INTO kelas (nama_kelas, ruangan, hari, jam_mulai, jam_selesai, id_matakuliah) VALUES (%s, %s, %s, %s, %s, %s)"
        cursor.execute(query, (nama_kelas, ruangan, hari, jam_mulai, jam_selesai, id_matakuliah))
        self.conn.commit()
        cursor.close()
        return "Kelas baru berhasil ditambahkan"

    def update_kelas(self, id_kelas, nama_kelas, ruangan, hari, jam_mulai, jam_selesai, id_matakuliah):
        cursor = self.conn.cursor()
        query = """
            UPDATE kelas 
            SET nama_kelas=%s, ruangan=%s, hari=%s, jam_mulai=%s, jam_selesai=%s, id_matakuliah=%s 
            WHERE id_kelas=%s
        """
        cursor.execute(query, (nama_kelas, ruangan, hari, jam_mulai, jam_selesai, id_matakuliah, id_kelas))
        self.conn.commit()
        cursor.close()
        return "Kelas berhasil diperbarui"

    def delete_kelas(self, id_kelas):
        # Note: Relasi FK di 'mahasiswa' adalah ON DELETE SET NULL, jadi mahasiswa tetap ada.
        # Relasi FK di 'pertemuan' adalah ON DELETE CASCADE, jadi semua pertemuan kelas ini akan terhapus.
        try:
            cursor = self.conn.cursor()
            cursor.execute("DELETE FROM kelas WHERE id_kelas = %s", (id_kelas,))
            self.conn.commit()
            cursor.close()
            return "Kelas berhasil dihapus. Pertemuan terkait juga terhapus."
        except Exception as e:
            self.conn.rollback()
            raise e

# Inisialisasi service untuk digunakan di routes
admin_service = AdminService()