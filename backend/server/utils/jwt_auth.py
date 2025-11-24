# server/utils/jwt_auth.py

from functools import wraps
import jwt
import datetime
from flask import request, jsonify
from config import Config

def generate_token(user_id, level):
    """Menghasilkan token JWT."""
    payload = {
        'user_id': user_id,
        'level': level,
        'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=24), # Kadaluarsa 24 jam
        'iat': datetime.datetime.utcnow()
    }
    return jwt.encode(payload, Config.JWT_SECRET_KEY, algorithm='HS256')

def jwt_required(f):
    """Decorator untuk melindungi rute API."""
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        # Ambil token dari header Authorization
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            try:
                # Format: "Bearer <token>"
                token = auth_header.split(" ")[1]
            except IndexError:
                return jsonify({'message': 'Token format salah: Bearer token diperlukan'}), 401

        if not token:
            return jsonify({'message': 'Token JWT tidak ada'}), 401
        
        try:
            # Decode token
            data = jwt.decode(token, Config.JWT_SECRET_KEY, algorithms=['HS256'])
            request.user_data = data # Simpan payload user ke objek request
        except jwt.ExpiredSignatureError:
            return jsonify({'message': 'Token kadaluarsa'}), 401
        except jwt.InvalidTokenError:
            return jsonify({'message': 'Token tidak valid'}), 401

        return f(*args, **kwargs)
    return decorated