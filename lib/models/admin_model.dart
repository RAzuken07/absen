// lib/models/admin_model.dart

class Kelas {
  final int idKelas;
  final String namaKelas;
  final int idMatakuliah; // FK
  final String? namaMatakuliah; // Dari join
  final String? nipDosen; // Dari join
  final String? hari;
  final String? jamMulai;
  final String? jamSelesai;
  final String? ruangan;
  final int? kapasitas;

  Kelas({
    required this.idKelas,
    required this.namaKelas,
    required this.idMatakuliah,
    this.namaMatakuliah,
    this.nipDosen,
    this.hari,
    this.jamMulai,
    this.jamSelesai,
    this.ruangan,
    this.kapasitas,
  });

  factory Kelas.fromJson(Map<String, dynamic> json) {
    return Kelas(
      idKelas: json['id_kelas'] as int,
      namaKelas: json['nama_kelas'] as String,
      idMatakuliah: json['id_matakuliah'] as int,
      namaMatakuliah: json['nama_matakuliah'] as String?,
      nipDosen: json['nip_dosen'] as String?,
      hari: json['hari'] as String?,
      jamMulai: json['jam_mulai'] as String?,
      jamSelesai: json['jam_selesai'] as String?,
      ruangan: json['ruangan'] as String?,
      kapasitas: json['kapasitas'] as int?,
    );
  }
}

class Matakuliah {
  final int idMatakuliah;
  final String namaMatakuliah;
  final String nipDosen; // FK

  Matakuliah({
    required this.idMatakuliah,
    required this.namaMatakuliah,
    required this.nipDosen,
  });

  factory Matakuliah.fromJson(Map<String, dynamic> json) {
    return Matakuliah(
      idMatakuliah: json['id_matakuliah'] as int,
      namaMatakuliah: json['nama_matakuliah'] as String,
      nipDosen: json['nip_dosen'] as String,
    );
  }
}

// Tambahan: Class Pertemuan untuk CRUD Admin
class Pertemuan {
  final int idPertemuan;
  final int idKelas;
  final int pertemuanKe;
  final String tanggal; // Atau DateTime jika perlu parsing

  Pertemuan({
    required this.idPertemuan,
    required this.idKelas,
    required this.pertemuanKe,
    required this.tanggal,
  });

  factory Pertemuan.fromJson(Map<String, dynamic> json) {
    return Pertemuan(
      idPertemuan: json['id_pertemuan'] as int,
      idKelas: json['id_kelas'] as int,
      pertemuanKe: json['pertemuan_ke'] as int,
      tanggal: json['tanggal'] as String,
    );
  }
}