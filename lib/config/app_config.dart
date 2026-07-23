class AppConfig {
  AppConfig._();

  static const String whatsappNumber = '+923055093503';
  static const String whatsappNumberRaw = '923055093503';
  static const int freeQuotaLimit = 20;

  static String get whatsappMessage {
    return '''Hello! I have reached the free limit in the Smart Lesson Planner app and would like to purchase the Pro version.

Name:
Email:
Device:
App Version:

Please share the subscription details.''';
  }

  static String get whatsappUrl {
    final encoded = Uri.encodeComponent(whatsappMessage);
    return 'https://wa.me/$whatsappNumberRaw?text=$encoded';
  }

  static String get whatsappAppUrl {
    final encoded = Uri.encodeComponent(whatsappMessage);
    return 'whatsapp://send?phone=$whatsappNumberRaw&text=$encoded';
  }
}
