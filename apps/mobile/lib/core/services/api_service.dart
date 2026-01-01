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

      if (response.statusCode == 200 || response.statusCode == 204) {
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

  // ===== Invite Methods =====

  /// Create an invite link for a group
  Future<InviteLink> createInviteLink(String groupId, {int? expiresInDays}) async {
    try {
      final headers = await _getHeaders();
      safePrint('Creating invite link for group $groupId');
      final response = await http.post(
        Uri.parse('$_baseUrl/invites/groups/$groupId'),
        headers: headers,
        body: expiresInDays != null
            ? json.encode({'expires_in_days': expiresInDays})
            : null,
      );

      if (response.statusCode == 200) {
        return InviteLink.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else if (response.statusCode == 403) {
        throw Exception('Only group leaders can create invite links');
      } else {
        safePrint('Create invite failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to create invite link');
      }
    } catch (e) {
      safePrint('Error creating invite link: $e');
      rethrow;
    }
  }

  /// Preview a group from an invite code (before joining)
  Future<Group> previewInvite(String code) async {
    try {
      final headers = await _getHeaders();
      safePrint('Previewing invite code $code');
      final response = await http.get(
        Uri.parse('$_baseUrl/invites/preview/$code'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Group.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else if (response.statusCode == 404) {
        throw Exception('Invite code not found or expired');
      } else {
        safePrint('Preview invite failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to preview invite');
      }
    } catch (e) {
      safePrint('Error previewing invite: $e');
      rethrow;
    }
  }

  /// Join a group using an invite code
  Future<void> joinByInvite(String code) async {
    try {
      final headers = await _getHeaders();
      safePrint('Joining with invite code $code');
      final response = await http.post(
        Uri.parse('$_baseUrl/invites/join'),
        headers: headers,
        body: json.encode({'code': code}),
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else if (response.statusCode == 404) {
        throw Exception('Invite code not found');
      } else if (response.statusCode == 400) {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Invalid invite');
      } else {
        safePrint('Join by invite failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to join group');
      }
    } catch (e) {
      safePrint('Error joining by invite: $e');
      rethrow;
    }
  }

  // ===== Study Methods =====

  /// List all studies for a group
  Future<List<Study>> listStudies(String groupId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/groups/$groupId/studies'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((s) => Study.fromJson(s)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else {
        throw Exception('Failed to load studies');
      }
    } catch (e) {
      safePrint('Error fetching studies: $e');
      rethrow;
    }
  }

  /// Create a new study in a group
  Future<Study> createStudy({
    required String groupId,
    required String title,
    String? description,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/groups/$groupId/studies'),
        headers: headers,
        body: json.encode({
          'title': title,
          if (description != null && description.isNotEmpty)
            'description': description,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Study.fromJson(json.decode(response.body));
      } else if (response.statusCode == 403) {
        throw Exception('Only leaders can create studies');
      } else {
        throw Exception('Failed to create study');
      }
    } catch (e) {
      safePrint('Error creating study: $e');
      rethrow;
    }
  }

  /// Update a study
  Future<Study> updateStudy({
    required String studyId,
    String? title,
    String? description,
    bool? isArchived,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('$_baseUrl/studies/$studyId'),
        headers: headers,
        body: json.encode({
          if (title != null) 'title': title,
          if (description != null) 'description': description,
          if (isArchived != null) 'is_archived': isArchived,
        }),
      );

      if (response.statusCode == 200) {
        return Study.fromJson(json.decode(response.body));
      } else if (response.statusCode == 403) {
        throw Exception('Only leaders can update studies');
      } else {
        throw Exception('Failed to update study');
      }
    } catch (e) {
      safePrint('Error updating study: $e');
      rethrow;
    }
  }

  /// Delete a study
  Future<void> deleteStudy(String studyId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/studies/$studyId'),
        headers: headers,
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        return;
      } else if (response.statusCode == 403) {
        throw Exception('Only leaders can delete studies');
      } else {
        throw Exception('Failed to delete study');
      }
    } catch (e) {
      safePrint('Error deleting study: $e');
      rethrow;
    }
  }

  // ===== Session Methods =====

  /// List all sessions for a study
  Future<List<Session>> listSessions(String studyId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/studies/$studyId/sessions'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((s) => Session.fromJson(s)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else {
        throw Exception('Failed to load sessions');
      }
    } catch (e) {
      safePrint('Error fetching sessions: $e');
      rethrow;
    }
  }

  /// Create a new session in a study
  Future<Session> createSession({
    required String studyId,
    required String title,
    String? description,
    int? position,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/studies/$studyId/sessions'),
        headers: headers,
        body: json.encode({
          'title': title,
          if (description != null && description.isNotEmpty)
            'description': description,
          if (position != null) 'position': position,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Session.fromJson(json.decode(response.body));
      } else if (response.statusCode == 403) {
        throw Exception('Only leaders can add sessions');
      } else {
        throw Exception('Failed to create session');
      }
    } catch (e) {
      safePrint('Error creating session: $e');
      rethrow;
    }
  }

  /// Update a session
  Future<Session> updateSession({
    required String studyId,
    required String sessionId,
    String? title,
    String? description,
    int? position,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('$_baseUrl/studies/$studyId/sessions/$sessionId'),
        headers: headers,
        body: json.encode({
          if (title != null) 'title': title,
          if (description != null) 'description': description,
          if (position != null) 'position': position,
        }),
      );

      if (response.statusCode == 200) {
        return Session.fromJson(json.decode(response.body));
      } else if (response.statusCode == 403) {
        throw Exception('Only leaders can update sessions');
      } else {
        throw Exception('Failed to update session');
      }
    } catch (e) {
      safePrint('Error updating session: $e');
      rethrow;
    }
  }

  /// Delete a session
  Future<void> deleteSession({
    required String studyId,
    required String sessionId,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/studies/$studyId/sessions/$sessionId'),
        headers: headers,
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        return;
      } else if (response.statusCode == 403) {
        throw Exception('Only leaders can delete sessions');
      } else {
        throw Exception('Failed to delete session');
      }
    } catch (e) {
      safePrint('Error deleting session: $e');
      rethrow;
    }
  }

  /// Reorder sessions in a study
  Future<List<Session>> reorderSessions({
    required String studyId,
    required List<SessionReorderItem> items,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/studies/$studyId/sessions/reorder'),
        headers: headers,
        body: json.encode(items.map((i) => i.toJson()).toList()),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((s) => Session.fromJson(s)).toList();
      } else if (response.statusCode == 403) {
        throw Exception('Only leaders can reorder sessions');
      } else {
        throw Exception('Failed to reorder sessions');
      }
    } catch (e) {
      safePrint('Error reordering sessions: $e');
      rethrow;
    }
  }
}

/// Model for invite link response
class InviteLink {
  final String code;
  final String link;
  final String groupId;
  final String groupName;

  InviteLink({
    required this.code,
    required this.link,
    required this.groupId,
    required this.groupName,
  });

  factory InviteLink.fromJson(Map<String, dynamic> json) {
    return InviteLink(
      code: json['code'] as String,
      link: json['link'] as String,
      groupId: json['group_id'] as String,
      groupName: json['group_name'] as String,
    );
  }
}

/// Model for a Bible study
class Study {
  final String id;
  final String groupId;
  final String title;
  final String? description;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  Study({
    required this.id,
    required this.groupId,
    required this.title,
    this.description,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Study.fromJson(Map<String, dynamic> json) {
    return Study(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      isArchived: json['is_archived'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

/// Model for a study session
class Session {
  final String id;
  final String studyId;
  final String title;
  final String? description;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;

  Session({
    required this.id,
    required this.studyId,
    required this.title,
    this.description,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      studyId: json['study_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      position: json['position'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

/// Model for reordering sessions
class SessionReorderItem {
  final String id;
  final int position;

  SessionReorderItem({
    required this.id,
    required this.position,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'position': position,
    };
  }
}
