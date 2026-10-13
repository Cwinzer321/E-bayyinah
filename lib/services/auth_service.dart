import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionString = prefs.getString(ApiConstants.keyUserSession);
    if (sessionString != null) {
      try {
        final Map<String, dynamic> json = jsonDecode(sessionString);
        _currentUser = UserModel.fromJson(json);
      } catch (e) {
        await prefs.remove(ApiConstants.keyUserSession);
      }
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await ApiService().get('login', {
      'username': username,
      'password': password,
    });

    if (res['success'] == true && res['user'] != null) {
      final user = UserModel.fromJson(res['user'] as Map<String, dynamic>);
      _currentUser = user;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        ApiConstants.keyUserSession,
        jsonEncode(user.toJson()),
      );
      return {'success': true, 'message': res['message'] ?? 'Login berhasil'};
    } else {
      return {
        'success': false,
        'message': res['message'] ?? 'Username atau Kata Sandi salah'
      };
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConstants.keyUserSession);
  }
}
