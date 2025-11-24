// lib/config/app_constants.dart

import 'package:flutter/material.dart';

// --- APLIKASI DASAR ---
const String AppName = 'Absensi AI Kampus';
const String AppVersion = '1.0.0';
const String DefaultAppLocale = 'id';

// --- PENYIMPANAN (SHARED PREFERENCES KEYS) ---
// Keys yang digunakan oleh AuthService untuk menyimpan data di penyimpanan lokal
const String SpTokenKey = 'jwt_token';
const String SpUserIdKey = 'user_id';
const String SpUserLevelKey = 'user_level';

// --- KONFIGURASI ABSENSI ---
// Radius default untuk absensi berbasis GPS (dalam meter)
const int DefaultRadiusMeter = 50; 
// Durasi default sesi absensi (dalam menit)
const int DefaultDurationMinutes = 15; 
// Ambang batas (threshold) minimum score yang dibutuhkan agar Face Recognition dianggap cocok
const double FaceRecognitionThreshold = 0.65; 

// --- TEMA & STYLE DASAR ---
// Warna utama aplikasi (PrimaryColor digunakan di AppBar, Button, dll.)
const Color PrimaryColor = Colors.blue;
const Color SecondaryColor = Color(0xFF1E88E5); 
// Padding default untuk layout
const double DefaultPadding = 16.0;