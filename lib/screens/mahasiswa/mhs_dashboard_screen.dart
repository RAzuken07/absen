// lib/screens/mahasiswa/mhs_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sesi_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/custom_button.dart';
import '../../config/app_constants.dart';
import 'absensi_screen.dart'; 

class MahasiswaDashboardScreen extends ConsumerStatefulWidget {
  const MahasiswaDashboardScreen({super.key});

  @override
  ConsumerState<MahasiswaDashboardScreen> createState() => _MahasiswaDashboardScreenState();
}

class _MahasiswaDashboardScreenState extends ConsumerState<MahasiswaDashboardScreen> {

  @override
  void initState() {
    super.initState();
    // Panggil fetchSesiAktif saat layar pertama kali dimuat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    // Memuat data sesi aktif dari service
    await ref.read(sesiAbsensiProvider.notifier).fetchSesiAktif();
  }

  @override
  Widget build(BuildContext context) {
    // Watch data Mahasiswa & status sesi aktif
    final user = ref.watch(authProvider).currentUser;
    final sesiState = ref.watch(sesiAbsensiProvider);

    if (user == null) {
      return const Center(child: Text("Data pengguna tidak valid."));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Mahasiswa'),
        backgroundColor: PrimaryColor,
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DefaultPadding),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserInfoCard(user.nama, user.userId),
              const SizedBox(height: 20),
              
              const Text(
                'Sesi Absensi Aktif Saat Ini:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              _buildSesiAktifList(sesiState),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildUserInfoCard(String nama, String nim) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(DefaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.school, color: PrimaryColor, size: 30),
                SizedBox(width: 10),
                Text('Selamat Datang', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              ],
            ),
            const Divider(),
            Text(nama, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text('NIM: $nim', style: const TextStyle(fontSize: 16, color: Colors.blueGrey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSesiAktifList(sesiState) {
    if (sesiState.isLoading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: CircularProgressIndicator(),
      ));
    }

    if (sesiState.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text('Gagal memuat sesi: ${sesiState.errorMessage}', style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (sesiState.sesiAktif.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('Tidak ada sesi absensi aktif untuk kelas Anda saat ini.', textAlign: TextAlign.center),
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sesiState.sesiAktif.length,
      itemBuilder: (context, index) {
        final sesi = sesiState.sesiAktif[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 15),
          elevation: 2,
          child: ListTile(
            leading: const Icon(Icons.alarm_on, color: Colors.green),
            title: Text(sesi.namaMatakuliah, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dosen: ${sesi.namaDosen}'),
                Text('Dibuka: ${sesi.waktuBuka.substring(0, 19)}'),
                Text('Radius GPS: ${sesi.radiusMeter.toInt()} meter'),
              ],
            ),
            trailing: SizedBox(
              width: 100,
              child: CustomButton(
                text: 'ABSEN',
                onPressed: () {
                  // Navigasi ke AbsensiScreen dengan membawa data sesi
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => AbsensiScreen(sesi: sesi),
                  ));
                },
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}