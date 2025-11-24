# server/services/face_service.py

import face_recognition
import numpy as np
import base64
from io import BytesIO
from PIL import Image
import json
from database.db import execute_db, query_db
from config import Config

def base64_to_image(base64_string):
    """Mengkonversi Base64 string ke objek gambar."""
    try:
        image_data = base64.b64decode(base64_string)
        return Image.open(BytesIO(image_data))
    except:
        return None

def register_face(user_id, user_type, image_base64):
    """Mendeteksi wajah, menghasilkan descriptor, dan menyimpannya ke DB."""
    img = base64_to_image(image_base64)
    if not img:
        return False, "Format gambar tidak valid."

    # Konversi ke array numpy (RGB)
    rgb_frame = np.array(img.convert('RGB'))

    # Dapatkan face encodings
    encodings = face_recognition.face_encodings(rgb_frame)

    if not encodings:
        return False, "Tidak ada wajah terdeteksi dalam gambar."

    # Ambil encoding pertama
    face_descriptor = encodings[0].tolist() # Konversi numpy array ke list agar bisa disimpan sebagai JSON/TEXT

    # Tentukan tabel dan kolom primary key
    if user_type == 'dosen':
        table = 'dosen'
        pk_col = 'nip'
    elif user_type == 'mahasiswa':
        table = 'mahasiswa'
        pk_col = 'nim'
    else:
        return False, "Tipe pengguna tidak valid."

    # Simpan descriptor ke database dan set face_registered = 1
    query = f"""
        UPDATE {table} 
        SET face_descriptor = %s, face_registered = 1, foto_wajah = 'registered' 
        WHERE {pk_col} = %s
    """
    success = execute_db(query, (json.dumps(face_descriptor), user_id))

    if success:
        return True, "Wajah berhasil didaftarkan."
    else:
        return False, "Gagal menyimpan ke database."

def verify_face(nim, image_base64):
    """Membandingkan wajah yang di-scan dengan descriptor yang tersimpan."""
    # 1. Ambil descriptor tersimpan
    db_data = query_db("SELECT face_descriptor FROM mahasiswa WHERE nim = %s AND face_registered = 1", (nim,), fetchone=True)
    if not db_data or not db_data.get('face_descriptor'):
        return False, 0.0, "Wajah belum terdaftar di database."

    known_descriptor = np.array(json.loads(db_data['face_descriptor']))

    # 2. Proses gambar input
    img = base64_to_image(image_base64)
    if not img:
        return False, 0.0, "Format gambar input tidak valid."
    
    rgb_frame = np.array(img.convert('RGB'))
    unknown_encodings = face_recognition.face_encodings(rgb_frame)

    if not unknown_encodings:
        return False, 0.0, "Tidak ada wajah terdeteksi dalam gambar input."

    unknown_descriptor = unknown_encodings[0]

    # 3. Bandingkan wajah (Hitung Jarak)
    # face_recognition.compare_faces mengembalikan array boolean
    # face_recognition.face_distance mengembalikan array jarak Euclidean
    
    distances = face_recognition.face_distance([known_descriptor], unknown_descriptor)
    distance = distances[0] # Jarak Euclidean

    # 4. Tentukan hasil
    if distance <= Config.FACE_RECOGNITION_TOLERANCE:
        # Confidence Score: 1 - distance (dibatasi agar tidak melebihi 1)
        confidence_score = round(max(0.0, 1.0 - distance), 2)
        return True, confidence_score, "Wajah cocok."
    else:
        confidence_score = round(max(0.0, 1.0 - distance), 2)
        return False, confidence_score, "Wajah tidak cocok."