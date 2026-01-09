import '../../../core/errors/app_exception.dart';
import '../../../core/utils/either.dart';
import 'auth_session.dart';

abstract class AuthRepository {
  Future<Either<AppException, AuthSession>> login({
    required String email,
    required String password,
    required bool rememberMe,
  });

  Future<Either<AppException, AuthSession>> setupAccount({
    required String email,
    required String password,
    required bool rememberMe,
  });

  Future<Either<AppException, void>> logout();

  Future<Either<AppException, AuthSession?>> getSavedSession();
}
