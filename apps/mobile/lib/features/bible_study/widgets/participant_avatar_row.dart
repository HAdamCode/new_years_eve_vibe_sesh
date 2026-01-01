import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/study_session.dart';

/// A beautifully styled row of participant avatars with online status
class ParticipantAvatarRow extends StatelessWidget {
  final List<Participant> participants;
  final int maxVisible;
  final VoidCallback? onTap;

  const ParticipantAvatarRow({
    super.key,
    required this.participants,
    this.maxVisible = 4,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onlineCount = participants.where((p) => p.isOnline).length;

    final visibleParticipants = participants.take(maxVisible).toList();
    final remainingCount = participants.length - maxVisible;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outlineVariant,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stacked avatars
            SizedBox(
              height: 32,
              width: (visibleParticipants.length * 22.0) +
                  (remainingCount > 0 ? 28 : 6),
              child: Stack(
                children: [
                  for (var i = 0; i < visibleParticipants.length; i++)
                    Positioned(
                      left: i * 22.0,
                      child: _ParticipantAvatar(
                        participant: visibleParticipants[i],
                      ),
                    ),
                  if (remainingCount > 0)
                    Positioned(
                      left: visibleParticipants.length * 22.0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '+$remainingCount',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Online indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.tertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.tertiary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.tertiary.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$onlineCount online',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.tertiaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantAvatar extends StatelessWidget {
  final Participant participant;

  const _ParticipantAvatar({required this.participant});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: participant.isLeader
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.secondary, AppColors.secondaryDark],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.8),
                      AppColors.primaryDark,
                    ],
                  ),
            shape: BoxShape.circle,
            border: Border.all(
              color: colorScheme.surface,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (participant.isLeader
                        ? AppColors.secondary
                        : AppColors.primary)
                    .withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              participant.initials,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        // Online indicator
        if (participant.isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.tertiary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.surface,
                  width: 2,
                ),
              ),
            ),
          ),
        // Leader badge
        if (participant.isLeader)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.surface,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.star_rounded,
                size: 8,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}
