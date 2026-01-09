import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import '../core/constants/url_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/network_info.dart';
import '../core/session/auth_session_manager.dart';
import '../features/auth/data/datasources/auth_local_data_source.dart';
import '../features/auth/data/datasources/auth_remote_data_source.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/auth/domain/usecases/get_saved_session_usecase.dart';
import '../features/auth/domain/usecases/login_usecase.dart';
import '../features/auth/domain/usecases/logout_usecase.dart';
import '../features/auth/domain/usecases/setup_account_usecase.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_event.dart';
import '../features/notifications/data/datasources/notifications_remote_data_source.dart';
import '../features/notifications/data/notifications_repository.dart';
import '../features/notifications/domain/notifications_repository.dart';
import '../features/notifications/domain/usecases/create_notification_usecase.dart';
import '../features/notifications/domain/usecases/fetch_notifications_usecase.dart';
import '../features/notifications/presentation/bloc/notifications_bloc.dart';

class AppProviders extends StatelessWidget {
  const AppProviders({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<NetworkInfo>(
          create: (_) => const NetworkInfoImpl(),
        ),
        RepositoryProvider<http.Client>(
          create: (_) => http.Client(),
        ),
        RepositoryProvider<ApiClient>(
          create: (context) => ApiClient(
            httpClient: context.read<http.Client>(),
            networkInfo: context.read<NetworkInfo>(),
            baseUrl: UrlConstants.baseUrl,
          ),
        ),
        RepositoryProvider<AuthRemoteDataSource>(
          create: (context) =>
              AuthRemoteDataSourceImpl(context.read<ApiClient>()),
        ),
        RepositoryProvider<AuthLocalDataSource>(
          create: (_) => AuthLocalDataSourceImpl(
            sessionManager: AuthSessionManager.instance,
          ),
        ),
        RepositoryProvider<AuthRepository>(
          create: (context) => AuthRepositoryImpl(
            remoteDataSource: context.read<AuthRemoteDataSource>(),
            localDataSource: context.read<AuthLocalDataSource>(),
          ),
        ),
        RepositoryProvider<LoginUseCase>(
          create: (context) => LoginUseCase(context.read<AuthRepository>()),
        ),
        RepositoryProvider<SetupAccountUseCase>(
          create: (context) =>
              SetupAccountUseCase(context.read<AuthRepository>()),
        ),
        RepositoryProvider<LogoutUseCase>(
          create: (context) => LogoutUseCase(context.read<AuthRepository>()),
        ),
        RepositoryProvider<GetSavedSessionUseCase>(
          create: (context) =>
              GetSavedSessionUseCase(context.read<AuthRepository>()),
        ),
        RepositoryProvider<NotificationsRemoteDataSource>(
          create: (context) =>
              NotificationsRemoteDataSourceImpl(context.read<ApiClient>()),
        ),
        RepositoryProvider<NotificationsRepository>(
          create: (context) => NotificationsRepositoryImpl(
            remoteDataSource: context.read<NotificationsRemoteDataSource>(),
          ),
        ),
        RepositoryProvider<FetchNotificationsUseCase>(
          create: (context) =>
              FetchNotificationsUseCase(context.read<NotificationsRepository>()),
        ),
        RepositoryProvider<CreateNotificationUseCase>(
          create: (context) =>
              CreateNotificationUseCase(context.read<NotificationsRepository>()),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              loginUseCase: context.read<LoginUseCase>(),
              setupAccountUseCase: context.read<SetupAccountUseCase>(),
              logoutUseCase: context.read<LogoutUseCase>(),
              getSavedSessionUseCase: context.read<GetSavedSessionUseCase>(),
            )..add(const AuthStarted()),
          ),
          BlocProvider<NotificationsBloc>(
            create: (context) => NotificationsBloc(
              fetchNotificationsUseCase:
                  context.read<FetchNotificationsUseCase>(),
              createNotificationUseCase:
                  context.read<CreateNotificationUseCase>(),
            ),
          ),
        ],
        child: child,
      ),
    );
  }
}
