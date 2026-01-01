import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';
import '../models/group.dart';

/// State for the groups list
class GroupsState {
  final List<Group> groups;
  final bool isLoading;
  final String? error;

  const GroupsState({
    this.groups = const [],
    this.isLoading = false,
    this.error,
  });

  GroupsState copyWith({
    List<Group>? groups,
    bool? isLoading,
    String? error,
  }) {
    return GroupsState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  factory GroupsState.initial() => const GroupsState();
  factory GroupsState.loading() => const GroupsState(isLoading: true);
  factory GroupsState.error(String message) => GroupsState(error: message);
}

/// Provider for managing groups state
final groupsProvider =
    StateNotifierProvider<GroupsNotifier, GroupsState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return GroupsNotifier(apiService);
});

/// StateNotifier for managing groups
class GroupsNotifier extends StateNotifier<GroupsState> {
  final dynamic _apiService;

  GroupsNotifier(this._apiService) : super(GroupsState.initial());

  /// Load groups from the API
  Future<void> loadGroups() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final groups = await _apiService.listGroups();
      state = state.copyWith(groups: groups, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Create a new group
  Future<Group?> createGroup({
    required String name,
    String? description,
  }) async {
    try {
      final group = await _apiService.createGroup(
        name: name,
        description: description,
      );
      state = state.copyWith(
        groups: [...state.groups, group],
      );
      return group;
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }

  /// Join an existing group
  Future<bool> joinGroup(String groupId) async {
    try {
      await _apiService.joinGroup(groupId);
      // Reload groups to get updated list
      await loadGroups();
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Leave a group
  Future<bool> leaveGroup(String groupId) async {
    try {
      await _apiService.leaveGroup(groupId);
      // Remove from local state
      state = state.copyWith(
        groups: state.groups.where((g) => g.id != groupId).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(
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
