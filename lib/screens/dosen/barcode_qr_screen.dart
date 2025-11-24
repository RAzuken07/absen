// lib/screens/dosen/barcode_qr_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/sesi_model.dart';
import '../../config/app_constants.dart';
// Asumsi: package qr_flutter sudah diinstal dan di-import
// import 'package:qr_flutter/qr_flutter.dart'; 

class BarcodeQrScreen extends ConsumerWidget {
  // Model SesiAbsensi yang sudah dibuka dikirim melalui navigator
  final SesiAbsensi sesi; 
  
  const BarcodeQrScreen({super.key, required this.sesi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // QR data biasanya berupa kombinasi ID Sesi, Waktu, dan Secret Key.
    // Kita asumsikan data ini sudah ada dalam model SesiAbsensi (atau langsung dibentuk di sini)
    // Contoh data: "ABSENSI_SESI:${sesi.idSesi}|T:${sesi.waktuBuka}"
    final String qrData = 'ABSENSI_SESI_ID:${sesi.idSesi}|MATKUL:${sesi.namaMatakuliah}';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Absensi'),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DefaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Tunjukkan QR Code ini kepada Mahasiswa untuk melakukan Absensi',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: PrimaryColor),
              ),
              const SizedBox(height: 30),

              // Placeholder untuk Widget QR Code
              Container(
                width: 250,
                height: 250,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(10)
                ),
                // Jika package qr_flutter terinstal, gunakan kode ini:
                /*
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
                */
                // Karena kita tidak bisa menginstal package, kita gunakan placeholder Icon:
                child: const Icon(Icons.qr_code_2, size: 200, color: Colors.black54),
              ),
              const SizedBox(height: 30),
              
              Card(
                elevation: 2,
                color: Colors.orange.shade50,
                child: ListTile(
                  leading: const Icon(Icons.alarm_on, color: Colors.orange),
                  title: Text(sesi.namaMatakuliah, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'Kelas: ${sesi.namaKelas}\nDibuka pada: ${sesi.waktuBuka.substring(0, 19)}\nBerakhir dalam: ${sesi.durasiMenit} menit'
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Perhatian: Sesi ini akan berakhir secara otomatis setelah durasi habis.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}