import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/either.dart';
import '../../domain/auth_session.dart';
import '../../domain/usecases/get_saved_session_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/setup_account_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required this.loginUseCase,
    required this.setupAccountUseCase,
    required this.logoutUseCase,
    required this.getSavedSessionUseCase,
  }) : super(const AuthState()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthSetupRequested>(_onSetupRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  final LoginUseCase loginUseCase;
  final SetupAccountUseCase setupAccountUseCase;
  final LogoutUseCase logoutUseCase;
  final GetSavedSessionUseCase getSavedSessionUseCase;

  Future<void> _onStarted(
    AuthStarted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearMessage: true));
    final result = await getSavedSessionUseCase();
    if (result is Left<AppException, AuthSession?>) {
      emit(
        state.copyWith(
          status: AuthStatus.error,
          message: result.value.message,
          clearSession: true,
        ),
      );
      return;
    }
    final session = (result as Right<AppException, AuthSession?>).value;
    emit(
      state.copyWith(
        status: AuthStatus.loaded,
        session: session,
        clearMessage: true,
      ),
    );
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearMessage: true));
    final result = await loginUseCase(
      email: event.email,
      password: event.password,
      rememberMe: event.rememberMe,
    );
    _emitAuthResult(result, emit);
  }

  Future<void> _onSetupRequested(
    AuthSetupRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearMessage: true));
    final result = await setupAccountUseCase(
      email: event.email,
      password: event.password,
      rememberMe: event.rememberMe,
    );
    _emitAuthResult(result, emit);
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearMessage: true));
    final result = await logoutUseCase();
    if (result is Left<AppException, void>) {
      emit(
        state.copyWith(
          status: AuthStatus.error,
          message: result.value.message,
          clearSession: true,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: AuthStatus.loaded,
        clearSession: true,
        clearMessage: true,
      ),
    );
  }

  void _emitAuthResult(
    Either<AppException, AuthSession> result,
    Emitter<AuthState> emit,
  ) {
    if (result is Left<AppException, AuthSession>) {
      emit(
        state.copyWith(
          status: AuthStatus.error,
          message: result.value.message,
          clearSession: true,
        ),
      );
      return;
    }

    final session = (result as Right<AppException, AuthSession>).value;
    emit(
      state.copyWith(
        status: AuthStatus.loaded,
        session: session,
        clearMessage: true,
      ),
    );
  }
}
