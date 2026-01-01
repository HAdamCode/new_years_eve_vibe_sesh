import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/assignment.dart';

/// A beautifully styled card for weekly assignments/practices
class AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final ValueChanged<bool>? onCompletedChanged;
  final VoidCallback? onTap;

  const AssignmentCard({
    super.key,
    required this.assignment,
    this.onCompletedChanged,
    this.onTap,
  });

  IconData _getIcon() {
    switch (assignment.type) {
      case AssignmentType.reading:
        return Icons.menu_book_rounded;
      case AssignmentType.prayer:
        return Icons.favorite_rounded;
      case AssignmentType.meditation:
        return Icons.spa_rounded;
      case AssignmentType.journaling:
        return Icons.edit_rounded;
      case AssignmentType.memorization:
        return Icons.lightbulb_rounded;
      case AssignmentType.practice:
        return Icons.directions_walk_rounded;
    }
  }

  Color _getTypeColor() {
    switch (assignment.type) {
      case AssignmentType.reading:
        return AppColors.primary;
      case AssignmentType.prayer:
        return const Color(0xFFE57373);
      case AssignmentType.meditation:
        return AppColors.tertiary;
      case AssignmentType.journaling:
        return AppColors.secondary;
      case AssignmentType.memorization:
        return const Color(0xFF7986CB);
      case AssignmentType.practice:
        return const Color(0xFF4DB6AC);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final typeColor = _getTypeColor();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: assignment.isCompleted
            ? AppColors.tertiary.withValues(alpha: 0.05)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: assignment.isCompleted
              ? AppColors.tertiary.withValues(alpha: 0.3)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () => onCompletedChanged?.call(!assignment.isCompleted),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon container
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: assignment.isCompleted
                        ? null
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              typeColor.withValues(alpha: 0.15),
                              typeColor.withValues(alpha: 0.05),
                            ],
                          ),
                    color: assignment.isCompleted
                        ? AppColors.tertiary.withValues(alpha: 0.1)
                        : null,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    assignment.isCompleted ? Icons.check_rounded : _getIcon(),
                    color: assignment.isCompleted
                        ? AppColors.tertiary
                        : typeColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          assignment.type.displayName.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: typeColor,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Title
                      Text(
                        assignment.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          decoration: assignment.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor:
                              colorScheme.onSurface.withValues(alpha: 0.5),
                          color: assignment.isCompleted
                              ? colorScheme.onSurface.withValues(alpha: 0.5)
                              : colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Description
                      Text(
                        assignment.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Checkbox
                GestureDetector(
                  onTap: () => onCompletedChanged?.call(!assignment.isCompleted),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: assignment.isCompleted
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.tertiary,
                                AppColors.tertiaryDark,
                              ],
                            )
                          : null,
                      color: assignment.isCompleted
                          ? null
                          : colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: assignment.isCompleted
                          ? null
                          : Border.all(
                              color: colorScheme.outline.withValues(alpha: 0.4),
                              width: 2,
                            ),
                      boxShadow: assignment.isCompleted
                          ? [
                              BoxShadow(
                                color: AppColors.tertiary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: assignment.isCompleted
                        ? const Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
