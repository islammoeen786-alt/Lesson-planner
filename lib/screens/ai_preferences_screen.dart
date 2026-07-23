import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';
import '../services/local_storage_service.dart';

class AiPreferencesScreen extends StatefulWidget {
  const AiPreferencesScreen({super.key});

  @override
  State<AiPreferencesScreen> createState() => _AiPreferencesScreenState();
}

class _AiPreferencesScreenState extends State<AiPreferencesScreen> {
  final _storageKey = 'ai_preferences';

  String _model = 'gemini-2.0-flash';
  int _maxLength = 1024;
  double _creativity = 0.7;
  String _language = 'English';

  final _models = ['gemini-2.0-flash', 'gemini-2.5-flash', 'gemini-2.0-pro'];
  final _lengths = [512, 1024, 2048, 4096];
  final _languages = ['English', 'Arabic', 'French', 'Spanish'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await LocalStorageService.getJson(_storageKey);
    if (data != null && mounted) {
      setState(() {
        _model = data['model'] as String? ?? _model;
        _maxLength = data['maxLength'] as int? ?? _maxLength;
        _creativity = (data['creativity'] as num?)?.toDouble() ?? _creativity;
        _language = data['language'] as String? ?? _language;
      });
    }
  }

  Future<void> _save() async {
    await LocalStorageService.setJson(_storageKey, {
      'model': _model,
      'maxLength': _maxLength,
      'creativity': _creativity,
      'language': _language,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text('AI preferences saved'),
          ]),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Preferences'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customize AI Behavior', style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text('These settings are stored locally', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight)),
              ],
            ),
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Model', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('Select the AI model for generation', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight)),
                const SizedBox(height: 12),
                DropdownButtonFormField(
                  initialValue: _model,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.memory_outlined)),
                  items: _models.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) => setState(() => _model = v!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Response Length', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('Maximum tokens: $_maxLength', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight)),
                const SizedBox(height: 12),
                SegmentedButton<int>(
                  segments: _lengths.map((l) => ButtonSegment(value: l, label: Text('$l'))).toList(),
                  selected: {_maxLength},
                  onSelectionChanged: (v) => setState(() => _maxLength = v.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Creativity', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('Higher values produce more varied results', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Precise', style: TextStyle(fontSize: 12)),
                    Expanded(
                      child: Slider(
                        value: _creativity,
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                        label: _creativity.toStringAsFixed(1),
                        onChanged: (v) => setState(() => _creativity = v),
                      ),
                    ),
                    const Text('Creative', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Center(child: Text(_creativity.toStringAsFixed(1), style: theme.textTheme.titleLarge)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Language', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('Preferred output language', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight)),
                const SizedBox(height: 12),
                DropdownButtonFormField(
                  initialValue: _language,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.language_outlined)),
                  items: _languages.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                  onChanged: (v) => setState(() => _language = v!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
