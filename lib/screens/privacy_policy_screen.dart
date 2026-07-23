import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = [
    {'title': 'Information We Collect', 'body': 'We collect information you provide when creating an account, such as your name, email address, and school information. We also collect data about your usage of the app, including lesson plans you generate and save.'},
    {'title': 'How We Use Your Information', 'body': 'Your information is used to provide and improve our lesson planning service, personalize your experience, and communicate with you about updates and features.'},
    {'title': 'Data Storage', 'body': 'Your data is stored securely using industry-standard encryption. We retain your data for as long as your account is active or as needed to provide you with our services.'},
    {'title': 'Third-Party Services', 'body': 'We use Firebase Authentication for secure login and Google AI (Gemini) for lesson plan generation. These services have their own privacy policies.'},
    {'title': 'Your Rights', 'body': 'You can access, update, or delete your account information at any time through the Profile settings. Contact us to request complete data deletion.'},
    {'title': 'Cookies', 'body': 'We use essential cookies and local storage to maintain your session and preferences. No tracking cookies are used.'},
    {'title': 'Changes to This Policy', 'body': 'We may update this privacy policy from time to time. We will notify you of any material changes via email or in-app notification.'},
    {'title': 'Contact Us', 'body': 'If you have questions about this privacy policy, please contact our support team through the Help & FAQ section.'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('Last updated: July 2026', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textTertiaryLight)),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text('This Privacy Policy explains how Smart Lesson Planner collects, uses, and protects your personal information when you use our application.', style: theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
          ),
          ..._sections.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s['title']!, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(s['body']!, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight, height: 1.6)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
