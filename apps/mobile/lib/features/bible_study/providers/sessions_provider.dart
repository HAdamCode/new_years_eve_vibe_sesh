import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/services/api_service.dart';

/// State for sessions within a study
class SessionsState {
  final List<Session> sessions;
  final bool isLoading;
  final String? error;

  const SessionsState({
    this.sessions = const [],
    this.isLoading = false,
    this.error,
  });

  SessionsState copyWith({
    List<Session>? sessions,
    bool? isLoading,
    String? error,
  }) {
    return SessionsState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing sessions
class SessionsNotifier extends StateNotifier<SessionsState> {
  final ApiService _apiService;
  String? _currentStudyId;

  SessionsNotifier(this._apiService) : super(const SessionsState());

  String? get currentStudyId => _currentStudyId;

  /// Load sessions for a study
  Future<void> loadSessions(String studyId) async {
    _currentStudyId = studyId;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final sessions = await _apiService.listSessions(studyId);
      state = state.copyWith(sessions: sessions, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Create a new session
  Future<Session?> createSession({
    required String title,
    String? description,
    int? position,
  }) async {
    if (_currentStudyId == null) return null;

    try {
      final session = await _apiService.createSession(
        studyId: _currentStudyId!,
        title: title,
        description: description,
        position: position,
      );
      state = state.copyWith(
        sessions: [...state.sessions, session]..sort((a, b) => a.position.compareTo(b.position)),
      );
      return session;
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }

  /// Update a session
  Future<bool> updateSession({
    required String sessionId,
    String? title,
    String? description,
    int? position,
  }) async {
    if (_currentStudyId == null) return false;

    try {
      final updated = await _apiService.updateSession(
        studyId: _currentStudyId!,
        sessionId: sessionId,
        title: title,
        description: description,
        position: position,
      );
      state = state.copyWith(
        sessions: state.sessions.map((s) => s.id == sessionId ? updated : s).toList()
          ..sort((a, b) => a.position.compareTo(b.position)),
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Delete a session
  Future<bool> deleteSession(String sessionId) async {
    if (_currentStudyId == null) return false;

    try {
      await _apiService.deleteSession(
        studyId: _currentStudyId!,
        sessionId: sessionId,
      );
      state = state.copyWith(
        sessions: state.sessions.where((s) => s.id != sessionId).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Reorder sessions
  Future<bool> reorderSessions(List<Session> newOrder) async {
    if (_currentStudyId == null) return false;

    // Optimistically update UI
    final oldSessions = state.sessions;
    state = state.copyWith(sessions: newOrder);

    try {
      final items = newOrder.asMap().entries.map((entry) {
        return SessionReorderItem(
          id: entry.value.id,
          position: entry.key + 1,
        );
      }).toList();

      final reordered = await _apiService.reorderSessions(
        studyId: _currentStudyId!,
        items: items,
      );
      state = state.copyWith(sessions: reordered);
      return true;
    } catch (e) {
      // Revert on error
      state = state.copyWith(
        sessions: oldSessions,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for sessions
final sessionsProvider = StateNotifierProvider<SessionsNotifier, SessionsState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return SessionsNotifier(apiService);
});
