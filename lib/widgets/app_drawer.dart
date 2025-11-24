// lib/widgets/app_drawer.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ambil data user dari AuthProvider
    final user = ref.watch(authProvider).currentUser;

    if (user == null) {
      // Tidak seharusnya terjadi karena drawer hanya diakses saat user login
      return const Drawer(child: Center(child: Text('Error: User data not found')));
    }

    // Fungsi untuk membuat ListTile navigasi
    Widget _buildDrawerItem(
        {required String title, required IconData icon, VoidCallback? onTap}) {
      return ListTile(
        leading: Icon(icon, color: Colors.blueGrey),
        title: Text(title, style: const TextStyle(fontSize: 16)),
        onTap: onTap,
      );
    }

    // Daftar item menu berdasarkan level pengguna
    List<Widget> _getMenuItems(String level) {
      final List<Widget> items = [];

      // Item untuk semua level
      items.add(_buildDrawerItem(
          title: 'Home / Dashboard',
          icon: Icons.home,
          onTap: () {
            // Tutup drawer
            Navigator.of(context).pop(); 
            // Navigasi ke rute utama sesuai level (sudah di handle app.dart)
          }));
      
      // Item spesifik per level
      if (level == 'mahasiswa') {
        items.add(const Divider());
        items.add(_buildDrawerItem(
            title: 'Riwayat Absensi',
            icon: Icons.history,
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/history'); // Rute akan didefinisikan nanti
            }));
        items.add(_buildDrawerItem(
            title: 'Pendaftaran Wajah',
            icon: Icons.face_retouching_natural,
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/face-register');
            }));
      } else if (level == 'dosen') {
        items.add(const Divider());
        items.add(_buildDrawerItem(
            title: 'Buka Sesi Absensi',
            icon: Icons.add_alarm,
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/open-sesi');
            }));
        items.add(_buildDrawerItem(
            title: 'Lihat Rekap Kelas',
            icon: Icons.bar_chart,
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/rekap');
            }));
      } else if (level == 'admin') {
        items.add(const Divider());
        items.add(_buildDrawerItem(
            title: 'Manajemen Users & MK',
            icon: Icons.admin_panel_settings,
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/admin-crud');
            }));
      }

      return items;
    }

    return Drawer(
      child: Column(
        children: <Widget>[
          // Header Drawer dengan info user
          UserAccountsDrawerHeader(
            accountName: Text(user.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text('Level: ${user.level.toUpperCase()}'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Colors.blue),
            ),
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
          ),
          
          // List Item Menu
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: _getMenuItems(user.level),
            ),
          ),

          // Footer: Logout
          Align(
            alignment: FractionalOffset.bottomCenter,
            child: Column(
              children: <Widget>[
                const Divider(),
                _buildDrawerItem(
                  title: 'Logout',
                  icon: Icons.exit_to_app,
                  onTap: () {
                    Navigator.of(context).pop(); // Tutup drawer
                    // Panggil fungsi logout dari AuthProvider
                    ref.read(authProvider.notifier).logout(); 
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}