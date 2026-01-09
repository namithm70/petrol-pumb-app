import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/validators.dart';
import '../auth_repository.dart';
import '../auth_session.dart';

class SetupAccountUseCase {
  const SetupAccountUseCase(this.repository);

  final AuthRepository repository;

  Future<Either<AppException, AuthSession>> call({
    required String email,
    required String password,
    required bool rememberMe,
  }) {
    if (!Validators.isValidEmail(email)) {
      return Future.value(Left(AppException('Enter a valid email.')));
    }
    if (password.length < 6) {
      return Future.value(
        Left(AppException('Password must be at least 6 characters.')),
      );
    }
    return repository.setupAccount(
      email: email,
      password: password,
      rememberMe: rememberMe,
    );
  }
}
