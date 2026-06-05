import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  static const _kToken  = 'auth_token';
  static const _kUserId = 'user_id';
  static const _kName   = 'user_name';
  static const _kEmail  = 'user_email';

  String?    _token;
  UserModel? _currentUser;

  String?    get token       => _token;
  UserModel? get currentUser => _currentUser;
  bool       get isLoggedIn  => _token != null;

  /// Load persisted session — call once from main() before runApp.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_kToken);
    final userId = prefs.getString(_kUserId);
    final name   = prefs.getString(_kName);
    final email  = prefs.getString(_kEmail);
    if (_token != null && userId != null && name != null && email != null) {
      _currentUser = UserModel(userId: userId, name: name, email: email);
    }
  }

  Future<void> login(String email, String password) async {
    final res = await http
        .post(
          Uri.parse('${AppConfig.backendBaseUrl}/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(AppConfig.apiTimeout);
    _handleResponse(res);
  }

  Future<void> register(String name, String email, String password) async {
    final res = await http
        .post(
          Uri.parse('${AppConfig.backendBaseUrl}/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'name': name, 'email': email, 'password': password}),
        )
        .timeout(AppConfig.apiTimeout);
    _handleResponse(res);
  }

  Future<void> logout() async {
    if (_token != null) {
      try {
        await http.post(
          Uri.parse('${AppConfig.backendBaseUrl}/auth/logout'),
          headers: {
            'Authorization': 'Bearer $_token',
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 10));
      } catch (_) {}
    }
    await _clearSession();
  }

  Future<List<UserMeeting>> getMyMeetings() async {
    if (_token == null) throw Exception('Not logged in');
    final res = await http.get(
      Uri.parse('${AppConfig.backendBaseUrl}/users/me/meetings'),
      headers: {'Authorization': 'Bearer $_token'},
    ).timeout(AppConfig.apiTimeout);
    if (res.statusCode != 200) {
      throw Exception('Failed to load meetings (${res.statusCode})');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => UserMeeting.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Map<String, String> get authHeaders =>
      _token != null ? {'Authorization': 'Bearer $_token'} : {};

  void _handleResponse(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      String msg = 'Request failed (${res.statusCode})';
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        msg = body['message'] as String? ?? body['error'] as String? ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }
    final auth =
        AuthResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    _token = auth.token;
    _currentUser =
        UserModel(userId: auth.userId, name: auth.name, email: auth.email);
    _persist(auth);
    notifyListeners();
  }

  Future<void> _persist(AuthResponse auth) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken,  auth.token);
    await prefs.setString(_kUserId, auth.userId);
    await prefs.setString(_kName,   auth.name);
    await prefs.setString(_kEmail,  auth.email);
  }

  Future<void> _clearSession() async {
    _token       = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kUserId);
    await prefs.remove(_kName);
    await prefs.remove(_kEmail);
    notifyListeners();
  }
}
