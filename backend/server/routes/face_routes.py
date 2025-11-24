# server/routes/face_routes.py

from flask import Blueprint, request, jsonify
from services.face_service import register_face, verify_face

face_bp = Blueprint('face', __name__, url_prefix='/face')

@face_bp.route('/register', methods=['POST'])
def register():
    data = request.json
    user_id = data.get('user_id')
    user_type = data.get('user_type')
    image_base64 = data.get('image_base64')

    if not all([user_id, user_type, image_base64]):
        return jsonify({"status": "error", "message": "Input tidak lengkap."}), 400

    success, message = register_face(user_id, user_type, image_base64)

    if success:
        return jsonify({"status": "success", "message": message}), 201
    else:
        return jsonify({"status": "error", "message": message}), 400

@face_bp.route('/verify', methods=['POST'])
def verify():
    data = request.json
    nim = data.get('nim')
    image_base64 = data.get('image_base64')

    if not all([nim, image_base64]):
        return jsonify({"status": "error", "message": "Input tidak lengkap."}), 400

    match, confidence_score, message = verify_face(nim, image_base64)
    
    # Catatan: Log ke face_scan_log harus ditambahkan di sini atau di logic absensi submit

    return jsonify({
        "status": "success" if match else "error",
        "match": match,
        "confidence_score": confidence_score,
        "message": message
    }), 200