import '../../domain/auth_session.dart';

class AuthSessionModel extends AuthSession {
  const AuthSessionModel({
    required super.token,
    required super.rememberMe,
  });

  factory AuthSessionModel.fromJson(
    Map<String, dynamic> json, {
    required bool rememberMe,
  }) {
    final token = json['token'] as String?;
    if (token == null || token.isEmpty) {
      throw const FormatException('Missing token in response.');
    }
    return AuthSessionModel(token: token, rememberMe: rememberMe);
  }
}
