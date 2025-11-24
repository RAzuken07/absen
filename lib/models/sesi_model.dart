// lib/models/sesi_model.dart

class SesiAbsensi {
  final int idSesi;
  final int idPertemuan;
  final String namaMatakuliah;
  final String namaDosen;
  final String waktuBuka; // DateTime string
  final int durasiMenit;
  final double radiusMeter;
  final double lokasiLat;
  final double lokasiLong;

  SesiAbsensi({
    required this.idSesi,
    required this.idPertemuan,
    required this.namaMatakuliah,
    required this.namaDosen,
    required this.waktuBuka,
    required this.durasiMenit,
    required this.radiusMeter,
    required this.lokasiLat,
    required this.lokasiLong,
  });

  factory SesiAbsensi.fromJson(Map<String, dynamic> json) {
    return SesiAbsensi(
      idSesi: json['id_sesi'] as int,
      idPertemuan: json['id_pertemuan'] as int,
      namaMatakuliah: json['nama_matakuliah'] as String,
      namaDosen: json['nama_dosen'] as String,
      waktuBuka: json['waktu_buka'] as String,
      durasiMenit: json['durasi_menit'] as int,
      radiusMeter: json['radius_meter'] as double,
      lokasiLat: json['lokasi_lat'] as double,
      lokasiLong: json['lokasi_long'] as double,
    );
  }
}

// Model lain seperti AbsensiLog, RekapKehadiran, dll., akan dibuat di file yang berbeda.