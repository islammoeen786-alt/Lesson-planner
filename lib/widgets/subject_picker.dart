import 'package:flutter/material.dart';
import '../config/subjects.dart';
import '../theme/app_colors.dart';

class SubjectPicker extends StatefulWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const SubjectPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  static Future<void> show(BuildContext context, {
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SubjectPicker(selected: selected, onSelected: onSelected),
    );
  }

  @override
  State<SubjectPicker> createState() => _SubjectPickerState();
}

class _SubjectPickerState extends State<SubjectPicker> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = SubjectCatalog.searchCategories(_query);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(0, 12, 0, 12 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Select Subject', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search subjects...',
                prefixIcon: const Icon(Icons.search, size: 22),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              children: [
                if (_query.isEmpty)
                  ...filtered.map((cat) => _buildCategory(theme, cat))
                else if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(children: [
                        const Icon(Icons.search_off, size: 48, color: AppColors.textTertiaryLight),
                        const SizedBox(height: 12),
                        Text('No subjects found', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight)),
                        Text('Try a different search term', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textTertiaryLight)),
                      ]),
                    ),
                  )
                else
                  ...filtered.map((cat) => _buildCategory(theme, cat)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategory(ThemeData theme, SubjectCategory cat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
          child: Row(children: [
            Icon(cat.icon, size: 16, color: AppColors.textSecondaryLight),
            const SizedBox(width: 8),
            Text(cat.name, style: theme.textTheme.labelLarge?.copyWith(color: AppColors.textSecondaryLight)),
          ]),
        ),
        ...cat.subjects.map((s) => _buildSubjectTile(theme, s)),
      ],
    );
  }

  Widget _buildSubjectTile(ThemeData theme, SubjectItem subject) {
    final isSelected = subject.name == widget.selected;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      child: Material(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            widget.onSelected(subject.name);
            Navigator.of(context).pop();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.borderLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(subject.icon, size: 20, color: isSelected ? AppColors.primary : AppColors.textSecondaryLight),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    subject.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : null,
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.check, size: 16, color: AppColors.primary),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
