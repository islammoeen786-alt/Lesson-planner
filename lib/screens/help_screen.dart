import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    {'q': 'How do I generate a lesson plan?', 'a': 'Tap "Generate New Lesson Plan" on the Home screen or navigate to the Generate tab. Fill in the subject, topic, and other details, then tap "Generate Now".'},
    {'q': 'How many plans can I generate?', 'a': 'Your account has a monthly quota of AI-generated plans. Check your quota on the Home screen dashboard.'},
    {'q': 'Can I edit a generated plan?', 'a': 'Yes. Open any lesson plan from your Library and tap the Edit button to make changes.'},
    {'q': 'How do I export or print a plan?', 'a': 'Open a lesson plan and tap the menu icon (three dots) in the app bar to find Export PDF and Print options.'},
    {'q': 'What subjects are supported?', 'a': 'Mathematics, English, Science, History, Geography, Art, Music, Physical Education, Computer Science, and more.'},
    {'q': 'Is my data safe?', 'a': 'Yes. Your lesson plans and profile data are stored securely and only accessible to you.'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Help & FAQ')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Frequently Asked Questions', style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text('${_faqs.length} articles', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight)),
              ],
            ),
          ),
          ExpansionPanelList.radio(
            elevation: 0,
            dividerColor: AppColors.dividerLight,
            children: _faqs.map((faq) => ExpansionPanelRadio(
              value: faq['q'] ?? '',
              headerBuilder: (_, expanded) => ListTile(
                title: Text(faq['q'] ?? '', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                contentPadding: const EdgeInsets.only(left: 4),
              ),
              body: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Text(faq['a'] ?? '', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight, height: 1.5)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 24),
          AppCard(
            child: Column(
              children: [
                const Icon(Icons.support_agent, size: 40, color: AppColors.primary),
                const SizedBox(height: 12),
                Text('Still need help?', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('Contact our support team', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight)),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.mail_outline, size: 18),
                  label: const Text('Contact Support'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
