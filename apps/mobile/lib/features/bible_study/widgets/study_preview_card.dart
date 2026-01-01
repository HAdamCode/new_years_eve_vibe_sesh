import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/study_session.dart';

class StudyPreviewCard extends StatelessWidget {
  final StudySession study;
  final String? groupName;
  final VoidCallback? onTap;

  const StudyPreviewCard({
    super.key,
    required this.study,
    this.groupName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUpcoming = study.sessionDate.isAfter(DateTime.now());

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Date card
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isUpcoming
                        ? [AppColors.primary, AppColors.primaryDark]
                        : [
                            colorScheme.surfaceContainerHighest,
                            colorScheme.surfaceContainerHighest,
                          ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isUpcoming
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getMonthAbbr(study.sessionDate.month),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isUpcoming
                            ? Colors.white.withValues(alpha: 0.8)
                            : colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${study.sessionDate.day}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: isUpcoming
                            ? Colors.white
                            : colorScheme.onSurface.withValues(alpha: 0.8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (groupName != null && groupName!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          groupName!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.secondaryDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      study.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildInfoChip(
                          context,
                          Icons.menu_book_outlined,
                          '${study.passages.length}',
                        ),
                        const SizedBox(width: 12),
                        _buildInfoChip(
                          context,
                          Icons.chat_bubble_outline_rounded,
                          '${study.questions.length}',
                        ),
                        const SizedBox(width: 12),
                        _buildInfoChip(
                          context,
                          Icons.people_outline_rounded,
                          '${study.participants.length}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Arrow
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getMonthAbbr(int month) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    return months[month - 1];
  }
}
