# server/routes/absensi_routes.py

from flask import Blueprint, request, jsonify
from utils.jwt_auth import jwt_required
from services.absensi_service import submit_absensi
from services.sesi_service import get_sesi_aktif_mahasiswa, verify_barcode_absensi
from database.db import query_db

absensi_bp = Blueprint('absensi', __name__, url_prefix='/absensi')

# absensi
@absensi_bp.route('/sesi/aktif', methods=['GET'])
@jwt_required
def sesi_aktif():
    if request.user_data.get('level') != 'mahasiswa':
        return jsonify({"status": "error", "message": "Akses ditolak."}), 403
    
    nim = request.user_data.get('user_id')
    sesi_aktif = get_sesi_aktif_mahasiswa(nim)
    
    if sesi_aktif:
        return jsonify({"status": "success", "sesi_aktif": sesi_aktif}), 200
    else:
        return jsonify({"status": "error", "message": "Tidak ada sesi aktif untuk kelas Anda saat ini."}), 404

# verify-barcode endpoint
@absensi_bp.route('/verify-barcode', methods=['POST'])
@jwt_required
def verify_barcode():
    if request.user_data.get('level') != 'mahasiswa':
        return jsonify({"status": "error", "message": "Akses ditolak."}), 403

    data = request.json
    nim = request.user_data.get('user_id')
    kode_barcode = data.get('kode_barcode')

    if not kode_barcode:
        return jsonify({"status": "error", "message": "Kode barcode diperlukan."}), 400

    result, message = verify_barcode_absensi(nim, kode_barcode)

    if result:
        return jsonify({"status": "success", "id_sesi": result['id_sesi'], "id_pertemuan": result['id_pertemuan'], "message": message}), 200
    else:
        return jsonify({"status": "error", "message": message}), 400

@absensi_bp.route('/submit', methods=['POST'])
@jwt_required # Mahasiswa harus login
def absensi_submit():
    # Pastikan ini adalah user mahasiswa
    if request.user_data.get('level') != 'mahasiswa':
        return jsonify({"status": "error", "message": "Akses ditolak."}), 403
    
    data = request.json
    nim = request.user_data.get('user_id') # Ambil NIM dari token JWT
    id_sesi = data.get('id_sesi')
    metode = data.get('metode')
    lokasi_lat = data.get('lokasi_lat')
    lokasi_long = data.get('lokasi_long')
    image_base64 = data.get('image_base64') # Hanya diperlukan jika metode='face_recognition'

    if not all([id_sesi, metode, lokasi_lat, lokasi_long]):
        return jsonify({"status": "error", "message": "Data absensi tidak lengkap."}), 400

    success, message = submit_absensi(nim, id_sesi, metode, lokasi_lat, lokasi_long, image_base64)

    if success:
        return jsonify({"status": "success", "message": message}), 201
    else:
        return jsonify({"status": "error", "message": message}), 400

# Endpoint History
@absensi_bp.route('/history/<nim>', methods=['GET'])
@jwt_required
def absensi_history(nim):
    # Logika query untuk mendapatkan riwayat absensi mahasiswa
    # Anda bisa menggunakan JOIN atau view jika diperlukan
    history = query_db("SELECT * FROM absensi WHERE nim = %s ORDER BY waktu_absen DESC", (nim,))
    
    return jsonify({"status": "success", "history": history}), 200

