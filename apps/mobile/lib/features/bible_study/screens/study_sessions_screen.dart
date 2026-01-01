import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/sessions_provider.dart';

/// Screen for managing sessions within a study
class StudySessionsScreen extends ConsumerStatefulWidget {
  final Study study;
  final bool isLeader;

  const StudySessionsScreen({
    super.key,
    required this.study,
    this.isLeader = false,
  });

  @override
  ConsumerState<StudySessionsScreen> createState() => _StudySessionsScreenState();
}

class _StudySessionsScreenState extends ConsumerState<StudySessionsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(sessionsProvider.notifier).loadSessions(widget.study.id);
    });
  }

  void _showCreateSessionDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SessionFormSheet(
        title: 'Add Session',
        titleController: titleController,
        descriptionController: descriptionController,
        onSave: () async {
          if (titleController.text.trim().isEmpty) return;

          final session = await ref.read(sessionsProvider.notifier).createSession(
            title: titleController.text.trim(),
            description: descriptionController.text.trim().isEmpty
                ? null
                : descriptionController.text.trim(),
          );

          if (session != null && mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Session added'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
      ),
    );
  }

  void _showEditSessionDialog(Session session) {
    final titleController = TextEditingController(text: session.title);
    final descriptionController = TextEditingController(text: session.description ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SessionFormSheet(
        title: 'Edit Session',
        titleController: titleController,
        descriptionController: descriptionController,
        onSave: () async {
          if (titleController.text.trim().isEmpty) return;

          final success = await ref.read(sessionsProvider.notifier).updateSession(
            sessionId: session.id,
            title: titleController.text.trim(),
            description: descriptionController.text.trim().isEmpty
                ? null
                : descriptionController.text.trim(),
          );

          if (success && mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Session updated'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
        onDelete: () async {
          Navigator.pop(context);
          _confirmDeleteSession(session);
        },
      ),
    );
  }

  void _confirmDeleteSession(Session session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: Text('Are you sure you want to delete "${session.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(sessionsProvider.notifier).deleteSession(session.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Session deleted'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sessionsState = ref.watch(sessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.study.title),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: sessionsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : sessionsState.sessions.isEmpty
              ? _buildEmptyState()
              : _buildSessionsList(sessionsState.sessions),
      floatingActionButton: widget.isLeader
          ? FloatingActionButton.extended(
              onPressed: _showCreateSessionDialog,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Session'),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today_outlined,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No sessions yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isLeader
                  ? 'Add sessions to organize your study into weeks or meetings'
                  : 'The leader hasn\'t added any sessions yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.isLeader) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _showCreateSessionDialog,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add First Session'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSessionsList(List<Session> sessions) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: sessions.length,
      buildDefaultDragHandles: widget.isLeader,
      onReorder: (oldIndex, newIndex) {
        if (!widget.isLeader) return;
        if (newIndex > oldIndex) newIndex--;

        final newList = List<Session>.from(sessions);
        final item = newList.removeAt(oldIndex);
        newList.insert(newIndex, item);

        ref.read(sessionsProvider.notifier).reorderSessions(newList);
      },
      itemBuilder: (context, index) {
        final session = sessions[index];
        return Card(
          key: ValueKey(session.id),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: widget.isLeader ? () => _showEditSessionDialog(session) : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Session number
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Session info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (session.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            session.description!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Drag handle or chevron
                  if (widget.isLeader)
                    ReorderableDragStartListener(
                      index: index,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.drag_handle,
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Bottom sheet form for creating/editing sessions
class _SessionFormSheet extends StatelessWidget {
  final String title;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final VoidCallback onSave;
  final VoidCallback? onDelete;

  const _SessionFormSheet({
    required this.title,
    required this.titleController,
    required this.descriptionController,
    required this.onSave,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                ),
            ],
          ),
          const SizedBox(height: 24),
          // Session title field
          TextField(
            controller: titleController,
            textCapitalization: TextCapitalization.words,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Session Title',
              hintText: 'e.g., Week 1: Introduction',
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Description field
          TextField(
            controller: descriptionController,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Description (optional)',
              hintText: 'Goals or focus for this session',
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Save button
          FilledButton(
            onPressed: onSave,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
