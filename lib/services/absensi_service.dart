// lib/services/absensi_service.dart

import 'package:dio/dio.dart';
import '../models/absensi_model.dart';
import '../models/sesi_model.dart';
import 'api_service.dart';

class AbsensiService {
  final ApiService _apiService = ApiService();
  
  // --- FACE RECOGNITION ---

  // Endpoint: POST /face/register
  Future<String> registerFace(String userId, String userType, String imageBase64) async {
    try {
      final response = await _apiService.dio.post(
        '/face/register',
        data: {
          'user_id': userId,
          'user_type': userType, // 'mahasiswa' atau 'dosen'
          'image_base64': imageBase64,
        },
      );
      return response.data['message'];
    } on DioException {
      rethrow;
    }
  }

  // Endpoint: POST /face/verify (digunakan internal di /submit, tapi bisa dipanggil terpisah)
  Future<Map<String, dynamic>> verifyFace(String nim, String imageBase64) async {
    try {
      final response = await _apiService.dio.post(
        '/face/verify',
        data: {
          'nim': nim,
          'image_base64': imageBase64,
        },
      );
      
      return {
        'match': response.data['match'] as bool,
        'confidence_score': response.data['confidence_score'] as double,
        'message': response.data['message'] as String,
      };
    } on DioException {
      rethrow;
    }
  }


  // --- ABSENSI MAHASISWA ---

  // Endpoint: GET /absensi/sesi/aktif
  Future<List<SesiAbsensi>> getSesiAktif() async {
    try {
      final response = await _apiService.dio.get('/absensi/sesi/aktif');
      
      final List<dynamic> sesiList = response.data['sesi_aktif'];
      return sesiList.map((json) => SesiAbsensi.fromJson(json)).toList();
      
    } on DioException {
      rethrow;
    }
  }

  // Endpoint: POST /absensi/verify-barcode
  Future<Map<String, int>> verifyBarcode(String nim, String kodeBarcode) async {
    try {
      final response = await _apiService.dio.post(
        '/absensi/verify-barcode',
        data: {
          'nim': nim,
          'kode_barcode': kodeBarcode,
        },
      );
      
      return {
        'id_sesi': response.data['id_sesi'] as int,
        'id_pertemuan': response.data['id_pertemuan'] as int,
      };
    } on DioException {
      rethrow;
    }
  }

  // Endpoint: POST /absensi/submit
  Future<String> submitAbsensi({
    required String nim,
    required int idSesi,
    required String metode,
    required double lokasiLat,
    required double lokasiLong,
    String? imageBase64,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/absensi/submit',
        data: {
          'nim': nim,
          'id_sesi': idSesi,
          'metode': metode,
          'lokasi_lat': lokasiLat,
          'lokasi_long': lokasiLong,
          'image_base64': imageBase64, // Hanya dikirim jika metode='face_recognition'
        },
      );
      return response.data['message'];
    } on DioException {
      rethrow;
    }
  }

  // Endpoint: GET /absensi/history/{nim}
  Future<List<AbsensiLog>> getAbsensiHistory(String nim) async {
    try {
      final response = await _apiService.dio.get('/absensi/history/$nim');
      
      final List<dynamic> historyList = response.data['history'];
      return historyList.map((json) => AbsensiLog.fromJson(json)).toList();
      
    } on DioException {
      rethrow;
    }
  }
}