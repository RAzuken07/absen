// lib/models/admin_model.dart

class Kelas {
  final int idKelas;
  final String namaKelas;
  final int idMatakuliah; // FK

  Kelas({
    required this.idKelas,
    required this.namaKelas,
    required this.idMatakuliah,
  });

  factory Kelas.fromJson(Map<String, dynamic> json) {
    return Kelas(
      idKelas: json['id_kelas'] as int,
      namaKelas: json['nama_kelas'] as String,
      idMatakuliah: json['id_matakuliah'] as int,
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