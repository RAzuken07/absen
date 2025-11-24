// lib/screens/dosen/rekap_kehadiran_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/admin_model.dart'; // Menggunakan model Kelas
import '../../models/absensi_model.dart'; // Menggunakan model RekapKehadiran
import '../../services/dosen_service.dart';
import '../../services/api_service.dart';
import '../../config/app_constants.dart';

// Definisi Provider untuk Rekap Kehadiran Kelas
final rekapKehadiranProvider = FutureProvider.family.autoDispose<List<RekapKehadiran>, int>((ref, idKelas) async {
  final service = ref.watch(dosenServiceProvider); 
  return service.getRekapKehadiran(idKelas);
});

class RekapKehadiranScreen extends ConsumerWidget {
  final Kelas kelas;
  const RekapKehadiranScreen({super.key, required this.kelas});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch status rekap berdasarkan idKelas
    final rekapAsync = ref.watch(rekapKehadiranProvider(kelas.idKelas));
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Rekap Kehadiran: ${kelas.namaMatakuliah} (${kelas.namaKelas})'),
        backgroundColor: Colors.deepOrange,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(rekapKehadiranProvider(kelas.idKelas));
        },
        child: rekapAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) {
            String message = (err is ApiException) ? err.message : 'Gagal memuat rekap data.';
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
                      onPressed: () => ref.invalidate(rekapKehadiranProvider(kelas.idKelas)),
                      child: const Text('Coba Lagi'),
                    )
                  ],
                ),
              ),
            );
          },
          data: (rekapList) {
            if (rekapList.isEmpty) {
              return const Center(child: Text('Tidak ada data rekap kehadiran untuk kelas ini.'));
            }
            return _buildDataTable(rekapList);
          },
        ),
      ),
    );
  }

  Widget _buildDataTable(List<RekapKehadiran> rekapList) {
    // Menghitung total pertemuan berdasarkan data mahasiswa pertama
    final totalPertemuan = rekapList.first.totalPertemuan;
    
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 18,
          dataRowMinHeight: 40,
          dataRowMaxHeight: 50,
          headingRowColor: MaterialStateProperty.all(Colors.deepOrange.shade100),
          columns: const [
            DataColumn(label: Text('NIM', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Nama Mahasiswa', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Total PTM', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Hadir', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
            DataColumn(label: Text('Izin', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
            DataColumn(label: Text('Sakit', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
            DataColumn(label: Text('Alpha', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
            DataColumn(label: Text('Persentase', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: rekapList.map((rekap) {
            return DataRow(
              cells: [
                DataCell(Text(rekap.nim)),
                DataCell(Text(rekap.nama)),
                DataCell(Text(totalPertemuan.toString(), textAlign: TextAlign.center)),
                DataCell(Text(rekap.hadir.toString(), textAlign: TextAlign.center)),
                DataCell(Text(rekap.izin.toString(), textAlign: TextAlign.center)),
                DataCell(Text(rekap.sakit.toString(), textAlign: TextAlign.center)),
                DataCell(Text(rekap.alpha.toString(), textAlign: TextAlign.center)),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPercentageColor(rekap.persentaseKehadiran),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('${rekap.persentaseKehadiran.toStringAsFixed(2)}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
  
  Color _getPercentageColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }
}