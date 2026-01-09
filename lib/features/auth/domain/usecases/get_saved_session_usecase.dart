import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/either.dart';
import '../auth_repository.dart';
import '../auth_session.dart';

class GetSavedSessionUseCase {
  const GetSavedSessionUseCase(this.repository);

  final AuthRepository repository;

  Future<Either<AppException, AuthSession?>> call() {
    return repository.getSavedSession();
  }
}
