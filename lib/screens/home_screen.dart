import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/lesson_plan_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';
import '../widgets/pro_upgrade_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_shimmer.dart';
import '../widgets/error_ui.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    debugPrint('[HomeScreen] Refreshing data');
    final auth = context.read<AuthProvider>();
    final lp = context.read<LessonPlanProvider>();
    await Future.wait([
      auth.refreshProfile().catchError((_) {}),
      lp.loadPlans(refresh: true),
      lp.loadQuota(),
    ]);
    debugPrint('[HomeScreen] Refresh complete');
    if (mounted && lp.appError != null && lp.appError!.isRetryable) {
      ErrorSnackbar.show(context, lp.appError!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final lp = context.watch<LessonPlanProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.person_outline), onPressed: () => Navigator.pushNamed(context, '/profile')),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _buildWelcomeCard(theme, user?.name ?? 'Teacher'),
            const SizedBox(height: 20),
            _buildStatsRow(theme, lp),
            const SizedBox(height: 20),
            _buildQuotaCard(theme, lp),
            const SizedBox(height: 20),
            _buildRecentPlans(theme, lp),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(ThemeData theme, String name) {
    final isPro = context.watch<AuthProvider>().user?.isPro ?? false;
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Welcome back,', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight)),
                    if (isPro) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('⭐ PRO',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF92400E))),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(isPro ? 'You\'re on the Pro plan - enjoy unlimited access!'
                    : 'Ready to create something amazing?',
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: isPro
                  ? const LinearGradient(colors: [Color(0xFF25D366), Color(0xFF1DA851)])
                  : const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme, LessonPlanProvider lp) {
    final total = lp.plans.length;
    final aiCount = lp.plans.where((p) => p.aiGenerated).length;
    final draftCount = lp.plans.where((p) => p.status == 'draft').length;

    return Row(
      children: [
        Expanded(child: _statCard(theme, Icons.menu_book, '$total', 'Total Plans', AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: _statCard(theme, Icons.auto_awesome, '$aiCount', 'AI Generated', AppColors.secondary)),
        const SizedBox(width: 12),
        Expanded(child: _statCard(theme, Icons.edit_note, '$draftCount', 'Drafts', AppColors.accent)),
      ],
    );
  }

  Widget _statCard(ThemeData theme, IconData icon, String value, String label, Color color) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildQuotaCard(ThemeData theme, LessonPlanProvider lp) {
    final auth = context.watch<AuthProvider>();
    final isPro = auth.user?.isPro ?? false;

    if (isPro) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: Color(0xFF25D366), size: 18),
              ),
              const SizedBox(width: 12),
              Text('AI Generation', style: theme.textTheme.titleMedium),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('⭐ ', style: TextStyle(fontSize: 12)),
                    Text('PRO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF92400E))),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 14),
            Text('Unlimited generations \u2022 All premium features enabled',
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.success)),
          ],
        ),
      );
    }

    final used = lp.quotaUsed;
    final limit = lp.quotaLimit;
    final remaining = lp.quotaRemaining;
    final progress = limit > 0 ? used / limit : 0.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Text('AI Generation Quota', style: theme.textTheme.titleMedium),
            const Spacer(),
            Text('$remaining left', style: theme.textTheme.bodySmall?.copyWith(color: remaining < 3 ? AppColors.error : AppColors.success)),
          ]),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.borderLight.withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation(remaining < 3 ? AppColors.error : AppColors.primary),
            ),
          ),
          const SizedBox(height: 6),
          Text('$used of $limit used this month', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textTertiaryLight)),
          if (remaining <= 0) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton.icon(
                onPressed: () => ProUpgradeDialog.show(context),
                icon: const Icon(Icons.lock_open, size: 18),
                label: const Text('Get Pro Version'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentPlans(ThemeData theme, LessonPlanProvider lp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Plans', style: theme.textTheme.titleMedium),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/library'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (lp.appError != null && lp.plans.isEmpty)
          InlineError(
            message: lp.appError!.message,
            isRetryable: lp.appError!.isRetryable,
            onRetry: () => context.read<LessonPlanProvider>().loadPlans(refresh: true),
          )
        else if (lp.isLoading && lp.plans.isEmpty)
          ...List.generate(3, (_) => const ShimmerCard())
        else if (lp.plans.isEmpty)
          EmptyState(
            icon: Icons.menu_book,
            title: 'No lesson plans yet',
            subtitle: 'Generate your first AI-powered lesson plan',
            actionLabel: 'Generate Now',
            onAction: () => Navigator.pushNamed(context, '/generate'),
          )
        else
          ...lp.plans.take(5).map((plan) => _planCard(theme, plan)),
      ],
    );
  }

  Widget _planCard(ThemeData theme, dynamic plan) {
    final statusColors = plan.status == 'final' ? AppColors.success : AppColors.accent;
    final statusIcon = plan.status == 'final' ? Icons.check_circle : Icons.edit_note;
    return AppCard(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      onTap: () => Navigator.pushNamed(context, '/plan-detail', arguments: plan.id),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.menu_book, color: Theme.of(context).colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.title, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('${plan.subject ?? 'General'} \u00b7 ${plan.gradeLevel ?? ''}',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: statusColors.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 14, color: statusColors),
                const SizedBox(width: 4),
                Text(plan.status == 'final' ? 'Final' : 'Draft',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: statusColors)),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: AppColors.textTertiaryLight, size: 20),
        ],
      ),
    );
  }
}
