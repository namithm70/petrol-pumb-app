import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/either.dart';
import '../auth_repository.dart';

class LogoutUseCase {
  const LogoutUseCase(this.repository);

  final AuthRepository repository;

  Future<Either<AppException, void>> call() {
    return repository.logout();
  }
}
