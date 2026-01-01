import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/group.dart';
import '../models/study_session.dart';
import '../models/scripture_passage.dart';
import '../models/discussion_question.dart';

/// Screen for creating a new study session
class CreateStudyScreen extends StatefulWidget {
  final Group group;

  const CreateStudyScreen({
    super.key,
    required this.group,
  });

  @override
  State<CreateStudyScreen> createState() => _CreateStudyScreenState();
}

class _CreateStudyScreenState extends State<CreateStudyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _scriptureController = TextEditingController();
  final List<TextEditingController> _questionControllers = [];
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addQuestion();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _scriptureController.dispose();
    for (var controller in _questionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questionControllers.add(TextEditingController());
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questionControllers[index].dispose();
      _questionControllers.removeAt(index);
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _createStudy() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Parse scripture references (simple comma-separated)
    final scriptureRefs = _scriptureController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // Create passages from references
    final passages = scriptureRefs.asMap().entries.map((entry) {
      return ScripturePassage(
        id: '${DateTime.now().millisecondsSinceEpoch}_${entry.key}',
        book: entry.value,
        chapter: 1,
        startVerse: 1,
        endVerse: 1,
        text: 'Scripture text will be loaded from API',
        version: 'ESV',
      );
    }).toList();

    // Create questions
    final questions = _questionControllers
        .asMap()
        .entries
        .where((e) => e.value.text.trim().isNotEmpty)
        .map((entry) {
      return DiscussionQuestion(
        id: '${DateTime.now().millisecondsSinceEpoch}_q${entry.key}',
        question: entry.value.text.trim(),
        order: entry.key + 1,
      );
    }).toList();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      final study = StudySession(
        id: 's${DateTime.now().millisecondsSinceEpoch}',
        groupId: widget.group.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        sessionDate: _selectedDate,
        leaderName: widget.group.leader?.name,
        participants: widget.group.members,
        passages: passages,
        questions: questions,
        notes: [],
        assignments: [],
      );

      Navigator.pop(context, study);
    });
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Study'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Group badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.groups_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.group.name,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Title field
            _buildLabel('Study Title'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.words,
              decoration: _buildInputDecoration('e.g., The Beatitudes'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            // Description field
            _buildLabel('Description (optional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: _buildInputDecoration('What will you study?'),
            ),
            const SizedBox(height: 20),
            // Date picker
            _buildLabel('Date'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 20,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatDate(_selectedDate),
                      style: theme.textTheme.bodyLarge,
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Scripture references
            _buildLabel('Scripture References'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _scriptureController,
              decoration: _buildInputDecoration(
                'e.g., Matthew 5:1-12, Matthew 5:13-16',
              ),
            ),
            Text(
              'Separate multiple references with commas',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            // Discussion questions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLabel('Discussion Questions'),
                TextButton.icon(
                  onPressed: _addQuestion,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._questionControllers.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.only(top: 10),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.secondaryDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: entry.value,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: _buildInputDecoration('Enter a question'),
                      ),
                    ),
                    if (_questionControllers.length > 1)
                      IconButton(
                        icon: Icon(
                          Icons.remove_circle_outline,
                          color: colorScheme.error,
                        ),
                        onPressed: () => _removeQuestion(entry.key),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 32),
            // Create button
            FilledButton(
              onPressed: _isLoading ? null : _createStudy,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Create Study'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    );
  }
}
