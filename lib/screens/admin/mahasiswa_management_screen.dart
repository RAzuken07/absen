// lib/screens/admin/mahasiswa_management_screen.dart
import 'package:flutter/material.dart';
import '../../config/app_constants.dart';

class MahasiswaManagementScreen extends StatelessWidget {
  const MahasiswaManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Mahasiswa'),
        backgroundColor: Colors.deepOrange,
      ),
      body: const Center(
        child: Text('Tampilan CRUD Mahasiswa (List, Add, Edit, Delete) akan diimplementasikan di sini, menggunakan struktur yang sama dengan MatakuliahManagementScreen.'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Implementasi navigasi ke Add/Edit Mahasiswa Form
        },
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}