import 'package:flutter/material.dart';
import '../models/angkatan_model.dart';
import '../models/student_model.dart';
import '../services/api_service.dart';

class StudentProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  String? _errorMessage;

  // Dashboard Stats (FR-03)
  Map<String, dynamic> _dashboardStats = {
    'total_siswa_aktif': 0,
    'total_alumni': 0,
    'total_angkatan': 0,
    'kehadiran_hari_ini': 0,
    'persentase_kehadiran': 0,
  };

  // Angkatan (FR-04)
  List<AngkatanModel> _angkatanList = [];
  String _selectedAngkatanId = 'ALL';

  // Siswa (FR-05 & FR-06)
  List<StudentModel> _students = [];
  String _searchQuery = '';
  String _selectedStatus = 'ALL';
  StudentModel? _selectedStudentDetail;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic> get dashboardStats => _dashboardStats;
  List<AngkatanModel> get angkatanList => _angkatanList;
  String get selectedAngkatanId => _selectedAngkatanId;
  List<StudentModel> get students => _students;
  String get searchQuery => _searchQuery;
  String get selectedStatus => _selectedStatus;
  StudentModel? get selectedStudentDetail => _selectedStudentDetail;

  Future<void> fetchDashboardStats() async {
    final res = await _api.get('get_dashboard_stats');
    if (res['success'] == true && res['data'] != null) {
      _dashboardStats = res['data'] as Map<String, dynamic>;
      notifyListeners();
    }
  }

  Future<void> fetchAngkatanList() async {
    final res = await _api.get('get_angkatan_list');
    if (res['success'] == true && res['data'] is List) {
      _angkatanList = (res['data'] as List)
          .map((item) => AngkatanModel.fromJson(item as Map<String, dynamic>))
          .toList();
      notifyListeners();
    }
  }

  Future<void> fetchStudents({
    String? idAngkatan,
    String? search,
    String? status,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (idAngkatan != null) _selectedAngkatanId = idAngkatan;
    if (search != null) _searchQuery = search;
    if (status != null) _selectedStatus = status;

    final params = <String, String>{};
    if (_selectedAngkatanId != 'ALL') params['id_angkatan'] = _selectedAngkatanId;
    if (_searchQuery.isNotEmpty) params['search'] = _searchQuery;
    if (_selectedStatus != 'ALL') params['status'] = _selectedStatus;

    final res = await _api.get('get_students', params);
    _isLoading = false;

    if (res['success'] == true && res['data'] is List) {
      _students = (res['data'] as List)
          .map((item) => StudentModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      _errorMessage = res['message']?.toString() ?? 'Gagal memuat data siswa';
    }
    notifyListeners();
  }

  Future<void> fetchStudentDetail(String idSiswa) async {
    _isLoading = true;
    notifyListeners();

    final res = await _api.get('get_student_detail', {'id_siswa': idSiswa});
    _isLoading = false;

    if (res['success'] == true && res['data'] != null) {
      _selectedStudentDetail = StudentModel.fromJson(res['data'] as Map<String, dynamic>);
    }
    notifyListeners();
  }

  Future<bool> saveStudent(Map<String, dynamic> payload) async {
    _isLoading = true;
    notifyListeners();

    final res = await _api.post('save_student', payload);
    _isLoading = false;

    if (res['success'] == true) {
      await fetchStudents();
      await fetchDashboardStats();
      return true;
    } else {
      _errorMessage = res['message']?.toString() ?? 'Gagal menyimpan siswa';
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveAngkatan(Map<String, dynamic> payload) async {
    _isLoading = true;
    notifyListeners();

    final res = await _api.post('save_angkatan', payload);
    _isLoading = false;

    if (res['success'] == true) {
      await fetchAngkatanList();
      await fetchDashboardStats();
      return true;
    } else {
      _errorMessage = res['message']?.toString() ?? 'Gagal menyimpan angkatan';
      notifyListeners();
      return false;
    }
  }

  void setSelectedAngkatan(String id) {
    _selectedAngkatanId = id;
    fetchStudents(idAngkatan: id);
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    fetchStudents(search: query);
  }

  void setSelectedStatus(String status) {
    _selectedStatus = status;
    fetchStudents(status: status);
  }
}
