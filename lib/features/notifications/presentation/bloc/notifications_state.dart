import 'package:equatable/equatable.dart';

import '../../domain/notification_item.dart';

enum NotificationsStatus {
  initial,
  loading,
  loaded,
  error,
}

class NotificationsState extends Equatable {
  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.items = const [],
    this.message,
  });

  final NotificationsStatus status;
  final List<NotificationItem> items;
  final String? message;

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<NotificationItem>? items,
    String? message,
    bool clearMessage = false,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      items: items ?? this.items,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, items, message];
}
