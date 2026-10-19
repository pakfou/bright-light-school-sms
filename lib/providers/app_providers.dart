import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'package:school_management_app/providers/auth_provider.dart';
import 'package:school_management_app/providers/classroom_provider.dart';

/// Centralized Provider Management
/// This makes `main.dart` cleaner and manages all global states professionally.
class AppProviders {
  static List<SingleChildWidget> get allProviders {
    return [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => ClassroomProvider()),
      ChangeNotifierProvider(create: (_) => SchoolDataProvider()),
      // Add other global providers here (e.g., ThemeProvider, SettingsProvider)
    ];
  }
}

class SchoolDataProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate API call or fetch real data
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      debugPrint("Error loading school data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
