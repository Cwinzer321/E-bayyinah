class StudentModel {
  final String idSiswa;
  final String nis;
  final String nisn;
  final String namaLengkap;
  final String idAngkatan;
  final String jenisKelamin; // 'L' atau 'P'
  final String tempatLahir;
  final String tglLahir;
  final String alamat;
  final String noHp;
  final String namaOrtu;
  final String status; // 'Aktif', 'Lulus', 'Keluar', 'Alumni'

  StudentModel({
    required this.idSiswa,
    required this.nis,
    required this.nisn,
    required this.namaLengkap,
    required this.idAngkatan,
    required this.jenisKelamin,
    required this.tempatLahir,
    required this.tglLahir,
    required this.alamat,
    required this.noHp,
    required this.namaOrtu,
    required this.status,
  });

  bool get isAktif => status.toLowerCase() == 'aktif';
  bool get isAlumni => status.toLowerCase() == 'lulus' || status.toLowerCase() == 'alumni';

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      idSiswa: json['id_siswa']?.toString() ?? '',
      nis: json['nis']?.toString() ?? '',
      nisn: json['nisn']?.toString() ?? '',
      namaLengkap: json['nama_lengkap']?.toString() ?? '',
      idAngkatan: json['id_angkatan']?.toString() ?? '',
      jenisKelamin: json['jenis_kelamin']?.toString() ?? 'L',
      tempatLahir: json['tempat_lahir']?.toString() ?? '',
      tglLahir: json['tgl_lahir']?.toString() ?? '',
      alamat: json['alamat']?.toString() ?? '',
      noHp: json['no_hp']?.toString() ?? '',
      namaOrtu: json['nama_ortu']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Aktif',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_siswa': idSiswa,
      'nis': nis,
      'nisn': nisn,
      'nama_lengkap': namaLengkap,
      'id_angkatan': idAngkatan,
      'jenis_kelamin': jenisKelamin,
      'tempat_lahir': tempatLahir,
      'tgl_lahir': tglLahir,
      'alamat': alamat,
      'no_hp': noHp,
      'nama_ortu': namaOrtu,
      'status': status,
    };
  }
}
