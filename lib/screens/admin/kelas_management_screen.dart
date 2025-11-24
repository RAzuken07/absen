// lib/screens/admin/kelas_management_screen.dart
import 'package:flutter/material.dart';
import '../../config/app_constants.dart';

class KelasManagementScreen extends StatelessWidget {
  const KelasManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Kelas & Jadwal'),
        backgroundColor: Colors.purple,
      ),
      body: const Center(
        child: Text('Tampilan CRUD Kelas (List, Add, Edit, Delete) akan diimplementasikan di sini. Kelas memerlukan relasi ke Matakuliah dan Dosen.'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Implementasi navigasi ke Add/Edit Kelas Form
        },
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}