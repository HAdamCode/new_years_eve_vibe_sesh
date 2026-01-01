import 'study_session.dart';

/// Represents a Bible study group
class Group {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final List<Participant> members;
  final DateTime createdAt;
  final bool isActive;

  const Group({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.members = const [],
    required this.createdAt,
    this.isActive = true,
  });

  /// Create a Group from JSON response
  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      members: const [], // Backend doesn't return members in list view
    );
  }

  /// Convert Group to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Returns the number of members in the group
  int get memberCount => members.length;

  /// Returns the group leader if one exists
  Participant? get leader => members.cast<Participant?>().firstWhere(
        (m) => m?.isLeader == true,
        orElse: () => null,
      );

  /// Returns formatted creation date
  String get formattedDate {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[createdAt.month - 1]} ${createdAt.day}, ${createdAt.year}';
  }

  /// Creates a copy with updated fields
  Group copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    List<Participant>? members,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
