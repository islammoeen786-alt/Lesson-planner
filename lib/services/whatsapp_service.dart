import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../config/app_config.dart';

class WhatsAppService {
  static String _deviceInfo = '';
  static String _appVersion = '';

  static Future<void> init() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = '${info.version}+${info.buildNumber}';
    } catch (_) {
      _appVersion = 'Unknown';
    }

    if (kIsWeb) {
      _deviceInfo = 'Web Browser';
    } else {
      try {
        _deviceInfo = Platform.operatingSystem;
      } catch (_) {
        _deviceInfo = 'Mobile App';
      }
    }
  }

  static String get deviceInfo => _deviceInfo;
  static String get appVersion => _appVersion;

  static String buildPersonalizedMessage({String name = '', String email = ''}) {
    return AppConfig.whatsappMessage
        .replaceFirst('Name:', 'Name: $name')
        .replaceFirst('Email:', 'Email: $email')
        .replaceFirst('Device:', 'Device: $_deviceInfo')
        .replaceFirst('App Version:', 'App Version: $_appVersion');
  }

  static Future<bool> openWhatsApp({String name = '', String email = ''}) async {
    final message = buildPersonalizedMessage(name: name, email: email);
    final encoded = Uri.encodeComponent(message);
    final appUri = Uri.parse('whatsapp://send?phone=${AppConfig.whatsappNumberRaw}&text=$encoded');
    final webUri = Uri.parse('https://wa.me/${AppConfig.whatsappNumberRaw}?text=$encoded');

    try {
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (_) {}

    try {
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (_) {}

    return false;
  }

  static void copyNumber() {
    Clipboard.setData(const ClipboardData(text: AppConfig.whatsappNumber));
  }

  static void copyMessage({String name = '', String email = ''}) {
    final msg = buildPersonalizedMessage(name: name, email: email);
    Clipboard.setData(ClipboardData(text: msg));
  }
}
