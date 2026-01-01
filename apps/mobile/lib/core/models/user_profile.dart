/// User profile model
class UserProfile {
  final String id;
  final String displayName;
  final String initials;

  const UserProfile({
    required this.id,
    required this.displayName,
    required this.initials,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      initials: json['initials'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'initials': initials,
    };
  }

  UserProfile copyWith({
    String? id,
    String? displayName,
    String? initials,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      initials: initials ?? this.initials,
    );
  }
}
