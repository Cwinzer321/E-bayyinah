import 'package:flutter/material.dart';
import '../models/presensi_model.dart';
import '../services/api_service.dart';

class PresensiProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  String? _errorMessage;
  List<PresensiModel> _history = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<PresensiModel> get history => _history;

  Future<void> fetchHistory({String? idSiswa, String? bulan, String? tanggal}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final params = <String, String>{};
    if (idSiswa != null) params['id_siswa'] = idSiswa;
    if (bulan != null) params['bulan'] = bulan;
    if (tanggal != null) params['tanggal'] = tanggal;

    final res = await _api.get('get_presensi_history', params);
    _isLoading = false;

    if (res['success'] == true && res['data'] is List) {
      _history = (res['data'] as List)
          .map((item) => PresensiModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      _errorMessage = res['message']?.toString() ?? 'Gagal memuat riwayat presensi';
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> recordPresensi({
    required String idSiswa,
    String? statusHadir,
    String? metode,
    String? lokasi,
  }) async {
    _isLoading = true;
    notifyListeners();

    final payload = {
      'id_siswa': idSiswa,
      'status_hadir': statusHadir ?? 'Hadir',
      'metode': metode ?? 'QR Code',
      'lokasi': lokasi ?? 'Gerbang Utama Al-Bayyinah',
    };

    final res = await _api.post('record_presensi', payload);
    _isLoading = false;

    if (res['success'] == true) {
      await fetchHistory(idSiswa: idSiswa);
    }
    notifyListeners();
    return res;
  }
}
