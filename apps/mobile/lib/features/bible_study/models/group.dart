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
    required this.members,
    required this.createdAt,
    this.isActive = true,
  });

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
