import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:google_fonts/google_fonts.dart';

/// Premium Design System for Bright Light School OS
/// Consistent colors, spacing, shadows, and reusable widget builders
class AppTheme {
  // ─── Brand Colors ───
  static const Color primary = Color(0xFF4F46E5); // Indigo 600
  static const Color primaryDark = Color(0xFF4338CA); // Indigo 700
  static const Color primaryLight = Color(0xFFEEF2FF); // Indigo 50
  static const Color accent = Color(0xFF0EA5E9);
  static const Color accentTeal = Color(0xFF0D9488); // Teal 600

  // ─── Semantic Colors ───
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color successLight = Color(0xFFD1FAE5); // Emerald 100
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFEF4444); // Red 500
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6); // Blue 500
  static const Color infoLight = Color(0xFFDBEAFE);

  // ─── Neutrals (Slate Palette) ───
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate50 = Color(0xFFF8FAFC);

  // ─── Background ───
  static const Color scaffoldBg = slate50;
  static const Color cardBg = Colors.white;
  static const Color sidebarBg = slate900;
  static const Color sidebarHover = slate800;

  // ─── Sidebar Gradient ───
  static const LinearGradient sidebarGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0F172A), Color(0xFF1A2332)],
  );

  // ─── Card Shadows ───
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get cardShadowMd => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get cardShadowLg => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 32,
      offset: const Offset(0, 16),
    ),
  ];

  // ─── Border Radius ───
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radius2xl = 24;

  // ─── Spacing ───
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;
  static const double space2xl = 48;

  // ─── Card Decoration ───
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardBg,
    borderRadius: BorderRadius.circular(radiusLg),
    border: Border.all(color: slate200.withValues(alpha: 0.8)),
    boxShadow: cardShadow,
  );

  static BoxDecoration cardDecorationColored(Color color) => BoxDecoration(
    color: cardBg,
    borderRadius: BorderRadius.circular(radiusLg),
    border: Border.all(color: color.withValues(alpha: 0.15)),
    boxShadow: [
      BoxShadow(
        color: color.withValues(alpha: 0.08),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );

  // ─── Font Families ───
  static const String fontKhmerMuol = 'Khmer OS Muol Light';
  static const String fontKhmerBattambang = 'Khmer OS Battambang';
  static const String fontKhmerModern = 'Kantumruy Pro';
  static const String fontEnglishHeading = 'Inter';

  // Fallbacks for web and cross-platform
  static const List<String> khmerMuolFallback = [
    'Khmer OS Muol Light',
    'Khmer OS Muol',
    'Noto Serif Khmer',
    'Segoe UI Symbol',
    'Segoe UI',
    'Arial',
    'sans-serif',
  ];
  static const List<String> khmerHeadingFallback = [
    'Kantumruy Pro',
    'Khmer OS Battambang',
    'Noto Sans Khmer',
    'Inter',
    'Segoe UI Symbol',
    'Segoe UI',
    'Arial',
    'sans-serif',
  ];
  static const List<String> khmerBattambangFallback = [
    'Khmer OS Battambang',
    'Kantumruy Pro',
    'Noto Sans Khmer',
    'Inter',
    'Segoe UI Symbol',
    'Segoe UI',
    'Arial',
    'sans-serif',
  ];
  static const List<String> englishHeadingFallback = [
    'Inter',
    'Outfit',
    'Segoe UI Symbol',
    'Segoe UI',
    'Arial',
    'Roboto',
    'sans-serif',
  ];

  // Modern, clean, crisp Khmer UI heading
  static TextStyle khmerHeading({
    double fontSize = 17,
    FontWeight fontWeight = FontWeight.w700,
    Color color = slate900,
    double height = 1.35,
    double letterSpacing = -0.2,
  }) {
    return TextStyle(
      fontFamily: fontKhmerModern,
      fontFamilyFallback: khmerHeadingFallback,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // Formal/Ceremonial Khmer Muol (for certificates & diplomas only)
  static TextStyle khmerCeremonial({
    double fontSize = 20,
    Color color = slate900,
    double height = 1.4,
  }) {
    return TextStyle(
      fontFamily: fontKhmerMuol,
      fontFamilyFallback: khmerMuolFallback,
      fontSize: fontSize,
      fontWeight: FontWeight.normal,
      color: color,
      height: height,
    );
  }

  static TextStyle khmerBody({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = slate600,
    double height = 1.5,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: fontKhmerBattambang,
      fontFamilyFallback: khmerBattambangFallback,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle englishHeading({
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.w600,
    Color color = slate900,
    double height = 1.25,
    double letterSpacing = -0.3,
  }) => TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: englishHeadingFallback,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  static TextStyle englishBody({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w400,
    Color color = slate600,
    double height = 1.45,
    double letterSpacing = 0,
  }) => TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: englishHeadingFallback,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  static TextStyle englishCaption({
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w500,
    Color color = slate400,
    double letterSpacing = 0.3,
  }) => TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: englishHeadingFallback,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
  );

  // ─── Standard App Text Styles ───
  static const TextStyle headingXl = TextStyle(
    fontFamily: fontKhmerModern,
    fontFamilyFallback: khmerHeadingFallback,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: slate900,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static const TextStyle headingLg = TextStyle(
    fontFamily: fontKhmerModern,
    fontFamilyFallback: khmerHeadingFallback,
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: slate900,
    letterSpacing: -0.2,
    height: 1.35,
  );

  static const TextStyle headingMd = TextStyle(
    fontFamily: fontKhmerModern,
    fontFamilyFallback: khmerHeadingFallback,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: slate900,
    height: 1.35,
  );

  static const TextStyle headingSm = TextStyle(
    fontFamily: fontKhmerBattambang,
    fontFamilyFallback: khmerBattambangFallback,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: slate800,
    height: 1.4,
  );

  static const TextStyle bodyLg = TextStyle(
    fontFamily: fontKhmerBattambang,
    fontFamilyFallback: khmerBattambangFallback,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: slate600,
    height: 1.5,
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: fontKhmerBattambang,
    fontFamilyFallback: khmerBattambangFallback,
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    color: slate500,
    height: 1.5,
  );

  static const TextStyle labelSm = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: englishHeadingFallback,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: slate400,
    letterSpacing: 0.5,
  );

  // ─── Reusable Widget Builders ───

  /// Pill / Chip badge
  static Widget badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  /// Modern Status Badge with optional icon
  static Widget statusBadge(
    String text, {
    Color color = primary,
    IconData? icon,
    bool filled = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: filled ? color : color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 13,
              color: filled ? Colors.white : color,
            ),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              fontFamily: fontKhmerBattambang,
              fontFamilyFallback: khmerBattambangFallback,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: filled ? Colors.white : color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  /// Dual Language Header: Khmer on top, English below
  static Widget dualLanguageHeader(
    String khmer,
    String english, {
    double khmerSize = 18,
    double englishSize = 12,
    Color? khmerColor,
    Color? englishColor,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          khmer,
          style: khmerHeading(
            fontSize: khmerSize,
            color: khmerColor ?? slate900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          english,
          style: englishHeading(
            fontSize: englishSize,
            fontWeight: FontWeight.w500,
            color: englishColor ?? slate500,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  /// Section header with optional action
  static Widget sectionHeader(String title, {Widget? action}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: headingMd),
        // ignore: use_null_aware_elements
        if (action != null) action,
      ],
    );
  }

  /// Empty state placeholder
  static Widget emptyState({
    required IconData icon,
    required String title,
    String? subtitle,
    Color color = primary,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: color.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 20),
          Text(title, style: headingMd.copyWith(color: slate700)),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle, style: bodySm, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }

  /// Standard page wrapper (title + subtitle + actions + body)
  static Widget pageScaffold({
    required String title,
    String? subtitle,
    List<Widget>? actions,
    required Widget body,
  }) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: headingXl),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle, style: bodySm),
                    ],
                  ],
                ),
              ),
              if (actions != null) Wrap(spacing: 12, children: actions),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(child: body),
        ],
      ),
    );
  }

  /// Primary action button
  static Widget primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color color = primary,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      onPressed: onPressed,
    );
  }

  /// Outlined action button
  static Widget outlinedButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color color = primary,
  }) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      onPressed: onPressed,
    );
  }
}
