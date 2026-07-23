class LessonSection {
  final String name;
  final int durationMinutes;
  final String description;

  LessonSection({
    required this.name,
    required this.durationMinutes,
    required this.description,
  });

  factory LessonSection.fromJson(Map<String, dynamic> json) => LessonSection(
    name: json['name'] as String,
    durationMinutes: json['durationMinutes'] as int,
    description: json['description'] as String,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'durationMinutes': durationMinutes,
    'description': description,
  };
}

class LessonContent {
  final String title;
  final String subject;
  final String gradeLevel;
  final int durationMinutes;
  final List<String> learningObjectives;
  final List<String> materials;
  final List<LessonSection> sections;

  LessonContent({
    required this.title,
    required this.subject,
    required this.gradeLevel,
    required this.durationMinutes,
    required this.learningObjectives,
    required this.materials,
    required this.sections,
  });

  factory LessonContent.fromJson(Map<String, dynamic> json) {
    final sectionsList = json['sections'];
    return LessonContent(
      title: json['title'] as String,
      subject: json['subject'] as String,
      gradeLevel: json['gradeLevel'] as String,
      durationMinutes: json['durationMinutes'] as int,
      learningObjectives: (json['learningObjectives'] as List)
          .map((e) => e as String)
          .toList(),
      materials: (json['materials'] as List)
          .map((e) => e as String)
          .toList(),
      sections: (sectionsList as List)
          .map((s) => LessonSection.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'subject': subject,
    'gradeLevel': gradeLevel,
    'durationMinutes': durationMinutes,
    'learningObjectives': learningObjectives,
    'materials': materials,
    'sections': sections.map((s) => s.toJson()).toList(),
  };
}

class LessonPlan {
  final int id;
  final int userId;
  final String title;
  final String? subject;
  final String? gradeLevel;
  final String? topic;
  final int? durationMinutes;
  final LessonContent content;
  final bool aiGenerated;
  final String status;
  final String? scheduledDate;
  final String createdAt;
  final String updatedAt;

  LessonPlan({
    required this.id,
    required this.userId,
    required this.title,
    this.subject,
    this.gradeLevel,
    this.topic,
    this.durationMinutes,
    required this.content,
    required this.aiGenerated,
    required this.status,
    this.scheduledDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LessonPlan.fromJson(Map<String, dynamic> json) => LessonPlan(
    id: json['id'] as int,
    userId: json['userId'] as int,
    title: json['title'] as String,
    subject: json['subject'] as String?,
    gradeLevel: json['gradeLevel'] as String?,
    topic: json['topic'] as String?,
    durationMinutes: json['durationMinutes'] as int?,
    content: LessonContent.fromJson(json['content'] as Map<String, dynamic>),
    aiGenerated: json['aiGenerated'] as bool,
    status: json['status'] as String,
    scheduledDate: json['scheduledDate'] as String?,
    createdAt: json['createdAt'] as String,
    updatedAt: json['updatedAt'] as String,
  );
}
