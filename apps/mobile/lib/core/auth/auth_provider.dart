import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';
import 'auth_state.dart';

/// Provider for the AuthService instance
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Provider for the current auth state
final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

/// StateNotifier for managing authentication state
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState.initial()) {
    // Check auth status when notifier is created
    checkAuthStatus();
  }

  /// Check if user is already authenticated
  Future<void> checkAuthStatus() async {
    state = AuthState.loading();
    state = await _authService.checkAuthStatus();
  }

  /// Sign up with email and password
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    state = AuthState.loading();
    state = await _authService.signUp(email: email, password: password);
  }

  /// Confirm sign up with verification code
  Future<void> confirmSignUp({
    required String username,
    required String confirmationCode,
  }) async {
    state = AuthState.loading();
    final result = await _authService.confirmSignUp(
      username: username,
      confirmationCode: confirmationCode,
    );

    if (result.status == AuthStatus.unauthenticated) {
      // Confirmation successful, now the user should sign in
      state = result;
    } else {
      state = result;
    }
  }

  /// Resend confirmation code
  Future<void> resendConfirmationCode(String username) async {
    await _authService.resendConfirmationCode(username);
  }

  /// Sign in with email and password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = AuthState.loading();
    state = await _authService.signIn(email: email, password: password);
  }

  /// Sign out the current user
  Future<void> signOut() async {
    state = AuthState.loading();
    try {
      await _authService.signOut();
      state = AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.error('Failed to sign out');
    }
  }

  /// Request password reset
  Future<void> resetPassword(String email) async {
    await _authService.resetPassword(email);
  }

  /// Confirm password reset
  Future<void> confirmResetPassword({
    required String email,
    required String newPassword,
    required String confirmationCode,
  }) async {
    await _authService.confirmResetPassword(
      email: email,
      newPassword: newPassword,
      confirmationCode: confirmationCode,
    );
  }

  /// Clear any error state
  void clearError() {
    if (state.status == AuthStatus.error) {
      state = AuthState.unauthenticated();
    }
  }

  /// Navigate to confirmation screen (for resending code flow)
  void needsConfirmation({required String email, required String username}) {
    state = AuthState.needsConfirmation(email: email, username: username);
  }
}
