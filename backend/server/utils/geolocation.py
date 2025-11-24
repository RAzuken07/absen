import math
from config import Config

def calculate_distance(lat1, lon1, lat2, lon2):
    """
    Menghitung jarak antara dua titik koordinat (latitude, longitude)
    menggunakan formula Haversine. Hasil dalam KILOMETER.
    """
    R = Config.EARTH_RADIUS_KM # Radius Bumi (6371 km)
    
    # Konversi derajat ke radian
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)

    # Formula Haversine
    a = math.sin(delta_phi / 2)**2 + math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    
    distance_km = R * c
    
    # Konversi ke meter
    return distance_km * 1000 # Jarak dalam meter