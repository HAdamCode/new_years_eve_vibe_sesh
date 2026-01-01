import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/group.dart';

class GroupCard extends StatelessWidget {
  final Group group;
  final int studyCount;
  final VoidCallback? onTap;

  const GroupCard({
    super.key,
    required this.group,
    this.studyCount = 0,
    this.onTap,
  });

  // Get a consistent color based on group id
  Color _getGroupColor() {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.tertiary,
      const Color(0xFF7986CB),
      const Color(0xFFE57373),
    ];
    return colors[group.id.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupColor = _getGroupColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: groupColor.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Background gradient
              Positioned.fill(
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
              // Decorative pattern
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      width: 44,
                      height: 44,
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
                    const SizedBox(height: 16),
                    // Name
                    Text(
                      group.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Stats row
                    Row(
                      children: [
                        // Member avatars
                        _buildMemberStack(context),
                        const Spacer(),
                        // Study count
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_stories_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$studyCount',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberStack(BuildContext context) {
    final visibleMembers = group.members.take(3).toList();

    return SizedBox(
      height: 28,
      width: (visibleMembers.length * 18.0) + 10,
      child: Stack(
        children: [
          for (var i = 0; i < visibleMembers.length; i++)
            Positioned(
              left: i * 18.0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    visibleMembers[i].initials,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: _getGroupColor(),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
