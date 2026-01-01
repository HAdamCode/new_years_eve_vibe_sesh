import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../amplifyconfiguration.dart';
import 'auth_state.dart';

/// Service that wraps AWS Amplify Cognito authentication operations
class AuthService {
  bool _isConfigured = false;

  /// Configure Amplify with auth plugin
  /// Call this once at app startup before using other methods
  Future<bool> configureAmplify() async {
    if (_isConfigured) return true;

    try {
      // Check if already configured
      if (Amplify.isConfigured) {
        _isConfigured = true;
        return true;
      }

      // Add the Auth plugin
      await Amplify.addPlugin(AmplifyAuthCognito());

      // Configure Amplify with the configuration
      await Amplify.configure(amplifyconfig);

      safePrint('Amplify configured successfully');

      _isConfigured = true;
      return true;
    } on AmplifyAlreadyConfiguredException {
      _isConfigured = true;
      return true;
    } catch (e) {
      safePrint('Error configuring Amplify: $e');
      return false;
    }
  }

  /// Check current authentication status
  /// Returns authenticated state if valid session exists
  Future<AuthState> checkAuthStatus() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();

      if (session.isSignedIn) {
        final user = await Amplify.Auth.getCurrentUser();
        final attributes = await Amplify.Auth.fetchUserAttributes();

        String? email;
        for (final attr in attributes) {
          if (attr.userAttributeKey == CognitoUserAttributeKey.email) {
            email = attr.value;
            break;
          }
        }

        return AuthState.authenticated(
          userId: user.userId,
          email: email ?? '',
        );
      }

      return AuthState.unauthenticated();
    } on SignedOutException {
      return AuthState.unauthenticated();
    } on AuthException catch (e) {
      safePrint('Error checking auth status: ${e.message}');
      return AuthState.unauthenticated();
    } catch (e) {
      safePrint('Unexpected error checking auth status: $e');
      return AuthState.unauthenticated();
    }
  }

  /// Generate a unique username from email
  String _generateUsername(String email) {
    // Use email prefix + timestamp for uniqueness
    final prefix = email.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    return '${prefix}_$timestamp';
  }

  /// Sign up a new user with email and password
  Future<AuthState> signUp({
    required String email,
    required String password,
  }) async {
    try {
      // Generate a username since the pool doesn't allow email as username
      final username = _generateUsername(email);

      final result = await Amplify.Auth.signUp(
        username: username,
        password: password,
        options: SignUpOptions(
          userAttributes: {
            CognitoUserAttributeKey.email: email,
            CognitoUserAttributeKey.preferredUsername: username,
          },
        ),
      );

      if (result.isSignUpComplete) {
        // Auto sign-in enabled, user is fully signed up
        return await signIn(email: email, password: password);
      } else {
        // Needs confirmation (email verification)
        return AuthState.needsConfirmation(email: email, username: username);
      }
    } on UsernameExistsException {
      return AuthState.error('An account with this email already exists');
    } on InvalidPasswordException catch (e) {
      return AuthState.error(e.message);
    } on AuthException catch (e) {
      return AuthState.error(e.message);
    } catch (e) {
      return AuthState.error('Sign up failed. Please try again.');
    }
  }

  /// Confirm sign up with verification code
  Future<AuthState> confirmSignUp({
    required String username,
    required String confirmationCode,
  }) async {
    try {
      final result = await Amplify.Auth.confirmSignUp(
        username: username,
        confirmationCode: confirmationCode,
      );

      if (result.isSignUpComplete) {
        return AuthState.unauthenticated();
      } else {
        return AuthState.needsConfirmation(email: '', username: username);
      }
    } on CodeMismatchException {
      return AuthState.error('Invalid verification code');
    } on ExpiredCodeException {
      return AuthState.error('Verification code has expired. Request a new one.');
    } on AuthException catch (e) {
      return AuthState.error(e.message);
    } catch (e) {
      return AuthState.error('Confirmation failed. Please try again.');
    }
  }

  /// Resend confirmation code
  Future<void> resendConfirmationCode(String username) async {
    try {
      await Amplify.Auth.resendSignUpCode(username: username);
    } on LimitExceededException {
      throw Exception('Too many attempts. Please try again later.');
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Sign in with email and password
  /// Note: This tries to sign in using email (if configured as alias in Cognito)
  Future<AuthState> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // First sign out any existing session
      try {
        await Amplify.Auth.signOut();
      } catch (_) {
        // Ignore sign out errors
      }

      final result = await Amplify.Auth.signIn(
        username: email,
        password: password,
      );

      if (result.isSignedIn) {
        return await checkAuthStatus();
      } else if (result.nextStep.signInStep ==
          AuthSignInStep.confirmSignUp) {
        // User needs to confirm but we don't have their username
        return AuthState.error('Please complete email verification. Check your inbox.');
      } else {
        return AuthState.error('Sign in incomplete. Additional steps required.');
      }
    } on UserNotConfirmedException {
      return AuthState.error('Please verify your email first. Check your inbox for the verification code.');
    } on UserNotFoundException {
      return AuthState.error('No account found with this email');
    } on NotAuthorizedServiceException {
      return AuthState.error('Incorrect email or password');
    } on AuthException catch (e) {
      return AuthState.error(e.message);
    } catch (e) {
      return AuthState.error('Sign in failed. Please try again.');
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      await Amplify.Auth.signOut();
    } on AuthException catch (e) {
      safePrint('Error signing out: ${e.message}');
      rethrow;
    }
  }

  /// Request password reset
  Future<void> resetPassword(String email) async {
    try {
      await Amplify.Auth.resetPassword(username: email);
    } on UserNotFoundException {
      throw Exception('No account found with this email');
    } on LimitExceededException {
      throw Exception('Too many attempts. Please try again later.');
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Confirm password reset with code and new password
  Future<void> confirmResetPassword({
    required String email,
    required String newPassword,
    required String confirmationCode,
  }) async {
    try {
      await Amplify.Auth.confirmResetPassword(
        username: email,
        newPassword: newPassword,
        confirmationCode: confirmationCode,
      );
    } on CodeMismatchException {
      throw Exception('Invalid verification code');
    } on ExpiredCodeException {
      throw Exception('Verification code has expired');
    } on InvalidPasswordException catch (e) {
      throw Exception(e.message);
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }
}
