# server/routes/dosen_routes.py

from flask import Blueprint, request, jsonify
from utils.jwt_auth import jwt_required
from services.sesi_service import open_sesi, generate_barcode, get_rekap_kehadiran, get_sesi_kehadiran_realtime
from functools import wraps # Diperlukan untuk decorator

dosen_bp = Blueprint('dosen', __name__, url_prefix='/dosen')

@dosen_bp.route('/sesi/open', methods=['POST'])
@jwt_required
def sesi_open():
    if request.user_data.get('level') != 'dosen':
        return jsonify({"status": "error", "message": "Akses ditolak. Hanya untuk Dosen."}), 403
        
    data = request.json
    nip_dosen = request.user_data.get('user_id') # Ambil NIP dari token JWT
    
    # ... (Ambil semua data yang diperlukan dari request.json) ...
    id_pertemuan = data.get('id_pertemuan')
    durasi_menit = data.get('durasi_menit')
    lokasi_lat = data.get('lokasi_lat')
    lokasi_long = data.get('lokasi_long')
    radius_meter = data.get('radius_meter')

    if not all([id_pertemuan, durasi_menit, lokasi_lat, lokasi_long, radius_meter]):
        return jsonify({"status": "error", "message": "Input tidak lengkap."}), 400

    id_sesi, message = open_sesi(id_pertemuan, nip_dosen, durasi_menit, lokasi_lat, lokasi_long, radius_meter)
    
    if id_sesi:
        return jsonify({"status": "success", "id_sesi": id_sesi, "message": message}), 201
    else:
        return jsonify({"status": "error", "message": message}), 400

@dosen_bp.route('/barcode/generate', methods=['POST'])
@jwt_required
def barcode_generate():
    if request.user_data.get('level') != 'dosen':
        return jsonify({"status": "error", "message": "Akses ditolak. Hanya untuk Dosen."}), 403
    
    data = request.json
    nip_dosen = request.user_data.get('user_id') 
    id_sesi = data.get('id_sesi')
    durasi_menit = data.get('durasi_menit', 10) # Barcode default aktif 10 menit

    kode_barcode, message = generate_barcode(id_sesi, nip_dosen, durasi_menit)
    
    if kode_barcode:
        return jsonify({"status": "success", "kode_barcode": kode_barcode, "message": message}), 201
    else:
        return jsonify({"status": "error", "message": message}), 400

@dosen_bp.route('/rekap/<int:id_kelas>', methods=['GET'])
@jwt_required
def rekap_kehadiran(id_kelas):
    if request.user_data.get('level') not in ('dosen', 'admin'):
        return jsonify({"status": "error", "message": "Akses ditolak."}), 403
        
    rekap = get_rekap_kehadiran(id_kelas)
    
    return jsonify({"status": "success", "rekap": rekap}), 200

@dosen_bp.route('/sesi/<int:id_sesi>/kehadiran', methods=['GET'])
@jwt_required
def sesi_kehadiran_realtime(id_sesi):
    if request.user_data.get('level') not in ('dosen', 'admin'):
        return jsonify({"status": "error", "message": "Akses ditolak."}), 403
        
    kehadiran = get_sesi_kehadiran_realtime(id_sesi)
    
    return jsonify({"status": "success", "kehadiran": kehadiran}), 200