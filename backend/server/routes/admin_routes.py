# server/routes/admin_routes.py

from flask import Blueprint, request, jsonify
from utils.jwt_auth import jwt_required
from database.db import query_db, execute_db
from functools import wraps

admin_bp = Blueprint('admin', __name__, url_prefix='/admin')

# Decorator Khusus Admin
def admin_required(f):
    @jwt_required
    @wraps(f)
    def decorated(*args, **kwargs):
        # request.user_data disuntikkan oleh jwt_required
        if request.user_data.get('level') != 'admin':
            return jsonify({'message': 'Akses ditolak. Hanya untuk Admin'}), 403
        return f(*args, **kwargs)
    return decorated

# Fungsi Template CRUD (Create, Read All, Update, Delete)
def create_crud_endpoint(blueprint, resource_name, table_name, pk_column):
    
    # READ ALL (GET) / CREATE (POST)
    @blueprint.route(f'/{resource_name}', methods=['GET', 'POST'])
    @admin_required
    def read_all_or_create():
        
        if request.method == 'GET':
            # READ ALL Logic (Existing)
            data = query_db(f"SELECT * FROM {table_name}")
            return jsonify({"status": "success", f"{resource_name}": data}), 200
        
        elif request.method == 'POST':
            # CREATE Logic (New)
            data = request.json
            if not data:
                return jsonify({"status": "error", "message": "Data wajib diisi (JSON payload)."}), 400

            # Dynamic Query Generation
            columns = ', '.join(data.keys())
            placeholders = ', '.join(['%s'] * len(data))
            params = tuple(data.values())

            insert_query = f"INSERT INTO {table_name} ({columns}) VALUES ({placeholders})"
            
            try:
                # Execute INSERT
                success = execute_db(insert_query, params) 
                
                if success:
                    # Ambil ID terakhir untuk feedback
                    # Note: Jika tabel menggunakan non-auto-increment PK (seperti NIM/NIP), data di 'data' sudah cukup.
                    return jsonify({"status": "success", "message": f"{resource_name} berhasil ditambahkan.", "data": data}), 201
                
                return jsonify({"status": "error", "message": "Gagal menambahkan data (Kemungkinan data unik duplikat atau FK tidak ditemukan)."}), 500
            
            except Exception as e:
                # Catch database errors (e.g., constraint violation, column mismatch)
                return jsonify({"status": "error", "message": f"Error Database: {str(e)}", "query": insert_query}), 500

    # READ ONE / UPDATE / DELETE
    @blueprint.route(f'/{resource_name}/<pk_value>', methods=['GET', 'PUT', 'DELETE'])
    @admin_required
    def crud_one(pk_value):
        
        if request.method == 'GET':
            # READ ONE Logic (Existing)
            data = query_db(f"SELECT * FROM {table_name} WHERE {pk_column} = %s", (pk_value,), fetchone=True)
            if data:
                return jsonify({"status": "success", f"{resource_name}": data}), 200
            return jsonify({"status": "error", "message": f"{resource_name} tidak ditemukan."}), 404
            
        elif request.method == 'DELETE':
            # DELETE Logic (Existing)
            try:
                success = execute_db(f"DELETE FROM {table_name} WHERE {pk_column} = %s", (pk_value,))
                if success:
                    return jsonify({"status": "success", "message": f"{resource_name} berhasil dihapus."}), 200
                return jsonify({"status": "error", "message": f"{resource_name} tidak ditemukan atau gagal menghapus."}), 404
            except Exception as e:
                return jsonify({"status": "error", "message": f"Gagal menghapus: {str(e)}"}), 500
            
        elif request.method == 'PUT':
            # UPDATE Logic (Existing)
            data = request.json
            if not data:
                 return jsonify({"status": "error", "message": "Data wajib diisi (JSON payload)."}, 400)
                 
            try:
                set_clauses = ', '.join([f"{key} = %s" for key in data.keys()])
                params = list(data.values()) + [pk_value]
                update_query = f"UPDATE {table_name} SET {set_clauses} WHERE {pk_column} = %s"
                
                success = execute_db(update_query, tuple(params))
                
                if success:
                    return jsonify({"status": "success", "message": f"{resource_name} berhasil diperbarui."}), 200
                return jsonify({"status": "error", "message": f"{resource_name} tidak ditemukan atau gagal memperbarui."}), 404
            except Exception as e:
                return jsonify({"status": "error", "message": f"Gagal memperbarui: {str(e)}"}), 500


# =======================================================================================
# INSTANTIATE CRUD ENDPOINTS UNTUK SEMUA DATA MASTER
# =======================================================================================

# Kelola Akun (Hati-hati dalam menggunakan ini, sebaiknya diatur via Dosen/Mahasiswa)
create_crud_endpoint(admin_bp, 'users', 'users', 'id_user')

# Kelola Dosen (PK: nip)
create_crud_endpoint(admin_bp, 'dosen', 'dosen', 'nip')

# Kelola Mahasiswa (PK: nim)
create_crud_endpoint(admin_bp, 'mahasiswa', 'mahasiswa', 'nim')

# Kelola Kelas (PK: id_kelas)
create_crud_endpoint(admin_bp, 'kelas', 'kelas', 'id_kelas')

# Kelola Matakuliah (PK: id_matakuliah)
create_crud_endpoint(admin_bp, 'matakuliah', 'matakuliah', 'id_matakuliah')

# Kelola Pertemuan (PK: id_pertemuan)
create_crud_endpoint(admin_bp, 'pertemuan', 'pertemuan', 'id_pertemuan')


# Endpoint Khusus: Logs Face Scan
@admin_bp.route('/logs/face-scan', methods=['GET'])
@admin_required
def log_face_scan():
    logs = query_db("SELECT * FROM face_scan_log ORDER BY created_at DESC")
    return jsonify({"status": "success", "logs": logs}), 200