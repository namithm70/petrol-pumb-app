import '../../../core/errors/app_exception.dart';
import '../../../core/utils/either.dart';
import '../domain/notification_item.dart';
import '../domain/notifications_repository.dart';
import 'datasources/notifications_remote_data_source.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl({required this.remoteDataSource});

  final NotificationsRemoteDataSource remoteDataSource;

  @override
  Future<Either<AppException, List<NotificationItem>>> fetchNotifications() {
    return remoteDataSource.fetchNotifications();
  }

  @override
  Future<Either<AppException, NotificationItem>> createNotification({
    required String title,
    required String message,
  }) {
    return remoteDataSource.createNotification(
      title: title,
      message: message,
    );
  }
}
