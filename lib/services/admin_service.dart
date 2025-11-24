// lib/services/admin_service.dart

import 'package:dio/dio.dart';
import '../models/admin_model.dart';
import 'api_service.dart';

class AdminService {
  final ApiService _apiService = ApiService();

  // --- CRUD TEMPLATE ---
  
  // Fungsi generik untuk mengambil semua data dari tabel (Read All)
  Future<List<T>> readAll<T>(String endpoint, T Function(Map<String, dynamic>) fromJson) async {
    try {
      final response = await _apiService.dio.get('/admin/$endpoint');
      final List<dynamic> dataList = response.data[endpoint] ?? [];
      return dataList.map((json) => fromJson(json)).toList();
    } on DioException {
      rethrow;
    }
  }

  // Fungsi generik untuk membuat data baru (Create)
  Future<String> createData(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.dio.post('/admin/$endpoint', data: data);
      return response.data['message'] ?? 'Data berhasil ditambahkan.';
    } on DioException {
      rethrow;
    }
  }

  // Fungsi generik untuk memperbarui data (Update)
  Future<String> updateData(String endpoint, String pkValue, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.dio.put('/admin/$endpoint/$pkValue', data: data);
      return response.data['message'] ?? 'Data berhasil diperbarui.';
    } on DioException {
      rethrow;
    }
  }

  // Fungsi generik untuk menghapus data (Delete)
  Future<String> deleteData(String endpoint, String pkValue) async {
    try {
      final response = await _apiService.dio.delete('/admin/$endpoint/$pkValue');
      return response.data['message'] ?? 'Data berhasil dihapus.';
    } on DioException {
      rethrow;
    }
  }

  // --- SPECIFIC CALLS ---
  
  // Contoh: CRUD Kelas
  Future<List<Kelas>> getAllKelas() => readAll('kelas', Kelas.fromJson);
  Future<String> createKelas(Map<String, dynamic> data) => createData('kelas', data);
  // ... dan seterusnya untuk Matakuliah, Pertemuan, dan Users
  
  // Endpoint Log
  Future<List<Map<String, dynamic>>> getFaceScanLogs() async {
    try {
      final response = await _apiService.dio.get('/admin/logs/face-scan');
      final List<dynamic> logList = response.data['logs'];
      return logList.cast<Map<String, dynamic>>();
    } on DioException {
      rethrow;
    }
  }
}