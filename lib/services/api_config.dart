import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  /// Allows manual override in runtime or app initialization
  static String? customBaseUrl;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('custom_api_base_url');
      if (saved != null && saved.trim().isNotEmpty) {
        customBaseUrl = saved.trim();
      }
    } catch (_) {}
  }

  static Future<void> setCustomBaseUrl(String? url) async {
    customBaseUrl = url?.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (url == null || url.trim().isEmpty) {
        await prefs.remove('custom_api_base_url');
      } else {
        await prefs.setString('custom_api_base_url', url.trim());
      }
    } catch (_) {}
  }

  static String get baseUrl {
    if (customBaseUrl != null && customBaseUrl!.trim().isNotEmpty) {
      return customBaseUrl!.trim();
    }

    if (kIsWeb) {
      final origin = Uri.base.origin;
      final host = Uri.base.host;

      // Check URL query parameters for ?api= or ?backend= override
      if (Uri.base.queryParameters.containsKey('api')) {
        return Uri.base.queryParameters['api']!;
      }
      if (Uri.base.queryParameters.containsKey('backend')) {
        return '${Uri.base.queryParameters['backend']!}/api';
      }

      // Local development (localhost / 127.0.0.1)
      if (host == 'localhost' || host == '127.0.0.1' || host.isEmpty) {
        return 'http://127.0.0.1:5000/api';
      }

      // If accessing via custom port 5000
      if (Uri.base.port == 5000) {
        return 'http://$host:5000/api';
      }

      // If running on Firebase Hosting (web.app or firebaseapp.com)
      if (host.contains('web.app') || host.contains('firebaseapp.com')) {
        return 'http://127.0.0.1:5000/api';
      }

      // In production web (e.g. Cloud Run, Render unified)
      return '$origin/api';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api'; // For Android Emulator
    }

    return 'http://127.0.0.1:5000/api'; // For Windows Desktop & fallback
  }
}

