/// Represents a discussion question for the study session
class DiscussionQuestion {
  final String id;
  final String question;
  final int order;
  final String? relatedPassageId;

  const DiscussionQuestion({
    required this.id,
    required this.question,
    required this.order,
    this.relatedPassageId,
  });
}
