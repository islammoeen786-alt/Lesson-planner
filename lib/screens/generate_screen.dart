import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/lesson_plan_provider.dart';
import '../config/subjects.dart';
import '../theme/app_colors.dart';
import '../widgets/pro_upgrade_dialog.dart';
import '../widgets/subject_picker.dart';

class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key});

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController();
  final _objectivesController = TextEditingController();
  final _instructionsController = TextEditingController();

  String _subject = 'Mathematics';
  String _gradeLevel = 'Grade 5';
  int _durationMinutes = 40;
  String _teachingStyle = 'Balanced';
  final _grades = [
    'Grade 1',
    'Grade 2',
    'Grade 3',
    'Grade 4',
    'Grade 5',
    'Grade 6',
    'Grade 7',
    'Grade 8',
    'Grade 9',
    'Grade 10',
    'Grade 11',
    'Grade 12'
  ];
  final _styles = [
    'Lecture',
    'Hands-on',
    'Discussion',
    'Group Work',
    'Project-based',
    'Balanced'
  ];

  bool _generating = false;
  String _loadingMessage = '';

  final _loadingMessages = [
    'Designing your lesson...',
    'Creating engaging activities...',
    'Structuring the content...',
    'Adding assessment strategies...',
    'Almost ready...',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LessonPlanProvider>().loadQuota();
    });
  }

  @override
  void dispose() {
    _topicController.dispose();
    _objectivesController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        final ok = _subject.isNotEmpty && _gradeLevel.isNotEmpty;
        debugPrint('[Generate] Step 0 canProceed: $ok (subject: "$_subject", grade: "$_gradeLevel")');
        return ok;
      case 1:
        final ok = _topicController.text.trim().isNotEmpty;
        debugPrint('[Generate] Step 1 canProceed: $ok (topic: "${_topicController.text}")');
        return ok;
      case 2:
        debugPrint('[Generate] Step 2 canProceed: true');
        return true;
      default:
        debugPrint('[Generate] Step $_currentStep canProceed: false');
        return false;
    }
  }

  void _next() {
    if (!_canProceed) return;
    setState(() => _currentStep++);
  }

  void _back() {
    setState(() => _currentStep--);
  }

  Future<void> _generate() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthProvider>();
    final provider = context.read<LessonPlanProvider>();

    // Pro users skip quota check
    if (!(auth.user?.isPro ?? false) && provider.quotaRemaining <= 0) {
      if (mounted) await ProUpgradeDialog.show(context);
      return;
    }

    setState(() {
      _generating = true;
      _loadingMessage = _loadingMessages[0];
    });

    final objectives = _objectivesController.text.isNotEmpty
        ? _objectivesController.text
            .split('\n')
            .where((l) => l.trim().isNotEmpty)
            .map((l) => l.trim())
            .toList()
        : null;

    _animateLoadingMessage();

    final plan = await provider.generatePlan(
      subject: _subject,
      gradeLevel: _gradeLevel,
      topic: _topicController.text.trim(),
      durationMinutes: _durationMinutes,
      learningObjectives: objectives,
      teachingStyle: _teachingStyle,
      extraInstructions: _instructionsController.text.trim().isNotEmpty
          ? _instructionsController.text.trim()
          : null,
    );

    if (mounted) {
      setState(() => _generating = false);
      if (plan != null) {
        Navigator.pushNamed(context, '/plan-detail', arguments: plan.id);
      }
    }
  }

  void _animateLoadingMessage() {
    Future.doWhile(() async {
      if (!_generating || !mounted) return false;
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted || !_generating) return false;
      setState(() {
        final current = _loadingMessages.indexOf(_loadingMessage);
        _loadingMessage =
            _loadingMessages[(current + 1) % _loadingMessages.length];
      });
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_generating) return _buildLoadingState(theme);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Lesson Plan'),
        leading: _currentStep > 0
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _back)
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context)),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildProgressIndicator(theme),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildStepContent(theme),
                  ),
                ],
              ),
            ),
            _buildBottomBar(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(ThemeData theme) {
    final steps = ['Subject', 'Topic', 'Details', 'Review'];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: List.generate(steps.length, (i) {
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;
          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (i > 0)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isDone || isActive
                              ? AppColors.primary
                              : AppColors.borderLight,
                        ),
                      ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? AppColors.primary
                            : (isActive
                                ? AppColors.primary
                                : AppColors.borderLight),
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 16)
                            : Text('${i + 1}',
                                style: TextStyle(
                                    color: isActive
                                        ? Colors.white
                                        : AppColors.textTertiaryLight,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                      ),
                    ),
                    if (i < steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isDone
                              ? AppColors.primary
                              : AppColors.borderLight,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(steps[i],
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive
                            ? AppColors.primary
                            : AppColors.textTertiaryLight)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(ThemeData theme) {
    switch (_currentStep) {
      case 0:
        return _stepSubject(theme);
      case 1:
        return _stepTopic(theme);
      case 2:
        return _stepDetails(theme);
      case 3:
        return _stepReview(theme);
      default:
        return const SizedBox();
    }
  }

  Widget _stepSubject(ThemeData theme) {
    final subjectIcon = SubjectCatalog.find(_subject)?.icon ?? Icons.book_outlined;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('What do you want to teach?', style: theme.textTheme.titleLarge),
        const SizedBox(height: 6),
        Text('Select the subject and grade level',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondaryLight)),
        const SizedBox(height: 28),
        InkWell(
          onTap: () => SubjectPicker.show(context, selected: _subject, onSelected: (s) {
            setState(() => _subject = s);
          }),
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Subject',
              prefixIcon: Icon(subjectIcon, color: AppColors.primary),
              suffixIcon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondaryLight),
            ),
            child: Text(_subject, style: theme.textTheme.bodyLarge),
          ),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField(
          initialValue: _gradeLevel,
          decoration: const InputDecoration(
              labelText: 'Grade Level', prefixIcon: Icon(Icons.grade_outlined)),
          items: _grades
              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
              .toList(),
          onChanged: (v) => setState(() => _gradeLevel = v!),
        ),
      ],
    );
  }

  Widget _stepTopic(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('What\'s the topic?', style: theme.textTheme.titleLarge),
        const SizedBox(height: 6),
        Text('Enter the main topic or chapter',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondaryLight)),
        const SizedBox(height: 28),
        TextFormField(
          controller: _topicController,
          decoration: const InputDecoration(
            labelText: 'Topic',
            prefixIcon: Icon(Icons.topic_outlined),
            hintText: 'e.g. Fractions, Solar System, World War II',
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Topic is required' : null,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _objectivesController,
          decoration: const InputDecoration(
            labelText: 'Learning Objectives (optional)',
            prefixIcon: Icon(Icons.flag_outlined),
            hintText: 'One per line',
          ),
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _stepDetails(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('Classroom details', style: theme.textTheme.titleLarge),
        const SizedBox(height: 6),
        Text('Set duration and teaching style',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondaryLight)),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: _durationMinutes,
                decoration: const InputDecoration(
                    labelText: 'Duration',
                    prefixIcon: Icon(Icons.timer_outlined)),
                items: [20, 30, 40, 45, 50, 60, 80, 90, 120]
                    .map((d) =>
                        DropdownMenuItem(value: d, child: Text('$d min')))
                    .toList(),
                onChanged: (v) => setState(() => _durationMinutes = v!),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField(
                initialValue: _teachingStyle,
                decoration: const InputDecoration(
                    labelText: 'Style', prefixIcon: Icon(Icons.style_outlined)),
                items: _styles
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _teachingStyle = v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _instructionsController,
          decoration: const InputDecoration(
            labelText: 'Extra Instructions (optional)',
            prefixIcon: Icon(Icons.notes_outlined),
            hintText: 'Hands-on activities, differentiation, etc.',
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _stepReview(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('Review & Generate', style: theme.textTheme.titleLarge),
        const SizedBox(height: 6),
        Text('Confirm your choices before generating',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondaryLight)),
        const SizedBox(height: 24),
        _reviewItem(theme, Icons.book_outlined, 'Subject', _subject),
        _reviewItem(theme, Icons.grade_outlined, 'Grade Level', _gradeLevel),
        _reviewItem(
            theme, Icons.topic_outlined, 'Topic', _topicController.text.trim()),
        _reviewItem(
            theme, Icons.timer_outlined, 'Duration', '$_durationMinutes min'),
        _reviewItem(theme, Icons.style_outlined, 'Style', _teachingStyle),
        if (_objectivesController.text.isNotEmpty)
          _reviewItem(theme, Icons.flag_outlined, 'Objectives',
              '${_objectivesController.text.split('\n').where((l) => l.trim().isNotEmpty).length} objectives'),
        if (_instructionsController.text.isNotEmpty)
          _reviewItem(theme, Icons.notes_outlined, 'Instructions',
              _instructionsController.text.trim()),
        const SizedBox(height: 16),
        Consumer<LessonPlanProvider>(
          builder: (_, lp, __) {
            if (lp.error != null) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(lp.error!,
                            style: const TextStyle(
                                color: AppColors.error, fontSize: 13))),
                  ]),
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ],
    );
  }

  Widget _reviewItem(
      ThemeData theme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textTertiaryLight)),
                Text(value, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2))
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _back,
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Back'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed:
                    _currentStep < 3 ? (_canProceed ? _next : null) : _generate,
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: Text(_currentStep < 3 ? 'Next' : 'Generate Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  _loadingMessage,
                  key: ValueKey(_loadingMessage),
                  style: theme.textTheme.titleLarge
                      ?.copyWith(color: AppColors.textPrimaryLight),
                ),
              ),
              const SizedBox(height: 12),
              Text('This may take a moment',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textSecondaryLight)),
              const SizedBox(height: 40),
              LinearProgressIndicator(
                backgroundColor: AppColors.borderLight.withValues(alpha: 0.5),
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
