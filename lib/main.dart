import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:school_management_app/screens/auth/login_screen.dart';

import 'package:provider/provider.dart';
import 'package:school_management_app/providers/app_providers.dart';

import 'package:school_management_app/services/api_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;
  await ApiConfig.init();
  runApp(
    MultiProvider(
      providers: AppProviders.allProviders,
      child: const BrightLightSchoolApp(),
    ),
  );
}

class BrightLightSchoolApp extends StatelessWidget {
  const BrightLightSchoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    const muolFallback = [
      'Khmer OS Muol Light',
      'Moul',
      'Noto Serif Khmer',
      'Segoe UI Symbol',
      'Segoe UI',
      'Arial',
      'Calibri Light',
      'sans-serif',
    ];
    const battambangFallback = [
      'Khmer OS Battambang',
      'Kantumruy Pro',
      'Noto Sans Khmer',
      'Segoe UI Symbol',
      'Segoe UI',
      'Arial',
      'Inter',
      'Khmer OS Battambang',
      'sans-serif',
    ];
    const interFallback = [
      'Inter',
      'Segoe UI Symbol',
      'Segoe UI',
      'Arial',
      'Khmer OS Battambang',
      'Kantumruy Pro',
      'sans-serif',
    ];

    return MaterialApp(
      title: 'សាលាប្រាយឡាយ • Bright Light School',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          primary: const Color(0xFF4F46E5),
          secondary: const Color(0xFF10B981),
          surface: Colors.white,
          // ignore: deprecated_member_use
          background: const Color(0xFFF8FAFC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        useMaterial3: true,
        fontFamily: 'Khmer OS Battambang',
        fontFamilyFallback: battambangFallback,
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'Kantumruy Pro',
            fontFamilyFallback: battambangFallback,
            fontWeight: FontWeight.w700,
          ),
          displayMedium: TextStyle(
            fontFamily: 'Kantumruy Pro',
            fontFamilyFallback: battambangFallback,
            fontWeight: FontWeight.w700,
          ),
          displaySmall: TextStyle(
            fontFamily: 'Kantumruy Pro',
            fontFamilyFallback: battambangFallback,
            fontWeight: FontWeight.w700,
          ),
          headlineLarge: TextStyle(
            fontFamily: 'Kantumruy Pro',
            fontFamilyFallback: battambangFallback,
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'Kantumruy Pro',
            fontFamilyFallback: battambangFallback,
            fontWeight: FontWeight.w600,
          ),
          headlineSmall: TextStyle(
            fontFamily: 'Khmer OS Battambang',
            fontFamilyFallback: battambangFallback,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Khmer OS Battambang',
            fontFamilyFallback: battambangFallback,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: TextStyle(
            fontFamily: 'Khmer OS Battambang',
            fontFamilyFallback: battambangFallback,
            fontWeight: FontWeight.w600,
          ),
          titleSmall: TextStyle(
            fontFamily: 'Khmer OS Battambang',
            fontFamilyFallback: battambangFallback,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Khmer OS Battambang',
            fontFamilyFallback: battambangFallback,
            fontSize: 13.5,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Khmer OS Battambang',
            fontFamilyFallback: battambangFallback,
            fontSize: 12.5,
          ),
          bodySmall: TextStyle(
            fontFamily: 'Khmer OS Battambang',
            fontFamilyFallback: battambangFallback,
            fontSize: 11.5,
          ),
          labelLarge: TextStyle(
            fontFamily: 'Inter',
            fontFamilyFallback: interFallback,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          labelMedium: TextStyle(
            fontFamily: 'Inter',
            fontFamilyFallback: interFallback,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          labelSmall: TextStyle(
            fontFamily: 'Inter',
            fontFamilyFallback: interFallback,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          color: Colors.white,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: const Color(0xFF0F172A),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Khmer OS Battambang',
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            side: const BorderSide(color: Color(0xFFCBD5E1)),
            textStyle: const TextStyle(
              fontFamily: 'Khmer OS Battambang',
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
