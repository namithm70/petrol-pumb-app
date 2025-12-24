import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
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
  String? _pinHash;
  String? _pinSalt;
  bool _rememberMe = false;

  String? get token => _token;
  bool get hasLocalPin => _pinHash != null && _pinSalt != null;
  bool get rememberMe => _rememberMe;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _pinHash = prefs.getString('pin_hash');
    _pinSalt = prefs.getString('pin_salt');
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
    required String pin,
    required bool rememberMe,
  }) async {
    if (!_isValidEmail(email)) {
      return AuthResult.failure('Enter a valid email');
    }
    if (password.length < 6) {
      return AuthResult.failure('Password must be at least 6 characters');
    }
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      return AuthResult.failure('PIN must be exactly 4 digits');
    }

    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);
    await _saveLocalPin(hash: hash, salt: salt);

    try {
      final uri = Uri.parse('$backendBaseUrl/api/auth/setup');
      final resp = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'pin': pin, 'email': email, 'password': password}),
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
    required String pin,
    required bool rememberMe,
  }) async {
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      return AuthResult.failure('PIN must be exactly 4 digits');
    }

    final localMatch = _isLocalPinMatch(pin);

    try {
      final uri = Uri.parse('$backendBaseUrl/api/auth/login');
      final resp = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'pin': pin}),
          )
          .timeout(const Duration(seconds: 5));

      if (resp.statusCode == 404) {
        return AuthResult.failure('Account not configured. Please set it up.');
      }
      if (resp.statusCode != 200) {
        return AuthResult.failure('Invalid PIN');
      }
      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      await _setToken(decoded['token'] as String?, rememberMe: rememberMe);
      return AuthResult.success();
    } on SocketException catch (_) {
      if (localMatch) {
        loggedIn.value = true;
        _rememberMe = false;
        return AuthResult.success();
      }
      return AuthResult.failure('No network. Connect to verify PIN.');
    } on TimeoutException catch (_) {
      if (localMatch) {
        loggedIn.value = true;
        _rememberMe = false;
        return AuthResult.success();
      }
      return AuthResult.failure('No network. Connect to verify PIN.');
    } catch (e) {
      return AuthResult.failure('Login failed: $e');
    }
  }

  Future<AuthResult> loginWithEmail({
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
      return AuthResult.failure('No network. Use PIN to login.');
    } on TimeoutException catch (_) {
      return AuthResult.failure('No network. Use PIN to login.');
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

  Future<void> _saveLocalPin({required String hash, required String salt}) async {
    _pinHash = hash;
    _pinSalt = salt;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pin_hash', hash);
    await prefs.setString('pin_salt', salt);
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

  bool _isLocalPinMatch(String pin) {
    if (_pinHash == null || _pinSalt == null) {
      return false;
    }
    return _hashPin(pin, _pinSalt!) == _pinHash;
  }

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }

  String _generateSalt() {
    final rand = Random.secure();
    final values = List<int>.generate(16, (_) => rand.nextInt(256));
    return base64UrlEncode(values);
  }
}
