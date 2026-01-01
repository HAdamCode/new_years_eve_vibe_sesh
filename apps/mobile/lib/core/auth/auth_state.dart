/// Authentication status enum
enum AuthStatus {
  /// Initial state before checking auth
  initial,

  /// Currently checking auth status or performing auth operation
  loading,

  /// User is authenticated
  authenticated,

  /// User is not authenticated
  unauthenticated,

  /// User signed up but needs to confirm email
  needsConfirmation,

  /// An error occurred
  error,
}

/// Authentication state model
class AuthState {
  final AuthStatus status;
  final String? userId;
  final String? email;
  final String? username; // Cognito username (different from email)
  final String? errorMessage;

  const AuthState._({
    required this.status,
    this.userId,
    this.email,
    this.username,
    this.errorMessage,
  });

  /// Initial state
  factory AuthState.initial() => const AuthState._(status: AuthStatus.initial);

  /// Loading state
  factory AuthState.loading() => const AuthState._(status: AuthStatus.loading);

  /// Authenticated state
  factory AuthState.authenticated({
    required String userId,
    required String email,
  }) =>
      AuthState._(
        status: AuthStatus.authenticated,
        userId: userId,
        email: email,
      );

  /// Unauthenticated state
  factory AuthState.unauthenticated() =>
      const AuthState._(status: AuthStatus.unauthenticated);

  /// Needs email confirmation state
  factory AuthState.needsConfirmation({
    required String email,
    required String username,
  }) =>
      AuthState._(
        status: AuthStatus.needsConfirmation,
        email: email,
        username: username,
      );

  /// Error state
  factory AuthState.error(String message) => AuthState._(
        status: AuthStatus.error,
        errorMessage: message,
      );

  /// Copy with modifications
  AuthState copyWith({
    AuthStatus? status,
    String? userId,
    String? email,
    String? username,
    String? errorMessage,
  }) {
    return AuthState._(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      username: username ?? this.username,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() =>
      'AuthState(status: $status, userId: $userId, email: $email)';
}
