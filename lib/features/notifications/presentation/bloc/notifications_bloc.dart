import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/either.dart';
import '../../domain/notification_item.dart';
import '../../domain/usecases/create_notification_usecase.dart';
import '../../domain/usecases/fetch_notifications_usecase.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc({
    required this.fetchNotificationsUseCase,
    required this.createNotificationUseCase,
  }) : super(const NotificationsState()) {
    on<NotificationsRequested>(_onFetchRequested);
    on<NotificationCreateRequested>(_onCreateRequested);
  }

  final FetchNotificationsUseCase fetchNotificationsUseCase;
  final CreateNotificationUseCase createNotificationUseCase;

  Future<void> _onFetchRequested(
    NotificationsRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(status: NotificationsStatus.loading, clearMessage: true));
    final result = await fetchNotificationsUseCase();
    result.fold(
      (error) {
        emit(
          state.copyWith(
            status: NotificationsStatus.error,
            message: error.message,
          ),
        );
      },
      (items) {
        emit(
          state.copyWith(
            status: NotificationsStatus.loaded,
            items: items,
            clearMessage: true,
          ),
        );
      },
    );
  }

  Future<void> _onCreateRequested(
    NotificationCreateRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(status: NotificationsStatus.loading, clearMessage: true));
    final result = await createNotificationUseCase(
      title: event.title,
      message: event.message,
    );
    result.fold(
      (error) {
        emit(
          state.copyWith(
            status: NotificationsStatus.error,
            message: error.message,
          ),
        );
      },
      (item) {
        final updatedItems = [item, ...state.items];
        emit(
          state.copyWith(
            status: NotificationsStatus.loaded,
            items: updatedItems,
            clearMessage: true,
          ),
        );
      },
    );
  }
}
