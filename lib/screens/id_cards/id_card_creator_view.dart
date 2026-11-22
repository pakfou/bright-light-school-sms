import 'dart:convert';
// ignore: unnecessary_import
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart';
// ignore: unused_import
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:school_management_app/services/api_service.dart';
import 'package:school_management_app/services/html_print_service.dart';
import 'package:school_management_app/utils/image_download_helper.dart';
// ignore: unused_import
import 'package:school_management_app/utils/app_theme.dart';
import 'package:school_management_app/utils/app_logo.dart';
// ignore: unused_import
import 'package:school_management_app/utils/pdf_font_helper.dart';

class IdCardCreatorView extends StatefulWidget {
  const IdCardCreatorView({super.key});

  @override
  State<IdCardCreatorView> createState() => _IdCardCreatorViewState();
}

class _IdCardCreatorViewState extends State<IdCardCreatorView> {
  static String get baseUrl => ApiService.baseUrl;

  Widget _buildPersonPhotoWidget({
    dynamic photoUrl,
    required double width,
    required double height,
    double borderRadius = 8,
    Border? border,
  }) {
    final str = (photoUrl ?? '').toString().trim();
    final fallback = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? Border.all(color: Colors.white, width: 2),
      ),
      child: Icon(
        Icons.person,
        color: const Color(0xFF94A3B8),
        size: width * 0.45,
      ),
    );

    if (str.isEmpty) return fallback;

    Uint8List? bytes;
    if (str.startsWith('data:image')) {
      try {
        final commaIdx = str.indexOf(',');
        final base64Data = commaIdx != -1 ? str.substring(commaIdx + 1) : str;
        bytes = base64Decode(base64Data);
      } catch (_) {}
    } else if (str.length > 100 &&
        !str.contains(' ') &&
        !str.startsWith('http')) {
      try {
        bytes = base64Decode(str);
      } catch (_) {}
    }

    if (bytes != null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(borderRadius),
          border: border ?? Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            borderRadius > 1 ? borderRadius - 1 : 0,
          ),
          child: Image.memory(
            bytes,
            width: width,
            height: height,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            // ignore: unnecessary_underscores
            errorBuilder: (_, __, ___) => fallback,
          ),
        ),
      );
    }

    String? fullUrl;
    if (str.startsWith('http://') || str.startsWith('https://')) {
      fullUrl = str;
    } else if (str.startsWith('/') || str.contains('uploads/')) {
      final origin = baseUrl.replaceAll('/api', '');
      fullUrl = '$origin/${str.startsWith('/') ? str.substring(1) : str}';
    }

    if (fullUrl != null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(borderRadius),
          border: border ?? Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            borderRadius > 1 ? borderRadius - 1 : 0,
          ),
          child: Image.network(
            fullUrl,
            width: width,
            height: height,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            // ignore: unnecessary_underscores
            errorBuilder: (_, __, ___) => fallback,
          ),
        ),
      );
    }

    if (str.startsWith('assets/')) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(borderRadius),
          border: border ?? Border.all(color: Colors.white, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            borderRadius > 1 ? borderRadius - 1 : 0,
          ),
          child: Image.asset(
            str,
            width: width,
            height: height,
            fit: BoxFit.cover,
            // ignore: unnecessary_underscores
            errorBuilder: (_, __, ___) => fallback,
          ),
        ),
      );
    }

    return fallback;
  }

  Widget _buildLanyardSlot({
    required double width,
    required double height,
    required double top,
    required double left,
  }) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(color: const Color(0xFF94A3B8), width: 1.2),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.2),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBackgroundPattern(
    String pattern,
    Color themeColor,
    bool isLandscape,
  ) {
    if (pattern == 'Seal') {
      return Center(
        child: Opacity(
          opacity: 0.04,
          child: AppLogo.widget(
            width: isLandscape ? 140 : 150,
            height: isLandscape ? 140 : 150,
            fit: BoxFit.contain,
          ),
        ),
      );
    } else if (pattern == 'Waves') {
      return Positioned.fill(
        child: Opacity(
          opacity: 0.05,
          child: CustomPaint(painter: _CardWavesPainter(themeColor)),
        ),
      );
    } else if (pattern == 'Dots') {
      return Positioned.fill(
        child: Opacity(
          opacity: 0.06,
          child: CustomPaint(painter: _CardDotsPainter(themeColor)),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 12, color: const Color(0xFF64748B)),
        const SizedBox(width: 5),
        SizedBox(
          width: 34,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF475569),
            ),
          ),
        ),
        const Text(
          ': ',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF94A3B8),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Khmer OS Battambang',
              fontSize: 9.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? const Color(0xFF1E293B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeField({
    required String label,
    required String value,
    bool isHighlight = false,
    Color? color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF64748B),
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Khmer OS Battambang',
              fontSize: 9.5,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              color: isHighlight
                  ? (color ?? const Color(0xFF2563EB))
                  : const Color(0xFF1E293B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }


  Widget _buildRuleItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Khmer OS Battambang',
          fontSize: 7.2,
          color: Color(0xFF334155),
          height: 1.35,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  bool _isStudent = true;
  String _orientation = 'Landscape';
  String _cardSide = 'Both';
  String _bgPattern = 'Seal';
  String _themeColor = 'Royal Blue';
  // ignore: prefer_final_fields
  final bool _hasLanyard = false;
  bool _hasGloss = true;
  // ignore: prefer_final_fields, unused_field
  double _previewScale = 1.0;

  // GlobalKeys for capturing exact high-resolution ID card designs directly from screen
  final GlobalKey _landscapeFrontKey = GlobalKey();
  final GlobalKey _landscapeBackKey = GlobalKey();
  final GlobalKey _portraitFrontKey = GlobalKey();
  final GlobalKey _portraitBackKey = GlobalKey();

  Future<Uint8List?> _captureCardWidget(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.5);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Card capture error: $e');
      return null;
    }
  }

  // ignore: unused_element
  Future<void> _downloadCardPng() async {
    if (_selectedPerson == null) return;
    try {
      final isLandscape = _orientation == 'Landscape';
      final frontKey = isLandscape ? _landscapeFrontKey : _portraitFrontKey;
      final backKey = isLandscape ? _landscapeBackKey : _portraitBackKey;
      final code = _isStudent
          ? (_selectedPerson!['student_code'] ?? 'STU-001')
          : (_selectedPerson!['teacher_code'] ?? 'TCH-001');

      Uint8List? bytes;
      if (_cardSide == 'Back') {
        bytes = await _captureCardWidget(backKey);
      } else {
        bytes = await _captureCardWidget(frontKey);
      }

      if (bytes != null) {
        downloadImageBytes(bytes, 'BLS_ID_Card_${code}_$_cardSide.png');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'បានទាញយករូបភាពកាត HD (PNG) ជោគជ័យ៖ BLS_ID_Card_$code.png',
                style: const TextStyle(fontFamily: 'Khmer OS Battambang'),
              ),
              backgroundColor: const Color(0xFF059669),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'មិនទាន់អាចចាប់យករូបភាពបានទេ សូមរង់ចាំមួយភ្លែត រួចសាកល្បងម្ដងទៀត',
                style: TextStyle(fontFamily: 'Khmer OS Battambang'),
              ),
              backgroundColor: Color(0xFFDC2626),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('កំហុសក្នុងការទាញយក PNG៖ $e')),
        );
      }
    }
  }

  List<dynamic> _students = [];
  List<dynamic> _teachers = [];
  Map<String, dynamic>? _selectedPerson;
  // ignore: unused_field
  bool _isLoading = true;

  final List<Map<String, dynamic>> _themes = [
    {'name': 'Royal Blue', 'color': const Color(0xFF2563EB)},
    {'name': 'Classic Emerald', 'color': const Color(0xFF059669)},
    {'name': 'Crimson Red', 'color': const Color(0xFFDC2626)},
    {'name': 'Sleek Charcoal', 'color': const Color(0xFF1E293B)},
    {'name': 'Vibrant Orange', 'color': const Color(0xFFEA580C)},
    {'name': 'Royal Purple', 'color': const Color(0xFF7C3AED)},
    {'name': 'Ocean Teal', 'color': const Color(0xFF0D9488)},
    {'name': 'Modern Gold', 'color': const Color(0xFFD97706)},
  ];

  // ignore: prefer_final_fields
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  // ignore: unused_element
  List<dynamic> get _filteredMemberList {
    final list = _isStudent ? _students : _teachers;
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.trim().toLowerCase();
    return list.where((m) {
      final kh = (m['name_kh'] ?? '').toString().toLowerCase();
      final en = (m['name_en'] ?? '').toString().toLowerCase();
      final code =
          (_isStudent ? (m['student_code'] ?? '') : (m['teacher_code'] ?? ''))
              .toString()
              .toLowerCase();
      final id = (m['id'] ?? '').toString().toLowerCase();
      final classOrSubj =
          (_isStudent
                  ? (m['class_name'] ??
                        m['grade'] ??
                        m['grade_level_name'] ??
                        '')
                  : (m['specialized_subject'] ??
                        m['subjects'] ??
                        m['role_title'] ??
                        ''))
              .toString()
              .toLowerCase();
      return kh.contains(q) ||
          en.contains(q) ||
          code.contains(q) ||
          id.contains(q) ||
          classOrSubj.contains(q);
    }).toList();
  }

  String get _currentCode {
    if (_selectedPerson == null) return '';
    return _isStudent
        ? (_selectedPerson!['student_code'] ??
              'BLS-${_selectedPerson!['id'] ?? '101'}')
        : (_selectedPerson!['teacher_code'] ??
              'TCH-${_selectedPerson!['id'] ?? '101'}');
  }

  String get _currentNameKh {
    return _selectedPerson?['name_kh']?.toString() ?? '';
  }

  String get _currentNameEn {
    return _selectedPerson?['name_en']?.toString() ?? '';
  }

  String get _currentRole {
    if (_isStudent) return 'សិស្ស (Student)';
    final role = _selectedPerson?['role_title']?.toString() ?? '';
    return role.isNotEmpty ? role : 'គ្រូបង្រៀន (Teacher)';
  }

  String get _currentCategoryOrGrade {
    if (_isStudent) {
      final cName =
          _selectedPerson?['class_name'] ??
          _selectedPerson?['grade'] ??
          _selectedPerson?['grade_level_name'];
      return (cName != null && cName.toString().isNotEmpty)
          ? cName.toString()
          : 'ថ្នាក់សិក្សា';
    } else {
      final subj =
          _selectedPerson?['specialized_subject'] ??
          _selectedPerson?['subjects'];
      return (subj != null && subj.toString().isNotEmpty)
          ? subj.toString()
          : 'មុខវិជ្ជាទូទៅ';
    }
  }

  String get _currentPhone {
    final p =
        _selectedPerson?['parent_phone'] ??
        _selectedPerson?['phone'] ??
        _selectedPerson?['tel'];
    return (p != null && p.toString().isNotEmpty)
        ? p.toString()
        : '012 889 911';
  }

  String get _currentDob {
    final d = _selectedPerson?['dob'];
    return (d != null && d.toString().isNotEmpty) ? d.toString() : '2008-05-12';
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        http.get(Uri.parse('$baseUrl/students')),
        http.get(Uri.parse('$baseUrl/teachers')),
      ]);
      final sRes = results[0];
      final tRes = results[1];

      if (sRes.statusCode == 200) {
        final data = jsonDecode(utf8.decode(sRes.bodyBytes))['data'];
        if (data != null) _students = data;
      }
      if (tRes.statusCode == 200) {
        final data = jsonDecode(utf8.decode(tRes.bodyBytes))['data'];
        if (data != null) _teachers = data;
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    }

    if (_students.isEmpty) {
      _students = [
        {
          'id': 1,
          'student_code': 'STU1001',
          'name_kh': 'សុខ ម៉ារី',
          'name_en': 'Sok Mary',
          'grade': 'Grade 4',
          'dob': '12.April.2016',
          'pob': 'Yeang Tmey, Kob Ochrov. BMC',
          'tel': '012345678',
        },
      ];
    }
    if (_teachers.isEmpty) {
      _teachers = [
        {
          'id': 1,
          'teacher_code': 'TCH2001',
          'name_kh': 'អ៊ុំ សុម៉ាលី',
          'name_en': 'Oum Somaly',
          'subjects': 'Khmer Literature, Mathematics, Social Studies',
          'tel': '012888111',
        },
      ];
    }

    _selectedPerson = _isStudent ? _students.first : _teachers.first;
    setState(() => _isLoading = false);
  }

  void _showQrCodeDialog() {
    if (_selectedPerson == null) return;
    final code = _isStudent
        ? (_selectedPerson!['student_code'] ?? 'STU-001')
        : (_selectedPerson!['teacher_code'] ?? 'TCH-001');
    final name = _selectedPerson!['name_kh'] ?? '';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.qr_code_2_rounded,
                size: 48,
                color: Color(0xFF2563EB),
              ),
              const SizedBox(height: 12),
              const Text(
                'QR Code សម្គាល់ខ្លួនផ្លូវការ',
                style: TextStyle(
                  fontFamily: 'Khmer OS Muol Light',
                  fontSize: 15,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$name ($code)',
                style: const TextStyle(
                  fontFamily: 'Khmer OS Battambang',
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                ),
                child: const Icon(
                  Icons.qr_code_rounded,
                  size: 160,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'កូដស្កេន៖ $code\nប្រើសម្រាប់ម៉ាស៊ីនស្កេនវត្តមាន BLS Scanner',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Khmer OS Battambang',
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'បានចម្លងកូដ $code រួចរាល់!',
                          style: const TextStyle(
                            fontFamily: 'Khmer OS Battambang',
                          ),
                        ),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text(
                    'ចម្លងកូដសម្គាល់ខ្លួន',
                    style: TextStyle(
                      fontFamily: 'Khmer OS Battambang',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  pw.Widget _buildPdfLandscapeFront({
    required pw.Font fontBold,
    required pw.Font fontRegular,
    required PdfColor themeColor,
    required String nameKh,
    required String nameEn,
    required String code,
    required String role,
    required String grade,
    required String phone,
    required pw.MemoryImage? photoImage,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: themeColor, width: 1.5),
        color: PdfColors.white,
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Image(AppLogo.pdfImage, width: 14, height: 14),
              pw.SizedBox(width: 5),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'សាលាប្រាយ ឡាយ',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 8.5,
                      color: const PdfColor.fromInt(0xFF1E3A8A),
                    ),
                  ),
                  pw.Text(
                    'BRIGHT LIGHT SCHOOL',
                    style: pw.TextStyle(
                      font: fontRegular,
                      fontSize: 5,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.Divider(thickness: 0.8, color: themeColor),
          pw.SizedBox(height: 2),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Photo on Left
              pw.Container(
                width: 44,
                height: 56,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: themeColor, width: 0.8),
                  borderRadius: pw.BorderRadius.circular(4),
                  color: PdfColors.grey100,
                ),
                child: photoImage != null
                    ? pw.ClipRRect(
                        horizontalRadius: 3,
                        verticalRadius: 3,
                        child: pw.Image(photoImage, fit: pw.BoxFit.cover),
                      )
                    : pw.Center(
                        child: pw.Text(
                          'រូបថត\nPhoto',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            font: fontRegular,
                            fontSize: 6,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ),
              ),
              pw.SizedBox(width: 8),
              // Details in Center
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      nameKh,
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 9.5,
                        color: PdfColors.black,
                      ),
                    ),
                    if (nameEn.isNotEmpty)
                      pw.Text(
                        nameEn,
                        style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: 7,
                          color: PdfColors.grey800,
                        ),
                      ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'អត្តលេខ: $code',
                      style: pw.TextStyle(
                        fontSize: 6.5,
                        font: fontBold,
                        color: themeColor,
                      ),
                    ),
                    pw.Text(
                      'តួនាទី: $role',
                      style: pw.TextStyle(font: fontRegular, fontSize: 6),
                    ),
                    pw.Text(
                      'ថ្នាក់/ជំនាញ: $grade',
                      style: pw.TextStyle(font: fontRegular, fontSize: 6),
                    ),
                    pw.Text(
                      'ទូរស័ព្ទ: $phone',
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 5.5,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 6),
              // QR Code on Right
              pw.Container(
                width: 44,
                height: 44,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
                  borderRadius: pw.BorderRadius.circular(4),
                  color: PdfColors.white,
                ),
                child: pw.Center(
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: code,
                    width: 38,
                    height: 38,
                  ),
                ),
              ),
            ],
          ),
          pw.Spacer(),
          pw.Divider(thickness: 0.4, color: PdfColors.grey300),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'ប័ណ្ណសម្គាល់ខ្លួនផ្លូវការ (ខាងមុខ) | OFFICIAL ID',
                style: pw.TextStyle(
                  font: fontRegular,
                  fontSize: 4.5,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                'Bright Light School | 2025-2026',
                style: pw.TextStyle(
                  font: fontRegular,
                  fontSize: 4.5,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  pw.Widget _buildPdfLandscapeBack({
    required pw.Font fontBold,
    required pw.Font fontRegular,
    required PdfColor themeColor,
    required String code,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: themeColor, width: 1.5),
        color: PdfColors.white,
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(
                children: [
                  pw.Image(AppLogo.pdfImage, width: 13, height: 13),
                  pw.SizedBox(width: 4),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'សាលាប្រាយ ឡាយ',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 8,
                          color: const PdfColor.fromInt(0xFF1E3A8A),
                        ),
                      ),
                      pw.Text(
                        'BRIGHT LIGHT SCHOOL',
                        style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: 4.5,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Text(
                '| ប័ណ្ណសម្គាល់ខ្លួនផ្លូវការ (ខាងក្រោយ) |',
                style: pw.TextStyle(
                  font: fontRegular,
                  fontSize: 4.5,
                  color: themeColor,
                ),
              ),
            ],
          ),
          pw.Divider(thickness: 0.6, color: themeColor),
          pw.SizedBox(height: 2),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 6,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(4),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'បទបញ្ជាផ្ទៃក្នុង / School Regulations:',
                        style: pw.TextStyle(font: fontBold, fontSize: 5),
                      ),
                      pw.SizedBox(height: 1.5),
                      pw.Text(
                        '១. ត្រូវពាក់ប័ណ្ណនេះជាប់ខ្លួនជានិច្ចពេលនៅក្នុងសាលា។',
                        style: pw.TextStyle(font: fontRegular, fontSize: 4.5),
                      ),
                      pw.Text(
                        '២. ហាមកែប្រែ ឬប្រគល់ប័ណ្ណនេះឱ្យអ្នកដទៃប្រើប្រាស់។',
                        style: pw.TextStyle(font: fontRegular, fontSize: 4.5),
                      ),
                      pw.Text(
                        '៣. ករណីបាត់បង់ សូមទាក់ទងការិយាល័យរដ្ឋបាលជាបន្ទាន់។',
                        style: pw.TextStyle(font: fontRegular, fontSize: 4.5),
                      ),
                      pw.Text(
                        'ទូរស័ព្ទ: 078 350 908 / 088 757 4732',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 4.5,
                          color: themeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                flex: 4,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'DISCIPLINE & RESPECT',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 4.5,
                        color: themeColor,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'PUNCTUAL RESPONSIBILITY',
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 4,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'នាយកសាលា / Principal',
                      style: pw.TextStyle(font: fontBold, fontSize: 4.5),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'ហត្ថលេខា & ត្រា',
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 4,
                        color: PdfColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.Spacer(),
          pw.Divider(thickness: 0.4, color: PdfColors.grey300),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Bright Light School | 2025-2026',
                style: pw.TextStyle(
                  font: fontRegular,
                  fontSize: 4,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                'Code: $code',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 4,
                  color: PdfColors.grey800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  pw.Widget _buildPdfPortraitFront({
    required pw.Font fontBold,
    required pw.Font fontRegular,
    required PdfColor themeColor,
    required String nameKh,
    required String nameEn,
    required String code,
    required String role,
    required String grade,
    required String phone,
    required pw.MemoryImage? photoImage,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: themeColor, width: 1.5),
        color: PdfColors.white,
      ),
      padding: const pw.EdgeInsets.all(5),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Image(AppLogo.pdfImage, width: 13, height: 13),
              pw.SizedBox(width: 4),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'សាលាប្រាយ ឡាយ',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 8,
                      color: const PdfColor.fromInt(0xFF1E3A8A),
                    ),
                  ),
                  pw.Text(
                    'BRIGHT LIGHT SCHOOL',
                    style: pw.TextStyle(
                      font: fontRegular,
                      fontSize: 4.5,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.Divider(thickness: 0.6, color: themeColor),
          pw.SizedBox(height: 3),
          // Photo
          pw.Container(
            width: 48,
            height: 60,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: themeColor, width: 0.8),
              borderRadius: pw.BorderRadius.circular(4),
              color: PdfColors.grey100,
            ),
            child: photoImage != null
                ? pw.ClipRRect(
                    horizontalRadius: 3,
                    verticalRadius: 3,
                    child: pw.Image(photoImage, fit: pw.BoxFit.cover),
                  )
                : pw.Center(
                    child: pw.Text(
                      'រូបថត\nPhoto',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 6,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            nameKh,
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 9,
              color: PdfColors.black,
            ),
          ),
          if (nameEn.isNotEmpty)
            pw.Text(
              nameEn,
              style: pw.TextStyle(
                font: fontRegular,
                fontSize: 6.5,
                color: PdfColors.grey800,
              ),
            ),
          pw.SizedBox(height: 3),
          pw.Container(
            padding: const pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'អត្តលេខ: $code',
                  style: pw.TextStyle(
                    fontSize: 6,
                    font: fontBold,
                    color: themeColor,
                  ),
                ),
                pw.Text(
                  'តួនាទី: $role',
                  style: pw.TextStyle(font: fontRegular, fontSize: 5.5),
                ),
                pw.Text(
                  'ថ្នាក់/ជំនាញ: $grade',
                  style: pw.TextStyle(font: fontRegular, fontSize: 5.5),
                ),
                pw.Text(
                  'ទូរស័ព្ទ: $phone',
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 5,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
          pw.Spacer(),
          pw.Container(
            width: 38,
            height: 38,
            child: pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: code),
          ),
          pw.Spacer(),
          pw.Text(
            'ប័ណ្ណសម្គាល់ខ្លួនផ្លូវការ (ខាងមុខ) | OFFICIAL ID',
            style: pw.TextStyle(
              font: fontRegular,
              fontSize: 4,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  pw.Widget _buildPdfPortraitBack({
    required pw.Font fontBold,
    required pw.Font fontRegular,
    required PdfColor themeColor,
    required String code,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: themeColor, width: 1.5),
        color: PdfColors.white,
      ),
      padding: const pw.EdgeInsets.all(5),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Image(AppLogo.pdfImage, width: 13, height: 13),
              pw.SizedBox(width: 4),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'សាលាប្រាយ ឡាយ',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 8,
                      color: const PdfColor.fromInt(0xFF1E3A8A),
                    ),
                  ),
                  pw.Text(
                    'BRIGHT LIGHT SCHOOL',
                    style: pw.TextStyle(
                      font: fontRegular,
                      fontSize: 4.5,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.Divider(thickness: 0.6, color: themeColor),
          pw.SizedBox(height: 2),
          pw.Text(
            '| វិន័យ និងបទបញ្ជាផ្ទៃក្នុង |',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 6.5,
              color: themeColor,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Container(
            padding: const pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '១. សិស្ស/បុគ្គលិក ត្រូវពាក់ប័ណ្ណនេះជាប់ខ្លួនជានិច្ចពេលនៅក្នុងសាលា។',
                  style: pw.TextStyle(font: fontRegular, fontSize: 4.5),
                ),
                pw.SizedBox(height: 1.5),
                pw.Text(
                  '២. ហាមកែប្រែ ក្លែងបន្លំ ឬប្រគល់ប័ណ្ណនេះឱ្យអ្នកដទៃប្រើប្រាស់។',
                  style: pw.TextStyle(font: fontRegular, fontSize: 4.5),
                ),
                pw.SizedBox(height: 1.5),
                pw.Text(
                  '៣. ករណីបាត់បង់ សូមរាយការណ៍មកការិយាល័យរដ្ឋបាលជាបន្ទាន់។',
                  style: pw.TextStyle(font: fontRegular, fontSize: 4.5),
                ),
                pw.SizedBox(height: 1.5),
                pw.Text(
                  '| DISCIPLINE | RESPECT | HONESTY | INTEGRITY |',
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 3.8,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
          pw.Spacer(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'ទំនាក់ទំនងបន្ទាន់:',
                    style: pw.TextStyle(font: fontBold, fontSize: 4.5),
                  ),
                  pw.Text(
                    '078 350 908',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 4.5,
                      color: themeColor,
                    ),
                  ),
                  pw.Text(
                    '088 757 4732',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 4.5,
                      color: themeColor,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'នាយកសាលា / Principal',
                    style: pw.TextStyle(font: fontBold, fontSize: 4.5),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'ហត្ថលេខា & ត្រា',
                    style: pw.TextStyle(
                      font: fontRegular,
                      fontSize: 3.8,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 3),
          pw.Divider(thickness: 0.4, color: PdfColors.grey300),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'BRIGHT LIGHT SCHOOL | 2025-2026',
                style: pw.TextStyle(
                  font: fontRegular,
                  fontSize: 4,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                code,
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 4,
                  color: PdfColors.grey800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _printIdCard({bool sheetA4 = true}) async {
    if (_selectedPerson == null) return;
    final assetBundle = DefaultAssetBundle.of(context);
    try {
      final nameKh = _selectedPerson!['name_kh'] ?? 'ឈ្មោះទូទៅ';
      final nameEn = _selectedPerson!['name_en'] ?? '';
      final code = _isStudent
          ? (_selectedPerson!['student_code'] ?? 'STU-001')
          : (_selectedPerson!['teacher_code'] ?? 'TCH-001');
      final role = _isStudent
          ? 'សិស្សពេញសិទ្ធ'
          : (_selectedPerson!['role_title'] ?? 'គ្រូបង្រៀន');
      final grade = _currentCategoryOrGrade;
      final phone = _currentPhone;

      final activeThemeMap = _themes.firstWhere(
        (t) => t['name'] == _themeColor,
        orElse: () => _themes.first,
      );
      final Color activeColor = activeThemeMap['color'] as Color;

      final isLandscape = _orientation == 'Landscape';

      // 1. Primary WYSIWYG: Capture pixel-perfect high-resolution design directly from the ID Studio screen!
      final frontKey = isLandscape ? _landscapeFrontKey : _portraitFrontKey;
      final backKey = isLandscape ? _landscapeBackKey : _portraitBackKey;
      Uint8List? frontBytes;
      Uint8List? backBytes;

      if (_cardSide == 'Front' || _cardSide == 'Both') {
        frontBytes = await _captureCardWidget(frontKey);
      }
      if (_cardSide == 'Back' || _cardSide == 'Both') {
        backBytes = await _captureCardWidget(backKey);
      }

      if (frontBytes != null || backBytes != null) {
        HtmlPrintService.printCapturedIdCards(
          frontPngBase64: frontBytes != null ? base64Encode(frontBytes) : null,
          backPngBase64: backBytes != null ? base64Encode(backBytes) : null,
          code: code,
          name: nameKh.isNotEmpty ? nameKh : nameEn,
          isLandscape: isLandscape,
          cardSide: _cardSide,
          sheetA4: sheetA4,
        );
        return;
      }

      String? photoUrlStr = (_selectedPerson!['photo_url'] ??
              _selectedPerson!['photo'] ??
              _selectedPerson!['avatar'] ??
              _selectedPerson!['image'] ??
              _selectedPerson!['image_url'])
          ?.toString()
          .trim();
      if (photoUrlStr != null && photoUrlStr.isNotEmpty) {
        if (photoUrlStr.startsWith('assets/')) {
          try {
            final byteData =
                // ignore: use_build_context_synchronously
                await assetBundle.load(photoUrlStr);
            final bytes = byteData.buffer.asUint8List();
            photoUrlStr = 'data:image/png;base64,${base64Encode(bytes)}';
          } catch (_) {}
        } else if (!photoUrlStr.startsWith('http') &&
            !photoUrlStr.startsWith('data:image')) {
          final origin = ApiService.baseUrl.replaceAll('/api', '');
          photoUrlStr =
              '$origin/${photoUrlStr.startsWith('/') ? photoUrlStr.substring(1) : photoUrlStr}';
        }
      }

      // Generate offline QR code base64
      String? qrBase64;
      try {
        final qrValidationResult = QrValidator.validate(
          data: code,
          version: QrVersions.auto,
          errorCorrectionLevel: QrErrorCorrectLevel.M,
        );
        if (qrValidationResult.status == QrValidationStatus.valid) {
          final painter = QrPainter.withQr(
            qr: qrValidationResult.qrCode!,
            // ignore: deprecated_member_use
            color: const Color(0xFF0F172A),
            // ignore: deprecated_member_use
            emptyColor: const Color(0xFFFFFFFF),
            gapless: true,
          );
          final picData = await painter.toImageData(
            200,
            format: ui.ImageByteFormat.png,
          );
          if (picData != null) {
            qrBase64 = base64Encode(picData.buffer.asUint8List());
          }
        }
      } catch (_) {}

      HtmlPrintService.printIdCard(
        nameKh: nameKh,
        nameEn: nameEn,
        code: code,
        role: role,
        grade: grade,
        phone: phone,
        dob: _currentDob,
        gender: _selectedPerson?['gender']?.toString(),
        photoUrl: photoUrlStr,
        qrBase64: qrBase64,
        isLandscape: isLandscape,
        cardSide: _cardSide,
        themeColorHex:
            // ignore: deprecated_member_use
            '#${activeColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
        academicYear: '2025-2026',
        sheetA4: sheetA4,
      );
      return;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('កំហុសក្នុងការបោះពុម្ពកាត៖ $e')));
      }
    }
  }

  // ignore: unused_element
  void _showPrintOptionsDialog() {
    if (_selectedPerson == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: const Icon(
                Icons.print_rounded,
                color: Color(0xFF4F46E5),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ជ្រើសរើសទម្រង់បោះពុម្ពកាត',
                    style: TextStyle(
                      fontFamily: 'Khmer OS Battambang',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'PRINT STUDIO PRODUCTION',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'សូមជ្រើសរើសប្រភេទប្លង់បោះពុម្ពសម្រាប់ ${_currentNameKh.isNotEmpty ? _currentNameKh : _currentNameEn} (ID: $_currentCode)៖',
                style: const TextStyle(
                  fontFamily: 'Khmer OS Battambang',
                  fontSize: 12,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 16),
              // Option 1: A4 Print Sheet (Recommended & matches photo)
              InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  _printIdCard(sheetA4: true);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.description_rounded,
                          color: Color(0xFF16A34A),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    '១. សន្លឹកក្រដាស A4 (Sheet Layout)',
                                    style: TextStyle(
                                      fontFamily: 'Khmer OS Battambang',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'ពេញនិយមបំផុត',
                                    style: TextStyle(
                                      fontFamily: 'Khmer OS Battambang',
                                      fontSize: 10,
                                      color: Color(0xFF15803D),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'ដាក់រូបកាតខាងមុខ និងខាងក្រោយទន្ទឹមគ្នាលើក្រដាស A4 • មានបន្ទាត់កាត់ (Crop Marks) និងងាយអ៊ុតប្លាស្ទិក (Laminate)',
                              style: TextStyle(
                                fontFamily: 'Khmer OS Battambang',
                                fontSize: 11,
                                color: Color(0xFF166534),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Option 2: Duplex CR-80 for PVC card printer
              InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  _printIdCard(sheetA4: false);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.credit_card_rounded,
                          color: Color(0xFF2563EB),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    '២. កាតស្តង់ដារ CR-80 (Duplex)',
                                    style: TextStyle(
                                      fontFamily: 'Khmer OS Battambang',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'សម្រាប់ម៉ាស៊ីន PVC',
                                    style: TextStyle(
                                      fontFamily: 'Khmer OS Battambang',
                                      fontSize: 10,
                                      color: Color(0xFF2563EB),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'ទំព័រទី១ ខាងមុខ, ទំព័រទី២ ខាងក្រោយ • បោះពុម្ពផ្ទាល់លើកាតផ្លាស្ទិក PVC ID Card',
                              style: TextStyle(
                                fontFamily: 'Khmer OS Battambang',
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'បោះបង់',
              style: TextStyle(
                fontFamily: 'Khmer OS Battambang',
                color: Color(0xFF64748B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopBanner(),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (ctx, constraints) {
                final isNarrow = constraints.maxWidth < 1040;
                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPreviewStage(),
                      const SizedBox(height: 20),
                      _buildMemberSelection(),
                      const SizedBox(height: 16),
                      _buildThemeAndStyling(),
                      const SizedBox(height: 16),
                      _buildProductionExport(),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 390,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildMemberSelection(),
                          const SizedBox(height: 16),
                          _buildThemeAndStyling(),
                          const SizedBox(height: 16),
                          _buildProductionExport(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(child: _buildPreviewStage()),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF334155).withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 16,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildBadge(
                      'PRO ID STUDIO',
                      Icons.auto_awesome_rounded,
                      const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      const Color(0xFF60A5FA),
                    ),
                    _buildBadge(
                      'ISO 7810 ID-1 Standard',
                      Icons.check_circle_rounded,
                      const Color(0xFF10B981).withValues(alpha: 0.15),
                      const Color(0xFF34D399),
                    ),
                    _buildBadge(
                      '300 DPI High-Res',
                      Icons.hd_rounded,
                      const Color(0xFFA855F7).withValues(alpha: 0.15),
                      const Color(0xFFC084FC),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.credit_card_rounded,
                        color: Color(0xFF60A5FA),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Flexible(
                      child: Text(
                        'ស្ទូឌីយោរចនាកាតសម្គាល់ខ្លួន • ID Card Studio',
                        style: TextStyle(
                          fontFamily: 'Khmer OS Battambang',
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'រចនាកាតសិស្ស និងគ្រូបង្រៀនកម្រិតអាជីព (300 DPI ID Cards) សម្រាប់ម៉ាស៊ីនបោះពុម្ព PVC ឬក្រដាស A4។',
                  style: TextStyle(
                    fontFamily: 'Khmer OS Battambang',
                    fontSize: 12.5,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildCountBox(
                'សិស្ស (Students)',
                _students.length.toString(),
                Icons.school_rounded,
                const Color(0xFF3B82F6),
              ),
              _buildCountBox(
                'គ្រូ (Teachers)',
                _teachers.length.toString(),
                Icons.badge_rounded,
                const Color(0xFF8B5CF6),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                onPressed: _showPrintOptionsDialog,
                icon: const Icon(Icons.print_rounded, size: 18),
                label: const Text(
                  'បោះពុម្ពភ្លាមៗ',
                  style: TextStyle(
                    fontFamily: 'Khmer OS Battambang',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, IconData icon, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 13),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountBox(
    String label,
    String count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.8),
        border: Border.all(color: const Color(0xFF334155)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Khmer OS Battambang',
                  fontSize: 10,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                count,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String step,
    required String titleKh,
    required String titleEn,
    required IconData icon,
    Color iconColor = const Color(0xFF3B82F6),
    bool isDark = false,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDark
                ? iconColor.withValues(alpha: 0.2)
                : iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark
                  ? iconColor.withValues(alpha: 0.35)
                  : iconColor.withValues(alpha: 0.2),
            ),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? iconColor.withValues(alpha: 0.2)
                          : iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      step,
                      style: TextStyle(
                        fontFamily: 'Khmer OS Battambang',
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF93C5FD) : iconColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      titleKh,
                      style: TextStyle(
                        fontFamily: 'Khmer OS Battambang',
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                titleEn.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        // ignore: use_null_aware_elements
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildPillTab({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Khmer OS Battambang',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberSelection() {
    final currentList = _filteredMemberList;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            step: '០១',
            titleKh: 'ជ្រើសរើសបុគ្គលិក ឬសិស្ស',
            titleEn: 'MEMBER SELECTION',
            icon: Icons.badge_outlined,
            iconColor: const Color(0xFF2563EB),
          ),
          const SizedBox(height: 18),

          // Segmented Switcher for Student / Teacher
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isStudent = true;
                        _searchCtrl.clear();
                        _searchQuery = '';
                        _selectedPerson = _students.isNotEmpty
                            ? _students.first
                            : null;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _isStudent ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _isStudent
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.school_rounded,
                            size: 16,
                            color: _isStudent
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'សិស្ស (Students)',
                            style: TextStyle(
                              fontFamily: 'Khmer OS Battambang',
                              fontSize: 11.5,
                              fontWeight: _isStudent
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: _isStudent
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: _isStudent
                                  ? const Color(0xFFEFF6FF)
                                  : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_students.length}',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: _isStudent
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isStudent = false;
                        _searchCtrl.clear();
                        _searchQuery = '';
                        _selectedPerson = _teachers.isNotEmpty
                            ? _teachers.first
                            : null;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !_isStudent ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: !_isStudent
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_rounded,
                            size: 16,
                            color: !_isStudent
                                ? const Color(0xFF4F46E5)
                                : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'គ្រូ (Teachers)',
                            style: TextStyle(
                              fontFamily: 'Khmer OS Battambang',
                              fontSize: 11.5,
                              fontWeight: !_isStudent
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: !_isStudent
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: !_isStudent
                                  ? const Color(0xFFEEF2FF)
                                  : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_teachers.length}',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: !_isStudent
                                    ? const Color(0xFF4F46E5)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Search Field
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) {
                setState(() {
                  _searchQuery = v;
                });
              },
              style: const TextStyle(
                fontFamily: 'Khmer OS Battambang',
                fontSize: 12,
                color: Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                border: InputBorder.none,
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
                hintText: _isStudent
                    ? 'ស្វែងរកឈ្មោះ ឬអត្តលេខសិស្ស...'
                    : 'ស្វែងរកឈ្មោះ ឬអត្តលេខគ្រូ...',
                hintStyle: const TextStyle(
                  fontFamily: 'Khmer OS Battambang',
                  fontSize: 11.5,
                  color: Color(0xFF94A3B8),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Color(0xFF94A3B8),
                        ),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Dropdown Selector
          Builder(
            builder: (_) {
              final personItems = <DropdownMenuItem<int>>[];
              final seenIds = <int>{};
              for (final p in currentList) {
                final id = p['id'] is int
                    ? p['id'] as int
                    : int.tryParse(p['id'].toString());
                if (id != null && seenIds.add(id)) {
                  final code = p['student_code'] ?? p['teacher_code'] ?? id;
                  personItems.add(
                    DropdownMenuItem<int>(
                      value: id,
                      child: Text(
                        '${p['name_kh']} (${p['name_en'] ?? ''}) • $code',
                        style: const TextStyle(
                          fontFamily: 'Khmer OS Battambang',
                          fontSize: 12,
                          color: Color(0xFF1E293B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }
              }

              final effectiveId =
                  (personItems.any((i) => i.value == _selectedPerson?['id']))
                  ? _selectedPerson!['id']
                  : (personItems.isNotEmpty ? personItems.first.value : null);

              if (effectiveId != null &&
                  (_selectedPerson == null ||
                      _selectedPerson!['id'] != effectiveId)) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _selectedPerson = currentList.firstWhere(
                        (p) => p['id'] == effectiveId,
                        orElse: () => currentList.first,
                      );
                    });
                  }
                });
              }

              if (personItems.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: Color(0xFF94A3B8),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'រកមិនឃើញទិន្នន័យត្រូវគ្នានឹងការស្វែងរក',
                          style: TextStyle(
                            fontFamily: 'Khmer OS Battambang',
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF64748B),
                    ),
                    value: effectiveId,
                    items: personItems,
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _selectedPerson = currentList.firstWhere(
                            (p) => p['id'] == v,
                            orElse: () => currentList.first,
                          );
                        });
                      }
                    },
                  ),
                ),
              );
            },
          ),

          // Selected Person Profile Card
          if (_selectedPerson != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildPersonPhotoWidget(
                    photoUrl: _selectedPerson!['photo_url'],
                    width: 50,
                    height: 50,
                    borderRadius: 10,
                    border: Border.all(
                      color: const Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${_selectedPerson!['name_kh']} (${_selectedPerson!['name_en'] ?? ''})',
                                style: const TextStyle(
                                  fontFamily: 'Khmer OS Battambang',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFBFDBFE),
                                ),
                              ),
                              child: Text(
                                _currentCode,
                                style: const TextStyle(
                                  color: Color(0xFF2563EB),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              _isStudent
                                  ? Icons.class_outlined
                                  : Icons.menu_book_outlined,
                              size: 13,
                              color: const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _isStudent
                                    ? 'ថ្នាក់: ${_selectedPerson!['class_name'] ?? _selectedPerson!['grade'] ?? _selectedPerson!['grade_level_name'] ?? 'ថ្នាក់ទី ៩A'}'
                                    : 'ជំនាញ: ${_selectedPerson!['role_title'] ?? _selectedPerson!['specialized_subject'] ?? _selectedPerson!['subjects'] ?? 'គ្រូបង្រៀន'}',
                                style: const TextStyle(
                                  fontFamily: 'Khmer OS Battambang',
                                  color: Color(0xFF475569),
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThemeAndStyling() {
    final activeThemeColor =
        _themes.firstWhere((t) => t['name'] == _themeColor)['color'] as Color;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            step: '០២',
            titleKh: 'ពណ៌ និងទម្រង់កាត',
            titleEn: 'THEME & STYLING',
            icon: Icons.palette_outlined,
            iconColor: const Color(0xFF0284C7),
          ),
          const SizedBox(height: 18),

          // Theme Color Palette
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ពណ៌ចម្បង / Color Palette',
                style: TextStyle(
                  fontFamily: 'Khmer OS Battambang',
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2.5,
                ),
                decoration: BoxDecoration(
                  color: activeThemeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: activeThemeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _themeColor,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: activeThemeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _themes.map((t) {
              final isSel = _themeColor == t['name'];
              final c = t['color'] as Color;
              return Tooltip(
                message: t['name'] as String,
                child: InkWell(
                  onTap: () =>
                      setState(() => _themeColor = t['name'] as String),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSel ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: isSel
                          ? [
                              BoxShadow(
                                color: c.withValues(alpha: 0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                    ),
                    child: isSel
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 20,
                          )
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),

          // Orientation & Card Side
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Orientation
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ទិសដៅ / Orientation',
                      style: TextStyle(
                        fontFamily: 'Khmer OS Battambang',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildPillTab(
                              label: 'បញ្ឈរ',
                              icon: Icons.stay_current_portrait_rounded,
                              isSelected: _orientation == 'Portrait',
                              onTap: () =>
                                  setState(() => _orientation = 'Portrait'),
                            ),
                          ),
                          Expanded(
                            child: _buildPillTab(
                              label: 'ផ្ដេក',
                              icon: Icons.stay_current_landscape_rounded,
                              isSelected: _orientation == 'Landscape',
                              onTap: () =>
                                  setState(() => _orientation = 'Landscape'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Card Side
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ផ្ទៃកាត / Card Side',
                      style: TextStyle(
                        fontFamily: 'Khmer OS Battambang',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildPillTab(
                              label: 'មុខ',
                              isSelected: _cardSide == 'Front',
                              onTap: () => setState(() => _cardSide = 'Front'),
                            ),
                          ),
                          Expanded(
                            child: _buildPillTab(
                              label: 'ក្រោយ',
                              isSelected: _cardSide == 'Back',
                              onTap: () => setState(() => _cardSide = 'Back'),
                            ),
                          ),
                          Expanded(
                            child: _buildPillTab(
                              label: 'ទាំងពីរ',
                              isSelected: _cardSide == 'Both',
                              onTap: () => setState(() => _cardSide = 'Both'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Background Pattern
          const Text(
            'ផ្ទៃខាងក្រោយ / Background Pattern',
            style: TextStyle(
              fontFamily: 'Khmer OS Battambang',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildPillTab(
                    label: 'ធម្មតា',
                    icon: Icons.crop_free_rounded,
                    isSelected: _bgPattern == 'Plain',
                    onTap: () => setState(() => _bgPattern = 'Plain'),
                  ),
                ),
                Expanded(
                  child: _buildPillTab(
                    label: 'ត្រាសាលា',
                    icon: Icons.verified_user_rounded,
                    isSelected: _bgPattern == 'Seal',
                    onTap: () => setState(() => _bgPattern = 'Seal'),
                  ),
                ),
                Expanded(
                  child: _buildPillTab(
                    label: 'រលក',
                    icon: Icons.waves_rounded,
                    isSelected: _bgPattern == 'Waves',
                    onTap: () => setState(() => _bgPattern = 'Waves'),
                  ),
                ),
                Expanded(
                  child: _buildPillTab(
                    label: 'ចំណុច',
                    icon: Icons.grain_rounded,
                    isSelected: _bgPattern == 'Dots',
                    onTap: () => setState(() => _bgPattern = 'Dots'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Gloss Feature (Interactive Switch Card)
          InkWell(
            onTap: () => setState(() => _hasGloss = !_hasGloss),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: _hasGloss
                    ? const Color(0xFFF5F3FF)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _hasGloss
                      ? const Color(0xFFC4B5FD)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: _hasGloss
                        ? const Color(0xFF7C3AED)
                        : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ពន្លឺរលោងលើកាត (Gloss Effect)',
                      style: TextStyle(
                        fontFamily: 'Khmer OS Battambang',
                        fontSize: 11,
                        fontWeight: _hasGloss
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _hasGloss
                            ? const Color(0xFF5B21B6)
                            : const Color(0xFF475569),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 22,
                    width: 36,
                    child: Switch(
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                      value: _hasGloss,
                      // ignore: deprecated_member_use
                      activeColor: const Color(0xFF7C3AED),
                      onChanged: (v) => setState(() => _hasGloss = v),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductionExport() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            step: '០៣',
            titleKh: 'ផលិតចេញជាកាត និងទាញយក',
            titleEn: 'PRODUCTION EXPORT',
            icon: Icons.print_rounded,
            iconColor: const Color(0xFF60A5FA),
            isDark: true,
          ),
          const SizedBox(height: 18),

          // Primary Hero Action: Print Studio
          InkWell(
            onTap: _showPrintOptionsDialog,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.print_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'បោះពុម្ពកាត • Print Studio',
                          style: TextStyle(
                            fontFamily: 'Khmer OS Battambang',
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'CR-80 Duplex ឬ សន្លឹកក្រដាស A4 Sheet (300 DPI)',
                          style: TextStyle(
                            fontFamily: 'Khmer OS Battambang',
                            fontSize: 10.5,
                            color: Color(0xFFBFDBFE),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white70,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Export Action Tiles Grid
          Row(
            children: [
              // PDF 300 DPI
              Expanded(
                child: InkWell(
                  onTap: _showPrintOptionsDialog,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFE11D48,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.picture_as_pdf_rounded,
                            color: Color(0xFFFB7185),
                            size: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'ទាញយក PDF',
                          style: TextStyle(
                            fontFamily: 'Khmer OS Battambang',
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '300 DPI',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // PNG HD
              Expanded(
                child: InkWell(
                  onTap: () {
                    _downloadCardPng();
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF059669,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.image_rounded,
                            color: Color(0xFF34D399),
                            size: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'ទាញយក PNG',
                          style: TextStyle(
                            fontFamily: 'Khmer OS Battambang',
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'រូបភាព HD',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // QR Code
              Expanded(
                child: InkWell(
                  onTap: _showQrCodeDialog,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF0284C7,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.qr_code_2_rounded,
                            color: Color(0xFF38BDF8),
                            size: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'កូដ QR',
                          style: TextStyle(
                            fontFamily: 'Khmer OS Battambang',
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'ស្កេនវត្តមាន',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewStage() {
    Color activeThemeColor =
        _themes.firstWhere((t) => t['name'] == _themeColor)['color'] as Color;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Studio Toolbar
          Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'STUDIO LIVE PREVIEW',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _orientation == 'Landscape'
                          ? 'CR-80 • 85.6 × 53.98 mm (Landscape)'
                          : 'CR-80 • 53.98 × 85.6 mm (Portrait)',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Fast side switcher right in preview toolbar
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMiniSideBtn(
                          'ទាំងពីរ',
                          _cardSide == 'Both',
                          () => setState(() => _cardSide = 'Both'),
                        ),
                        _buildMiniSideBtn(
                          'មុខ',
                          _cardSide == 'Front',
                          () => setState(() => _cardSide = 'Front'),
                        ),
                        _buildMiniSideBtn(
                          'ក្រោយ',
                          _cardSide == 'Back',
                          () => setState(() => _cardSide = 'Back'),
                        ),
                      ],
                    ),
                  ),
                  // Zoom scale controls
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_rounded, size: 14),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          onPressed: _previewScale > 0.6
                              ? () => setState(() => _previewScale -= 0.1)
                              : null,
                        ),
                        Text(
                          '${(_previewScale * 100).round()}%',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF334155),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_rounded, size: 14),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          onPressed: _previewScale < 1.4
                              ? () => setState(() => _previewScale += 0.1)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  // Theme color chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: activeThemeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: activeThemeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _themeColor,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: activeThemeColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Studio Canvas Area
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Center(
              child: Transform.scale(
                scale: _previewScale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_orientation == 'Landscape') ...[
                      if (_cardSide == 'Front' || _cardSide == 'Both') ...[
                        _buildSideLabel(
                          'ខាងមុខ • FRONT CARD',
                          activeThemeColor,
                        ),
                        const SizedBox(height: 10),
                        _buildLandscapeFront(activeThemeColor),
                      ],
                      if (_cardSide == 'Both') const SizedBox(height: 32),
                      if (_cardSide == 'Back' || _cardSide == 'Both') ...[
                        _buildSideLabel(
                          'ខាងក្រោយ • BACK CARD',
                          activeThemeColor,
                        ),
                        const SizedBox(height: 10),
                        _buildLandscapeBack(activeThemeColor),
                      ],
                    ] else ...[
                      if (_cardSide == 'Front' || _cardSide == 'Both') ...[
                        _buildSideLabel(
                          'ខាងមុខ • FRONT CARD',
                          activeThemeColor,
                        ),
                        const SizedBox(height: 10),
                        _buildPortraitFront(activeThemeColor),
                      ],
                      if (_cardSide == 'Both') const SizedBox(height: 32),
                      if (_cardSide == 'Back' || _cardSide == 'Both') ...[
                        _buildSideLabel(
                          'ខាងក្រោយ • BACK CARD',
                          activeThemeColor,
                        ),
                        const SizedBox(height: 10),
                        _buildPortraitBack(activeThemeColor),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Studio Footer
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildStudioFooterTag(
                'ស្តង់ដារ CR-80 High Definition',
                Icons.verified_rounded,
              ),
              _buildStudioFooterTag(
                'ISO/IEC 7810 ID-1 Standard',
                Icons.check_circle_outline_rounded,
              ),
              _buildStudioFooterTag(
                '300 DPI Ultra Clarity',
                Icons.print_rounded,
              ),
              _buildStudioFooterTag(
                'Bright Light Official Studio',
                Icons.school_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniSideBtn(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Khmer OS Battambang',
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? const Color(0xFF2563EB)
                : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildSideLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF475569),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildStudioFooterTag(String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Khmer OS Battambang',
            fontSize: 10.5,
            color: Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeFront(Color themeColor) {
    final code = _currentCode;
    final nameKh = _currentNameKh;
    final nameEn = _currentNameEn;
    final role = _currentRole;
    final detailField = _currentCategoryOrGrade;
    final phone = _currentPhone;
    final dob = _currentDob;

    return Container(
      width: 430,
      height: 270,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          // ignore: deprecated_member_use
          color: themeColor.withOpacity(0.4),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: const Color(0xFF0F172A).withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Background Pattern
            _buildCardBackgroundPattern(_bgPattern, themeColor, true),

            // Left Accent Panel
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 140,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      themeColor,
                      Color.lerp(themeColor, const Color(0xFF0F172A), 0.3)!,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(24),
                    bottomRight: Radius.circular(55),
                  ),
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(2, 0),
                    ),
                  ],
                ),
              ),
            ),

            // Lanyard Slot
            if (_hasLanyard)
              _buildLanyardSlot(
                width: 32,
                height: 7,
                top: 8,
                left: (140 - 32) / 2,
              ),

            // Left Side: Photo + Role Pill + Code (ALL WHITE/LIGHT ELEMENTS, HIGH CONTRAST!)
            Positioned(
              left: 0,
              top: _hasLanyard ? 22 : 16,
              width: 140,
              bottom: 12,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          // ignore: deprecated_member_use
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _buildPersonPhotoWidget(
                      photoUrl: _selectedPerson?['photo_url'],
                      width: 82,
                      height: 100,
                      borderRadius: 8,
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          // ignore: deprecated_member_use
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      _isStudent ? 'សិស្ស • STUDENT' : 'គ្រូ • TEACHER',
                      style: GoogleFonts.notoSansKhmer(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    code,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),

            // Right Side: Branding, Names, Metadata Grid, QR Code
            Positioned(
              left: 152,
              right: 16,
              top: 14,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // School Banner Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            // ignore: deprecated_member_use
                            color: themeColor.withOpacity(0.4),
                          ),
                        ),
                        child: AppLogo.widget(
                          width: 24,
                          height: 24,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'សាលាប្រាយ ឡាយ',
                              style: const TextStyle(
                                fontFamily: 'Khmer OS Battambang',
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                            Text(
                              'BRIGHT LIGHT SCHOOL',
                              style: GoogleFonts.outfit(
                                fontSize: 7.2,
                                fontWeight: FontWeight.w800,
                                color: themeColor,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          // ignore: deprecated_member_use
                          color: themeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '2024-2025',
                          style: GoogleFonts.outfit(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: themeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Divider(
                    height: 1,
                    // ignore: deprecated_member_use
                    color: themeColor.withOpacity(0.2),
                  ),
                  const SizedBox(height: 8),

                  // Name Area
                  Text(
                    nameEn.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (nameKh.isNotEmpty)
                    Text(
                      nameKh,
                      style: const TextStyle(
                        fontFamily: 'Khmer OS Battambang',
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),

                  // Structured Details Card Container (Clean, organized, professional)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLandscapeField(
                                label: 'ID',
                                value: code,
                                isHighlight: true,
                                color: themeColor,
                              ),
                              const SizedBox(height: 5),
                              _buildLandscapeField(
                                label: _isStudent ? 'Class' : 'Subj',
                                value: detailField,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLandscapeField(
                                label: _isStudent ? 'DOB' : 'Role',
                                value: _isStudent ? dob : role,
                              ),
                              const SizedBox(height: 5),
                              _buildLandscapeField(label: 'Tel', value: phone),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),

                  // Bottom Line: Security Microtext + Real Scannable QR Code
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            size: 10,
                            color: themeColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'OFFICIAL ID • BRIGHT LIGHT SCHOOL • CR-80',
                            style: GoogleFonts.outfit(
                              fontSize: 6.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF64748B),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: const Color(0xFFCBD5E1),
                            width: 0.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: code.isNotEmpty ? code : 'BLS-104002',
                          version: QrVersions.auto,
                          size: 32,
                          padding: EdgeInsets.zero,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF0F172A),
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_hasGloss) _buildGlossSheen(),
          ],
        ),
      ),
    );
  }

  Widget _buildLandscapeBack(Color themeColor) {
    return Container(
      width: 430,
      height: 270,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          // ignore: deprecated_member_use
          color: themeColor.withOpacity(0.4),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: const Color(0xFF0F172A).withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Background Pattern
            _buildCardBackgroundPattern(_bgPattern, themeColor, true),

            // Top Magnetic Stripe
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 28,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF0F172A),
                      Color(0xFF334155),
                      Color(0xFF0F172A),
                    ],
                  ),
                ),
              ),
            ),

            // Lanyard Slot
            if (_hasLanyard)
              _buildLanyardSlot(
                width: 32,
                height: 7,
                top: 34,
                left: (430 - 32) / 2,
              ),

            // Main Back Content
            Positioned(
              top: _hasLanyard ? 48 : 36,
              left: 18,
              right: 18,
              bottom: 12,
              child: Column(
                children: [
                  // School Branding Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppLogo.widget(
                        width: 22,
                        height: 22,
                        shape: BoxShape.circle,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'សាលាប្រាយ ឡាយ • BRIGHT LIGHT SCHOOL',
                        style: TextStyle(
                          fontFamily: 'Khmer OS Battambang',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Content Body: Rules on Left, Signature & Contacts on Right
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Rules Box
                        Expanded(
                          flex: 5,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Text(
                                    '• វិន័យ និងបទបញ្ជាផ្ទៃក្នុង •',
                                    style: TextStyle(
                                      fontFamily: 'Khmer OS Battambang',
                                      fontSize: 8.8,
                                      fontWeight: FontWeight.bold,
                                      color: themeColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                _buildRuleItem(
                                  '១. ត្រូវពាក់ប័ណ្ណនេះជាប់ខ្លួនជានិច្ចពេលនៅក្នុងសាលា។',
                                ),
                                _buildRuleItem(
                                  '២. ហាមកែប្រែ ក្លែងបន្លំ ឬប្រគល់ឱ្យអ្នកដទៃប្រើប្រាស់។',
                                ),
                                _buildRuleItem(
                                  '៣. ករណីបាត់បង់ សូមរាយការណ៍មកការិយាល័យជាបន្ទាន់។',
                                ),
                                _buildRuleItem(
                                  '៤. ប័ណ្ណនេះជាសម្បត្តិផ្លូវការរបស់សាលាប្រាយ ឡាយ។',
                                ),
                                const Spacer(),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: themeColor.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'DISCIPLINE • RESPECT • INTEGRITY • EXCELLENCE',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      fontSize: 6.8,
                                      fontWeight: FontWeight.w800,
                                      color: themeColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Right: Signatures & Address
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ទូរស័ព្ទទំនាក់ទំនង (Hotline):',
                                style: TextStyle(
                                  fontFamily: 'Khmer OS Battambang',
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: themeColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '078 350 908 / 088 757 4732',
                                style: GoogleFonts.outfit(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'អាសយដ្ឋាន៖ រាជធានីភ្នំពេញ, កម្ពុជា',
                                style: TextStyle(
                                  fontFamily: 'Khmer OS Battambang',
                                  fontSize: 7.5,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const Spacer(),
                              Center(
                                child: Column(
                                  children: [
                                    Text(
                                      'នាយកសាលា / Principal',
                                      style: GoogleFonts.outfit(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF334155),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF2F2),
                                        borderRadius: BorderRadius.circular(3),
                                        border: Border.all(
                                          color: const Color(0xFFFCA5A5),
                                          width: 0.6,
                                        ),
                                      ),
                                      child: const Text(
                                        'ត្រា & ហត្ថលេខាផ្លូវការ',
                                        style: TextStyle(
                                          fontFamily: 'Khmer OS Battambang',
                                          fontSize: 6.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFDC2626),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Container(
                                      width: 90,
                                      height: 1,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'ហត្ថលេខា & ត្រា (Seal)',
                                      style: TextStyle(
                                        fontFamily: 'Khmer OS Battambang',
                                        fontSize: 6.5,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 3.5),
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: themeColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Center(
                      child: Text(
                        'បើបានរើស សូមប្រគល់ជូនសាលាវិញ (If found, please return to Bright Light School)',
                        style: TextStyle(
                          fontFamily: 'Khmer OS Battambang',
                          fontSize: 6.8,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_hasGloss) _buildGlossSheen(),
          ],
        ),
      ),
    );
  }

  Widget _buildPortraitFront(Color themeColor) {
    final code = _currentCode;
    final nameKh = _currentNameKh;
    final nameEn = _currentNameEn;
    final role = _currentRole;
    final detailField = _currentCategoryOrGrade;
    final phone = _currentPhone;
    final dob = _currentDob;

    return Container(
      width: 270,
      height: 430,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          // ignore: deprecated_member_use
          color: themeColor.withOpacity(0.4),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: const Color(0xFF0F172A).withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            // ignore: deprecated_member_use
            color: themeColor.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Background Pattern
            _buildCardBackgroundPattern(_bgPattern, themeColor, false),

            // Top Header Gradient Arc
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 160,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      themeColor,
                      Color.lerp(themeColor, const Color(0xFF0F172A), 0.3)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(85),
                    bottomRight: Radius.circular(85),
                  ),
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),

            // Gold/Silver accent stripe at the arc edge
            Positioned(
              left: 30,
              right: 30,
              top: 157,
              height: 2.5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.amber.shade300,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Lanyard Slot
            if (_hasLanyard)
              _buildLanyardSlot(
                width: 32,
                height: 7,
                top: 8,
                left: (270 - 32) / 2,
              ),

            // Top Header Content: Logo & School Name
            Positioned(
              top: _hasLanyard ? 22 : 14,
              left: 14,
              right: 14,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              // ignore: deprecated_member_use
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: AppLogo.widget(
                          width: 26,
                          height: 26,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'សាលាប្រាយ ឡាយ',
                            style: TextStyle(
                              fontFamily: 'Khmer OS Battambang',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'BRIGHT LIGHT SCHOOL',
                            style: GoogleFonts.outfit(
                              fontSize: 7.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withValues(alpha: 0.95),
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white38, width: 0.8),
                    ),
                    child: Text(
                      _isStudent
                          ? 'STUDENT\'S IDENTITY CARD'
                          : 'TEACHER\'S IDENTITY CARD',
                      style: GoogleFonts.outfit(
                        fontSize: 6.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Body Content
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Member Photo
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              // ignore: deprecated_member_use
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _buildPersonPhotoWidget(
                          photoUrl: _selectedPerson?['photo_url'],
                          width: 84,
                          height: 104,
                          borderRadius: 10,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Role pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: _isStudent
                            ? const Color(0xFFEFF6FF)
                            : const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          // ignore: deprecated_member_use
                          color: themeColor.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        role,
                        style: GoogleFonts.notoSansKhmer(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Names
                    Text(
                      nameEn.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        letterSpacing: 0.6,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (nameKh.isNotEmpty)
                      Text(
                        nameKh,
                        style: const TextStyle(
                          fontFamily: 'Khmer OS Battambang',
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334155),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 10),

                    // Metadata Box
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            icon: Icons.badge_outlined,
                            label: 'ID',
                            value: code,
                            isBold: true,
                            valueColor: themeColor,
                          ),
                          const SizedBox(height: 4),
                          _buildDetailRow(
                            icon: _isStudent
                                ? Icons.school_outlined
                                : Icons.menu_book_outlined,
                            label: _isStudent ? 'Class' : 'Subj',
                            value: detailField,
                          ),
                          const SizedBox(height: 4),
                          _buildDetailRow(
                            icon: _isStudent
                                ? Icons.cake_outlined
                                : Icons.work_outline,
                            label: _isStudent ? 'DOB' : 'Role',
                            value: _isStudent ? dob : role,
                          ),
                          const SizedBox(height: 4),
                          _buildDetailRow(
                            icon: Icons.phone_outlined,
                            label: 'Tel',
                            value: phone,
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Card Footer: Security Bar & QR Code
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BRIGHT LIGHT SCHOOL',
                                style: GoogleFonts.outfit(
                                  fontSize: 6.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1E293B),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'ACADEMIC YEAR 2024-2025',
                                style: GoogleFonts.outfit(
                                  fontSize: 5.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                'OFFICIAL ID: $code',
                                style: GoogleFonts.outfit(
                                  fontSize: 5.5,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                                width: 0.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: QrImageView(
                              data: code.isNotEmpty ? code : 'BLS-104002',
                              version: QrVersions.auto,
                              size: 32,
                              padding: EdgeInsets.zero,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Color(0xFF0F172A),
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_hasGloss) _buildGlossSheen(),
          ],
        ),
      ),
    );
  }

  Widget _buildPortraitBack(Color themeColor) {
    return Container(
      width: 270,
      height: 430,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          // ignore: deprecated_member_use
          color: themeColor.withOpacity(0.4),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: const Color(0xFF0F172A).withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Background Pattern
            _buildCardBackgroundPattern(_bgPattern, themeColor, false),

            // Top Magnetic Stripe
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 28,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF0F172A),
                      Color(0xFF334155),
                      Color(0xFF0F172A),
                    ],
                  ),
                ),
              ),
            ),

            // Lanyard Slot
            if (_hasLanyard)
              _buildLanyardSlot(
                width: 32,
                height: 7,
                top: 36,
                left: (270 - 32) / 2,
              ),

            // Main Back Content
            Positioned(
              top: _hasLanyard ? 52 : 36,
              left: 14,
              right: 14,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // School Branding
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppLogo.widget(
                        width: 20,
                        height: 20,
                        shape: BoxShape.circle,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'សាលាប្រាយ ឡាយ • BRIGHT LIGHT SCHOOL',
                        style: TextStyle(
                          fontFamily: 'Khmer OS Battambang',
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Rules & Terms Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            '• វិន័យ និងបទបញ្ជាផ្ទៃក្នុង •',
                            style: TextStyle(
                              fontFamily: 'Khmer OS Battambang',
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: themeColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildRuleItem(
                          '១. ត្រូវពាក់ប័ណ្ណនេះជាប់ខ្លួនជានិច្ចពេលនៅក្នុងសាលា។',
                        ),
                        _buildRuleItem(
                          '២. ហាមកែប្រែ ក្លែងបន្លំ ឬប្រគល់ឱ្យអ្នកដទៃប្រើប្រាស់។',
                        ),
                        _buildRuleItem(
                          '៣. ករណីបាត់បង់ សូមរាយការណ៍មកការិយាល័យជាបន្ទាន់។',
                        ),
                        _buildRuleItem(
                          '៤. ប័ណ្ណនេះជាសម្បត្តិផ្លូវការរបស់សាលាប្រាយ ឡាយ។',
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              // ignore: deprecated_member_use
                              color: themeColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'DISCIPLINE • RESPECT • INTEGRITY • EXCELLENCE',
                              style: GoogleFonts.outfit(
                                fontSize: 6.5,
                                fontWeight: FontWeight.bold,
                                color: themeColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Principal Signature Area & Contacts
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ទូរស័ព្ទទំនាក់ទំនង (Hotline):',
                            style: TextStyle(
                              fontFamily: 'Khmer OS Battambang',
                              fontSize: 7.5,
                              fontWeight: FontWeight.bold,
                              color: themeColor,
                            ),
                          ),
                          Text(
                            '078 350 908 / 088 757 4732',
                            style: GoogleFonts.outfit(
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'អាសយដ្ឋាន៖ រាជធានីភ្នំពេញ, កម្ពុជា',
                            style: TextStyle(
                              fontFamily: 'Khmer OS Battambang',
                              fontSize: 7,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            'នាយកសាលា / Principal',
                            style: GoogleFonts.outfit(
                              fontSize: 7.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: const Color(0xFFFCA5A5),
                                width: 0.6,
                              ),
                            ),
                            child: const Text(
                              'ត្រា & ហត្ថលេខាផ្លូវការ',
                              style: TextStyle(
                                fontFamily: 'Khmer OS Battambang',
                                fontSize: 6.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            width: 80,
                            height: 1,
                            color: const Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'ហត្ថលេខា & ត្រា (Seal)',
                            style: TextStyle(
                              fontFamily: 'Khmer OS Battambang',
                              fontSize: 6.5,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: themeColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Center(
                      child: Text(
                        'បើបានរើស សូមប្រគល់ជូនសាលាវិញ (If found, please return to Bright Light School)',
                        style: TextStyle(
                          fontFamily: 'Khmer OS Battambang',
                          fontSize: 6.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_hasGloss) _buildGlossSheen(),
          ],
        ),
      ),
    );
  }

  Widget _buildGlossSheen() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              // ignore: deprecated_member_use
              Colors.white.withOpacity(0.4),
              // ignore: deprecated_member_use
              Colors.white.withOpacity(0.0),
              // ignore: deprecated_member_use
              Colors.white.withOpacity(0.0),
              // ignore: deprecated_member_use
              Colors.white.withOpacity(0.1),
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
      ),
    );
  }
}

class _CardWavesPainter extends CustomPainter {
  final Color color;
  _CardWavesPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 6; i++) {
      final path = Path();
      final yOffset = size.height * (0.15 + i * 0.14);
      path.moveTo(0, yOffset);
      path.quadraticBezierTo(
        size.width * 0.25,
        yOffset - 16,
        size.width * 0.5,
        yOffset,
      );
      path.quadraticBezierTo(
        size.width * 0.75,
        yOffset + 16,
        size.width,
        yOffset,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CardWavesPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _CardDotsPainter extends CustomPainter {
  final Color color;
  _CardDotsPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const spacing = 14.0;
    for (double x = 8; x < size.width; x += spacing) {
      for (double y = 8; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.9, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CardDotsPainter oldDelegate) =>
      oldDelegate.color != color;
}
