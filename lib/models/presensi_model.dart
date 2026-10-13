class PresensiModel {
  final String idPresensi;
  final String tanggal;
  final String idSiswa;
  final String statusHadir; // 'Hadir', 'Izin', 'Sakit', 'Alpa'
  final String jamScan;
  final String metode; // 'QR Code', 'Manual Guru', 'GPS'
  final String lokasi;

  PresensiModel({
    required this.idPresensi,
    required this.tanggal,
    required this.idSiswa,
    required this.statusHadir,
    required this.jamScan,
    required this.metode,
    required this.lokasi,
  });

  bool get isHadir => statusHadir.toLowerCase() == 'hadir';

  factory PresensiModel.fromJson(Map<String, dynamic> json) {
    return PresensiModel(
      idPresensi: json['id_presensi']?.toString() ?? '',
      tanggal: json['tanggal']?.toString() ?? '',
      idSiswa: json['id_siswa']?.toString() ?? '',
      statusHadir: json['status_hadir']?.toString() ?? 'Hadir',
      jamScan: json['jam_scan']?.toString() ?? '',
      metode: json['metode']?.toString() ?? 'QR Code',
      lokasi: json['lokasi']?.toString() ?? 'Sekolah Al-Bayyinah',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_presensi': idPresensi,
      'tanggal': tanggal,
      'id_siswa': idSiswa,
      'status_hadir': statusHadir,
      'jam_scan': jamScan,
      'metode': metode,
      'lokasi': lokasi,
    };
  }
}
