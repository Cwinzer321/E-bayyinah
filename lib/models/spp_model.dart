class SPPModel {
  final String idSpp;
  final String idSiswa;
  final String bulan;
  final int tahun;
  final double nominalTagihan;
  final double nominalBayar;
  final String? tglBayar;
  final String statusBayar; // 'Lunas', 'Menunggu_Verifikasi', 'Belum_Bayar'
  final String? buktiUrl;
  final String? verifiedBy;

  SPPModel({
    required this.idSpp,
    required this.idSiswa,
    required this.bulan,
    required this.tahun,
    required this.nominalTagihan,
    required this.nominalBayar,
    this.tglBayar,
    required this.statusBayar,
    this.buktiUrl,
    this.verifiedBy,
  });

  bool get isLunas => statusBayar.toLowerCase() == 'lunas';
  bool get isWaiting => statusBayar.toLowerCase() == 'menunggu_verifikasi';
  bool get isUnpaid => statusBayar.toLowerCase() == 'belum_bayar';

  factory SPPModel.fromJson(Map<String, dynamic> json) {
    return SPPModel(
      idSpp: json['id_spp']?.toString() ?? '',
      idSiswa: json['id_siswa']?.toString() ?? '',
      bulan: json['bulan']?.toString() ?? '',
      tahun: int.tryParse(json['tahun']?.toString() ?? '') ?? DateTime.now().year,
      nominalTagihan: double.tryParse(json['nominal_tagihan']?.toString() ?? '') ?? 350000.0,
      nominalBayar: double.tryParse(json['nominal_bayar']?.toString() ?? '') ?? 0.0,
      tglBayar: json['tgl_bayar']?.toString(),
      statusBayar: json['status_bayar']?.toString() ?? 'Belum_Bayar',
      buktiUrl: json['bukti_url']?.toString(),
      verifiedBy: json['verified_by']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_spp': idSpp,
      'id_siswa': idSiswa,
      'bulan': bulan,
      'tahun': tahun,
      'nominal_tagihan': nominalTagihan,
      'nominal_bayar': nominalBayar,
      'tgl_bayar': tglBayar,
      'status_bayar': statusBayar,
      'bukti_url': buktiUrl,
      'verified_by': verifiedBy,
    };
  }
}
