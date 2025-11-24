// lib/screens/mahasiswa/history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/absensi_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/absensi_service.dart';
import '../../services/api_service.dart';
import '../../config/app_constants.dart';

// Definisi Provider untuk History (Fetch stateful data)
final absensiHistoryProvider = FutureProvider.autoDispose<List<AbsensiLog>>((ref) async {
  final user = ref.watch(authProvider).currentUser;
  final nim = user?.userId;
  
  if (nim == null || nim.isEmpty) {
    throw Exception("User NIM tidak ditemukan.");
  }
  
  final service = ref.watch(absensiServiceProvider);
  return service.getAbsensiHistory(nim);
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(absensiHistoryProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Absensi'),
        backgroundColor: PrimaryColor,
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) {
          String message = (err is ApiException) ? err.message : 'Gagal memuat data.';
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(DefaultPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 50),
                  const SizedBox(height: 10),
                  Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(absensiHistoryProvider),
                    child: const Text('Coba Lagi'),
                  )
                ],
              ),
            ),
          );
        },
        data: (historyList) {
          if (historyList.isEmpty) {
            return const Center(child: Text('Anda belum memiliki riwayat absensi.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(DefaultPadding),
            itemCount: historyList.length,
            itemBuilder: (context, index) {
              final log = historyList[index];
              return _buildAbsensiLogCard(log);
            },
          );
        },
      ),
    );
  }
  
  Widget _buildAbsensiLogCard(AbsensiLog log) {
    Color statusColor;
    IconData statusIcon;
    
    switch (log.status) {
      case 'hadir':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'sakit':
        statusColor = Colors.orange;
        statusIcon = Icons.medical_services;
        break;
      case 'izin':
        statusColor = Colors.amber;
        statusIcon = Icons.info;
        break;
      default: // alpha
        statusColor = Colors.red;
        statusIcon = Icons.close;
        break;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor, size: 30),
        title: Text(
          '${log.namaMatakuliah} Pertemuan Ke-${log.idPertemuan} (${log.status.toUpperCase()})',
          style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Waktu: ${log.waktuAbsen.substring(0, 19)}'),
            Text('Metode: ${log.metode.replaceAll('_', ' ')}'),
            if (log.metode == 'face_recognition')
              Text('Confidence Score: ${log.confidenceScore.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
          ],
        ),
      ),
    );
  }
}