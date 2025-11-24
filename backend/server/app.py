# server/app.py - FINAL IMPLEMENTASI FASE 2

from flask import Flask, jsonify, request
from flask_cors import CORS
from config import Config
from utils.jwt_auth import jwt_required 
from utils.jwt_auth import generate_token 

# Import Semua Blueprints
from routes.face_routes import face_bp
from routes.absensi_routes import absensi_bp
from routes.dosen_routes import dosen_bp
from routes.admin_routes import admin_bp

# PENTING: Untuk Hashing Password di proyek nyata, ganti 'password' == password:
from database.db import query_db 

app = Flask(__name__)
app.config.from_object(Config)
CORS(app) 

# --- Daftarkan Blueprints/Routes ---
app.register_blueprint(face_bp)
app.register_blueprint(absensi_bp)
app.register_blueprint(dosen_bp)
app.register_blueprint(admin_bp)

# --- AUTH ROUTE (IMPLEMENTASI FINAL FASE 2) ---
@app.route('/auth/login', methods=['POST'])
def login():
    data = request.json
    username = data.get('username')
    password = data.get('password')

    user = query_db("SELECT * FROM users WHERE username = %s", (username,), fetchone=True)

    if not user:
        return jsonify({"status": "error", "message": "Username tidak ditemukan."}), 404
        
    # PERINGATAN: Password di SQL dump tidak di-hash. 
    # Gunakan perbandingan plain text SEMENTARA
    if user['password'] == password: 
        user_id = user['nim'] if user['level'] == 'mahasiswa' else user['nip']
        token = generate_token(user_id=user_id, level=user['level'])
        
        return jsonify({
            "status": "success", 
            "token": token, 
            "level": user['level'], 
            "user_id": user_id,
            "nama": user['nama']
        }), 200
    else:
        return jsonify({"status": "error", "message": "Password salah."}), 401

@app.route('/protected', methods=['GET'])
@jwt_required
def protected():
    return jsonify({
        "message": "Akses berhasil!",
        "user": request.user_data
    })

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000, debug=True)