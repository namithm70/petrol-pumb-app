import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bpclpos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bpclpos/features/auth/presentation/bloc/auth_state.dart';
import 'package:bpclpos/features/auth/presentation/views/login_view.dart';
import 'package:bpclpos/features/home/presentation/views/home_view.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status == AuthStatus.loading ||
            state.status == AuthStatus.initial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return state.isAuthenticated ? const HomeView() : const LoginScreen();
      },
    );
  }
}
