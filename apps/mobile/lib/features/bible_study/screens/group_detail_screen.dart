import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/mock_data.dart';
import '../models/group.dart';
import '../models/study_session.dart';
import '../widgets/study_preview_card.dart';
import '../widgets/participant_avatar_row.dart';
import '../widgets/empty_state.dart';
import 'study_session_screen.dart';
import 'create_study_screen.dart';

/// Screen showing group details and its studies
class GroupDetailScreen extends StatefulWidget {
  final Group group;
  final VoidCallback? onGroupUpdated;

  const GroupDetailScreen({
    super.key,
    required this.group,
    this.onGroupUpdated,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late List<StudySession> _studies;

  @override
  void initState() {
    super.initState();
    _loadStudies();
  }

  void _loadStudies() {
    setState(() {
      _studies = getStudiesForGroup(widget.group.id);
    });
  }

  void _navigateToStudy(StudySession study) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudySessionScreen(session: study),
      ),
    );
  }

  void _createStudy() async {
    final result = await Navigator.push<StudySession>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateStudyScreen(group: widget.group),
      ),
    );
    if (result != null) {
      setState(() {
        mockStudySessions.add(result);
        _studies = getStudiesForGroup(widget.group.id);
      });
      widget.onGroupUpdated?.call();
    }
  }

  // Get a consistent color based on group id
  Color _getGroupColor() {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.tertiary,
      const Color(0xFF7986CB),
      const Color(0xFFE57373),
    ];
    return colors[widget.group.id.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final groupColor = _getGroupColor();

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 280,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    groupColor,
                    groupColor.withValues(alpha: 0.8),
                    groupColor.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ),
          // Decorative circles
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            top: 80,
            left: -60,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          // Main content
          CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: groupColor,
                foregroundColor: Colors.white,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 56, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Group icon
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.groups_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.group.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.group.description != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.group.description!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              // Members Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: groupColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.people_rounded,
                                    color: groupColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Members',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${widget.group.memberCount} people',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: groupColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.person_add_rounded,
                                    size: 16,
                                    color: groupColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Invite',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: groupColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ParticipantAvatarRow(
                          participants: widget.group.members,
                          maxVisible: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Studies Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Studies',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: groupColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_studies.length}',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: groupColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: _createStudy,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [groupColor, groupColor.withValues(alpha: 0.8)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: groupColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.add_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'New',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Studies List
              if (_studies.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: EmptyState(
                      icon: Icons.menu_book_outlined,
                      title: 'No studies yet',
                      description: 'Create your first study session',
                      actionLabel: 'Create Study',
                      onAction: _createStudy,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final study = _studies[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: StudyPreviewCard(
                            study: study,
                            onTap: () => _navigateToStudy(study),
                          ),
                        );
                      },
                      childCount: _studies.length,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [groupColor, groupColor.withValues(alpha: 0.8)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: groupColor.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _createStudy,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          icon: const Icon(Icons.add_rounded),
          label: const Text('New Study'),
        ),
      ),
    );
  }
}
