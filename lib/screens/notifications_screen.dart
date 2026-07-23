import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Notification Settings', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text('Choose what updates you receive', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _settingCard(theme, 'New Lesson Plans', 'When AI generation completes', Icons.auto_awesome, true),
          _settingCard(theme, 'Weekly Summary', 'Weekly generation usage stats', Icons.summarize_outlined, false),
          _settingCard(theme, 'Tips & Tricks', 'Teaching tips and feature updates', Icons.lightbulb_outline, true),
          _settingCard(theme, 'Subscription', 'Billing and plan changes', Icons.card_membership_outlined, true),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const EmptyState(
            icon: Icons.notifications_none,
            title: 'No notifications yet',
            subtitle: 'We\'ll notify you here when something important happens',
          ),
        ],
      ),
    );
  }

  Widget _settingCard(ThemeData theme, String title, String subtitle, IconData icon, bool enabled) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight)),
              ],
            ),
          ),
          Switch.adaptive(value: enabled, onChanged: (_) {}),
        ],
      ),
    );
  }
}
