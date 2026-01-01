import 'scripture_passage.dart';
import 'discussion_question.dart';
import 'group_note.dart';
import 'assignment.dart';

/// Represents a group Bible study session
class StudySession {
  final String id;
  final String? groupId;
  final String title;
  final String? description;
  final DateTime sessionDate;
  final List<ScripturePassage> passages;
  final List<DiscussionQuestion> questions;
  final List<GroupNote> notes;
  final List<Assignment> assignments;
  final List<Participant> participants;
  final String? leaderName;

  const StudySession({
    required this.id,
    this.groupId,
    required this.title,
    this.description,
    required this.sessionDate,
    required this.passages,
    required this.questions,
    required this.notes,
    required this.assignments,
    required this.participants,
    this.leaderName,
  });

  /// Returns formatted session date
  String get formattedDate {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[sessionDate.month - 1]} ${sessionDate.day}, ${sessionDate.year}';
  }
}

/// Represents a participant in the study session
class Participant {
  final String id;
  final String name;
  final String initials;
  final bool isLeader;
  final bool isOnline;

  const Participant({
    required this.id,
    required this.name,
    required this.initials,
    this.isLeader = false,
    this.isOnline = false,
  });
}
