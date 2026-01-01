import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import 'auth_state.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/confirm_email_screen.dart';
import '../../features/bible_study/screens/home_screen.dart';

/// Wrapper widget that handles authentication-based routing
///
/// Shows different screens based on the current auth state:
/// - [SplashScreen] while checking auth status
/// - [LoginScreen] when unauthenticated
/// - [ConfirmEmailScreen] when email needs confirmation
/// - [HomeScreen] when authenticated
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return switch (authState.status) {
      AuthStatus.initial || AuthStatus.loading => const SplashScreen(),
      AuthStatus.authenticated => const HomeScreen(),
      AuthStatus.unauthenticated || AuthStatus.error => const LoginScreen(),
      AuthStatus.needsConfirmation => ConfirmEmailScreen(
          email: authState.email ?? '',
          username: authState.username ?? '',
        ),
    };
  }
}
