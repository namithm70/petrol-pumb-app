class AuthSessionManager {
  AuthSessionManager._();

  static final AuthSessionManager instance = AuthSessionManager._();

  String? _token;
  bool _rememberMe = false;

  String? get token => _token;
  bool get rememberMe => _rememberMe;

  void updateSession({required String? token, required bool rememberMe}) {
    _token = token;
    _rememberMe = rememberMe;
  }

  void clear() {
    _token = null;
    _rememberMe = false;
  }

  Map<String, String> authHeaders({bool json = true}) {
    final headers = <String, String>{};
    if (json) {
      headers['Content-Type'] = 'application/json';
    }
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
}
