// lib/screens/mahasiswa/absensi_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:io';

import '../../models/sesi_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/absensi_service.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/error_dialog.dart';
import '../../config/app_constants.dart';
import '../../main.dart';

// Catatan: Pastikan List<CameraDescription> cameras diinisialisasi di main.dart

class AbsensiScreen extends ConsumerStatefulWidget {
  final SesiAbsensi sesi;
  const AbsensiScreen({super.key, required this.sesi});

  @override
  ConsumerState<AbsensiScreen> createState() => _AbsensiScreenState();
}

class _AbsensiScreenState extends ConsumerState<AbsensiScreen> with WidgetsBindingObserver {
  
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  Position? _currentPosition;
  double _distanceMeters = double.infinity;
  bool _isLocationValid = false;
  String _locationStatus = 'Memeriksa lokasi...';
  bool _isSubmitting = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCameraAndLocation();
  }

  // Handle app lifecycle (pause/resume) untuk kamera
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCameraAndLocation();
    }
  }

  Future<void> _initializeCameraAndLocation() async {
    await _checkLocationAndPermissions();
    
    // Inisialisasi Kamera Depan
    if (cameras.isEmpty) { return; }
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _cameraController = CameraController(
      frontCamera, ResolutionPreset.medium, enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() { _isCameraInitialized = true; });
    } on CameraException catch (e) {
      if(mounted) showErrorDialog(context, 'Error Kamera', 'Gagal inisialisasi kamera: ${e.code}');
    }
  }

  Future<void> _checkLocationAndPermissions() async {
    // ... Logika Pengecekan Izin GPS, GPS Aktif, Ambil Posisi, dan Hitung Jarak ...
    if (!mounted) return;
    setState(() { _locationStatus = 'Memeriksa izin lokasi...'; });
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if(mounted) setState(() {_locationStatus = 'Izin lokasi ditolak.'; _isLocationValid = false;});
        return;
      }
    }
    
    bool isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      if(mounted) setState(() {_locationStatus = 'GPS tidak aktif. Mohon aktifkan.'; _isLocationValid = false;});
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high, timeLimit: const Duration(seconds: 10));
      double distance = Geolocator.distanceBetween(
        position.latitude, position.longitude, widget.sesi.lokasiLat, widget.sesi.lokasiLong,
      );

      if (!mounted) return;
      setState(() {
        _currentPosition = position;
        _distanceMeters = distance;
        _isLocationValid = distance <= widget.sesi.radiusMeter;
        _locationStatus = _isLocationValid 
          ? 'Lokasi Valid! Jarak: ${distance.toStringAsFixed(1)}m'
          : 'Anda terlalu jauh (${distance.toStringAsFixed(1)}m). Max Radius: ${widget.sesi.radiusMeter.toInt()}m';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {_locationStatus = 'Gagal mengambil lokasi.'; _isLocationValid = false;});
    }
  }

  Future<void> _captureAndSubmit() async {
    if (!_isLocationValid || _currentPosition == null) { return; }
    setState(() { _isSubmitting = true; });

    try {
      final XFile imageFile = await _cameraController!.takePicture();
      String imageBase64 = base64Encode(await imageFile.readAsBytes());
      final nim = ref.read(authProvider).currentUser?.userId ?? '';

      final message = await ref.read(absensiServiceProvider).submitAbsensi(
        nim: nim,
        idSesi: widget.sesi.idSesi,
        metode: 'face_recognition',
        lokasiLat: _currentPosition!.latitude,
        lokasiLong: _currentPosition!.longitude,
        imageBase64: imageBase64,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Absensi Berhasil: $message'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop();
      
    } catch (e) {
      if (!mounted) return;
      String errorMessage = (e is ApiException) ? e.message : 'Absensi Gagal. Cek koneksi.';
      showErrorDialog(context, 'Absensi Gagal', errorMessage);
    } finally {
      if (!mounted) return;
      setState(() { _isSubmitting = false; });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.sesi.namaMatakuliah),
          backgroundColor: PrimaryColor,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.face_retouching_natural), text: 'Face Scan'),
              Tab(icon: Icon(Icons.qr_code_scanner), text: 'QR Scan'),
            ],
          ),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildFaceRecognitionTab(),
            _buildQrScanTab(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFaceRecognitionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DefaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSessionInfo(),
          const SizedBox(height: 20),
          _buildLocationStatusCard(),
          const SizedBox(height: 20),
          Container(
            height: 300,
            decoration: BoxDecoration(border: Border.all(color: PrimaryColor, width: 2), borderRadius: BorderRadius.circular(10)),
            child: _isCameraInitialized && _cameraController!.value.isInitialized
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: _cameraController!.value.aspectRatio,
                        child: CameraPreview(_cameraController!),
                      ),
                    ),
                  )
                : const Center(child: Text('Memuat Kamera...')),
          ),
          const SizedBox(height: 30),
          CustomButton(
            text: 'ABSEN SEKARANG (Face Recognition)',
            onPressed: (_isLocationValid && !_isSubmitting) ? _captureAndSubmit : null,
            isLoading: _isSubmitting,
            backgroundColor: _isLocationValid ? Colors.green : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildQrScanTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DefaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_scanner, size: 80, color: Colors.blueGrey),
            const SizedBox(height: 20),
            const Text('Fitur QR Code Scanning belum diimplementasikan. Harap gunakan Face Scan.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
            const SizedBox(height: 40),
            CustomButton(
              text: 'Mulai Pindai QR Code',
              onPressed: _isLocationValid ? () => showErrorDialog(context, 'Peringatan', 'Fitur QR Scan belum aktif.') : null,
              backgroundColor: _isLocationValid ? Colors.orange : Colors.grey,
            ),
             const SizedBox(height: 10),
            _buildLocationStatusCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationStatusCard() {
    return Card(
      color: _isLocationValid ? Colors.green.shade50 : Colors.red.shade50,
      elevation: 1,
      child: ListTile(
        leading: Icon(_isLocationValid ? Icons.check_circle : Icons.warning, color: _isLocationValid ? Colors.green : Colors.red),
        title: const Text('Status Lokasi GPS', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(_locationStatus),
        trailing: IconButton(icon: const Icon(Icons.refresh), onPressed: _checkLocationAndPermissions),
      ),
    );
  }
  
  Widget _buildSessionInfo() {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.class_, color: PrimaryColor),
        title: Text(widget.sesi.namaMatakuliah, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Dosen: ${widget.sesi.namaDosen}\nRadius Max: ${widget.sesi.radiusMeter.toInt()}m'),
      ),
    );
  }
}