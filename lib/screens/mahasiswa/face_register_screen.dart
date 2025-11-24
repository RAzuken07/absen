// lib/screens/mahasiswa/face_register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'dart:convert';
import '../../providers/auth_provider.dart';
import '../../services/absensi_service.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/error_dialog.dart';
import '../../config/app_constants.dart';
import '../../main.dart'; 

class FaceRegisterScreen extends ConsumerStatefulWidget {
  const FaceRegisterScreen({super.key});

  @override
  ConsumerState<FaceRegisterScreen> createState() => _FaceRegisterScreenState();
}

class _FaceRegisterScreenState extends ConsumerState<FaceRegisterScreen> {
  
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isRegistering = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (cameras.isEmpty) { 
      if(mounted) showErrorDialog(context, 'Error', 'Tidak ada kamera yang tersedia.');
      return;
    }
    
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() { _isCameraInitialized = true; });
    } on CameraException catch (e) {
      if(mounted) showErrorDialog(context, 'Error Kamera', 'Gagal inisialisasi kamera: ${e.code}');
    }
  }

  Future<void> _captureAndRegister() async {
    if (!_isCameraInitialized) { return; }
    setState(() { _isRegistering = true; });

    try {
      final XFile imageFile = await _cameraController!.takePicture();
      List<int> imageBytes = await imageFile.readAsBytes();
      String imageBase64 = base64Encode(imageBytes);

      final nim = ref.read(authProvider).currentUser?.userId ?? '';
      if (nim.isEmpty) { throw ApiException('Data NIM tidak ditemukan.', 400); }

      final message = await ref.read(absensiServiceProvider).registerFace(
        nim, 'mahasiswa', imageBase64,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pendaftaran Wajah Berhasil: $message'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop();
      
    } catch (e) {
      if (!mounted) return;
      String errorMessage = (e is ApiException) ? e.message : 'Pendaftaran Gagal.';
      showErrorDialog(context, 'Pendaftaran Gagal', errorMessage);
    } finally {
      if (!mounted) return;
      setState(() { _isRegistering = false; });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Wajah (Face ID)'),
        backgroundColor: PrimaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DefaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pastikan Wajah Anda berada di tengah layar dan pencahayaan cukup.'),
            const SizedBox(height: 20),
            
            Container(
              height: 400,
              decoration: BoxDecoration(border: Border.all(color: PrimaryColor, width: 3), borderRadius: BorderRadius.circular(15)),
              child: _isCameraInitialized && _cameraController!.value.isInitialized
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: _cameraController!.value.aspectRatio,
                        child: CameraPreview(_cameraController!),
                      ),
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
            const SizedBox(height: 30),

            CustomButton(
              text: 'DAFTARKAN WAJAH SAYA',
              onPressed: (_isCameraInitialized && !_isRegistering) ? _captureAndRegister : null,
              isLoading: _isRegistering,
              backgroundColor: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }
}