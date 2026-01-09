import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/either.dart';
import '../notification_item.dart';
import '../notifications_repository.dart';

class CreateNotificationUseCase {
  const CreateNotificationUseCase(this.repository);

  final NotificationsRepository repository;

  Future<Either<AppException, NotificationItem>> call({
    required String title,
    required String message,
  }) {
    return repository.createNotification(
      title: title,
      message: message,
    );
  }
}
