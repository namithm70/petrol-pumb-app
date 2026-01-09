import '../../../../core/constants/url_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/either.dart';
import '../models/auth_session_model.dart';

abstract class AuthRemoteDataSource {
  Future<Either<AppException, AuthSessionModel>> login({
    required String email,
    required String password,
    required bool rememberMe,
  });

  Future<Either<AppException, AuthSessionModel>> setupAccount({
    required String email,
    required String password,
    required bool rememberMe,
  });

  Future<Either<AppException, void>> logout({
    required String token,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<Either<AppException, AuthSessionModel>> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final result = await apiClient.post(
      UrlConstants.authLogin,
      body: {'email': email, 'password': password},
    );

    if (result is Left<AppException, ApiResponse>) {
      return Left(result.value);
    }

    final response = (result as Right<AppException, ApiResponse>).value;
    if (response.statusCode == 404) {
      return Left(
        AppException(
          'Account not configured. Please set it up.',
          statusCode: response.statusCode,
        ),
      );
    }
    if (response.statusCode != 200) {
      return Left(
        AppException(
          'Invalid email or password.',
          statusCode: response.statusCode,
        ),
      );
    }
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      return Left(AppException('Invalid server response.'));
    }
    try {
      return Right(
        AuthSessionModel.fromJson(data, rememberMe: rememberMe),
      );
    } catch (e) {
      return Left(AppException('Invalid server response.', cause: e));
    }
  }

  @override
  Future<Either<AppException, AuthSessionModel>> setupAccount({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final result = await apiClient.post(
      UrlConstants.authSetup,
      body: {'email': email, 'password': password},
    );

    if (result is Left<AppException, ApiResponse>) {
      return Left(result.value);
    }

    final response = (result as Right<AppException, ApiResponse>).value;
    if (response.statusCode == 409) {
      return Left(
        AppException(
          'Account already configured. Please login.',
          statusCode: response.statusCode,
        ),
      );
    }
    if (response.statusCode != 200) {
      return Left(
        AppException(
          'Server error: HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        ),
      );
    }
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      return Left(AppException('Invalid server response.'));
    }
    try {
      return Right(
        AuthSessionModel.fromJson(data, rememberMe: rememberMe),
      );
    } catch (e) {
      return Left(AppException('Invalid server response.', cause: e));
    }
  }

  @override
  Future<Either<AppException, void>> logout({required String token}) async {
    final result = await apiClient.post(
      UrlConstants.authLogout,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (result is Left<AppException, ApiResponse>) {
      return Left(result.value);
    }

    final response = (result as Right<AppException, ApiResponse>).value;
    if (response.statusCode != 200) {
      return Left(
        AppException(
          'Failed to logout.',
          statusCode: response.statusCode,
        ),
      );
    }
    return const Right(null);
  }
}
