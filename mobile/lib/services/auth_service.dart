import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

class AuthService extends ChangeNotifier {
  static const _tokenKey = 'admin_token';

  String? _token;
  bool _isAdmin = false;
  bool _initialized = false;

  String? get token => _token;
  bool get isAdmin => _isAdmin;
  bool get initialized => _initialized;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    if (_token != null) {
      await _verifyToken();
    }
    _initialized = true;
    notifyListeners();
  }

  Future<bool> login(String password) async {
    final dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));
    final response = await dio.post<Map<String, dynamic>>(
      '/api/auth/login',
      data: {'password': password},
    );

    final token = response.data?['token'] as String?;
    if (token == null) return false;

    _token = token;
    _isAdmin = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _token = null;
    _isAdmin = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);

    try {
      final dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));
      await dio.post('/api/auth/logout');
    } catch (_) {}

    notifyListeners();
  }

  Future<void> _verifyToken() async {
    try {
      final dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));
      final response = await dio.get<Map<String, dynamic>>(
        '/api/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $_token'}),
      );
      _isAdmin = response.data?['isAdmin'] == true;
      if (!_isAdmin) {
        await logout();
      }
    } catch (_) {
      _isAdmin = false;
      _token = null;
    }
  }
}
