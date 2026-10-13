class AngkatanModel {
  final String idAngkatan;
  final String namaAngkatan;
  final int tahunMasuk;
  final int tahunLulus;
  final int totalSiswa;
  final String status; // 'Aktif', 'Lulus'
  final String? keterangan;

  AngkatanModel({
    required this.idAngkatan,
    required this.namaAngkatan,
    required this.tahunMasuk,
    required this.tahunLulus,
    required this.totalSiswa,
    required this.status,
    this.keterangan,
  });

  bool get isLulus => status.toLowerCase() == 'lulus';

  factory AngkatanModel.fromJson(Map<String, dynamic> json) {
    return AngkatanModel(
      idAngkatan: json['id_angkatan']?.toString() ?? '',
      namaAngkatan: json['nama_angkatan']?.toString() ?? '',
      tahunMasuk: int.tryParse(json['tahun_masuk']?.toString() ?? '') ?? 2021,
      tahunLulus: int.tryParse(json['tahun_lulus']?.toString() ?? '') ?? 2024,
      totalSiswa: int.tryParse(json['total_siswa']?.toString() ?? '') ?? 0,
      status: json['status']?.toString() ?? 'Aktif',
      keterangan: json['keterangan']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_angkatan': idAngkatan,
      'nama_angkatan': namaAngkatan,
      'tahun_masuk': tahunMasuk,
      'tahun_lulus': tahunLulus,
      'total_siswa': totalSiswa,
      'status': status,
      'keterangan': keterangan,
    };
  }
}
