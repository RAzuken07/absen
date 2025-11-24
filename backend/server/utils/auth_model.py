# backend/utils/auth_model.py

class User:
    """
    Model data sederhana untuk representasi pengguna dari tabel users.
    Berguna untuk standardisasi data yang disimpan dalam sesi atau JWT.
    """
    def __init__(self, id_user, username, nama, level, **kwargs):
        self.id_user = id_user
        self.username = username
        self.nama = nama
        self.level = level
        # kwargs bisa mencakup nip, nim, atau field lain yang spesifik
        for key, value in kwargs.items():
            setattr(self, key, value)

    def to_dict(self):
        """Mengembalikan representasi dictionary untuk digunakan dalam JSON/JWT."""
        data = {
            'id_user': self.id_user,
            'username': self.username,
            'nama': self.nama,
            'level': self.level,
        }
        # Tambahkan atribut dinamis (seperti 'nip' atau 'nim')
        for key, value in self.__dict__.items():
            if key not in data and not key.startswith('_'):
                data[key] = value
        return data

    @staticmethod
    def from_db_row(row):
        """Membuat instance User dari row hasil query database (dictionary)."""
        if not row:
            return None
        # Pisahkan field utama dan sisanya
        primary_fields = {k: row.pop(k) for k in ['id_user', 'username', 'nama', 'level'] if k in row}
        # Sisa row menjadi kwargs (misal: nip, nim, dll.)
        return User(**primary_fields, **row)