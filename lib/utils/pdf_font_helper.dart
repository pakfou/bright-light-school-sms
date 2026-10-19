import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Helper to load offline bundled Khmer fonts for PDF generation
/// without relying on network or Google Fonts CDN.
class PdfFontHelper {
  static pw.Font? _cachedRegular;
  static pw.Font? _cachedBold;
  static pw.Font? _cachedMuol;

  /// Returns Khmer regular font (KhmerOSbattambang)
  static Future<pw.Font> getRegularFont() async {
    if (_cachedRegular != null) return _cachedRegular!;
    try {
      final data = await rootBundle.load('assets/fonts/KhmerOSbattambang.ttf');
      _cachedRegular = pw.Font.ttf(data);
      return _cachedRegular!;
    } catch (_) {
      try {
        final data = await rootBundle.load('assets/fonts/Battambang-Regular.ttf');
        _cachedRegular = pw.Font.ttf(data);
        return _cachedRegular!;
      } catch (_) {
        _cachedRegular = await PdfGoogleFonts.notoSansKhmerRegular();
        return _cachedRegular!;
      }
    }
  }

  /// Returns Khmer bold font (KhmerOSbattambang-Bold)
  static Future<pw.Font> getBoldFont() async {
    if (_cachedBold != null) return _cachedBold!;
    try {
      final data = await rootBundle.load('assets/fonts/KhmerOSbattambang-Bold.ttf');
      _cachedBold = pw.Font.ttf(data);
      return _cachedBold!;
    } catch (_) {
      try {
        final data = await rootBundle.load('assets/fonts/Battambang-Bold.ttf');
        _cachedBold = pw.Font.ttf(data);
        return _cachedBold!;
      } catch (_) {
        _cachedBold = await PdfGoogleFonts.notoSansKhmerBold();
        return _cachedBold!;
      }
    }
  }

  /// Returns Khmer Muol font for large titles (KhmerOSmuollight)
  static Future<pw.Font> getMuolFont() async {
    if (_cachedMuol != null) return _cachedMuol!;
    try {
      final data = await rootBundle.load('assets/fonts/KhmerOSmuollight.ttf');
      _cachedMuol = pw.Font.ttf(data);
      return _cachedMuol!;
    } catch (_) {
      try {
        final data = await rootBundle.load('assets/fonts/Moul-Regular.ttf');
        _cachedMuol = pw.Font.ttf(data);
        return _cachedMuol!;
      } catch (_) {
        return getBoldFont();
      }
    }
  }

  /// Returns a full pw.ThemeData configured with Khmer typography
  static Future<pw.ThemeData> getKhmerTheme() async {
    final regular = await getRegularFont();
    final bold = await getBoldFont();
    return pw.ThemeData.withFont(
      base: regular,
      bold: bold,
      italic: regular,
      boldItalic: bold,
      fontFallback: [regular, bold],
    );
  }

  /// Safely sanitizes strings for PDF rendering to ensure no unsupported
  /// characters (like bullet '•' U+2022) trigger missing glyph warnings or fallbacks.
  static String safe(String text) {
    return text.replaceAll('•', '|');
  }
}

