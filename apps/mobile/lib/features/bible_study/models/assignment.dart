/// Represents an optional assignment or practice for the week
class Assignment {
  final String id;
  final String title;
  final String description;
  final AssignmentType type;
  final bool isCompleted;

  const Assignment({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.isCompleted = false,
  });

  Assignment copyWith({bool? isCompleted}) {
    return Assignment(
      id: id,
      title: title,
      description: description,
      type: type,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

enum AssignmentType {
  reading,
  prayer,
  meditation,
  journaling,
  memorization,
  practice,
}

extension AssignmentTypeExtension on AssignmentType {
  String get displayName {
    switch (this) {
      case AssignmentType.reading:
        return 'Reading';
      case AssignmentType.prayer:
        return 'Prayer';
      case AssignmentType.meditation:
        return 'Meditation';
      case AssignmentType.journaling:
        return 'Journaling';
      case AssignmentType.memorization:
        return 'Memorization';
      case AssignmentType.practice:
        return 'Practice';
    }
  }

  String get icon {
    switch (this) {
      case AssignmentType.reading:
        return 'menu_book';
      case AssignmentType.prayer:
        return 'volunteer_activism';
      case AssignmentType.meditation:
        return 'self_improvement';
      case AssignmentType.journaling:
        return 'edit_note';
      case AssignmentType.memorization:
        return 'psychology';
      case AssignmentType.practice:
        return 'directions_run';
    }
  }
}
