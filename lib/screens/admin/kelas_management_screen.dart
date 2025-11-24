// lib/screens/admin/kelas_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_constants.dart';
import '../../models/admin_model.dart';
import '../../services/admin_service.dart';
import '../../services/api_service.dart';

// Provider untuk list Kelas
final kelasListProvider = FutureProvider.autoDispose<List<Kelas>>((ref) async {
  final service = AdminService();
  return service.getAllKelas();
});

class KelasManagementScreen extends ConsumerWidget {
  const KelasManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kelasAsync = ref.watch(kelasListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Kelas & Jadwal'),
        backgroundColor: Colors.purple,
      ),
      body: kelasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) {
          String message = (err is ApiException) ? err.message : 'Gagal memuat data kelas.';
          return Center(child: Text('Error: $message', style: const TextStyle(color: Colors.red)));
        },
        data: (kelasList) {
          if (kelasList.isEmpty) {
            return const Center(child: Text('Belum ada data kelas.'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(kelasListProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: kelasList.length,
              itemBuilder: (context, index) {
                final kelas = kelasList[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: ListTile(
                    title: Text('${kelas.namaMatakuliah ?? "N/A"} (${kelas.namaKelas})', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${kelas.hari ?? ""}, ${kelas.jamMulai ?? ""} - ${kelas.jamSelesai ?? ""} | Ruang: ${kelas.ruangan ?? ""} | Kap: ${kelas.kapasitas ?? 0}'),
                    trailing: PopupMenuButton(
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem(
                          child: const Text('Edit'),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Fitur edit akan ditambahkan segera.')),
                            );
                          },
                        ),
                        PopupMenuItem(
                          child: const Text('Hapus'),
                          onTap: () {
                            _showDeleteConfirmation(context, ref, kelas.idKelas);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigasi ke Add Kelas Form
        },
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, int kelasId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Kelas?'),
          content: const Text('Apakah Anda yakin ingin menghapus kelas ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.invalidate(kelasListProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kelas berhasil dihapus.')),
                );
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}