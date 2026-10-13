class NilaiModel {
  final String idNilai;
  final String idSiswa;
  final String semester; // 'Ganjil', 'Genap'
  final String tahunAjaran; // '2024/2025'
  final String mataPelajaran;
  final double tugas;
  final double uts;
  final double uas;
  final double nilaiAkhir;
  final String predikat; // 'A', 'B', 'C', 'D'

  NilaiModel({
    required this.idNilai,
    required this.idSiswa,
    required this.semester,
    required this.tahunAjaran,
    required this.mataPelajaran,
    required this.tugas,
    required this.uts,
    required this.uas,
    required this.nilaiAkhir,
    required this.predikat,
  });

  factory NilaiModel.fromJson(Map<String, dynamic> json) {
    return NilaiModel(
      idNilai: json['id_nilai']?.toString() ?? '',
      idSiswa: json['id_siswa']?.toString() ?? '',
      semester: json['semester']?.toString() ?? 'Ganjil',
      tahunAjaran: json['tahun_ajaran']?.toString() ?? '2024/2025',
      mataPelajaran: json['mata_pelajaran']?.toString() ?? '',
      tugas: double.tryParse(json['tugas']?.toString() ?? '') ?? 0.0,
      uts: double.tryParse(json['uts']?.toString() ?? '') ?? 0.0,
      uas: double.tryParse(json['uas']?.toString() ?? '') ?? 0.0,
      nilaiAkhir: double.tryParse(json['nilai_akhir']?.toString() ?? '') ?? 0.0,
      predikat: json['predikat']?.toString() ?? 'B',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_nilai': idNilai,
      'id_siswa': idSiswa,
      'semester': semester,
      'tahun_ajaran': tahunAjaran,
      'mata_pelajaran': mataPelajaran,
      'tugas': tugas,
      'uts': uts,
      'uas': uas,
      'nilai_akhir': nilaiAkhir,
      'predikat': predikat,
    };
  }
}
