import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Templates')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Starter Templates', style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text('Quick-start with pre-built structures', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight)),
              ],
            ),
          ),
          _templateCard(context, theme, Icons.calculate, 'Mathematics', 'Basic lesson structure for math topics', const Color(0xFF4F46E5)),
          _templateCard(context, theme, Icons.science, 'Science', 'Hands-on lab-oriented lesson format', const Color(0xFF0EA5E9)),
          _templateCard(context, theme, Icons.menu_book, 'English / Language Arts', 'Reading comprehension and writing', const Color(0xFF10B981)),
          _templateCard(context, theme, Icons.public, 'Geography', 'Map-based and cultural exploration', const Color(0xFFF59E0B)),
          _templateCard(context, theme, Icons.history, 'History', 'Chronological and thematic lessons', const Color(0xFFEF4444)),
          _templateCard(context, theme, Icons.palette, 'Art', 'Creative expression and techniques', const Color(0xFFEC4899)),
        ],
      ),
    );
  }

  Widget _templateCard(BuildContext context, ThemeData theme, IconData icon, String title, String subtitle, Color color) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Row(children: [const Icon(Icons.info_outline, color: Colors.white, size: 20), const SizedBox(width: 12), Text('Template "$title" selected')])),
        );
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.add, color: AppColors.primary, size: 20),
          ),
        ],
      ),
    );
  }
}
