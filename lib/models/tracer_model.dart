class TracerModel {
  final String idAlumni;
  final String idSiswa;
  final String namaLengkap;
  final int tahunLulus;
  final String statusAktivitas; // 'Kuliah', 'Bekerja', 'Wirausaha', 'Mencari_Kerja'
  final String namaInstansi;
  final String bidangJurusan;
  final String kontak;
  final String tglUpdate;
  final String statusLegalisir;

  TracerModel({
    required this.idAlumni,
    required this.idSiswa,
    required this.namaLengkap,
    required this.tahunLulus,
    required this.statusAktivitas,
    required this.namaInstansi,
    required this.bidangJurusan,
    required this.kontak,
    required this.tglUpdate,
    required this.statusLegalisir,
  });

  factory TracerModel.fromJson(Map<String, dynamic> json) {
    return TracerModel(
      idAlumni: json['id_alumni']?.toString() ?? '',
      idSiswa: json['id_siswa']?.toString() ?? '',
      namaLengkap: json['nama_lengkap']?.toString() ?? '',
      tahunLulus: int.tryParse(json['tahun_lulus']?.toString() ?? '') ?? 2024,
      statusAktivitas: json['status_aktivitas']?.toString() ?? 'Kuliah',
      namaInstansi: json['nama_instansi']?.toString() ?? '',
      bidangJurusan: json['bidang_jurusan']?.toString() ?? '',
      kontak: json['kontak']?.toString() ?? '',
      tglUpdate: json['tgl_update']?.toString() ?? '',
      statusLegalisir: json['status_legalisir']?.toString() ?? 'Tidak Ada',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_alumni': idAlumni,
      'id_siswa': idSiswa,
      'nama_lengkap': namaLengkap,
      'tahun_lulus': tahunLulus,
      'status_aktivitas': statusAktivitas,
      'nama_instansi': namaInstansi,
      'bidang_jurusan': bidangJurusan,
      'kontak': kontak,
      'tgl_update': tglUpdate,
      'status_legalisir': statusLegalisir,
    };
  }
}
