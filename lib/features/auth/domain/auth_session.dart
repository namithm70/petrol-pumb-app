class AuthSession {
  const AuthSession({
    required this.token,
    required this.rememberMe,
  });

  final String token;
  final bool rememberMe;
}
