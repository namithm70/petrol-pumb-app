import '../../../../core/constants/url_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/session/auth_session_manager.dart';
import '../../../../core/utils/either.dart';
import '../models/notification_model.dart';

abstract class NotificationsRemoteDataSource {
  Future<Either<AppException, List<NotificationModel>>> fetchNotifications();
  Future<Either<AppException, NotificationModel>> createNotification({
    required String title,
    required String message,
  });
}

class NotificationsRemoteDataSourceImpl implements NotificationsRemoteDataSource {
  NotificationsRemoteDataSourceImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<Either<AppException, List<NotificationModel>>> fetchNotifications() async {
    final result = await apiClient.get(
      UrlConstants.notifications,
      headers: AuthSessionManager.instance.authHeaders(),
    );
    if (result is Left<AppException, ApiResponse>) {
      return Left(result.value);
    }
    final response = (result as Right<AppException, ApiResponse>).value;
    if (response.statusCode != 200) {
      return Left(
        AppException(
          'Failed to load notifications.',
          statusCode: response.statusCode,
        ),
      );
    }
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      return Left(AppException('Invalid server response.'));
    }
    final list = (data['notifications'] as List?) ?? [];
    final notifications = list
        .whereType<Map<String, dynamic>>()
        .map(NotificationModel.fromJson)
        .toList();
    return Right(notifications);
  }

  @override
  Future<Either<AppException, NotificationModel>> createNotification({
    required String title,
    required String message,
  }) async {
    final result = await apiClient.post(
      UrlConstants.notifications,
      headers: AuthSessionManager.instance.authHeaders(),
      body: {'title': title, 'message': message},
    );
    if (result is Left<AppException, ApiResponse>) {
      return Left(result.value);
    }
    final response = (result as Right<AppException, ApiResponse>).value;
    if (response.statusCode != 200) {
      return Left(
        AppException(
          'Failed to create notification.',
          statusCode: response.statusCode,
        ),
      );
    }
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      return Left(AppException('Invalid server response.'));
    }
    final notification = data['notification'];
    if (notification is! Map<String, dynamic>) {
      return Left(AppException('Invalid server response.'));
    }
    return Right(NotificationModel.fromJson(notification));
  }
}
