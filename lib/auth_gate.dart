import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'form.dart';
import 'login.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = AuthService.instance.init();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return ValueListenableBuilder<bool>(
          valueListenable: AuthService.instance.loggedIn,
          builder: (context, loggedIn, _) {
            return loggedIn ? const MyFormCard() : const LoginScreen();
          },
        );
      },
    );
  }
}
