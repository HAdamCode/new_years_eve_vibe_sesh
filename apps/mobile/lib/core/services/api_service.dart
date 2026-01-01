import 'dart:convert';
import 'dart:io' show Platform;

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart' hide UserProfile;
import 'package:http/http.dart' as http;

import '../models/user_profile.dart';

/// Service for communicating with the backend API
class ApiService {
  /// Get the base URL for the current platform
  /// - iOS Simulator: localhost works
  /// - Android Emulator: 10.0.2.2 is the host machine
  /// - Physical device: Use your machine's IP or deployed URL
  static String get _baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  /// Get the current auth token from Amplify
  Future<String?> _getAuthToken() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (session is CognitoAuthSession) {
        return session.userPoolTokensResult.value.idToken.raw;
      }
      return null;
    } catch (e) {
      safePrint('Error getting auth token: $e');
      return null;
    }
  }

  /// Get headers with auth token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Get current user's profile
  Future<UserProfile> getProfile() async {
    try {
      final headers = await _getHeaders();
      safePrint('Fetching profile from $_baseUrl/profile');
      final response = await http.get(
        Uri.parse('$_baseUrl/profile'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return UserProfile.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else {
        safePrint('Profile fetch failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      safePrint('Error fetching profile: $e');
      rethrow;
    }
  }

  /// Update user's display name
  Future<UserProfile> updateProfile(String displayName) async {
    try {
      final headers = await _getHeaders();
      safePrint('Updating profile at $_baseUrl/profile');
      final response = await http.put(
        Uri.parse('$_baseUrl/profile'),
        headers: headers,
        body: json.encode({'display_name': displayName}),
      );

      if (response.statusCode == 200) {
        return UserProfile.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - please sign in again');
      } else if (response.statusCode == 422) {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Invalid data');
      } else {
        safePrint('Profile update failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      safePrint('Error updating profile: $e');
      rethrow;
    }
  }
}
