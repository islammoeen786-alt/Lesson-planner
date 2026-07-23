import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '1.0.0';
  String _buildNumber = '1';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = info.version;
          _buildNumber = info.buildNumber;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child:
                      const Icon(Icons.school, color: Colors.white, size: 48),
                ),
                const SizedBox(height: 16),
                Text('Smart Lesson Planner',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Version $_version ($_buildNumber)',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textSecondaryLight)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          AppCard(
            child: Column(
              children: [
                _aboutRow(
                    theme, Icons.person_outline, 'Developer', 'MoeenIslam'),
                const Divider(),
                _aboutRow(theme, Icons.copyright_outlined, 'Copyright',
                    '2026 Smart Lesson Planner'),
                const Divider(),
                _aboutRow(theme, Icons.code_outlined, 'License', 'MIT License'),
                const Divider(),
                _aboutRow(theme, Icons.language_outlined, 'Website',
                    'smartlessonplanner.com'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Open Source Licenses',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                Text(
                    'This application uses the following open source libraries:',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondaryLight)),
                const SizedBox(height: 12),
                _licenseItem('Flutter', 'BSD-3-Clause', 'Google'),
                _licenseItem('Firebase', 'Apache 2.0', 'Google'),
                _licenseItem('Dio', 'MIT', 'flutterchina'),
                _licenseItem('Provider', 'MIT', 'rrousselGit'),
                _licenseItem('Shared Preferences', 'BSD-3-Clause', 'Flutter'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text('Made with \u2764 for teachers everywhere',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textTertiaryLight)),
          ),
        ],
      ),
    );
  }

  Widget _aboutRow(ThemeData theme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondaryLight),
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

  Widget _licenseItem(String name, String license, String author) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child:
                Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Text(license,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
          const SizedBox(width: 8),
          Text('by $author',
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textTertiaryLight)),
        ],
      ),
    );
  }
}
