import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/session/auth_session_manager.dart';
import '../../domain/auth_session.dart';

abstract class AuthLocalDataSource {
  Future<AuthSession?> getSavedSession();
  Future<void> cacheSession(AuthSession session);
  Future<void> clearSession();
  AuthSession? getCurrentSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl({required this.sessionManager});

  final AuthSessionManager sessionManager;

  static const _tokenKey = 'auth_token';
  static const _rememberKey = 'remember_me';

  @override
  Future<AuthSession?> getSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final rememberMe = prefs.getBool(_rememberKey) ?? false;
    if (token == null || !rememberMe) {
      sessionManager.clear();
      return null;
    }
    final session = AuthSession(token: token, rememberMe: rememberMe);
    sessionManager.updateSession(token: session.token, rememberMe: session.rememberMe);
    return session;
  }

  @override
  Future<void> cacheSession(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    if (session.rememberMe) {
      await prefs.setString(_tokenKey, session.token);
      await prefs.setBool(_rememberKey, true);
    } else {
      await prefs.remove(_tokenKey);
      await prefs.setBool(_rememberKey, false);
    }
    sessionManager.updateSession(token: session.token, rememberMe: session.rememberMe);
  }

  @override
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.setBool(_rememberKey, false);
    sessionManager.clear();
  }

  @override
  AuthSession? getCurrentSession() {
    final token = sessionManager.token;
    if (token == null) return null;
    return AuthSession(token: token, rememberMe: sessionManager.rememberMe);
  }
}
