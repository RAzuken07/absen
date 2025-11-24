class Config:
    DB_HOST = "localhost" 
    DB_USER = "root"
    DB_PASSWORD = ""  
    DB_NAME = "absensi"

    # --- Flask & JWT Configuration ---
    SECRET_KEY = "123456789"  # Ganti dengan kunci rahasia yang kuat!
    JWT_SECRET_KEY = SECRET_KEY 
    
    # --- Face Recognition Configuration ---
    FACE_RECOGNITION_TOLERANCE = 0.6  # Batas ambang untuk jarak Euclidean (0.6 umumnya baik)

    # --- Geolocation Configuration ---
    EARTH_RADIUS_KM = 6371 # Radius bumi untuk perhitungan Haversine
    
# Import dari config.py di file lain:
# from config import Config

# server/config.py - Konfigurasi Global Aplikasi
