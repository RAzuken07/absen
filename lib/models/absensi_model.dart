// lib/models/absensi_model.dart

class AbsensiLog {
  final int idAbsensi;
  final String nim;
  final int idPertemuan;
  final String status; // 'hadir', 'izin', 'sakit', 'alpha'
  final String waktuAbsen;
  final String metode; // 'face_recognition', 'manual', 'qr_code'
  final double confidenceScore;

  AbsensiLog({
    required this.idAbsensi,
    required this.nim,
    required this.idPertemuan,
    required this.status,
    required this.waktuAbsen,
    required this.metode,
    required this.confidenceScore,
  });

  factory AbsensiLog.fromJson(Map<String, dynamic> json) {
    return AbsensiLog(
      idAbsensi: json['id_absensi'] as int,
      nim: json['nim'] as String,
      idPertemuan: json['id_pertemuan'] as int,
      status: json['status'] as String,
      waktuAbsen: json['waktu_absen'] as String,
      metode: json['metode'] as String,
      confidenceScore: double.tryParse(json['confidence_score'].toString()) ?? 0.0,
    );
  }
}

class RekapKehadiran {
  // Data dari view v_rekap_kehadiran + data mahasiswa
  final String nim;
  final String nama;
  final int totalHadir;
  final int totalSakit;
  final int totalIzin;
  final int totalAlpha;
  final double persentaseKehadiran;

  RekapKehadiran({
    required this.nim,
    required this.nama,
    required this.totalHadir,
    required this.totalSakit,
    required this.totalIzin,
    required this.totalAlpha,
    required this.persentaseKehadiran,
  });

  factory RekapKehadiran.fromJson(Map<String, dynamic> json) {
    return RekapKehadiran(
      nim: json['nim'] as String,
      nama: json['nama'] as String,
      totalHadir: json['total_hadir'] as int,
      totalSakit: json['total_sakit'] as int,
      totalIzin: json['total_izin'] as int,
      totalAlpha: json['total_alpha'] as int,
      // Persentase mungkin perlu dihitung di frontend jika tidak disediakan oleh view
      persentaseKehadiran: double.tryParse(json['persentase_kehadiran']?.toString() ?? '0.0') ?? 0.0,
    );
  }
}