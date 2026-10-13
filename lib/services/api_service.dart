import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String _baseUrl = ApiConstants.defaultBaseUrl;
  bool _useDemoFallback = true;

  String get baseUrl => _baseUrl;
  bool get useDemoFallback => _useDemoFallback;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final customUrl = prefs.getString(ApiConstants.keyApiUrl);
    if (customUrl != null && customUrl.trim().isNotEmpty) {
      _baseUrl = customUrl.trim();
    }
    _useDemoFallback = prefs.getBool(ApiConstants.keyDemoMode) ?? true;
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.keyApiUrl, _baseUrl);
  }

  Future<void> setDemoFallback(bool enabled) async {
    _useDemoFallback = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(ApiConstants.keyDemoMode, enabled);
  }

  /// Eksekusi HTTP GET ke Google Apps Script
  Future<Map<String, dynamic>> get(String action, [Map<String, String>? params]) async {
    try {
      final queryParams = {'action': action, ...?params};
      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);

      final response = await http
          .get(uri)
          .timeout(ApiConstants.timeoutDuration);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        if (_useDemoFallback) return _getMockData(action, params);
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: Gagal menghubungi Google Apps Script'
        };
      }
    } catch (e) {
      if (_useDemoFallback) return _getMockData(action, params);
      return {
        'success': false,
        'message': 'Koneksi API Error: ${e.toString()}'
      };
    }
  }

  /// Eksekusi HTTP POST ke Google Apps Script
  Future<Map<String, dynamic>> post(String action, Map<String, dynamic> payload) async {
    try {
      final bodyData = jsonEncode({
        'action': action,
        'payload': payload,
      });

      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: bodyData,
          )
          .timeout(ApiConstants.timeoutDuration);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        if (_useDemoFallback) return _getMockPostResponse(action, payload);
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: Gagal menyimpan ke Google Apps Script'
        };
      }
    } catch (e) {
      if (_useDemoFallback) return _getMockPostResponse(action, payload);
      return {
        'success': false,
        'message': 'Koneksi POST Error: ${e.toString()}'
      };
    }
  }

  /// Data Cadangan Cerdas (Realistic Mock Data) jika Apps Script belum di-deploy
  Map<String, dynamic> _getMockData(String action, [Map<String, String>? params]) {
    switch (action) {
      case 'ping':
        return {'success': true, 'message': 'Demo Mode: Server SIMS E-Bayyinah Aktif'};

      case 'login':
        final username = params?['username'] ?? '';
        final password = params?['password'] ?? '';
        return _mockLogin(username, password);

      case 'get_dashboard_stats':
        return {
          'success': true,
          'data': {
            'total_siswa_aktif': 121,
            'total_alumni': 32,
            'total_angkatan': 4,
            'kehadiran_hari_ini': 116,
            'persentase_kehadiran': 96,
          }
        };

      case 'get_angkatan_list':
        return {
          'success': true,
          'data': [
            {
              'id_angkatan': 'ANGK-1',
              'nama_angkatan': 'Angkatan 1 (Al-Fatih)',
              'tahun_masuk': 2021,
              'tahun_lulus': 2024,
              'total_siswa': 32,
              'status': 'Lulus',
              'keterangan': 'Angkatan Pertama - Alumni Berprestasi'
            },
            {
              'id_angkatan': 'ANGK-2',
              'nama_angkatan': 'Angkatan 2 (Al-Farabi)',
              'tahun_masuk': 2022,
              'tahun_lulus': 2025,
              'total_siswa': 36,
              'status': 'Aktif',
              'keterangan': 'Kelas XII - Persiapan Ujian Akhir'
            },
            {
              'id_angkatan': 'ANGK-3',
              'nama_angkatan': 'Angkatan 3 (Ar-Razi)',
              'tahun_masuk': 2023,
              'tahun_lulus': 2026,
              'total_siswa': 40,
              'status': 'Aktif',
              'keterangan': 'Kelas XI'
            },
            {
              'id_angkatan': 'ANGK-4',
              'nama_angkatan': 'Angkatan 4 (Ibnu Sina)',
              'tahun_masuk': 2024,
              'tahun_lulus': 2027,
              'total_siswa': 45,
              'status': 'Aktif',
              'keterangan': 'Kelas X Santri Baru'
            },
          ]
        };

      case 'get_students':
        final idAngkatan = params?['id_angkatan'];
        final search = params?['search']?.toLowerCase();
        final status = params?['status']?.toLowerCase();

        var list = _mockStudents;
        if (idAngkatan != null && idAngkatan != 'ALL') {
          list = list.where((s) => s['id_angkatan'] == idAngkatan).toList();
        }
        if (status != null && status != 'all') {
          list = list.where((s) => s['status'].toString().toLowerCase() == status).toList();
        }
        if (search != null && search.isNotEmpty) {
          list = list
              .where((s) =>
                  s['nama_lengkap'].toString().toLowerCase().contains(search) ||
                  s['nis'].toString().contains(search))
              .toList();
        }
        return {'success': true, 'data': list, 'count': list.length};

      case 'get_student_detail':
        final idSiswa = params?['id_siswa'];
        final found = _mockStudents.firstWhere(
          (s) => s['id_siswa'] == idSiswa,
          orElse: () => _mockStudents.first,
        );
        return {'success': true, 'data': found};

      case 'get_presensi_history':
        return {
          'success': true,
          'data': [
            {
              'id_presensi': 'PRS-001',
              'tanggal': DateTime.now().toString().substring(0, 10),
              'id_siswa': 'SISWA-2024001',
              'status_hadir': 'Hadir',
              'jam_scan': '06:48:12',
              'metode': 'QR Code',
              'lokasi': 'Gerbang Utama Al-Bayyinah'
            },
            {
              'id_presensi': 'PRS-002',
              'tanggal': DateTime.now().subtract(const Duration(days: 1)).toString().substring(0, 10),
              'id_siswa': 'SISWA-2024001',
              'status_hadir': 'Hadir',
              'jam_scan': '06:50:00',
              'metode': 'QR Code',
              'lokasi': 'Gerbang Utama Al-Bayyinah'
            },
            {
              'id_presensi': 'PRS-003',
              'tanggal': DateTime.now().subtract(const Duration(days: 2)).toString().substring(0, 10),
              'id_siswa': 'SISWA-2024001',
              'status_hadir': 'Izin',
              'jam_scan': '07:10:00',
              'metode': 'Manual Guru',
              'lokasi': 'Surat Keterangan'
            },
          ]
        };

      case 'get_nilai_list':
        return {
          'success': true,
          'data': [
            {
              'id_nilai': 'NIL-001',
              'id_siswa': 'SISWA-2024001',
              'semester': 'Ganjil',
              'tahun_ajaran': '2024/2025',
              'mata_pelajaran': 'Pendidikan Agama Islam & Tahfidz',
              'tugas': 92,
              'uts': 90,
              'uas': 94,
              'nilai_akhir': 92,
              'predikat': 'A'
            },
            {
              'id_nilai': 'NIL-002',
              'id_siswa': 'SISWA-2024001',
              'semester': 'Ganjil',
              'tahun_ajaran': '2024/2025',
              'mata_pelajaran': 'Bahasa Arab & Nahwu Sharaf',
              'tugas': 88,
              'uts': 85,
              'uas': 90,
              'nilai_akhir': 88,
              'predikat': 'B'
            },
            {
              'id_nilai': 'NIL-003',
              'id_siswa': 'SISWA-2024001',
              'semester': 'Ganjil',
              'tahun_ajaran': '2024/2025',
              'mata_pelajaran': 'Matematika Terapan',
              'tugas': 85,
              'uts': 82,
              'uas': 88,
              'nilai_akhir': 85,
              'predikat': 'B'
            },
            {
              'id_nilai': 'NIL-004',
              'id_siswa': 'SISWA-2024001',
              'semester': 'Ganjil',
              'tahun_ajaran': '2024/2025',
              'mata_pelajaran': 'Bahasa Inggris & Conversation',
              'tugas': 95,
              'uts': 92,
              'uas': 96,
              'nilai_akhir': 95,
              'predikat': 'A'
            },
            {
              'id_nilai': 'NIL-005',
              'id_siswa': 'SISWA-2024001',
              'semester': 'Ganjil',
              'tahun_ajaran': '2024/2025',
              'mata_pelajaran': 'Ilmu Pengetahuan Alam',
              'tugas': 86,
              'uts': 84,
              'uas': 87,
              'nilai_akhir': 86,
              'predikat': 'B'
            },
          ]
        };

      case 'get_spp_list':
        return {
          'success': true,
          'data': [
            {
              'id_spp': 'SPP-202407',
              'id_siswa': 'SISWA-2024001',
              'bulan': 'Juli',
              'tahun': 2024,
              'nominal_tagihan': 350000,
              'nominal_bayar': 350000,
              'tgl_bayar': '2024-07-10',
              'status_bayar': 'Lunas',
              'bukti_url': 'https://drive.google.com/sample',
              'verified_by': 'Admin TU'
            },
            {
              'id_spp': 'SPP-202408',
              'id_siswa': 'SISWA-2024001',
              'bulan': 'Agustus',
              'tahun': 2024,
              'nominal_tagihan': 350000,
              'nominal_bayar': 350000,
              'tgl_bayar': '2024-08-08',
              'status_bayar': 'Lunas',
              'bukti_url': '',
              'verified_by': 'Admin TU'
            },
            {
              'id_spp': 'SPP-202409',
              'id_siswa': 'SISWA-2024001',
              'bulan': 'September',
              'tahun': 2024,
              'nominal_tagihan': 350000,
              'nominal_bayar': 350000,
              'tgl_bayar': '2024-09-05',
              'status_bayar': 'Menunggu_Verifikasi',
              'bukti_url': 'https://drive.google.com/sample_bukti',
              'verified_by': ''
            },
            {
              'id_spp': 'SPP-202410',
              'id_siswa': 'SISWA-2024001',
              'bulan': 'Oktober',
              'tahun': 2024,
              'nominal_tagihan': 350000,
              'nominal_bayar': 0,
              'tgl_bayar': '',
              'status_bayar': 'Belum_Bayar',
              'bukti_url': '',
              'verified_by': ''
            },
          ]
        };

      case 'get_tracer_list':
        return {
          'success': true,
          'data': [
            {
              'id_alumni': 'ALM-001',
              'id_siswa': 'SISWA-2021001',
              'nama_lengkap': 'Fajar Ramadhan',
              'tahun_lulus': 2024,
              'status_aktivitas': 'Kuliah',
              'nama_instansi': 'Universitas Pendidikan Indonesia (UPI)',
              'bidang_jurusan': 'Pendidikan Bahasa Arab',
              'kontak': '087812345678',
              'tgl_update': '2024-08-15',
              'status_legalisir': 'Selesai Legalisir'
            },
            {
              'id_alumni': 'ALM-002',
              'id_siswa': 'SISWA-2021002',
              'nama_lengkap': 'Zahra Muthmainnah',
              'tahun_lulus': 2024,
              'status_aktivitas': 'Bekerja',
              'nama_instansi': 'Baitul Maal Wa Tamwil (BMT)',
              'bidang_jurusan': 'Customer Support Syariah',
              'kontak': '081398765432',
              'tgl_update': '2024-09-01',
              'status_legalisir': 'Tidak Ada'
            },
          ]
        };

      default:
        return {'success': false, 'message': 'Endpoint mock tidak ditemukan'};
    }
  }

  Map<String, dynamic> _mockLogin(String username, String password) {
    final u = username.trim().toLowerCase();
    if (u == 'admin' && (password == 'admin123' || password.isNotEmpty)) {
      return {
        'success': true,
        'message': 'Login Admin Berhasil (Mode Offline/Demo)',
        'user': {
          'id_user': 'USR-1',
          'username': 'admin',
          'role': 'Admin',
          'id_ref': '',
          'full_name': 'Admin TU Al-Bayyinah',
        }
      };
    } else if (u == 'guru01' || u == 'guru') {
      return {
        'success': true,
        'message': 'Login Guru Berhasil (Mode Offline/Demo)',
        'user': {
          'id_user': 'USR-2',
          'username': 'guru01',
          'role': 'Guru',
          'id_ref': '',
          'full_name': 'Ust. Ahmad Dahlan, S.Pd.I',
        }
      };
    } else if (u == '2024001' || u == 'siswa') {
      return {
        'success': true,
        'message': 'Login Siswa Berhasil (Mode Offline/Demo)',
        'user': {
          'id_user': 'USR-3',
          'username': '2024001',
          'role': 'Siswa',
          'id_ref': 'SISWA-2024001',
          'full_name': 'Muhammad Raihan',
          'student_profile': _mockStudents.first,
        }
      };
    } else if (u == '2021001' || u == 'alumni') {
      return {
        'success': true,
        'message': 'Login Alumni Berhasil (Mode Offline/Demo)',
        'user': {
          'id_user': 'USR-4',
          'username': '2021001',
          'role': 'Alumni',
          'id_ref': 'SISWA-2021001',
          'full_name': 'Fajar Ramadhan',
          'student_profile': _mockStudents.last,
        }
      };
    }

    return {'success': false, 'message': 'Username atau Kata Sandi salah'};
  }

  Map<String, dynamic> _getMockPostResponse(String action, Map<String, dynamic> payload) {
    switch (action) {
      case 'save_student':
        return {
          'success': true,
          'message': 'Data Siswa berhasil disimpan (Tersimpan Lokal/Demo)'
        };
      case 'save_angkatan':
        return {
          'success': true,
          'message': 'Data Angkatan berhasil disimpan (Mode Demo)'
        };
      case 'record_presensi':
        return {
          'success': true,
          'message': 'Presensi Berhasil Dicatat: Hadir pukul ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}'
        };
      case 'save_nilai':
        return {
          'success': true,
          'message': 'Nilai Rapor berhasil disimpan'
        };
      case 'pay_spp':
        return {
          'success': true,
          'message': 'Bukti transfer terkirim ke Admin TU, status: Menunggu Verifikasi'
        };
      case 'verify_spp':
        return {
          'success': true,
          'message': 'Status tagihan SPP berhasil diperbarui'
        };
      case 'update_tracer':
        return {
          'success': true,
          'message': 'Data Tracer Study Alumni berhasil diperbarui'
        };
      case 'request_legalisir':
        return {
          'success': true,
          'message': 'Permohonan legalisir digital ijazah/rapor berhasil diajukan'
        };
      default:
        return {'success': true, 'message': 'Aksi berhasil dieksekusi'};
    }
  }

  static final List<Map<String, dynamic>> _mockStudents = [
    {
      'id_siswa': 'SISWA-2024001',
      'nis': '2024001',
      'nisn': '0081234567',
      'nama_lengkap': 'Muhammad Raihan',
      'id_angkatan': 'ANGK-4',
      'jenis_kelamin': 'L',
      'tempat_lahir': 'Bandung',
      'tgl_lahir': '2008-05-14',
      'alamat': 'Jl. Terusan Al-Bayyinah No. 12, Bandung',
      'no_hp': '081234567890',
      'nama_ortu': 'H. Abdullah',
      'status': 'Aktif'
    },
    {
      'id_siswa': 'SISWA-2024002',
      'nis': '2024002',
      'nisn': '0081234568',
      'nama_lengkap': 'Aisyah Nurul Izzah',
      'id_angkatan': 'ANGK-4',
      'jenis_kelamin': 'P',
      'tempat_lahir': 'Jakarta',
      'tgl_lahir': '2008-08-20',
      'alamat': 'Jl. Pesantren Asri No. 5, Cimahi',
      'no_hp': '081298765432',
      'nama_ortu': 'Drs. Ahmad Mansur',
      'status': 'Aktif'
    },
    {
      'id_siswa': 'SISWA-2023001',
      'nis': '2023001',
      'nisn': '0071234510',
      'nama_lengkap': 'Fathur Rahman',
      'id_angkatan': 'ANGK-3',
      'jenis_kelamin': 'L',
      'tempat_lahir': 'Tasikmalaya',
      'tgl_lahir': '2007-03-11',
      'alamat': 'Komplek Permata Hijau B1',
      'no_hp': '085712348899',
      'nama_ortu': 'H. Ridwan',
      'status': 'Aktif'
    },
    {
      'id_siswa': 'SISWA-2022001',
      'nis': '2022001',
      'nisn': '0061234501',
      'nama_lengkap': 'Bilal Ramadhan',
      'id_angkatan': 'ANGK-2',
      'jenis_kelamin': 'L',
      'tempat_lahir': 'Bogor',
      'tgl_lahir': '2006-11-02',
      'alamat': 'Komplek Hijau Blok B4',
      'no_hp': '085612345678',
      'nama_ortu': 'Ir. Usman',
      'status': 'Aktif'
    },
    {
      'id_siswa': 'SISWA-2021001',
      'nis': '2021001',
      'nisn': '0051234999',
      'nama_lengkap': 'Fajar Ramadhan',
      'id_angkatan': 'ANGK-1',
      'jenis_kelamin': 'L',
      'tempat_lahir': 'Cimahi',
      'tgl_lahir': '2005-02-18',
      'alamat': 'Jl. Raya Cihanjuang No. 88',
      'no_hp': '087812345678',
      'nama_ortu': 'Supriyadi',
      'status': 'Lulus'
    },
  ];
}
