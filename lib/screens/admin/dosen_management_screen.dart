// lib/screens/admin/dosen_management_screen.dart
import 'package:flutter/material.dart';
import '../../config/app_constants.dart';
import 'add_edit_dosen_screen.dart';

class DosenManagementScreen extends StatelessWidget {
  const DosenManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Dosen'),
        backgroundColor: Colors.green,
      ),
      body: const Center(
        child: Text(
          'Tampilan CRUD Dosen (List, Add, Edit, Delete) akan diimplementasikan di sini, menggunakan struktur yang sama dengan MatakuliahManagementScreen.',
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigasi ke layar Add/Edit Dosen dan tunggu hasilnya
          final result = await Navigator.of(context).push<Map<String, String>>(
            MaterialPageRoute(builder: (_) => const AddEditDosenScreen()),
          );

          // Jika ada data dikembalikan, tampilkan konfirmasi singkat
          if (result != null) {
            final nama = result['nama'] ?? '-';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Dosen "${nama}" berhasil ditambahkan.')),
            );
          }
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
