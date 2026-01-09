import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/either.dart';
import '../notification_item.dart';
import '../notifications_repository.dart';

class FetchNotificationsUseCase {
  const FetchNotificationsUseCase(this.repository);

  final NotificationsRepository repository;

  Future<Either<AppException, List<NotificationItem>>> call() {
    return repository.fetchNotifications();
  }
}
