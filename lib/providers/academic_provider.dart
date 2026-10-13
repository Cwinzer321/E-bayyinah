import 'package:flutter/material.dart';
import '../models/nilai_model.dart';
import '../models/tracer_model.dart';
import '../services/api_service.dart';

class AcademicProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  String? _errorMessage;
  List<NilaiModel> _nilaiList = [];
  List<TracerModel> _tracerList = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<NilaiModel> get nilaiList => _nilaiList;
  List<TracerModel> get tracerList => _tracerList;

  Future<void> fetchNilaiList({String? idSiswa, String? semester, String? tahunAjaran}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final params = <String, String>{};
    if (idSiswa != null) params['id_siswa'] = idSiswa;
    if (semester != null) params['semester'] = semester;
    if (tahunAjaran != null) params['tahun_ajaran'] = tahunAjaran;

    final res = await _api.get('get_nilai_list', params);
    _isLoading = false;

    if (res['success'] == true && res['data'] is List) {
      _nilaiList = (res['data'] as List)
          .map((item) => NilaiModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      _errorMessage = res['message']?.toString() ?? 'Gagal memuat daftar nilai';
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> saveNilai(Map<String, dynamic> payload) async {
    _isLoading = true;
    notifyListeners();

    final res = await _api.post('save_nilai', payload);
    _isLoading = false;

    if (res['success'] == true && payload['id_siswa'] != null) {
      await fetchNilaiList(idSiswa: payload['id_siswa'].toString());
    }
    notifyListeners();
    return res;
  }

  Future<void> fetchTracerList({int? tahunLulus, String? search}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final params = <String, String>{};
    if (tahunLulus != null) params['tahun_lulus'] = tahunLulus.toString();
    if (search != null) params['search'] = search;

    final res = await _api.get('get_tracer_list', params);
    _isLoading = false;

    if (res['success'] == true && res['data'] is List) {
      _tracerList = (res['data'] as List)
          .map((item) => TracerModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      _errorMessage = res['message']?.toString() ?? 'Gagal memuat tracer study';
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> updateTracer(Map<String, dynamic> payload) async {
    _isLoading = true;
    notifyListeners();

    final res = await _api.post('update_tracer', payload);
    _isLoading = false;

    if (res['success'] == true) {
      await fetchTracerList();
    }
    notifyListeners();
    return res;
  }

  Future<Map<String, dynamic>> requestLegalisir({
    required String idSiswa,
    required String jenisDokumen,
  }) async {
    _isLoading = true;
    notifyListeners();

    final payload = {
      'id_siswa': idSiswa,
      'dokumen': jenisDokumen,
    };

    final res = await _api.post('request_legalisir', payload);
    _isLoading = false;

    if (res['success'] == true) {
      await fetchTracerList();
    }
    notifyListeners();
    return res;
  }
}
