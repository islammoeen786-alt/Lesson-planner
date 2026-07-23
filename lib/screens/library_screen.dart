import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lesson_plan_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_shimmer.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LessonPlanProvider>().loadPlans(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Search plans...', border: InputBorder.none, filled: false),
                onChanged: (v) => context.read<LessonPlanProvider>().setSearch(v),
              )
            : const Text('My Lesson Plans'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  context.read<LessonPlanProvider>().setSearch('');
                }
              });
            },
          ),
        ],
      ),
      body: Consumer<LessonPlanProvider>(
        builder: (_, lp, __) {
          if (lp.isLoading && lp.plans.isEmpty) {
            return ListView(padding: const EdgeInsets.all(16), children: List.generate(6, (_) => const ShimmerCard()));
          }

          if (lp.plans.isEmpty) {
            return EmptyState(
              icon: Icons.library_books_outlined,
              title: _searchController.text.isNotEmpty ? 'No results found' : 'No lesson plans yet',
              subtitle: _searchController.text.isNotEmpty ? 'Try a different search term' : 'Generate your first AI-powered lesson plan',
              actionLabel: _searchController.text.isNotEmpty ? null : 'Generate Now',
              onAction: () => Navigator.pushNamed(context, '/generate'),
            );
          }

          final hasMore = lp.currentPage < lp.totalPages;

          return RefreshIndicator(
            onRefresh: () => lp.loadPlans(refresh: true),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: lp.plans.length + (hasMore ? 1 : 0),
              itemBuilder: (_, i) {
                if (i >= lp.plans.length) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => lp.loadPlans(page: lp.currentPage + 1));
                  return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
                }

                final plan = lp.plans[i];
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
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.menu_book, color: theme.colorScheme.primary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(plan.title, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(
                              '${plan.subject ?? 'General'} \u00b7 ${plan.gradeLevel ?? ''} \u00b7 ${plan.scheduledDate ?? ''}',
                              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight),
                            ),
                          ],
                        ),
                      ),
                      if (plan.aiGenerated)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: statusColors.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 14, color: statusColors),
                            const SizedBox(width: 4),
                            Text(plan.status == 'final' ? 'Final' : 'Draft', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: statusColors)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, color: AppColors.textTertiaryLight, size: 20),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
