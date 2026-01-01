/// Represents a note or comment from a group member
class GroupNote {
  final String id;
  final String authorName;
  final String authorInitials;
  final String content;
  final DateTime createdAt;
  final String? relatedQuestionId;

  const GroupNote({
    required this.id,
    required this.authorName,
    required this.authorInitials,
    required this.content,
    required this.createdAt,
    this.relatedQuestionId,
  });

  /// Returns a formatted time string
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${createdAt.month}/${createdAt.day}';
    }
  }
}
