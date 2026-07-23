class UserProfile {
  final int id;
  final String uid;
  final String name;
  final String email;
  final String role;
  final String? schoolName;
  final List<String>? subjectsTaught;
  final List<String>? gradeLevelsTaught;
  final String? languagePreference;
  final String plan;
  final bool isPro;
  final String? subscriptionStatus;
  final String? subscriptionStart;
  final String? subscriptionEnd;
  final String? createdAt;

  UserProfile({
    required this.id,
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.schoolName,
    this.subjectsTaught,
    this.gradeLevelsTaught,
    this.languagePreference,
    this.plan = 'free',
    this.isPro = false,
    this.subscriptionStatus,
    this.subscriptionStart,
    this.subscriptionEnd,
    this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'],
    uid: json['uid'] ?? '',
    name: json['name'],
    email: json['email'],
    role: json['role'],
    schoolName: json['schoolName'],
    subjectsTaught: json['subjectsTaught'] != null
        ? List<String>.from(json['subjectsTaught'])
        : null,
    gradeLevelsTaught: json['gradeLevelsTaught'] != null
        ? List<String>.from(json['gradeLevelsTaught'])
        : null,
    languagePreference: json['languagePreference'],
    plan: json['plan'] ?? 'free',
    isPro: json['isPro'] ?? false,
    subscriptionStatus: json['subscriptionStatus'],
    subscriptionStart: json['subscriptionStart'],
    subscriptionEnd: json['subscriptionEnd'],
    createdAt: json['createdAt'],
  );
}
