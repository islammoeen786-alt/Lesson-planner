import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/local_storage_service.dart';
import '../services/theme_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';
import '../widgets/app_dialog.dart';
import '../widgets/pro_upgrade_dialog.dart';
import '../widgets/error_ui.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('[ProfileScreen] Initial profile refresh');
      _refreshProfile();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AuthProvider>().refreshProfile().catchError((_) {});
    }
  }

  Future<void> _refreshProfile() async {
    final auth = context.read<AuthProvider>();
    try {
      await auth.refreshProfile();
    } catch (e) {
      if (mounted && auth.appError != null) {
        ErrorSnackbar.show(context, auth.appError!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const SizedBox(height: 8),
            _buildProfileHeader(theme, user),
            const SizedBox(height: 16),
            _buildProCard(context, theme),
            const SizedBox(height: 16),
            _buildMenuSection(theme, 'Account', [
              _menuItem(theme, Icons.person_outline, 'Edit Profile', () => _showEditProfile(context, auth)),
              _menuItem(theme, Icons.school_outlined, 'School Info', user?.schoolName ?? 'Not set', () => _showSchoolInfo(context, auth)),
              if (user?.subjectsTaught != null && user!.subjectsTaught!.isNotEmpty)
                _menuItem(theme, Icons.book_outlined, 'Subjects', user.subjectsTaught!.join(', '), null),
              _menuItem(theme, Icons.language_outlined, 'Language', 'English', null),
            ]),
            const SizedBox(height: 12),
            _buildMenuSection(theme, 'Preferences', [
              _menuItemWithTrailing(theme, Icons.dark_mode_outlined, 'Theme', () => _showThemePicker(context), _ThemeBadge(theme: theme)),
              _menuItem(theme, Icons.notifications_outlined, 'Notifications', () => Navigator.pushNamed(context, '/notifications')),
              _menuItem(theme, Icons.auto_awesome_outlined, 'AI Preferences', () => Navigator.pushNamed(context, '/ai-preferences')),
            ]),
            const SizedBox(height: 12),
            _buildMenuSection(theme, 'Support', [
              _menuItem(theme, Icons.help_outline, 'Help & FAQ', () => Navigator.pushNamed(context, '/help')),
              _menuItem(theme, Icons.shield_outlined, 'Privacy Policy', () => Navigator.pushNamed(context, '/privacy')),
              _menuItem(theme, Icons.info_outline, 'About', () => Navigator.pushNamed(context, '/about')),
            ]),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: () => _signOut(context, auth),
                icon: const Icon(Icons.logout, color: AppColors.error),
                label: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context, AuthProvider auth) async {
    final confirm = await AppDialog.confirm(
      context, title: 'Sign Out', message: 'Are you sure you want to sign out?',
      confirmLabel: 'Sign Out', confirmColor: AppColors.error,
    );
    if (confirm != true || !context.mounted) return;
    await LocalStorageService.clearAuthData();
    await auth.logout();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  void _showEditProfile(BuildContext context, AuthProvider auth) {
    final user = auth.user;
    final nameCtl = TextEditingController(text: user?.name ?? '');
    final schoolCtl = TextEditingController(text: user?.schoolName ?? '');
    final subjectsCtl = TextEditingController(text: user?.subjectsTaught?.join(', ') ?? '');
    final gradesCtl = TextEditingController(text: user?.gradeLevelsTaught?.join(', ') ?? '');
    final formKey = GlobalKey<FormState>();
    var saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Profile'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)), validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null),
                  const SizedBox(height: 12),
                  TextFormField(controller: schoolCtl, decoration: const InputDecoration(labelText: 'School Name', prefixIcon: Icon(Icons.school_outlined))),
                  const SizedBox(height: 12),
                  TextFormField(controller: subjectsCtl, decoration: const InputDecoration(labelText: 'Subjects (comma separated)', prefixIcon: Icon(Icons.book_outlined))),
                  const SizedBox(height: 12),
                  TextFormField(controller: gradesCtl, decoration: const InputDecoration(labelText: 'Grade Levels (comma separated)', prefixIcon: Icon(Icons.grade_outlined))),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving ? null : () async {
                if (!formKey.currentState!.validate()) return;
                setDialogState(() => saving = true);
                try {
                  await auth.updateProfile({
                    'name': nameCtl.text.trim(),
                    'schoolName': schoolCtl.text.trim(),
                    'subjectsTaught': subjectsCtl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                    'gradeLevelsTaught': gradesCtl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) ErrorSnackbar.showSuccess(context, 'Profile updated');
                } catch (_) {
                  setDialogState(() => saving = false);
                  if (context.mounted) ErrorSnackbar.showError(context, auth.appError?.message ?? 'Unable to save changes.');
                }
              },
              child: saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSchoolInfo(BuildContext context, AuthProvider auth) {
    final user = auth.user;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('School Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow(ctx, 'School', user?.schoolName ?? 'Not set'),
            const Divider(),
            _infoRow(ctx, 'Subjects', user?.subjectsTaught?.join(', ') ?? 'Not set'),
            const Divider(),
            _infoRow(ctx, 'Grade Levels', user?.gradeLevelsTaught?.join(', ') ?? 'Not set'),
            const Divider(),
            _infoRow(ctx, 'Language', 'English'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  void _showThemePicker(BuildContext context) {
    final themeService = context.read<ThemeService>();
    final current = themeService.themeMode;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _themeOption(ctx, themeService, Icons.light_mode, 'Light', ThemeMode.light, current),
            _themeOption(ctx, themeService, Icons.dark_mode, 'Dark', ThemeMode.dark, current),
            _themeOption(ctx, themeService, Icons.settings_brightness, 'System Default', ThemeMode.system, current),
          ],
        ),
      ),
    );
  }

  Widget _themeOption(BuildContext context, ThemeService service, IconData icon, String label, ThemeMode mode, ThemeMode current) {
    final selected = mode == current;
    return ListTile(
      leading: Icon(icon, color: selected ? AppColors.primary : null),
      title: Text(label),
      trailing: selected ? const Icon(Icons.check, color: AppColors.primary) : null,
      onTap: () {
        service.setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textTertiaryLight)),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, dynamic user) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 64, height: 64,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                (user?.name ?? 'T')[0].toUpperCase(),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.name ?? 'Teacher', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(user?.email ?? '', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight)),
                if (user?.schoolName != null && user!.schoolName!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.school, size: 14, color: AppColors.textTertiaryLight),
                    const SizedBox(width: 4),
                    Text(user.schoolName!, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textTertiaryLight)),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProCard(BuildContext context, ThemeData theme) {
    final isPro = context.watch<AuthProvider>().user?.isPro ?? false;

    if (isPro) {
      return AppCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome, color: Color(0xFF25D366), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Plan Karo Pro', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('⭐ PRO',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF92400E))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('Unlimited AI generations & all premium features',
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Smart Lesson Planner Pro', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Unlimited AI generations & more', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => ProUpgradeDialog.show(context),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            child: const Text('Get Pro'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(ThemeData theme, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: theme.textTheme.titleSmall?.copyWith(color: AppColors.textSecondaryLight)),
        ),
        ...items,
      ],
    );
  }

  Widget _menuItem(ThemeData theme, IconData icon, String title, [dynamic subtitleOrOnTap, VoidCallback? onTap]) {
    final subtitle = subtitleOrOnTap is String ? subtitleOrOnTap : null;
    final tap = subtitleOrOnTap is VoidCallback ? subtitleOrOnTap : onTap;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      margin: const EdgeInsets.only(bottom: 4),
      onTap: tap,
      child: ListTile(
        leading: Icon(icon, color: AppColors.textSecondaryLight),
        title: Text(title, style: theme.textTheme.bodyLarge),
        subtitle: subtitle != null ? Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textTertiaryLight)) : null,
        trailing: tap != null ? const Icon(Icons.chevron_right, color: AppColors.textTertiaryLight, size: 20) : null,
        contentPadding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _menuItemWithTrailing(ThemeData theme, IconData icon, String title, VoidCallback? onTap, Widget trailing) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      margin: const EdgeInsets.only(bottom: 4),
      onTap: onTap,
      child: ListTile(
        leading: Icon(icon, color: AppColors.textSecondaryLight),
        title: Text(title, style: theme.textTheme.bodyLarge),
        trailing: trailing,
        contentPadding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _ThemeBadge extends StatelessWidget {
  final ThemeData theme;
  const _ThemeBadge({required this.theme});

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final mode = themeService.themeMode;
    String label;
    switch (mode) {
      case ThemeMode.light: label = 'Light'; break;
      case ThemeMode.dark: label = 'Dark'; break;
      case ThemeMode.system: label = 'Auto'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primary)),
    );
  }
}
