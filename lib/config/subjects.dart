import 'package:flutter/material.dart';

class SubjectItem {
  final String name;
  final IconData icon;

  const SubjectItem({required this.name, required this.icon});
}

class SubjectCategory {
  final String name;
  final IconData icon;
  final List<SubjectItem> subjects;

  const SubjectCategory({
    required this.name,
    required this.icon,
    required this.subjects,
  });
}

class SubjectCatalog {
  SubjectCatalog._();

  static const List<SubjectCategory> categories = [
    SubjectCategory(
      name: 'Languages',
      icon: Icons.translate,
      subjects: [
        SubjectItem(name: 'English', icon: Icons.language),
        SubjectItem(name: 'Urdu', icon: Icons.translate),
        SubjectItem(name: 'Arabic', icon: Icons.translate),
        SubjectItem(name: 'French', icon: Icons.language),
      ],
    ),
    SubjectCategory(
      name: 'Science',
      icon: Icons.science,
      subjects: [
        SubjectItem(name: 'General Science', icon: Icons.science),
        SubjectItem(name: 'Biology', icon: Icons.biotech),
        SubjectItem(name: 'Chemistry', icon: Icons.science),
        SubjectItem(name: 'Physics', icon: Icons.science),
        SubjectItem(name: 'Environmental Science', icon: Icons.eco),
      ],
    ),
    SubjectCategory(
      name: 'Mathematics',
      icon: Icons.calculate,
      subjects: [
        SubjectItem(name: 'Mathematics', icon: Icons.calculate),
        SubjectItem(name: 'Additional Mathematics', icon: Icons.calculate_outlined),
        SubjectItem(name: 'Statistics', icon: Icons.bar_chart),
      ],
    ),
    SubjectCategory(
      name: 'Social Studies',
      icon: Icons.public,
      subjects: [
        SubjectItem(name: 'Pakistan Studies', icon: Icons.flag),
        SubjectItem(name: 'Social Studies', icon: Icons.public),
        SubjectItem(name: 'History', icon: Icons.history),
        SubjectItem(name: 'Geography', icon: Icons.explore),
        SubjectItem(name: 'Civics', icon: Icons.account_balance),
        SubjectItem(name: 'Economics', icon: Icons.trending_up),
      ],
    ),
    SubjectCategory(
      name: 'Computer & Technology',
      icon: Icons.computer,
      subjects: [
        SubjectItem(name: 'Computer Science', icon: Icons.computer),
        SubjectItem(name: 'Information Technology', icon: Icons.lan),
        SubjectItem(name: 'Artificial Intelligence', icon: Icons.psychology),
        SubjectItem(name: 'Robotics', icon: Icons.smart_toy),
      ],
    ),
    SubjectCategory(
      name: 'Commerce',
      icon: Icons.business,
      subjects: [
        SubjectItem(name: 'Accounting', icon: Icons.account_balance),
        SubjectItem(name: 'Business Studies', icon: Icons.business),
        SubjectItem(name: 'Commerce', icon: Icons.shopping_cart),
        SubjectItem(name: 'Entrepreneurship', icon: Icons.rocket_launch),
      ],
    ),
    SubjectCategory(
      name: 'Arts & Creative',
      icon: Icons.palette,
      subjects: [
        SubjectItem(name: 'Fine Arts', icon: Icons.palette),
        SubjectItem(name: 'Drawing', icon: Icons.brush),
        SubjectItem(name: 'Music', icon: Icons.music_note),
        SubjectItem(name: 'Drama', icon: Icons.theater_comedy),
      ],
    ),
    SubjectCategory(
      name: 'Health & Physical Education',
      icon: Icons.fitness_center,
      subjects: [
        SubjectItem(name: 'Physical Education', icon: Icons.fitness_center),
        SubjectItem(name: 'Health Education', icon: Icons.health_and_safety),
      ],
    ),
    SubjectCategory(
      name: 'Religious Studies',
      icon: Icons.menu_book,
      subjects: [
        SubjectItem(name: 'Islamic Studies', icon: Icons.menu_book),
        SubjectItem(name: 'Ethics', icon: Icons.balance),
      ],
    ),
    SubjectCategory(
      name: 'Other',
      icon: Icons.more_horiz,
      subjects: [
        SubjectItem(name: 'General Knowledge', icon: Icons.lightbulb),
        SubjectItem(name: 'Life Skills', icon: Icons.people),
        SubjectItem(name: 'STEM', icon: Icons.handyman),
        SubjectItem(name: 'Moral Education', icon: Icons.verified),
      ],
    ),
  ];

  static List<String> get allSubjectNames =>
      categories.expand((c) => c.subjects.map((s) => s.name)).toList();

  static SubjectItem? find(String name) {
    for (final cat in categories) {
      for (final sub in cat.subjects) {
        if (sub.name == name) return sub;
      }
    }
    return null;
  }

  static List<SubjectItem> search(String query) {
    if (query.isEmpty) return allSubjectNames.map((n) => find(n)!).toList();
    final q = query.toLowerCase();
    return allSubjectNames
        .where((n) => n.toLowerCase().contains(q))
        .map((n) => find(n)!)
        .toList();
  }

  static List<SubjectCategory> searchCategories(String query) {
    if (query.isEmpty) return categories;
    final q = query.toLowerCase();
    return categories
        .map((cat) => SubjectCategory(
              name: cat.name,
              icon: cat.icon,
              subjects: cat.subjects
                  .where((s) => s.name.toLowerCase().contains(q))
                  .toList(),
            ))
        .where((cat) => cat.subjects.isNotEmpty)
        .toList();
  }
}
