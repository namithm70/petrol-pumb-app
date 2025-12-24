import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _rememberMe = false;
  bool _isSetup = false;
  bool _useEmailLogin = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _isSetup = !AuthService.instance.hasLocalPin;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
    });
    final pin = _pinController.text.trim();
    final confirm = _confirmPinController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_isSetup) {
      if (pin != confirm) {
        _showMessage('PINs do not match');
        setState(() {
          _submitting = false;
        });
        return;
      }
      final result = await AuthService.instance.setupAccount(
        email: email,
        password: password,
        pin: pin,
        rememberMe: _rememberMe,
      );
      if (!result.ok) {
        _showMessage(result.message ?? 'Failed to setup account');
      }
    } else {
      final result = _useEmailLogin
          ? await AuthService.instance.loginWithEmail(
              email: email,
              password: password,
              rememberMe: _rememberMe,
            )
          : await AuthService.instance.login(
              pin: pin,
              rememberMe: _rememberMe,
            );
      if (!result.ok) {
        _showMessage(result.message ?? 'Login failed');
      }
    }

    if (mounted) {
      setState(() {
        _submitting = false;
      });
    }
  }

  void _toggleMode() {
    setState(() {
      _isSetup = !_isSetup;
      _useEmailLogin = false;
      _emailController.clear();
      _passwordController.clear();
      _pinController.clear();
      _confirmPinController.clear();
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock, size: 48, color: Color(0xFF1A2E35)),
                  const SizedBox(height: 12),
                  Text(
                    _isSetup ? 'Set Up Account' : (_useEmailLogin ? 'Email Login' : 'PIN Login'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2E35),
                    ),
                  ),
                  if (!_isSetup) ...[
                    const SizedBox(height: 12),
                    ToggleButtons(
                      borderRadius: BorderRadius.circular(10),
                      isSelected: [_useEmailLogin == false, _useEmailLogin == true],
                      onPressed: (index) {
                        setState(() {
                          _useEmailLogin = index == 1;
                          _emailController.clear();
                          _passwordController.clear();
                          _pinController.clear();
                        });
                      },
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text('PIN'),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text('Email'),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (_isSetup || _useEmailLogin) ...[
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_isSetup || !_useEmailLogin) ...[
                    TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: InputDecoration(
                        labelText: 'PIN',
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                  if (_isSetup) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmPinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Confirm PIN',
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                      ),
                      const Text('Remember me'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A2E35),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(_isSetup ? 'CREATE ACCOUNT' : 'LOGIN'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _toggleMode,
                    child: Text(_isSetup ? 'Use existing login' : 'Set up account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
