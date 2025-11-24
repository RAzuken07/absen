// lib/services/api_service.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/base_url.dart';

// Class untuk custom error handling
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (Code: $statusCode)';
}

class ApiService {
  final Dio _dio = Dio();
  static const String _tokenKey = 'jwt_token';
  
  // Instance Singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
    _dio.options.contentType = 'application/json';
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        if (kDebugMode) {
          print('Dio Error: ${e.response?.statusCode} | ${e.message}');
        }
        
        // Ekstraksi pesan error dari respons Flask JSON
        String errorMessage = e.response?.data?['message'] ?? e.message ?? 'Terjadi kesalahan jaringan/server.';
        
        return handler.next(DioException(
          requestOptions: e.requestOptions,
          error: ApiException(errorMessage, e.response?.statusCode ?? 500),
          response: e.response,
        ));
      },
    ));
  }

  // --- Token Management ---

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
  
  Dio get dio => _dio;
}