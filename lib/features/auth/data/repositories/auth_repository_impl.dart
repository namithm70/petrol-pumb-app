import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/either.dart';
import '../../domain/auth_repository.dart';
import '../../domain/auth_session.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/auth_session_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  @override
  Future<Either<AppException, AuthSession>> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final result = await remoteDataSource.login(
      email: email,
      password: password,
      rememberMe: rememberMe,
    );

    if (result is Left<AppException, AuthSessionModel>) {
      return Left(result.value);
    }

    final session = (result as Right<AppException, AuthSessionModel>).value;
    await localDataSource.cacheSession(session);
    return Right(session);
  }

  @override
  Future<Either<AppException, AuthSession>> setupAccount({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final result = await remoteDataSource.setupAccount(
      email: email,
      password: password,
      rememberMe: rememberMe,
    );

    if (result is Left<AppException, AuthSessionModel>) {
      return Left(result.value);
    }

    final session = (result as Right<AppException, AuthSessionModel>).value;
    await localDataSource.cacheSession(session);
    return Right(session);
  }

  @override
  Future<Either<AppException, void>> logout() async {
    final session = localDataSource.getCurrentSession();
    if (session != null) {
      final remote = await remoteDataSource.logout(token: session.token);
      if (remote is Left<AppException, void>) {
        await localDataSource.clearSession();
        return Left(remote.value);
      }
    }
    await localDataSource.clearSession();
    return const Right(null);
  }

  @override
  Future<Either<AppException, AuthSession?>> getSavedSession() async {
    try {
      final session = await localDataSource.getSavedSession();
      return Right(session);
    } catch (e) {
      return Left(AppException.unexpected('Failed to read session.', e));
    }
  }
}
