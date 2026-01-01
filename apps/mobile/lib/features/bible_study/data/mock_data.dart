import '../models/study_session.dart';
import '../models/scripture_passage.dart';
import '../models/discussion_question.dart';
import '../models/group_note.dart';
import '../models/assignment.dart';
import '../models/group.dart';

/// Mock data for demonstration purposes
/// Replace with real API calls when backend is ready

// ============================================================================
// GROUPS
// ============================================================================

final List<Group> mockGroups = [
  Group(
    id: 'g1',
    name: 'Downtown Bible Study',
    description: 'A welcoming group exploring Scripture together in the heart of the city.',
    members: mockParticipants.take(6).toList(),
    createdAt: DateTime(2024, 9, 15),
  ),
  Group(
    id: 'g2',
    name: 'Young Adults Fellowship',
    description: 'For young professionals seeking to grow in faith and community.',
    members: mockParticipants.skip(2).take(4).toList(),
    createdAt: DateTime(2024, 10, 1),
  ),
  Group(
    id: 'g3',
    name: 'Women\'s Prayer Circle',
    description: 'A supportive space for women to study and pray together.',
    members: [mockParticipants[1], mockParticipants[3], mockParticipants[5]],
    createdAt: DateTime(2024, 11, 10),
  ),
];

// ============================================================================
// STUDY SESSIONS
// ============================================================================

final List<StudySession> mockStudySessions = [
  StudySession(
    id: '1',
    groupId: 'g1',
    title: 'The Sermon on the Mount',
    description: 'Exploring Jesus\' teachings on kingdom living',
    sessionDate: DateTime(2024, 12, 31),
    leaderName: 'Pastor Mike',
    participants: mockParticipants,
    passages: mockPassages,
    questions: mockQuestions,
    notes: mockNotes,
    assignments: mockAssignments,
  ),
  StudySession(
    id: '2',
    groupId: 'g1',
    title: 'The Lord\'s Prayer',
    description: 'Learning to pray as Jesus taught',
    sessionDate: DateTime(2025, 1, 7),
    leaderName: 'Pastor Mike',
    participants: mockParticipants.take(4).toList(),
    passages: [
      const ScripturePassage(
        id: '3',
        book: 'Matthew',
        chapter: 6,
        startVerse: 9,
        endVerse: 13,
        version: 'ESV',
        text: 'Pray then like this: "Our Father in heaven, hallowed be your name. Your kingdom come, your will be done, on earth as it is in heaven. Give us this day our daily bread, and forgive us our debts, as we also have forgiven our debtors. And lead us not into temptation, but deliver us from evil."',
      ),
    ],
    questions: [
      const DiscussionQuestion(
        id: '6',
        question: 'What does it mean to hallow God\'s name in our daily lives?',
        order: 1,
      ),
      const DiscussionQuestion(
        id: '7',
        question: 'How do we balance asking for our needs ("daily bread") with trusting God\'s provision?',
        order: 2,
      ),
    ],
    notes: [],
    assignments: [
      const Assignment(
        id: '6',
        title: 'Pray the Lord\'s Prayer Daily',
        description: 'Use the Lord\'s Prayer as a framework for your daily prayer time.',
        type: AssignmentType.prayer,
      ),
    ],
  ),
  StudySession(
    id: '3',
    groupId: 'g2',
    title: 'Faith in the Workplace',
    description: 'Living out your faith Monday through Friday',
    sessionDate: DateTime(2025, 1, 5),
    leaderName: 'David Chen',
    participants: mockParticipants.skip(2).take(4).toList(),
    passages: [
      const ScripturePassage(
        id: '4',
        book: 'Colossians',
        chapter: 3,
        startVerse: 23,
        endVerse: 24,
        version: 'ESV',
        text: 'Whatever you do, work heartily, as for the Lord and not for men, knowing that from the Lord you will receive the inheritance as your reward. You are serving the Lord Christ.',
      ),
    ],
    questions: [
      const DiscussionQuestion(
        id: '8',
        question: 'What does it look like to work "as for the Lord" in your specific job?',
        order: 1,
      ),
    ],
    notes: [],
    assignments: [],
  ),
];

// Keep for backwards compatibility
final mockStudySession = mockStudySessions.first;

// ============================================================================
// PARTICIPANTS
// ============================================================================

final mockParticipants = [
  const Participant(
    id: '1',
    name: 'Pastor Mike',
    initials: 'PM',
    isLeader: true,
    isOnline: true,
  ),
  const Participant(
    id: '2',
    name: 'Sarah Johnson',
    initials: 'SJ',
    isOnline: true,
  ),
  const Participant(
    id: '3',
    name: 'David Chen',
    initials: 'DC',
    isOnline: true,
  ),
  const Participant(
    id: '4',
    name: 'Maria Garcia',
    initials: 'MG',
    isOnline: false,
  ),
  const Participant(
    id: '5',
    name: 'James Wilson',
    initials: 'JW',
    isOnline: true,
  ),
  const Participant(
    id: '6',
    name: 'Emily Brown',
    initials: 'EB',
    isOnline: false,
  ),
];

// ============================================================================
// SCRIPTURE PASSAGES
// ============================================================================

final mockPassages = [
  const ScripturePassage(
    id: '1',
    book: 'Matthew',
    chapter: 5,
    startVerse: 1,
    endVerse: 12,
    version: 'ESV',
    text: '''Seeing the crowds, he went up on the mountain, and when he sat down, his disciples came to him. And he opened his mouth and taught them, saying:

"Blessed are the poor in spirit, for theirs is the kingdom of heaven.

Blessed are those who mourn, for they shall be comforted.

Blessed are the meek, for they shall inherit the earth.

Blessed are those who hunger and thirst for righteousness, for they shall be satisfied.

Blessed are the merciful, for they shall receive mercy.

Blessed are the pure in heart, for they shall see God.

Blessed are the peacemakers, for they shall be called sons of God.

Blessed are those who are persecuted for righteousness' sake, for theirs is the kingdom of heaven.

Blessed are you when others revile you and persecute you and utter all kinds of evil against you falsely on my account. Rejoice and be glad, for your reward is great in heaven, for so they persecuted the prophets who were before you."''',
  ),
  const ScripturePassage(
    id: '2',
    book: 'Matthew',
    chapter: 5,
    startVerse: 13,
    endVerse: 16,
    version: 'ESV',
    text: '''"You are the salt of the earth, but if salt has lost its taste, how shall its saltiness be restored? It is no longer good for anything except to be thrown out and trampled under people's feet.

You are the light of the world. A city set on a hill cannot be hidden. Nor do people light a lamp and put it under a basket, but on a stand, and it gives light to all in the house. In the same way, let your light shine before others, so that they may see your good works and give glory to your Father who is in heaven."''',
  ),
];

// ============================================================================
// DISCUSSION QUESTIONS
// ============================================================================

final mockQuestions = [
  const DiscussionQuestion(
    id: '1',
    question: 'Which of the Beatitudes speaks most to your current life situation, and why?',
    order: 1,
    relatedPassageId: '1',
  ),
  const DiscussionQuestion(
    id: '2',
    question: 'What does it mean to be "poor in spirit" in today\'s world?',
    order: 2,
    relatedPassageId: '1',
  ),
  const DiscussionQuestion(
    id: '3',
    question: 'How can we be "salt and light" in our workplaces and communities?',
    order: 3,
    relatedPassageId: '2',
  ),
  const DiscussionQuestion(
    id: '4',
    question: 'What are some practical ways to be a peacemaker in times of conflict?',
    order: 4,
    relatedPassageId: '1',
  ),
  const DiscussionQuestion(
    id: '5',
    question: 'How do the Beatitudes challenge cultural definitions of success and happiness?',
    order: 5,
    relatedPassageId: '1',
  ),
];

// ============================================================================
// NOTES
// ============================================================================

final mockNotes = [
  GroupNote(
    id: '1',
    authorName: 'Pastor Mike',
    authorInitials: 'PM',
    content: 'Remember that the Beatitudes are not separate requirements, but a description of the character of those who belong to God\'s kingdom. They work together as a whole.',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  GroupNote(
    id: '2',
    authorName: 'Sarah Johnson',
    authorInitials: 'SJ',
    content: 'I\'ve been thinking about what it means to mourn in a spiritual sense. It seems connected to recognizing our need for God.',
    createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
  ),
  GroupNote(
    id: '3',
    authorName: 'David Chen',
    authorInitials: 'DC',
    content: 'The salt and light imagery is powerful. Salt preserves and light reveals - we\'re called to both preserve goodness and reveal truth in the world.',
    createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
  ),
];

// ============================================================================
// ASSIGNMENTS
// ============================================================================

final mockAssignments = [
  const Assignment(
    id: '1',
    title: 'Memorize Matthew 5:3-10',
    description: 'Learn the Beatitudes by heart this week. Try reciting them each morning.',
    type: AssignmentType.memorization,
  ),
  const Assignment(
    id: '2',
    title: 'Daily Beatitude Reflection',
    description: 'Each day, focus on one Beatitude and journal about how it applies to your life.',
    type: AssignmentType.journaling,
  ),
  const Assignment(
    id: '3',
    title: 'Practice Peacemaking',
    description: 'Look for an opportunity to be a peacemaker in a conflict situation this week.',
    type: AssignmentType.practice,
  ),
  const Assignment(
    id: '4',
    title: 'Read Matthew 5-7',
    description: 'Read through the entire Sermon on the Mount to prepare for next week\'s study.',
    type: AssignmentType.reading,
  ),
  const Assignment(
    id: '5',
    title: 'Pray for the Persecuted',
    description: 'Spend time in prayer for Christians facing persecution around the world.',
    type: AssignmentType.prayer,
  ),
];

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/// Get studies for a specific group
List<StudySession> getStudiesForGroup(String groupId) {
  return mockStudySessions.where((s) => s.groupId == groupId).toList();
}

/// Get upcoming studies across all groups
List<StudySession> getUpcomingStudies() {
  final now = DateTime.now();
  return mockStudySessions
      .where((s) => s.sessionDate.isAfter(now.subtract(const Duration(days: 1))))
      .toList()
    ..sort((a, b) => a.sessionDate.compareTo(b.sessionDate));
}
