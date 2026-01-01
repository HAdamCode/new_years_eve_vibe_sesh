import 'dart:convert';
import 'dart:io' show Platform;

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart' hide UserProfile;
import 'package:http/http.dart' as http;

import '../models/user_profile.dart';
import '../../features/bible_study/models/group.dart';

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

  // ===== Group Methods =====

  /// List all groups for the current user
  Future<List<Group>> listGroups() async {
    try {
      final headers = await _getHeaders();
      safePrint('Fetching groups from $_baseUrl/groups');
      final response = await http.get(
        Uri.parse('$_baseUrl/groups'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((g) => Group.fromJson(g)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else {
        safePrint('Groups fetch failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load groups: ${response.statusCode}');
      }
    } catch (e) {
      safePrint('Error fetching groups: $e');
      rethrow;
    }
  }

  /// Create a new group
  Future<Group> createGroup({
    required String name,
    String? description,
  }) async {
    try {
      final headers = await _getHeaders();
      safePrint('Creating group at $_baseUrl/groups');
      final response = await http.post(
        Uri.parse('$_baseUrl/groups'),
        headers: headers,
        body: json.encode({
          'name': name,
          if (description != null && description.isNotEmpty)
            'description': description,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Group.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else if (response.statusCode == 422) {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Invalid data');
      } else {
        safePrint('Group creation failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to create group');
      }
    } catch (e) {
      safePrint('Error creating group: $e');
      rethrow;
    }
  }

  /// Join an existing group
  Future<void> joinGroup(String groupId) async {
    try {
      final headers = await _getHeaders();
      safePrint('Joining group at $_baseUrl/groups/$groupId/join');
      final response = await http.post(
        Uri.parse('$_baseUrl/groups/$groupId/join'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else if (response.statusCode == 404) {
        throw Exception('Group not found');
      } else if (response.statusCode == 400) {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Already a member');
      } else {
        safePrint('Join group failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to join group');
      }
    } catch (e) {
      safePrint('Error joining group: $e');
      rethrow;
    }
  }

  /// Leave a group
  Future<void> leaveGroup(String groupId) async {
    try {
      final headers = await _getHeaders();
      safePrint('Leaving group at $_baseUrl/groups/$groupId/leave');
      final response = await http.post(
        Uri.parse('$_baseUrl/groups/$groupId/leave'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else if (response.statusCode == 404) {
        throw Exception('Group not found');
      } else if (response.statusCode == 400) {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Not a member');
      } else {
        safePrint('Leave group failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to leave group');
      }
    } catch (e) {
      safePrint('Error leaving group: $e');
      rethrow;
    }
  }
}
