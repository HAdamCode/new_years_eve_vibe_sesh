import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'auth_service.dart';
import 'auth_state.dart';

/// Provider for the AuthService instance
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Provider for the ApiService instance
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

/// Provider for the current auth state
final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final apiService = ref.watch(apiServiceProvider);
  return AuthNotifier(authService, apiService);
});

/// StateNotifier for managing authentication state
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final ApiService _apiService;

  AuthNotifier(this._authService, this._apiService) : super(AuthState.initial()) {
    // Check auth status when notifier is created
    checkAuthStatus();
  }

  /// Check if user is already authenticated
  Future<void> checkAuthStatus() async {
    state = AuthState.loading();
    final authState = await _authService.checkAuthStatus();
    state = authState;

    // If authenticated, load the profile
    if (authState.status == AuthStatus.authenticated) {
      await loadProfile();
    }
  }

  /// Load user profile from backend
  Future<void> loadProfile() async {
    if (state.status != AuthStatus.authenticated) return;

    try {
      final profile = await _apiService.getProfile();
      state = state.copyWith(
        displayName: profile.displayName,
        initials: profile.initials,
      );
    } catch (e) {
      // Profile loading failed, but user is still authenticated
      // They just don't have a profile yet
    }
  }

  /// Update user's display name
  Future<void> updateProfile(String displayName) async {
    try {
      final profile = await _apiService.updateProfile(displayName);
      state = state.copyWith(
        displayName: profile.displayName,
        initials: profile.initials,
      );
    } catch (e) {
      rethrow;
    }
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
    final authState = await _authService.signIn(email: email, password: password);
    state = authState;

    // If authenticated, load the profile
    if (authState.status == AuthStatus.authenticated) {
      await loadProfile();
    }
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
