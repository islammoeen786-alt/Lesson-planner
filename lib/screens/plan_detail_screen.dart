import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../providers/lesson_plan_provider.dart';
import '../models/lesson_plan.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';

String _sanitizePdfText(String text) {
  return text
      .replaceAll('\u2022', '-')
      .replaceAll('\u2023', '>')
      .replaceAll('\u25E6', '-')
      .replaceAll('\u2026', '...')
      .replaceAll('\u2018', "'")
      .replaceAll('\u2019', "'")
      .replaceAll('\u201C', '"')
      .replaceAll('\u201D', '"')
      .replaceAll('\u2013', '-')
      .replaceAll('\u2014', '--')
      .replaceAll('\u00A0', ' ');
}

class PlanDetailScreen extends StatefulWidget {
  final int planId;
  const PlanDetailScreen({super.key, required this.planId});

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  LessonPlan? _plan;
  bool _loading = true;
  String? _error;
  bool _editMode = false;

  List<LessonContent> _history = [];
  int _historyIndex = -1;
  static const int _maxHistory = 50;

  String? _lastSavedAt;
  DateTime? _lastEditedAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchPlan());
  }

  Future<void> _fetchPlan() async {
    try {
      final provider = context.read<LessonPlanProvider>();
      await provider.loadPlans(refresh: true);
      if (!mounted) return;
      LessonPlan? found;
      for (final p in provider.plans) {
        if (p.id == widget.planId) {
          found = p;
          break;
        }
      }
      if (found != null) {
        _plan = found;
        _pushHistory(found.content);
        _lastSavedAt = found.updatedAt;
      }
      if (mounted) setState(() { _plan = found; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to load plan'; _loading = false; });
    }
  }

  void _pushHistory(LessonContent content) {
    _history = _history.sublist(0, _historyIndex + 1);
    _history.add(content);
    if (_history.length > _maxHistory) _history.removeAt(0);
    _historyIndex = _history.length - 1;
  }

  bool get _canUndo => _historyIndex > 0;
  bool get _canRedo => _historyIndex < _history.length - 1;

  void _undo() {
    if (!_canUndo) return;
    setState(() {
      _historyIndex--;
      _plan = LessonPlan(
        id: _plan!.id, userId: _plan!.userId, title: _plan!.title,
        subject: _plan!.subject, gradeLevel: _plan!.gradeLevel, topic: _plan!.topic,
        durationMinutes: _plan!.durationMinutes, content: _history[_historyIndex],
        aiGenerated: _plan!.aiGenerated, status: _plan!.status,
        scheduledDate: _plan!.scheduledDate, createdAt: _plan!.createdAt,
        updatedAt: _plan!.updatedAt,
      );
      _lastEditedAt = DateTime.now();
    });
  }

  void _redo() {
    if (!_canRedo) return;
    setState(() {
      _historyIndex++;
      _plan = LessonPlan(
        id: _plan!.id, userId: _plan!.userId, title: _plan!.title,
        subject: _plan!.subject, gradeLevel: _plan!.gradeLevel, topic: _plan!.topic,
        durationMinutes: _plan!.durationMinutes, content: _history[_historyIndex],
        aiGenerated: _plan!.aiGenerated, status: _plan!.status,
        scheduledDate: _plan!.scheduledDate, createdAt: _plan!.createdAt,
        updatedAt: _plan!.updatedAt,
      );
      _lastEditedAt = DateTime.now();
    });
  }

  void _updateContent(LessonContent newContent) {
    setState(() {
      _plan = LessonPlan(
        id: _plan!.id, userId: _plan!.userId, title: _plan!.title,
        subject: _plan!.subject, gradeLevel: _plan!.gradeLevel, topic: _plan!.topic,
        durationMinutes: _plan!.durationMinutes, content: newContent,
        aiGenerated: _plan!.aiGenerated, status: _plan!.status,
        scheduledDate: _plan!.scheduledDate, createdAt: _plan!.createdAt,
        updatedAt: _plan!.updatedAt,
      );
      _pushHistory(newContent);
      _lastEditedAt = DateTime.now();
    });
    _autoSave();
  }

  Future<void> _autoSave() async {
    if (_saving) return;
    _saving = true;
    try {
      final updated = await context.read<LessonPlanProvider>().updatePlan(
        widget.planId, {'content': _plan!.content.toJson()},
      );
      if (updated != null && mounted) {
        setState(() {
          _lastSavedAt = updated.updatedAt;
          _plan = updated;
        });
      }
    } finally {
      _saving = false;
    }
  }

  Future<void> _regenerateSection(int index) async {
    final section = _plan!.content.sections[index];
    _showLoading('Regenerating ${section.name}...');
    final updated = await context.read<LessonPlanProvider>().regenerateSection(
      widget.planId, section.name,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    if (updated != null) {
      setState(() { _plan = updated; });
      _showSnackBar('Section regenerated');
    } else {
      _showSnackBar('Failed to regenerate section', isError: true);
    }
  }

  void _showLoading(String message) {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(children: [
          const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 16),
          Text(message),
        ]),
      ),
    );
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _printPlan() async {
    debugPrint('[PRINT] Starting print layout...');
    try {
      await Printing.layoutPdf(
        onLayout: (_) => _buildPdf(PdfPageFormat.a4),
      );
      debugPrint('[PRINT] Print completed');
    } catch (e, stack) {
      debugPrint('[PRINT] ERROR: $e');
      debugPrint('[PRINT] STACK: $stack');
      _showSnackBar('Print failed: $e', isError: true);
    }
  }

  Future<void> _exportPdf() async {
    _showLoading('Generating PDF...');
    try {
      debugPrint('[PDF] Starting PDF generation...');
      final pdfBytes = await _buildPdf(PdfPageFormat.a4);
      debugPrint('[PDF] PDF generated (${pdfBytes.length} bytes)');

      if (!mounted) return;
      Navigator.of(context).pop();
      debugPrint('[PDF] Sharing PDF via XFile.fromData...');
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(pdfBytes, name: '${_plan!.title.replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), '')}.pdf')],
          text: '${_plan!.title} - Lesson Plan',
        ),
      );
      debugPrint('[PDF] Share completed successfully');
    } catch (e, stack) {
      debugPrint('[PDF] ERROR: $e');
      debugPrint('[PDF] STACK TRACE:');
      debugPrint(stack.toString());
      if (mounted) {
        Navigator.of(context).pop();
        _showSnackBar('Failed to generate PDF: $e', isError: true);
      }
    }
  }

  Future<Uint8List> _buildPdf(PdfPageFormat format) async {
    final plan = _plan!;
    final c = plan.content;
    final intl = DateFormat('MMMM d, yyyy');

    late final pw.Font baseFont;
    late final pw.Font boldFont;
    try {
      debugPrint('[PDF] Loading Roboto font...');
      baseFont = await PdfGoogleFonts.robotoRegular();
      boldFont = await PdfGoogleFonts.robotoBold();
      debugPrint('[PDF] Roboto font loaded successfully');
    } catch (e, stack) {
      debugPrint('[PDF] Font loading failed: $e');
      debugPrint('[PDF] Font loading stack: $stack');
      debugPrint('[PDF] Falling back to Helvetica');
      baseFont = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
    }

    final h1 = pw.TextStyle(font: boldFont, fontSize: 18);
    final h2 = pw.TextStyle(font: boldFont, fontSize: 13);
    final subtitle = pw.TextStyle(font: baseFont, fontSize: 9, color: PdfColors.grey700);
    final body = pw.TextStyle(font: baseFont, fontSize: 10);
    final small = pw.TextStyle(font: baseFont, fontSize: 8, color: PdfColors.grey600);

    String sep(String text) => _sanitizePdfText(text);
    String bullet = '-';

    pw.Widget bulletList(List<String> items) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: items.map((item) => pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('$bullet ', style: body),
            pw.Expanded(child: pw.Text(sep(item), style: body)),
          ],
        )).toList(),
      );
    }

    debugPrint('[PDF] Creating document...');
    final pdf = pw.Document();
    debugPrint('[PDF] Adding page...');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(48),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(sep(plan.title), style: h1),
            pw.SizedBox(height: 4),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('${sep(c.subject)} | ${sep(c.gradeLevel)} | ${c.durationMinutes} min', style: subtitle),
              pw.Text(intl.format(DateTime.now()), style: subtitle),
            ]),
            pw.Divider(),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (ctx) => pw.Column(children: [
          pw.Divider(),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('Smart Lesson Planner', style: small),
            pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}', style: small),
          ]),
        ]),
        build: (ctx) => [
          pw.Text('Learning Objectives', style: h2),
          pw.SizedBox(height: 6),
          bulletList(c.learningObjectives),
          pw.SizedBox(height: 16),
          pw.Text('Materials Needed', style: h2),
          pw.SizedBox(height: 6),
          bulletList(c.materials),
          pw.SizedBox(height: 16),
          pw.Text('Lesson Structure', style: h2),
          pw.SizedBox(height: 8),
          ...c.sections.map((s) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text(sep(s.name), style: pw.TextStyle(font: boldFont, fontSize: 11)),
                pw.Text('${s.durationMinutes} min', style: subtitle),
              ]),
              pw.SizedBox(height: 4),
              pw.Text(sep(s.description), style: body),
              pw.SizedBox(height: 12),
            ],
          )),
        ],
      ),
    );
    debugPrint('[PDF] Saving PDF...');
    final bytes = await pdf.save();
    debugPrint('[PDF] PDF saved (${bytes.length} bytes)');
    return bytes;
  }

  Future<void> _share() async {
    final c = _plan!.content;
    final buf = StringBuffer();
    buf.writeln('Lesson Plan: ${_plan!.title}');
    buf.writeln('${c.subject} | ${c.gradeLevel} | ${c.durationMinutes} min');
    buf.writeln('');
    buf.writeln('Learning Objectives:');
    for (final o in c.learningObjectives) {
      buf.writeln('  \u2022 $o');
    }
    buf.writeln('');
    buf.writeln('Materials:');
    for (final m in c.materials) {
      buf.writeln('  \u2022 $m');
    }
    buf.writeln('');
    buf.writeln('Lesson Structure:');
    for (final s in c.sections) {
      buf.writeln('  ${s.name} (${s.durationMinutes} min)');
      buf.writeln('    ${s.description}');
      buf.writeln('');
    }
    buf.writeln('---');
    buf.writeln('Generated by Smart Lesson Planner');

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Share Lesson Plan', style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _shareOption(ctx, Icons.picture_as_pdf, 'PDF', () async {
                    Navigator.pop(ctx);
                    _exportPdf();
                  }),
                  _shareOption(ctx, Icons.text_snippet, 'Text', () {
                    Navigator.pop(ctx);
                    SharePlus.instance.share(ShareParams(text: buf.toString()));
                  }),
                  _shareOption(ctx, Icons.share, 'Share App', () {
                    Navigator.pop(ctx);
                    SharePlus.instance.share(ShareParams(text: buf.toString()));
                  }),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: buf.toString()));
                    Navigator.pop(ctx);
                    _showSnackBar('Copied to clipboard');
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy to Clipboard'),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _exportPdf();
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Share as PDF'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shareOption(BuildContext ctx, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(String? ts) {
    if (ts == null) return '';
    try {
      final dt = DateTime.parse(ts);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return DateFormat('MMM d, h:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_plan?.title ?? 'Lesson Plan'),
        actions: [
          if (_plan != null) ...[
            if (_editMode) ...[
              IconButton(
                icon: const Icon(Icons.undo),
                onPressed: _canUndo ? _undo : null,
                tooltip: 'Undo',
              ),
              IconButton(
                icon: const Icon(Icons.redo),
                onPressed: _canRedo ? _redo : null,
                tooltip: 'Redo',
              ),
            ],
            IconButton(
              icon: Icon(_editMode ? Icons.check : Icons.edit),
              onPressed: () => setState(() => _editMode = !_editMode),
              tooltip: _editMode ? 'Done Editing' : 'Edit',
            ),
            PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'print', child: ListTile(leading: Icon(Icons.print), title: Text('Print'), dense: true)),
                const PopupMenuItem(value: 'export', child: ListTile(leading: Icon(Icons.file_download), title: Text('Export PDF'), dense: true)),
                const PopupMenuItem(value: 'share', child: ListTile(leading: Icon(Icons.share), title: Text('Share'), dense: true)),
              ],
              onSelected: (v) async {
                if (v == 'print') await _printPlan();
                if (v == 'export') await _exportPdf();
                if (v == 'share') await _share();
              },
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text(_error!, style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 12),
                      FilledButton.icon(onPressed: _fetchPlan, icon: const Icon(Icons.refresh), label: const Text('Retry')),
                    ],
                  ),
                )
              : _plan == null
                  ? const Center(child: Text('Plan not found'))
                  : _buildContent(theme),
    );
  }

  Widget _buildContent(ThemeData theme) {
    final plan = _plan!;
    final content = plan.content;
    return RefreshIndicator(
      onRefresh: _fetchPlan,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _buildHeader(theme, plan, content),
          if (_editMode && _lastEditedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.edit_outlined, size: 14, color: AppColors.textTertiaryLight),
                  const SizedBox(width: 4),
                  Text('Last edited ${_formatTimestamp(_lastEditedAt!.toIso8601String())}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textTertiaryLight)),
                  if (_saving) ...[
                    const SizedBox(width: 8),
                    const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5)),
                  ],
                  if (!_saving && _lastSavedAt != null) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.cloud_done, size: 14, color: AppColors.success),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 20),
          _buildSection(
            theme, 'Learning Objectives', Icons.flag_outlined, AppColors.primary,
            content.learningObjectives.asMap().entries.map((e) =>
              _editMode
                  ? _buildEditableObjective(theme, e.key, e.value)
                  : ListTile(
                      dense: true,
                      leading: const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 20),
                      title: Text(e.value, style: theme.textTheme.bodyMedium),
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
            ).toList(),
            editable: _editMode,
            onAdd: () {
              final newList = List<String>.from(content.learningObjectives)..add('');
              _updateContent(LessonContent(
                title: content.title, subject: content.subject,
                gradeLevel: content.gradeLevel, durationMinutes: content.durationMinutes,
                learningObjectives: newList, materials: content.materials,
                sections: content.sections,
              ));
            },
          ),
          const SizedBox(height: 12),
          _buildSection(
            theme, 'Materials Needed', Icons.inventory_2_outlined, AppColors.secondary,
            [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 8, runSpacing: 6,
                  children: content.materials.asMap().entries.map((e) =>
                    _editMode
                        ? _buildEditableMaterial(theme, e.key, e.value)
                        : Chip(
                            label: Text(e.value, style: const TextStyle(fontSize: 13)),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                  ).toList(),
                ),
              ),
            ],
            editable: _editMode,
            onAdd: () {
              final newList = List<String>.from(content.materials)..add('');
              _updateContent(LessonContent(
                title: content.title, subject: content.subject,
                gradeLevel: content.gradeLevel, durationMinutes: content.durationMinutes,
                learningObjectives: content.learningObjectives, materials: newList,
                sections: content.sections,
              ));
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Lesson Structure', style: theme.textTheme.titleMedium),
              const Spacer(),
              if (_editMode)
                TextButton.icon(
                  onPressed: () {
                    final newSections = List<LessonSection>.from(content.sections)..add(
                      LessonSection(name: 'New Section', durationMinutes: 5, description: ''),
                    );
                    _updateContent(LessonContent(
                      title: content.title, subject: content.subject,
                      gradeLevel: content.gradeLevel, durationMinutes: content.durationMinutes,
                      learningObjectives: content.learningObjectives, materials: content.materials,
                      sections: newSections,
                    ));
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Section'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...content.sections.asMap().entries.map((entry) =>
            _buildLessonSection(theme, entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildEditableObjective(ThemeData theme, int index, String value) {
    final controller = TextEditingController(text: value);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 20, height: 20,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withValues(alpha: 0.1)),
            child: const Icon(Icons.check_circle_outline, size: 14, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              style: theme.textTheme.bodyMedium,
              decoration: const InputDecoration(
                isDense: true, border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onChanged: (v) {
                final list = List<String>.from(_plan!.content.learningObjectives);
                list[index] = v;
                _updateContent(LessonContent(
                  title: _plan!.content.title, subject: _plan!.content.subject,
                  gradeLevel: _plan!.content.gradeLevel, durationMinutes: _plan!.content.durationMinutes,
                  learningObjectives: list, materials: _plan!.content.materials,
                  sections: _plan!.content.sections,
                ));
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () {
              final list = List<String>.from(_plan!.content.learningObjectives)..removeAt(index);
              _updateContent(LessonContent(
                title: _plan!.content.title, subject: _plan!.content.subject,
                gradeLevel: _plan!.content.gradeLevel, durationMinutes: _plan!.content.durationMinutes,
                learningObjectives: list, materials: _plan!.content.materials,
                sections: _plan!.content.sections,
              ));
            },
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildEditableMaterial(ThemeData theme, int index, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 120,
            child: TextField(
              controller: TextEditingController(text: value),
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                isDense: true, border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              ),
              onChanged: (v) {
                final list = List<String>.from(_plan!.content.materials);
                list[index] = v;
                _updateContent(LessonContent(
                  title: _plan!.content.title, subject: _plan!.content.subject,
                  gradeLevel: _plan!.content.gradeLevel, durationMinutes: _plan!.content.durationMinutes,
                  learningObjectives: _plan!.content.learningObjectives, materials: list,
                  sections: _plan!.content.sections,
                ));
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () {
              final list = List<String>.from(_plan!.content.materials)..removeAt(index);
              _updateContent(LessonContent(
                title: _plan!.content.title, subject: _plan!.content.subject,
                gradeLevel: _plan!.content.gradeLevel, durationMinutes: _plan!.content.durationMinutes,
                learningObjectives: _plan!.content.learningObjectives, materials: list,
                sections: _plan!.content.sections,
              ));
            },
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, LessonPlan plan, LessonContent content) {
    final statusColors = plan.status == 'final' ? AppColors.success : AppColors.accent;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColors.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(plan.status == 'final' ? Icons.check_circle : Icons.edit_note, size: 14, color: statusColors),
                    const SizedBox(width: 4),
                    Text(plan.status.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColors)),
                  ],
                ),
              ),
              if (plan.aiGenerated) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 12, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text('AI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          _editMode
              ? TextField(
                  controller: TextEditingController(text: content.title),
                  style: theme.textTheme.headlineSmall,
                  decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                  onChanged: (v) {
                    _updateContent(LessonContent(
                      title: v, subject: content.subject,
                      gradeLevel: content.gradeLevel, durationMinutes: content.durationMinutes,
                      learningObjectives: content.learningObjectives, materials: content.materials,
                      sections: content.sections,
                    ));
                  },
                )
              : Text(content.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              _infoChip(theme, Icons.book_outlined, content.subject),
              const SizedBox(width: 12),
              _infoChip(theme, Icons.grade_outlined, content.gradeLevel),
              const SizedBox(width: 12),
              _infoChip(theme, Icons.timer_outlined, '${content.durationMinutes} min'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(ThemeData theme, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondaryLight),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
      ],
    );
  }

  Widget _buildSection(
    ThemeData theme, String title, IconData icon, Color color, List<Widget> children, {
    bool editable = false, VoidCallback? onAdd,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
            if (editable && onAdd != null)
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
          ]),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLessonSection(ThemeData theme, int index, LessonSection section) {
    final sectionIcons = [
      Icons.login_outlined, Icons.explore_outlined, Icons.groups_outlined,
      Icons.psychology_outlined, Icons.assignment_outlined, Icons.home_outlined, Icons.star_outline,
    ];

    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: _editMode
          ? _buildEditableSection(theme, index, section, sectionIcons)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(sectionIcons[index % sectionIcons.length], color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(section.name, style: theme.textTheme.titleMedium)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text('${section.durationMinutes} min', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ),
                ]),
                const SizedBox(height: 12),
                Text(section.description, style: theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
              ],
            ),
    );
  }

  Widget _buildEditableSection(ThemeData theme, int index, LessonSection section, List<IconData> icons) {
    final nameCtrl = TextEditingController(text: section.name);
    final descCtrl = TextEditingController(text: section.description);
    final durCtrl = TextEditingController(text: section.durationMinutes.toString());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icons[index % icons.length], color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  TextField(
                    controller: nameCtrl,
                    style: theme.textTheme.titleMedium,
                    decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                    onChanged: (v) {
                      final sections = List<LessonSection>.from(_plan!.content.sections);
                      sections[index] = LessonSection(name: v, durationMinutes: section.durationMinutes, description: section.description);
                      _updateContent(LessonContent(
                        title: _plan!.content.title, subject: _plan!.content.subject,
                        gradeLevel: _plan!.content.gradeLevel, durationMinutes: _plan!.content.durationMinutes,
                        learningObjectives: _plan!.content.learningObjectives, materials: _plan!.content.materials,
                        sections: sections,
                      ));
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: durCtrl,
                    style: const TextStyle(fontSize: 12),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true, border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      labelText: 'Minutes', suffixText: 'min',
                    ),
                    onChanged: (v) {
                      final dur = int.tryParse(v) ?? 5;
                      final sections = List<LessonSection>.from(_plan!.content.sections);
                      sections[index] = LessonSection(name: section.name, durationMinutes: dur, description: section.description);
                      _updateContent(LessonContent(
                        title: _plan!.content.title, subject: _plan!.content.subject,
                        gradeLevel: _plan!.content.gradeLevel, durationMinutes: _plan!.content.durationMinutes,
                        learningObjectives: _plan!.content.learningObjectives, materials: _plan!.content.materials,
                        sections: sections,
                      ));
                    },
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.auto_awesome, size: 20),
                  tooltip: 'Regenerate with AI',
                  onPressed: () => _regenerateSection(index),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    final sections = List<LessonSection>.from(_plan!.content.sections)..removeAt(index);
                    _updateContent(LessonContent(
                      title: _plan!.content.title, subject: _plan!.content.subject,
                      gradeLevel: _plan!.content.gradeLevel, durationMinutes: _plan!.content.durationMinutes,
                      learningObjectives: _plan!.content.learningObjectives, materials: _plan!.content.materials,
                      sections: sections,
                    ));
                  },
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: descCtrl,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          maxLines: 4,
          decoration: const InputDecoration(
            isDense: true, border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(10),
          ),
          onChanged: (v) {
            final sections = List<LessonSection>.from(_plan!.content.sections);
            sections[index] = LessonSection(name: section.name, durationMinutes: section.durationMinutes, description: v);
            _updateContent(LessonContent(
              title: _plan!.content.title, subject: _plan!.content.subject,
              gradeLevel: _plan!.content.gradeLevel, durationMinutes: _plan!.content.durationMinutes,
              learningObjectives: _plan!.content.learningObjectives, materials: _plan!.content.materials,
              sections: sections,
            ));
          },
        ),
      ],
    );
  }
}
