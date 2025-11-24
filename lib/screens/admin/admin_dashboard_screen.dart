// lib/screens/admin/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../config/app_constants.dart';
import 'matakuliah_management_screen.dart';
import 'dosen_management_screen.dart';
import 'mahasiswa_management_screen.dart';
import 'kelas_management_screen.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).currentUser;

    if (user == null) {
      return const Center(child: Text("Data pengguna tidak valid."));
    }
    
    // Daftar modul master data
    final List<Map<String, dynamic>> masterModules = [
      {'title': 'Kelola Matakuliah', 'icon': Icons.book, 'color': Colors.blue, 'route': const MatakuliahManagementScreen()},
      {'title': 'Kelola Dosen', 'icon': Icons.person_pin, 'color': Colors.green, 'route': const DosenManagementScreen()},
      {'title': 'Kelola Mahasiswa', 'icon': Icons.school, 'color': Colors.deepOrange, 'route': const MahasiswaManagementScreen()},
      {'title': 'Kelola Kelas & Jadwal', 'icon': Icons.meeting_room, 'color': Colors.purple, 'route': const KelasManagementScreen()},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.red.shade700,
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DefaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserInfoCard(user.nama, user.userId),
            const SizedBox(height: 30),
            
            const Text(
              'Modul Pengelolaan Data Master',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: DefaultPadding,
                mainAxisSpacing: DefaultPadding,
                childAspectRatio: 1.0, 
              ),
              itemCount: masterModules.length,
              itemBuilder: (context, index) {
                final module = masterModules[index];
                return _buildModuleCard(context, module['title'], module['icon'], module['color'], module['route']);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(String nama, String userId) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(DefaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.red, size: 30),
                SizedBox(width: 10),
                Text('Administrator', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              ],
            ),
            const Divider(),
            Text(nama, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text('ID Admin: $userId', style: const TextStyle(fontSize: 16, color: Colors.blueGrey)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildModuleCard(BuildContext context, String title, IconData icon, Color color, Widget route) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => route));
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}