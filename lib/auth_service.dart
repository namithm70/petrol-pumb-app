import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'app_config.dart';

class AuthResult {
  final bool ok;
  final String? message;

  AuthResult(this.ok, {this.message});

  static AuthResult success() => AuthResult(true);
  static AuthResult failure(String message) => AuthResult(false, message: message);
}

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final ValueNotifier<bool> loggedIn = ValueNotifier<bool>(false);

  String? _token;
  bool _rememberMe = false;

  String? get token => _token;
  bool get rememberMe => _rememberMe;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _rememberMe = prefs.getBool('remember_me') ?? false;
    loggedIn.value = _rememberMe && _token != null;
  }

  Map<String, String> authHeaders({bool json = true}) {
    final headers = <String, String>{};
    if (json) {
      headers['Content-Type'] = 'application/json';
    }
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  Future<AuthResult> setupAccount({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    if (!_isValidEmail(email)) {
      return AuthResult.failure('Enter a valid email');
    }
    if (password.length < 6) {
      return AuthResult.failure('Password must be at least 6 characters');
    }

    try {
      final uri = Uri.parse('$backendBaseUrl/api/auth/setup');
      final resp = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 5));

      if (resp.statusCode == 409) {
        return AuthResult.failure('Account already configured. Please login.');
      }
      if (resp.statusCode != 200) {
        return AuthResult.failure('Server error: HTTP ${resp.statusCode}');
      }
      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      await _setToken(decoded['token'] as String?, rememberMe: rememberMe);
      return AuthResult.success();
    } on SocketException catch (_) {
      loggedIn.value = true;
      _rememberMe = false;
      return AuthResult.success();
    } on TimeoutException catch (_) {
      loggedIn.value = true;
      _rememberMe = false;
      return AuthResult.success();
    } catch (e) {
      return AuthResult.failure('Failed to setup account: $e');
    }
  }

  Future<AuthResult> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    if (!_isValidEmail(email)) {
      return AuthResult.failure('Enter a valid email');
    }
    if (password.length < 6) {
      return AuthResult.failure('Password must be at least 6 characters');
    }

    try {
      final uri = Uri.parse('$backendBaseUrl/api/auth/login');
      final resp = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 5));

      if (resp.statusCode == 404) {
        return AuthResult.failure('Account not configured. Please set it up.');
      }
      if (resp.statusCode != 200) {
        return AuthResult.failure('Invalid email or password');
      }
      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      await _setToken(decoded['token'] as String?, rememberMe: rememberMe);
      return AuthResult.success();
    } on SocketException catch (_) {
      return AuthResult.failure('No network. Please try again later.');
    } on TimeoutException catch (_) {
      return AuthResult.failure('No network. Please try again later.');
    } catch (e) {
      return AuthResult.failure('Login failed: $e');
    }
  }

  Future<void> logout() async {
    final token = _token;
    _token = null;
    _rememberMe = false;
    loggedIn.value = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.setBool('remember_me', false);

    if (token == null) {
      return;
    }
    try {
      final uri = Uri.parse('$backendBaseUrl/api/auth/logout');
      await http
          .post(
            uri,
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  Future<void> _setToken(String? token, {required bool rememberMe}) async {
    _token = token;
    _rememberMe = rememberMe && token != null;
    loggedIn.value = token != null;
    final prefs = await SharedPreferences.getInstance();
    if (token != null && _rememberMe) {
      await prefs.setString('auth_token', token);
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('auth_token');
      await prefs.setBool('remember_me', false);
    }
  }

}
