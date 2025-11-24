// lib/services/dosen_service.dart

import 'package:dio/dio.dart';
import '../models/absensi_model.dart';
import 'api_service.dart';

class DosenService {
  final ApiService _apiService = ApiService();

  // Endpoint: POST /dosen/sesi/open
  Future<int> openSesi({
    required String nipDosen,
    required int idPertemuan,
    required int durasiMenit,
    required double lokasiLat,
    required double lokasiLong,
    required double radiusMeter,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/dosen/sesi/open',
        data: {
          'nip_dosen': nipDosen,
          'id_pertemuan': idPertemuan,
          'durasi_menit': durasiMenit,
          'lokasi_lat': lokasiLat,
          'lokasi_long': lokasiLong,
          'radius_meter': radiusMeter,
        },
      );
      // Mengembalikan id_sesi yang baru dibuat
      return response.data['id_sesi'] as int;
    } on DioException {
      rethrow;
    }
  }

  // Endpoint: POST /dosen/barcode/generate
  Future<String> generateBarcode(int idSesi, String nipDosen) async {
    try {
      final response = await _apiService.dio.post(
        '/dosen/barcode/generate',
        data: {
          'id_sesi': idSesi,
          'nip_dosen': nipDosen,
        },
      );
      // Mengembalikan kode barcode (string)
      return response.data['kode_barcode'] as String; 
    } on DioException {
      rethrow;
    }
  }

  // Endpoint: GET /dosen/rekap/{id_kelas}
  Future<List<RekapKehadiran>> getRekapKehadiran(int idKelas) async {
    try {
      final response = await _apiService.dio.get('/dosen/rekap/$idKelas');
      
      final List<dynamic> rekapList = response.data['rekap'];
      return rekapList.map((json) => RekapKehadiran.fromJson(json)).toList();
      
    } on DioException {
      rethrow;
    }
  }

  // Endpoint: GET /dosen/sesi/{id_sesi}/kehadiran (Realtime Monitoring)
  Future<List<Map<String, dynamic>>> getSesiKehadiranRealtime(int idSesi) async {
    try {
      final response = await _apiService.dio.get('/dosen/sesi/$idSesi/kehadiran');
      
      final List<dynamic> kehadiranList = response.data['kehadiran'];
      // Mengembalikan raw Map karena data ini mungkin bervariasi
      return kehadiranList.cast<Map<String, dynamic>>(); 
      
    } on DioException {
      rethrow;
    }
  }
}