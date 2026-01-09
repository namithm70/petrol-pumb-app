import 'package:equatable/equatable.dart';

import '../../domain/auth_session.dart';

enum AuthStatus {
  initial,
  loading,
  loaded,
  error,
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.session,
    this.message,
  });

  final AuthStatus status;
  final AuthSession? session;
  final String? message;

  bool get isAuthenticated => session != null;

  AuthState copyWith({
    AuthStatus? status,
    AuthSession? session,
    String? message,
    bool clearMessage = false,
    bool clearSession = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      session: clearSession ? null : session ?? this.session,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, session, message];
}
