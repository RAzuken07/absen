// lib/models/auth_model.dart

class User {
  final String token;
  final String level;
  final String userId;
  final String nama;

  User({
    required this.token,
    required this.level,
    required this.userId,
    required this.nama,
  });

  // Factory constructor untuk membuat objek User dari JSON respons login
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      token: json['token'] as String,
      level: json['level'] as String,
      // API Flask mengembalikan 'user_id'
      userId: json['user_id'] as String, 
      nama: json['nama'] as String,
    );
  }

  // Konversi objek User kembali ke Map (penting untuk penyimpanan lokal di SharedPreferences)
  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'level': level,
      'user_id': userId,
      'nama': nama,
    };
  }
}