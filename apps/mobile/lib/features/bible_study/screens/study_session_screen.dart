import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/study_session.dart';
import '../models/group_note.dart';
import '../models/assignment.dart';
import '../widgets/scripture_card.dart';
import '../widgets/discussion_question_card.dart';
import '../widgets/note_card.dart';
import '../widgets/assignment_card.dart';
import '../widgets/participant_avatar_row.dart';
import '../widgets/section_header.dart';

/// Main screen for viewing and participating in a Bible study session
class StudySessionScreen extends StatefulWidget {
  final StudySession session;

  const StudySessionScreen({
    super.key,
    required this.session,
  });

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<GroupNote> _notes;
  late List<Assignment> _assignments;
  int? _activeQuestionIndex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _notes = List.from(widget.session.notes);
    _assignments = List.from(widget.session.assignments);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addNote(String content) {
    setState(() {
      _notes.add(GroupNote(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        authorName: 'You',
        authorInitials: 'YO',
        content: content,
        createdAt: DateTime.now(),
      ));
    });
  }

  void _toggleAssignment(int index, bool completed) {
    setState(() {
      _assignments[index] = _assignments[index].copyWith(
        isCompleted: completed,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 290,
              floating: false,
              pinned: true,
              backgroundColor: colorScheme.surface,
              foregroundColor: colorScheme.onSurface,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeader(context),
                collapseMode: CollapseMode.pin,
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.bookmark_outline_rounded,
                    color: colorScheme.onSurface,
                  ),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(
                    Icons.share_outlined,
                    color: colorScheme.onSurface,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                tabBar: TabBar(
                  controller: _tabController,
                  labelStyle: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: theme.textTheme.labelLarge,
                  tabs: const [
                    Tab(text: 'Scripture'),
                    Tab(text: 'Discuss'),
                    Tab(text: 'Notes'),
                    Tab(text: 'Practice'),
                  ],
                ),
                color: colorScheme.surface,
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildScriptureTab(),
            _buildQuestionsTab(),
            _buildNotesTab(),
            _buildAssignmentsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            colorScheme.surface,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Session type badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.groups_rounded,
                      size: 12,
                      color: AppColors.secondaryDark,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'GROUP STUDY',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.secondaryDark,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Title
              Text(
                widget.session.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              if (widget.session.description != null) ...[
                const SizedBox(height: 6),
                Text(
                  widget.session.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              // Meta info row
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _buildMetaChip(
                    context,
                    Icons.calendar_today_outlined,
                    widget.session.formattedDate,
                  ),
                  if (widget.session.leaderName != null)
                    _buildMetaChip(
                      context,
                      Icons.person_outline_rounded,
                      widget.session.leaderName!,
                    ),
                  _buildMetaChip(
                    context,
                    Icons.menu_book_outlined,
                    '${widget.session.passages.length} passages',
                  ),
                ],
              ),
              const Spacer(),
              // Participants
              ParticipantAvatarRow(
                participants: widget.session.participants,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaChip(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildScriptureTab() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      itemCount: widget.session.passages.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ScriptureCard(
            passage: widget.session.passages[index],
          ),
        );
      },
    );
  }

  Widget _buildQuestionsTab() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      itemCount: widget.session.questions.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DiscussionQuestionCard(
            question: widget.session.questions[index],
            isActive: _activeQuestionIndex == index,
            onTap: () {
              setState(() {
                _activeQuestionIndex =
                    _activeQuestionIndex == index ? null : index;
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildNotesTab() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Expanded(
          child: _notes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.forum_outlined,
                            size: 40,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Start the conversation',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Share your thoughts, insights, or questions with the group.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    final note = _notes[index];
                    return NoteCard(
                      note: note,
                      isCurrentUser: note.authorName == 'You',
                    );
                  },
                ),
        ),
        AddNoteField(
          onSubmit: _addNote,
          hintText: 'Share your thoughts...',
        ),
      ],
    );
  }

  Widget _buildAssignmentsTab() {
    final theme = Theme.of(context);
    final completedCount = _assignments.where((a) => a.isCompleted).length;
    final progress = _assignments.isEmpty ? 0.0 : completedCount / _assignments.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      children: [
        // Progress card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.tertiary.withValues(alpha: 0.15),
                AppColors.tertiary.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.tertiary.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.tertiary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.trending_up_rounded,
                      color: AppColors.tertiaryDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weekly Progress',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.tertiaryDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$completedCount of ${_assignments.length} completed',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.tertiaryDark.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppColors.tertiaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: AppColors.tertiary.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.tertiary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        // Section header
        SectionHeader(
          title: 'This Week',
          subtitle: 'Optional practices to deepen your study',
        ),
        const SizedBox(height: 16),
        // Assignment list
        ...List.generate(_assignments.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AssignmentCard(
              assignment: _assignments[index],
              onCompletedChanged: (completed) {
                _toggleAssignment(index, completed);
              },
            ),
          );
        }),
      ],
    );
  }
}

/// Delegate for the persistent tab bar header
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color color;

  _TabBarDelegate({
    required this.tabBar,
    required this.color,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar || color != oldDelegate.color;
  }
}
