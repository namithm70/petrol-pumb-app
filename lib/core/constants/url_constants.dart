class UrlConstants {
  // Point mobile clients to the EC2-hosted backend (http on port 3001).
  static const String baseUrl = 'http://18.61.163.152:3001';

  static const String authSetup = '/api/auth/setup';
  static const String authLogin = '/api/auth/login';
  static const String authLogout = '/api/auth/logout';

  static const String notifications = '/api/notifications';
}
