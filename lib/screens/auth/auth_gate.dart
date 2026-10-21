import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../main_navigation_scaffold.dart';
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
    _subscribeToAuth();
  }

  Future<void> _checkInitialAuth() async {
    final authed = await AuthService.isAuthenticated();
    if (mounted) {
      setState(() {
        _isAuthenticated = authed;
        _isLoading = false;
      });
    }
  }

  void _subscribeToAuth() {
    AuthService.authStateChanges?.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (!mounted) return;

      if (event == AuthChangeEvent.signedIn && session != null) {
        setState(() {
          _isAuthenticated = true;
          _isLoading = false;
        });
      } else if (event == AuthChangeEvent.signedOut) {
        setState(() {
          _isAuthenticated = false;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Loading Coaching Portal...',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isAuthenticated) {
      return const MainNavigationScaffold();
    }

    return LoginScreen(
      onLoginSuccess: () {
        setState(() {
          _isAuthenticated = true;
        });
      },
    );
  }
}
