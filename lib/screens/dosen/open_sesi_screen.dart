// lib/screens/dosen/open_sesi_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/admin_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/dosen_service.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/error_dialog.dart';
import '../../config/app_constants.dart';

class OpenSesiScreen extends ConsumerStatefulWidget {
  final Kelas kelas;
  const OpenSesiScreen({super.key, required this.kelas});

  @override
  ConsumerState<OpenSesiScreen> createState() => _OpenSesiScreenState();
}

class _OpenSesiScreenState extends ConsumerState<OpenSesiScreen> {
  
  Position? _currentPosition;
  bool _isLocating = true;
  bool _isSubmitting = false;
  String _locationStatus = 'Mencari lokasi kampus...';
  
  // Form State
  int _selectedDuration = DefaultDurationMinutes;
  int _selectedRadius = DefaultRadiusMeter;
  String _selectedMethod = 'face_recognition'; // Default
  
  // List pilihan
  final List<int> _durations = [5, 10, 15, 20, 30]; // menit
  final List<int> _radii = [10, 25, 50, 75, 100]; // meter

  @override
  void initState() {
    super.initState();
    _getLocation();
  }
  
  // Mendapatkan lokasi saat ini
  Future<void> _getLocation() async {
    setState(() {
      _isLocating = true;
      _locationStatus = 'Memeriksa izin dan mengambil lokasi...';
    });
    
    try {
      // Cek Izin & Service
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          throw Exception('Izin lokasi ditolak.');
        }
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Layanan GPS (Lokasi) tidak aktif.');
      }
      
      // Ambil Posisi
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high, timeLimit: const Duration(seconds: 15));

      if (!mounted) return;
      setState(() {
        _currentPosition = position;
        _locationStatus = 'Lokasi ditemukan: Lat ${position.latitude.toStringAsFixed(6)}, Long ${position.longitude.toStringAsFixed(6)}';
        _isLocating = false;
      });

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentPosition = null;
        _locationStatus = 'Gagal menemukan lokasi: ${e.toString().contains('Exception:') ? e.toString().split(':').last : 'Cek koneksi dan GPS.'}';
        _isLocating = false;
      });
      showErrorDialog(context, 'Error Lokasi', _locationStatus);
    }
  }

  Future<void> _submitOpenSesi() async {
    if (_currentPosition == null) {
      showErrorDialog(context, 'Error', 'Lokasi belum terdeteksi. Silakan coba lagi.');
      return;
    }

    setState(() { _isSubmitting = true; });

    try {
      final nip = ref.read(authProvider).currentUser?.userId ?? '';

      final message = await ref.read(dosenServiceProvider).openSesi(
        nip: nip,
        idKelas: widget.kelas.idKelas,
        durasiMenit: _selectedDuration,
        radiusMeter: _selectedRadius,
        lokasiLat: _currentPosition!.latitude,
        lokasiLong: _currentPosition!.longitude,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sesi Berhasil Dibuka: $message'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop(); // Kembali ke dashboard
      
    } catch (e) {
      if (!mounted) return;
      String errorMessage = (e is ApiException) ? e.message : 'Gagal membuka sesi. Cek koneksi.';
      showErrorDialog(context, 'Gagal', errorMessage);
      
    } finally {
      if (!mounted) return;
      setState(() { _isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buka Sesi Absensi'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DefaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildKelasInfo(),
            const SizedBox(height: 20),
            _buildLocationCard(),
            const SizedBox(height: 20),
            
            _buildOptionDropdown('Durasi Sesi (Menit)', _durations, _selectedDuration, (newValue) {
              setState(() { _selectedDuration = newValue!; });
            }),
            const SizedBox(height: 15),
            
            _buildOptionDropdown('Radius Toleransi (Meter)', _radii, _selectedRadius, (newValue) {
              setState(() { _selectedRadius = newValue!; });
            }),
            const SizedBox(height: 15),

            // Metode Absensi (Hanya Face Recognition/GPS yang didukung di sini)
            _buildMethodToggle(),
            const SizedBox(height: 30),

            CustomButton(
              text: 'BUKA SESI SEKARANG',
              onPressed: (_currentPosition != null && !_isSubmitting) ? _submitOpenSesi : null,
              isLoading: _isSubmitting,
              backgroundColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKelasInfo() {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.class_, color: PrimaryColor),
        title: Text(widget.kelas.namaMatakuliah, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Kelas: ${widget.kelas.namaKelas} | Pertemuan berikutnya perlu dicek via API.'),
      ),
    );
  }

  Widget _buildLocationCard() {
    Color cardColor = _currentPosition != null ? Colors.blue.shade50 : Colors.orange.shade50;
    
    return Card(
      color: cardColor,
      elevation: 2,
      child: ListTile(
        leading: _isLocating 
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
          : Icon(_currentPosition != null ? Icons.location_on : Icons.error, color: _currentPosition != null ? PrimaryColor : Colors.red),
        title: const Text('Lokasi Sesi (Titik Absen)', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(_locationStatus),
        trailing: IconButton(icon: const Icon(Icons.refresh), onPressed: _getLocation),
      ),
    );
  }
  
  Widget _buildOptionDropdown(String label, List<int> options, int currentValue, Function(int?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        DropdownButtonFormField<int>(
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          value: currentValue,
          items: options.map((int value) {
            return DropdownMenuItem<int>(
              value: value,
              child: Text(value.toString()),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildMethodToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Metode Absensi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('Face Recognition/GPS'),
                selected: _selectedMethod == 'face_recognition',
                onSelected: (selected) {
                  if (selected) setState(() { _selectedMethod = 'face_recognition'; });
                },
                selectedColor: PrimaryColor.withOpacity(0.8),
                backgroundColor: Colors.grey.shade200,
                labelStyle: TextStyle(color: _selectedMethod == 'face_recognition' ? Colors.white : Colors.black),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ChoiceChip(
                label: const Text('QR Code'),
                selected: _selectedMethod == 'qr_code',
                onSelected: (selected) {
                  // Jika QR Code dipilih, perlu implementasi backend QR generation
                  if (selected) setState(() { _selectedMethod = 'qr_code'; });
                },
                selectedColor: Colors.orange.withOpacity(0.8),
                backgroundColor: Colors.grey.shade200,
                labelStyle: TextStyle(color: _selectedMethod == 'qr_code' ? Colors.white : Colors.black),
              ),
            ),
          ],
        ),
      ],
    );
  }
}