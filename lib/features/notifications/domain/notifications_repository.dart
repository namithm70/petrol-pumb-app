import '../../../core/errors/app_exception.dart';
import '../../../core/utils/either.dart';
import 'notification_item.dart';

abstract class NotificationsRepository {
  Future<Either<AppException, List<NotificationItem>>> fetchNotifications();

  Future<Either<AppException, NotificationItem>> createNotification({
    required String title,
    required String message,
  });
}
