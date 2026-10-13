import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/spp_model.dart';
import '../services/api_service.dart';

class SPPProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  String? _errorMessage;
  List<SPPModel> _sppList = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<SPPModel> get sppList => _sppList;

  Future<void> fetchSPPList({String? idSiswa, int? tahun, String? statusBayar}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final params = <String, String>{};
    if (idSiswa != null) params['id_siswa'] = idSiswa;
    if (tahun != null) params['tahun'] = tahun.toString();
    if (statusBayar != null && statusBayar != 'ALL') params['status_bayar'] = statusBayar;

    final res = await _api.get('get_spp_list', params);
    _isLoading = false;

    if (res['success'] == true && res['data'] is List) {
      _sppList = (res['data'] as List)
          .map((item) => SPPModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      _errorMessage = res['message']?.toString() ?? 'Gagal memuat tagihan SPP';
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> paySPP({
    required String idSpp,
    required double nominal,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    _isLoading = true;
    notifyListeners();

    final payload = <String, dynamic>{
      'id_spp': idSpp,
      'nominal_bayar': nominal,
    };

    if (fileBytes != null && fileName != null) {
      payload['bukti_base64'] = base64Encode(fileBytes);
      payload['bukti_filename'] = fileName;
    }

    final res = await _api.post('pay_spp', payload);
    _isLoading = false;

    if (res['success'] == true) {
      // Refresh list
      final currentSiswa = _sppList.isNotEmpty ? _sppList.first.idSiswa : null;
      if (currentSiswa != null) {
        await fetchSPPList(idSiswa: currentSiswa);
      }
    }
    notifyListeners();
    return res;
  }

  Future<Map<String, dynamic>> verifySPP({
    required String idSpp,
    required String status,
    required String verifiedBy,
  }) async {
    _isLoading = true;
    notifyListeners();

    final payload = {
      'id_spp': idSpp,
      'status': status,
      'verified_by': verifiedBy,
    };

    final res = await _api.post('verify_spp', payload);
    _isLoading = false;

    if (res['success'] == true) {
      await fetchSPPList();
    }
    notifyListeners();
    return res;
  }
}
