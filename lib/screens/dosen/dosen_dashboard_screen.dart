// lib/screens/dosen/dosen_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../models/admin_model.dart';
import '../../services/dosen_service.dart';
import '../../services/api_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/custom_button.dart';
import '../../config/app_constants.dart';
import 'open_sesi_screen.dart';
import 'rekap_kehadiran_screen.dart';

// Definisi Provider untuk Kelas yang diajar Dosen
// Asumsi: dosenServiceProvider sudah didefinisikan di lib/services/dosen_service.dart
final dosenKelasProvider = FutureProvider.autoDispose<List<Kelas>>((ref) async {
  final user = ref.watch(authProvider).currentUser;
  final nip = user?.userId; 
  
  if (nip == null || nip.isEmpty) {
    throw Exception("Data NIP Dosen tidak ditemukan.");
  }
  
  final service = ref.watch(dosenServiceProvider); 
  return service.getDosenKelas(nip);
});


class DosenDashboardScreen extends ConsumerWidget {
  const DosenDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).currentUser;
    final kelasAsync = ref.watch(dosenKelasProvider);

    if (user == null) {
      return const Center(child: Text("Data pengguna tidak valid."));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Dosen'),
        backgroundColor: PrimaryColor,
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dosenKelasProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DefaultPadding),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserInfoCard(user.nama, user.userId),
              const SizedBox(height: 20),
              
              const Text(
                'Daftar Kelas yang Anda Ajar:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              _buildKelasList(context, kelasAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(String nama, String nip) {
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
                Icon(Icons.person_pin, color: PrimaryColor, size: 30),
                SizedBox(width: 10),
                Text('Selamat Datang', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              ],
            ),
            const Divider(),
            Text(nama, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text('NIP: $nip', style: const TextStyle(fontSize: 16, color: Colors.blueGrey)),
          ],
        ),
      ),
    );
  }

  Widget _buildKelasList(BuildContext context, AsyncValue<List<Kelas>> kelasAsync) {
    return kelasAsync.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator())),
      error: (err, stack) {
        String message = (err is ApiException) ? err.message : 'Gagal memuat data kelas.';
        return Center(child: Text('Error: $message', style: const TextStyle(color: Colors.red)));
      },
      data: (kelasList) {
        if (kelasList.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text('Anda belum terdaftar mengajar di kelas manapun.'),
            ),
          );
        }
        
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: kelasList.length,
          itemBuilder: (context, index) {
            final kelas = kelasList[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 15),
              elevation: 2,
              child: ExpansionTile(
                leading: const Icon(Icons.meeting_room, color: SecondaryColor),
                title: Text('${kelas.namaMatakuliah} (${kelas.namaKelas})', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Ruangan: ${kelas.ruangan} | ${kelas.hari}, ${kelas.jamMulai.substring(0, 5)} - ${kelas.jamSelesai.substring(0, 5)}'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(DefaultPadding),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        CustomButton(
                          text: 'BUKA SESI ABSENSI',
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => OpenSesiScreen(kelas: kelas),
                            ));
                          },
                          backgroundColor: Colors.green,
                          width: 150,
                          height: 40,
                          fontSize: 12,
                        ),
                        CustomButton(
                          text: 'LIHAT REKAP',
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => RekapKehadiranScreen(kelas: kelas),
                            ));
                          },
                          backgroundColor: Colors.deepOrange,
                          width: 150,
                          height: 40,
                          fontSize: 12,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}