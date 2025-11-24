// lib/screens/admin/mahasiswa_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/admin_service.dart';
import '../../services/api_service.dart';

final mahasiswaListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final service = AdminService();
  return service.readAll('mahasiswa', (json) => json);
});

class MahasiswaManagementScreen extends ConsumerWidget {
  const MahasiswaManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mahasiswaAsync = ref.watch(mahasiswaListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Mahasiswa'),
        backgroundColor: Colors.deepOrange,
      ),
      body: mahasiswaAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) {
          String message = (err is ApiException) ? err.message : 'Gagal memuat data.';
          return Center(child: Text('Error: $message', style: const TextStyle(color: Colors.red)));
        },
        data: (mahasiswaList) {
          if (mahasiswaList.isEmpty) {
            return const Center(child: Text('Belum ada data mahasiswa.'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(mahasiswaListProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: mahasiswaList.length,
              itemBuilder: (context, index) {
                final mhs = mahasiswaList[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: ListTile(
                    title: Text(mhs['nama'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('NIM: ${mhs['nim']}'),
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Fitur hapus akan ditambahkan segera.')),
                            );
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fitur tambah mahasiswa akan ditambahkan segera.')),
          );
        },
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}