// lib/services/auth_service.dart

import 'package:dio/dio.dart';
import '../models/auth_model.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  // Memuat user yang tersimpan di SharedPreferences saat aplikasi dimulai
  Future<User?> loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final level = prefs.getString('user_level');
    final userId = prefs.getString('user_id');
    final nama = prefs.getString('user_nama');
    
    if (token != null && level != null && userId != null && nama != null) {
      return User(userId: userId, nama: nama, level: level, token: token);
    }
    return null;
  }

  // Login (Memanggil /auth/login)
  Future<User> login(String username, String password) async {
    try {
      final response = await _apiService.dio.post(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );

      final data = response.data;
      final user = User.fromJson(data);
      
      // Simpan data user ke SharedPreferences (selain token yang sudah di handle ApiService)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_level', user.level);
      await prefs.setString('user_id', user.userId);
      await prefs.setString('user_nama', user.nama);
      
      return user;
    } on DioException {
      rethrow;
    }
  }

  // Logout (Hanya menghapus token dan data lokal)
  Future<void> logout() async {
    await _apiService.deleteToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_level');
    await prefs.remove('user_id');
    await prefs.remove('user_nama');
  }
}