import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized API & Networking Configuration
/// Bright Light School Enterprise System
class ApiConfig {
  /// Default Cloud Backend URL (Render Cloud Backend)
  static const String baseUrlConstant =
      'https://bls-backend.onrender.com/api';

  /// Static Demo Admin credentials for offline fallback
  static const String demoAdminEmail = 'admin@brightlight.edu.kh';
  static const String demoAdminPass = '1202';

  /// Whether the app is currently running in offline demo fallback mode
  static bool isDemoMode = false;

  /// Custom Base URL configured by the user via UI or Settings
  static String? customBaseUrl;

  /// Initialize and load saved API configuration
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('custom_api_base_url');
      if (saved != null && saved.trim().isNotEmpty) {
        customBaseUrl = saved.trim();
      }
    } catch (_) {}
  }

  /// Update custom Base URL
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

  /// Unified Base URL for all API requests across the system
  static String get baseUrl {
    if (customBaseUrl != null && customBaseUrl!.trim().isNotEmpty) {
      return customBaseUrl!.trim();
    }

    if (kIsWeb) {
      // 1. Check URL query parameters for ?api= or ?backend= override
      if (Uri.base.queryParameters.containsKey('api')) {
        return Uri.base.queryParameters['api']!;
      }
      if (Uri.base.queryParameters.containsKey('backend')) {
        return '${Uri.base.queryParameters['backend']!}/api';
      }

      // Default all web instances to Render Cloud Backend
      return baseUrlConstant;
    }

    // Default for Android, iOS, Desktop to Render Cloud Backend
    return baseUrlConstant;
  }
}
