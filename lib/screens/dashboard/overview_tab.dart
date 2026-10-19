import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:school_management_app/services/api_service.dart';
import 'package:school_management_app/services/html_print_service.dart';
import 'package:school_management_app/utils/app_logo.dart';
import 'package:school_management_app/utils/app_theme.dart';
import 'package:school_management_app/utils/pdf_font_helper.dart';

class OverviewTab extends StatefulWidget {
  final Function(int menuIndex, {int? subTab, bool? openAdd})? onNavigate;
  final bool isAdmin;

  const OverviewTab({
    super.key,
    this.onNavigate,
    this.isAdmin = true,
  });

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab>
    with SingleTickerProviderStateMixin {
  static String baseUrl = ApiService.baseUrl;

  bool _isLoading = true;
  bool _isRefreshing = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Chart view toggle: 0 = Bar Chart, 1 = Line Chart
  int _chartTypeIndex = 0;

  Map<String, dynamic> _stats = {
    'totalStudents': 0,
    'fullTimeStudents': 0,
    'partTimeStudents': 0,
    'activeStudents': 0,
    'totalTeachers': 0,
    'activeTeachers': 0,
    'totalClassrooms': 0,
    'fullTimeRooms': 0,
    'partTimeRooms': 0,
    'todayAttendance': 0,
    'todayAbsent': 0,
    'attendanceRate': '0.0',
    'absentCount': 0,
    'avgAttendance': '95.0',
    'avgAbsent': '5.0',
    'monthRevenue': 0,
  };

  List<dynamic> _trends = [];
  List<dynamic> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _loadDashboardData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    if (mounted) setState(() => _isRefreshing = true);

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final results = await Future.wait([
        http.get(Uri.parse('$baseUrl/dashboard/stats?_t=$now')).timeout(const Duration(seconds: 5)),
        http.get(Uri.parse('$baseUrl/dashboard/attendance-trends?_t=$now')).timeout(const Duration(seconds: 5)),
        http.get(Uri.parse('$baseUrl/dashboard/recent-activity?_t=$now')).timeout(const Duration(seconds: 5)),
      ]);
      final resStats = results[0];
      final resTrends = results[1];
      final resActs = results[2];

      if (resStats.statusCode == 200) {
        final d = jsonDecode(
          utf8.decode(resStats.bodyBytes, allowMalformed: true),
        );
        if (d['success'] == true && d['data'] != null) {
          final raw = d['data'] as Map<String, dynamic>;
          int tStudents =
              int.tryParse(raw['totalStudents']?.toString() ?? '0') ?? 0;
          int tTeachers =
              int.tryParse(raw['totalTeachers']?.toString() ?? '0') ?? 0;
          int tRooms =
              int.tryParse(raw['totalClassrooms']?.toString() ?? '0') ?? 0;
          int tAtt =
              int.tryParse(raw['todayAttendance']?.toString() ?? '0') ?? 0;
          int ftStudents =
              int.tryParse(raw['fullTimeStudents']?.toString() ?? '') ??
              tStudents;
          int ptStudents =
              int.tryParse(raw['partTimeStudents']?.toString() ?? '') ??
              (tStudents - ftStudents);
          int actTeachers =
              int.tryParse(raw['activeTeachers']?.toString() ?? '') ??
              tTeachers;
          int ftRooms =
              int.tryParse(raw['fullTimeRooms']?.toString() ?? '') ??
              (tRooms > 0 ? (tRooms ~/ 2 + 1) : 0);
          int ptRooms =
              int.tryParse(raw['partTimeRooms']?.toString() ?? '') ??
              (tRooms - ftRooms);

          String rateStr = raw['attendanceRate']?.toString() ?? '0.0';
          if ((rateStr == '0.0' || rateStr.isEmpty) &&
              tStudents > 0 &&
              tAtt > 0) {
            rateStr = ((tAtt / tStudents) * 100).toStringAsFixed(1);
          }

          int absCount =
              int.tryParse(raw['absentCount']?.toString() ?? '') ??
              (tStudents > tAtt ? tStudents - tAtt : 0);

          if (mounted) {
            setState(() {
              _stats = {
                'totalStudents': tStudents,
                'fullTimeStudents': max(ftStudents, 0),
                'partTimeStudents': max(ptStudents, 0),
                'activeStudents': tStudents,
                'totalTeachers': tTeachers,
                'activeTeachers': actTeachers,
                'totalClassrooms': tRooms,
                'fullTimeRooms': max(ftRooms, 0),
                'partTimeRooms': max(ptRooms, 0),
                'todayAttendance': tAtt,
                'todayAbsent': absCount,
                'attendanceRate': rateStr,
                'absentCount': absCount,
                'avgAttendance':
                    raw['avgAttendance']?.toString() ??
                    (double.tryParse(rateStr) != null &&
                            double.parse(rateStr) > 0
                        ? rateStr
                        : '96.5'),
                'avgAbsent': raw['avgAbsent']?.toString() ?? '3.5',
                'monthRevenue': raw['monthRevenue'] ?? 0,
              };
            });
          }
        }
      }

      if (resTrends.statusCode == 200) {
        final d = jsonDecode(
          utf8.decode(resTrends.bodyBytes, allowMalformed: true),
        );
        final list = (d['trends'] ?? d['data']) as List<dynamic>?;
        if (list != null && mounted) {
          setState(() => _trends = list);
        }
      }

      if (resActs.statusCode == 200) {
        final d = jsonDecode(
          utf8.decode(resActs.bodyBytes, allowMalformed: true),
        );
        final list = (d['activities'] ?? d['data']) as List<dynamic>?;
        if (list != null && mounted) {
          setState(() => _recentActivities = list);
        }
      }
    } catch (_) {
      // Fallback gracefully without breaking UI
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
        _fadeController.forward(from: 0.0);
      }
    }
  }

  Future<void> _generateFullReportPDF() async {
    if (kIsWeb) {
      HtmlPrintService.printDashboardOverviewReport(
        stats: _stats,
        trends: _trends,
      );
      return;
    }

    final pdf = pw.Document();
    final fontBold = await PdfFontHelper.getBoldFont();
    final fontRegular = await PdfFontHelper.getRegularFont();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
          fontFallback: [fontRegular, fontBold],
        ),
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Image(AppLogo.pdfImage, width: 44, height: 44),
                    pw.SizedBox(width: 12),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'សាលាប្រាយឡាយ',
                          style: pw.TextStyle(
                            fontSize: 20,
                            font: fontBold,
                            color: const PdfColor.fromInt(0xFF0F172A),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Bright Light School - Dashboard Overview Report',
                          style: pw.TextStyle(
                            font: fontRegular,
                            fontSize: 11,
                            color: const PdfColor.fromInt(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFFEEF2FF),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(
                    'កាលបរិច្ឆេទ: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      font: fontBold,
                      color: const PdfColor.fromInt(0xFF4F46E5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            '១. ស្ថិតិទូទៅប្រចាំសាលា (Key Performance Metrics)',
            style: pw.TextStyle(
              fontSize: 14,
              font: fontBold,
              color: const PdfColor.fromInt(0xFF1E293B),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: [
              'ប្រភេទស្ថិតិ (Metric)',
              'ចំនួនសរុប (Total)',
              'ព័ត៌មានលម្អិត (Details)',
              'ស្ថានភាព (Status)',
            ],
            headerStyle: pw.TextStyle(
              font: fontBold,
              color: PdfColors.white,
              fontSize: 11,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF4F46E5),
            ),
            cellStyle: pw.TextStyle(font: fontRegular, fontSize: 10),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            data: [
              [
                'សិស្សសរុប (Students)',
                '${_stats['totalStudents']} នាក់',
                'ពេញម៉ោង: ${_stats['fullTimeStudents']} | ក្រៅម៉ោង: ${_stats['partTimeStudents']}',
                'សកម្ម (Active)',
              ],
              [
                'គ្រូបង្រៀន (Teachers)',
                '${_stats['totalTeachers']} នាក់',
                'សកម្ម: ${_stats['activeTeachers']} នាក់',
                'ពេញសិទ្ធិ',
              ],
              [
                'បន្ទប់រៀន (Classrooms)',
                '${_stats['totalClassrooms']} បន្ទប់',
                'វេនព្រឹក: ${_stats['fullTimeRooms']} | វេនរសៀល: ${_stats['partTimeRooms']}',
                'ដំណើរការ',
              ],
              [
                'វត្តមានថ្ងៃនេះ (Today Attendance)',
                '${_stats['todayAttendance']} នាក់',
                'អត្រាវត្តមាន: ${_stats['attendanceRate']}%',
                'អវត្តមាន: ${_stats['absentCount']} នាក់',
              ],
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            '២. និន្នាការវត្តមាន ៧ ថ្ងៃចុងក្រោយ (Weekly Attendance Trends)',
            style: pw.TextStyle(
              fontSize: 14,
              font: fontBold,
              color: const PdfColor.fromInt(0xFF1E293B),
            ),
          ),
          pw.SizedBox(height: 12),
          _trends.isEmpty
              ? pw.Text(
                  'មិនទាន់មានទិន្នន័យនិន្នាការវត្តមានប្រចាំសប្តាហ៍ទេ',
                  style: pw.TextStyle(font: fontRegular, fontSize: 11),
                )
              : pw.TableHelper.fromTextArray(
                  headers: [
                    'កាលបរិច្ឆេទ (Date)',
                    'សិស្សមានវត្តមាន (Students)',
                    'គ្រូមានវត្តមាន (Teachers)',
                    'ស្ថានភាព',
                  ],
                  headerStyle: pw.TextStyle(
                    font: fontBold,
                    color: PdfColors.white,
                    fontSize: 10,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF0D9488),
                  ),
                  cellStyle: pw.TextStyle(font: fontRegular, fontSize: 10),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellPadding: const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  data: _trends.map((t) {
                    final dStr = t['date']?.toString() ?? '-';
                    final sCount =
                        t['presentCount'] ?? t['presentStudents'] ?? 0;
                    final tCount = t['presentTeachers'] ?? 0;
                    return [dStr, '$sCount នាក់', '$tCount នាក់', 'បានកត់ត្រា'];
                  }).toList(),
                ),
          pw.SizedBox(height: 40),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'អ្នករៀបចំរបាយការណ៍',
                    style: pw.TextStyle(font: fontBold, fontSize: 10),
                  ),
                  pw.SizedBox(height: 40),
                  pw.Text(
                    '(..................................................)',
                    style: pw.TextStyle(font: fontRegular, fontSize: 10),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'នាយកសាលា / គណៈគ្រប់គ្រង',
                    style: pw.TextStyle(font: fontBold, fontSize: 10),
                  ),
                  pw.SizedBox(height: 40),
                  pw.Text(
                    '(..................................................)',
                    style: pw.TextStyle(font: fontRegular, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (fmt) async => pdf.save(),
      name: 'bls_school_overview_report.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: AppTheme.primary,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: LayoutBuilder(
                  builder: (ctx, screenConstraints) {
                    if (screenConstraints.maxWidth <= 50 || screenConstraints.maxHeight <= 50) {
                      return const SizedBox.shrink();
                    }
                    final hPad = screenConstraints.maxWidth < 600
                        ? 16.0
                        : (screenConstraints.maxWidth < 1100 ? 24.0 : 32.0);
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: hPad,
                        vertical: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Enterprise Top Header
                          _buildHeader(),
                          const SizedBox(height: 28),

                          // 2. Modern 4 KPI Cards
                          _buildKPICards(),
                          const SizedBox(height: 28),

                          // 3. Quick Action Hub
                          _buildQuickActionsBar(),
                          const SizedBox(height: 28),

                          // 4. Responsive 2-Column Analytics & Live Feed
                          LayoutBuilder(
                            builder: (ctx, constraints) {
                              final isDesktop = constraints.maxWidth > 1000;
                              return isDesktop
                                  ? Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 7,
                                          child: Column(
                                            children: [
                                              _buildAttendanceChartCard(),
                                              const SizedBox(height: 24),
                                              _buildEnrollmentDistributionCard(),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 24),
                                        Expanded(
                                          flex: 4,
                                          child: _buildLiveFeedCard(),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        _buildAttendanceChartCard(),
                                        const SizedBox(height: 24),
                                        _buildEnrollmentDistributionCard(),
                                        const SizedBox(height: 24),
                                        _buildLiveFeedCard(),
                                      ],
                                    );
                            },
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }

  // ─── Header Section ───
  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 960;
        final isMobile = constraints.maxWidth < 550;

        final titleWidget = Row(
          children: [
            AppLogo.widget(
              width: isMobile ? 44 : 52,
              height: isMobile ? 44 : 52,
              shape: BoxShape.circle,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      Text(
                        'ផ្ទាំងគ្រប់គ្រងទូទៅ',
                        style: AppTheme.khmerHeading(
                          fontSize: isMobile ? 20 : 24,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Row(
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
                            const SizedBox(width: 6),
                            Text(
                              'ប្រព័ន្ធសកម្ម (Live)',
                              style: AppTheme.khmerBody(
                                color: const Color(0xFF065F46),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ទិដ្ឋភាពរួមនៃប្រព័ន្ធគ្រប់គ្រងសាលាប្រាយឡាយ (Bright Light School)',
                    style: AppTheme.khmerBody(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );

        final actionButtons = Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _generateFullReportPDF,
              icon: const Icon(
                Icons.picture_as_pdf_rounded,
                color: Color(0xFFEF4444),
                size: 18,
              ),
              label: Text(
                'ទាញយករបាយការណ៍ (PDF)',
                style: AppTheme.khmerBody(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isRefreshing ? null : _loadDashboardData,
              icon: _isRefreshing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                _isRefreshing ? 'កំពុងផ្ទុក...' : 'ផ្ទុកទិន្នន័យឡើងវិញ (Refresh)',
                style: AppTheme.khmerBody(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );

        return Container(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleWidget,
                    const SizedBox(height: 16),
                    actionButtons,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: titleWidget),
                    const SizedBox(width: 16),
                    actionButtons,
                  ],
                ),
        );
      },
    );
  }

  // ─── 4 KPI Stat Cards ───
  Widget _buildKPICards() {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final w = constraints.maxWidth;
        final int count;
        final double ratio;

        if (w > 1300) {
          count = 4;
          ratio = 1.25;
        } else if (w > 950) {
          count = 4;
          ratio = 1.15;
        } else if (w > 650) {
          count = 2;
          ratio = 1.45;
        } else {
          count = 1;
          ratio = 2.4;
        }

        return GridView.count(
          crossAxisCount: count,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 18,
          mainAxisSpacing: 18,
          childAspectRatio: ratio,
          children: [
            _buildStatCard(
              title: 'សិស្សសរុប (Students)',
              value: '${_stats['totalStudents']}',
              unit: 'នាក់',
              subPill1: 'ពេញម៉ោង: ${_stats['fullTimeStudents']}',
              subPill2: 'ក្រៅម៉ោង: ${_stats['partTimeStudents']}',
              icon: Icons.school_rounded,
              color: const Color(0xFF3B82F6),
              bgColor: const Color(0xFFEFF6FF),
              onTap: () {
                if (!widget.isAdmin) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'មុខងារនេះសម្រាប់តែ Admin ប៉ុណ្ណោះ! លោកគ្រូ/អ្នកគ្រូមានសិទ្ធិតែ មើលទិដ្ឋភាពទូទៅ, ស្កេនវត្តមាន និងបញ្ចូលពិន្ទុ។',
                      ),
                      backgroundColor: Color(0xFFDC2626),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                widget.onNavigate?.call(3);
              },
            ),
            _buildStatCard(
              title: 'គ្រូបង្រៀន (Teachers)',
              value: '${_stats['totalTeachers']}',
              unit: 'នាក់',
              subPill1: 'សកម្ម: ${_stats['activeTeachers']}',
              subPill2: 'ពេញសិទ្ធិ: 100%',
              icon: Icons.badge_rounded,
              color: const Color(0xFF0D9488),
              bgColor: const Color(0xFFCCFBF1),
              onTap: () {
                if (!widget.isAdmin) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'មុខងារនេះសម្រាប់តែ Admin ប៉ុណ្ណោះ! លោកគ្រូ/អ្នកគ្រូមានសិទ្ធិតែ មើលទិដ្ឋភាពទូទៅ, ស្កេនវត្តមាន និងបញ្ចូលពិន្ទុ។',
                      ),
                      backgroundColor: Color(0xFFDC2626),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                widget.onNavigate?.call(4);
              },
            ),
            _buildStatCard(
              title: 'បន្ទប់រៀន (Classrooms)',
              value: '${_stats['totalClassrooms']}',
              unit: 'បន្ទប់',
              subPill1: 'ពេញម៉ោង: ${_stats['fullTimeRooms']}',
              subPill2: 'ក្រៅម៉ោង: ${_stats['partTimeRooms']}',
              icon: Icons.meeting_room_rounded,
              color: const Color(0xFF7C3AED),
              bgColor: const Color(0xFFEDE9FE),
              onTap: () {
                if (!widget.isAdmin) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'មុខងារនេះសម្រាប់តែ Admin ប៉ុណ្ណោះ! លោកគ្រូ/អ្នកគ្រូមានសិទ្ធិតែ មើលទិដ្ឋភាពទូទៅ, ស្កេនវត្តមាន និងបញ្ចូលពិន្ទុ។',
                      ),
                      backgroundColor: Color(0xFFDC2626),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                widget.onNavigate?.call(5);
              },
            ),
            _buildStatCard(
              title: 'វត្តមានថ្ងៃនេះ (Attendance)',
              value: '${_stats['attendanceRate']}%',
              unit: '(${_stats['todayAttendance']} នាក់)',
              subPill1: 'មានវត្តមាន: ${_stats['todayAttendance']}',
              subPill2: 'អវត្តមាន: ${_stats['absentCount']}',
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF16A34A),
              bgColor: const Color(0xFFDCFCE7),
              onTap: () => widget.onNavigate?.call(1),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String unit,
    required String subPill1,
    required String subPill2,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: LayoutBuilder(
          builder: (ctx, cardConstraints) {
            return SizedBox(
              width: cardConstraints.maxWidth,
              height: cardConstraints.maxHeight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: cardConstraints.maxWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(icon, color: color, size: 22),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'មើលលម្អិត',
                                style: AppTheme.khmerBody(
                                  fontSize: 11,
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 10,
                                color: Color(0xFF94A3B8),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: AppTheme.khmerBody(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                value,
                                style: AppTheme.englishHeading(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                unit,
                                style: AppTheme.khmerBody(
                                  fontSize: 12,
                                  color: const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: bgColor.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              subPill1,
                              style: AppTheme.khmerBody(
                                fontSize: 10.5,
                                color: color,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              subPill2,
                              style: AppTheme.khmerBody(
                                fontSize: 10.5,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      ),
    );
  }

  // ─── Quick Actions Hub ───
  Widget _buildQuickActionsBar() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      size: 18,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'សកម្មភាពរហ័ស',
                        style: AppTheme.khmerHeading(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Quick Shortcuts & Direct Jump',
                        style: AppTheme.englishCaption(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  widget.isAdmin ? 'គ្រប់គ្រង ១២ ម៉ូឌុល' : 'សិទ្ធិគ្រូបង្រៀន (Faculty)',
                  style: AppTheme.khmerBody(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildActionChip(
                icon: Icons.qr_code_scanner_rounded,
                label: 'ស្កេនវត្តមាន (Scanner)',
                color: const Color(0xFF10B981),
                onTap: () => widget.onNavigate?.call(1),
              ),
              if (widget.isAdmin) ...[
                _buildActionChip(
                  icon: Icons.analytics_outlined,
                  label: 'ស្ថិតិវត្តមាន (Analytics)',
                  color: const Color(0xFF6366F1),
                  onTap: () => widget.onNavigate?.call(2),
                ),
                _buildActionChip(
                  icon: Icons.school_outlined,
                  label: 'គ្រប់គ្រងសិស្ស (Students)',
                  color: const Color(0xFF3B82F6),
                  onTap: () => widget.onNavigate?.call(3),
                ),
                _buildActionChip(
                  icon: Icons.badge_outlined,
                  label: 'គ្រប់គ្រងគ្រូបង្រៀន (Teachers)',
                  color: const Color(0xFF0D9488),
                  onTap: () => widget.onNavigate?.call(4),
                ),
                _buildActionChip(
                  icon: Icons.meeting_room_outlined,
                  label: 'គ្រប់គ្រងថ្នាក់រៀន (Classrooms)',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => widget.onNavigate?.call(5),
                ),
                _buildActionChip(
                  icon: Icons.credit_card_rounded,
                  label: 'បង្កើតកាតសម្គាល់ (ID Studio)',
                  color: const Color(0xFF0284C7),
                  onTap: () => widget.onNavigate?.call(6),
                ),
                _buildActionChip(
                  icon: Icons.calendar_month_rounded,
                  label: 'កាលវិភាគ (Timetable)',
                  color: const Color(0xFFF59E0B),
                  onTap: () => widget.onNavigate?.call(7),
                ),
              ],
              _buildActionChip(
                icon: Icons.auto_stories_rounded,
                label: 'ពិន្ទុ និងការសិក្សា (Grades)',
                color: const Color(0xFFE11D48),
                onTap: () => widget.onNavigate?.call(8),
              ),
              if (widget.isAdmin) ...[
                _buildActionChip(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'ហិរញ្ញវត្ថុ & បៀវត្សរ៍ (Finance)',
                  color: const Color(0xFF059669),
                  onTap: () => widget.onNavigate?.call(9),
                ),
                _buildActionChip(
                  icon: Icons.smart_toy_rounded,
                  label: 'ជំនួយការ AI (Assistant)',
                  color: const Color(0xFFEC4899),
                  onTap: () => widget.onNavigate?.call(10),
                ),
                _buildActionChip(
                  icon: Icons.assessment_rounded,
                  label: 'របាយការណ៍បិទបញ្ជី (Reports)',
                  color: const Color(0xFFD97706),
                  onTap: () => widget.onNavigate?.call(11),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTheme.khmerBody(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Attendance Trends Chart Section ───
  Widget _buildAttendanceChartCard() {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.show_chart_rounded,
                        color: Color(0xFF3B82F6),
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ស្ថិតិវត្តមាន ៧ ថ្ងៃចុងក្រោយ',
                        style: GoogleFonts.notoSansKhmer(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'វិភាគនិន្នាការវត្តមានសិស្ស និងគ្រូបង្រៀនប្រចាំថ្ងៃ',
                    style: GoogleFonts.notoSansKhmer(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildChartToggleBtn(
                      'បង្គោល (Bar)',
                      Icons.bar_chart_rounded,
                      _chartTypeIndex == 0,
                      () {
                        setState(() => _chartTypeIndex = 0);
                      },
                    ),
                    _buildChartToggleBtn(
                      'ខ្សែ (Line)',
                      Icons.timeline_rounded,
                      _chartTypeIndex == 1,
                      () {
                        setState(() => _chartTypeIndex = 1);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Render chart or empty state
          _trends.isEmpty
              ? Container(
                  height: 230,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.analytics_outlined,
                        color: Color(0xFFCBD5E1),
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'មិនទាន់មានទិន្នន័យវត្តមានសម្រាប់ ៧ ថ្ងៃនេះនៅឡើយទេ',
                        style: GoogleFonts.notoSansKhmer(
                          color: const Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              : SizedBox(
                  height: 230,
                  child: _chartTypeIndex == 0
                      ? _buildBarChart()
                      : _buildLineChart(),
                ),

          const SizedBox(height: 24),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 20),

          // Mini statistics callouts
          LayoutBuilder(
            builder: (ctx, constraints) {
              final isNarrow = constraints.maxWidth < 460;
              final item1 = _buildMiniStatCallout(
                'អត្រាវត្តមានមធ្យម',
                '${_stats['avgAttendance']}%',
                'ល្អប្រសើរ (High Attendance)',
                const Color(0xFF10B981),
                const Color(0xFFECFDF5),
              );
              final item2 = _buildMiniStatCallout(
                'អវត្តមានមធ្យម',
                '${_stats['avgAbsent']}%',
                'ស្ថិតក្រោមការគ្រប់គ្រង (Normal)',
                const Color(0xFFF59E0B),
                const Color(0xFFFEF3C7),
              );

              return isNarrow
                  ? Column(
                      children: [
                        item1,
                        const SizedBox(height: 12),
                        item2,
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: item1),
                        const SizedBox(width: 16),
                        Expanded(child: item2),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChartToggleBtn(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? const Color(0xFF0F172A)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.notoSansKhmer(
                fontSize: 12,
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

  Widget _buildBarChart() {
    int maxCount = 1;
    for (var item in _trends) {
      int c =
          int.tryParse(
            (item['presentCount'] ?? item['presentStudents'] ?? 0).toString(),
          ) ??
          0;
      if (c > maxCount) maxCount = c;
    }
    // ensure room
    maxCount = max(maxCount, _stats['totalStudents'] as int? ?? 5);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: _trends.map((item) {
        final count =
            int.tryParse(
              (item['presentCount'] ?? item['presentStudents'] ?? 0).toString(),
            ) ??
            0;
        final factor = (count / max(maxCount, 1)).clamp(0.08, 1.0);
        final dateStr = item['date']?.toString() ?? '';
        final parts = dateStr.split('-');
        final displayDate = parts.length >= 3
            ? '${parts[1]}/${parts[2]}'
            : dateStr;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: count > 0
                    ? const Color(0xFFEFF6FF)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: count > 0
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              width: 38,
              height: 140 * factor,
              decoration: BoxDecoration(
                gradient: count > 0
                    ? const LinearGradient(
                        colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : LinearGradient(
                        colors: [
                          const Color(0xFFCBD5E1),
                          const Color(0xFFE2E8F0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: count > 0
                    ? [
                        BoxShadow(
                          color: const Color(
                            0xFF2563EB,
                          ).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              displayDate,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildLineChart() {
    final spots = <FlSpot>[];
    for (int i = 0; i < _trends.length; i++) {
      final c =
          double.tryParse(
            (_trends[i]['presentCount'] ?? _trends[i]['presentStudents'] ?? 0)
                .toString(),
          ) ??
          0.0;
      spots.add(FlSpot(i.toDouble(), c));
    }

    if (spots.isEmpty) {
      spots.add(const FlSpot(0, 0));
    }

    double maxY = 5.0;
    for (var s in spots) {
      if (s.y > maxY) maxY = s.y;
    }
    maxY = (maxY * 1.3).ceilToDouble();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: max(1, (maxY / 4).roundToDouble()),
          getDrawingHorizontalLine: (val) => FlLine(
            color: const Color(0xFFF1F5F9),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (val, meta) => Text(
                val.toInt().toString(),
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (val, meta) {
                int idx = val.toInt();
                if (idx >= 0 && idx < _trends.length) {
                  final dStr = _trends[idx]['date']?.toString() ?? '';
                  final parts = dStr.split('-');
                  final label = parts.length >= 3
                      ? '${parts[1]}/${parts[2]}'
                      : dStr;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      label,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: max(0, (_trends.length - 1).toDouble()),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: const Color(0xFF2563EB),
            barWidth: 3.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, p, bar, idx) => FlDotCirclePainter(
                radius: 4.5,
                color: const Color(0xFF2563EB),
                strokeWidth: 2.5,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3B82F6).withValues(alpha: 0.25),
                  const Color(0xFF3B82F6).withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCallout(
    String title,
    String val,
    String desc,
    Color color,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.notoSansKhmer(
              fontSize: 12,
              color: const Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                val,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  desc,
                  style: GoogleFonts.notoSansKhmer(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Enrollment Distribution Card ───
  Widget _buildEnrollmentDistributionCard() {
    int total = _stats['totalStudents'] as int? ?? 1;
    if (total == 0) total = 1;
    int ft = _stats['fullTimeStudents'] as int? ?? 0;
    int pt = _stats['partTimeStudents'] as int? ?? 0;
    double ftRatio = (ft / total).clamp(0.0, 1.0);
    double ptRatio = (pt / total).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.pie_chart_rounded,
                    color: Color(0xFF8B5CF6),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ការបែងចែកសិស្សតាមកម្មវិធីសិក្សា',
                    style: AppTheme.khmerHeading(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Text(
                'សរុប: ${_stats['totalStudents']} នាក់',
                style: AppTheme.khmerBody(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4F46E5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Stacked Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  Expanded(
                    flex: max(1, (ftRatio * 100).toInt()),
                    child: Container(color: const Color(0xFF3B82F6)),
                  ),
                  Expanded(
                    flex: max(1, (ptRatio * 100).toInt()),
                    child: Container(color: const Color(0xFF10B981)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Legend cards
          LayoutBuilder(
            builder: (ctx, constraints) {
              final isNarrow = constraints.maxWidth < 420;
              final fullTimeCard = Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3B82F6),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'សិស្សពេញម៉ោង (Full-Time)',
                            style: AppTheme.khmerBody(
                              fontSize: 11,
                              color: const Color(0xFF1E40AF),
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text(
                            '$ft នាក់ (${(ftRatio * 100).toStringAsFixed(0)}%)',
                            style: AppTheme.englishHeading(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E3A8A),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );

              final partTimeCard = Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'សិស្សក្រៅម៉ោង (Part-Time)',
                            style: AppTheme.khmerBody(
                              fontSize: 11,
                              color: const Color(0xFF065F46),
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text(
                            '$pt នាក់ (${(ptRatio * 100).toStringAsFixed(0)}%)',
                            style: AppTheme.englishHeading(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF064E3B),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );

              return isNarrow
                  ? Column(
                      children: [
                        fullTimeCard,
                        const SizedBox(height: 10),
                        partTimeCard,
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: fullTimeCard),
                        const SizedBox(width: 14),
                        Expanded(child: partTimeCard),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }

  // ─── Live Feed Card (Recent Activities) ───
  Widget _buildLiveFeedCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    color: Color(0xFFF59E0B),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'សកម្មភាពទាន់ហេតុការណ៍',
                    style: AppTheme.khmerHeading(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_recentActivities.length} កំណត់ត្រា',
                  style: AppTheme.khmerBody(
                    color: const Color(0xFF2563EB),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'វត្តមាន និងការចុះឈ្មោះសិស្សថ្មីៗ',
            style: AppTheme.khmerBody(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 18),

          _recentActivities.isEmpty
              ? Container(
                  height: 220,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.inbox_rounded,
                        color: Color(0xFFCBD5E1),
                        size: 40,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'មិនទាន់មានសកម្មភាពថ្មីទេ',
                        style: AppTheme.khmerBody(
                          color: const Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: min(_recentActivities.length, 8),
                  // ignore: unnecessary_underscores
                  separatorBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ),
                  itemBuilder: (ctx, i) {
                    final a = _recentActivities[i] as Map<String, dynamic>;
                    final nameKh = (a['name_kh'] ?? a['title'] ?? 'សិស្ស')
                        .toString();
                    final initial = nameKh.isNotEmpty ? nameKh[0] : 'S';
                    final className =
                        (a['class_name'] ?? a['description'] ?? 'ទូទៅ')
                            .toString();
                    final time = (a['time'] ?? 'ថ្មីៗ').toString();
                    final status = (a['status'] ?? 'Present').toString();
                    final isPresent = status == 'Present';

                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 19,
                          backgroundColor: isPresent
                              ? const Color(0xFFE0E7FF)
                              : const Color(0xFFFEF3C7),
                          child: Text(
                            initial,
                            style: AppTheme.khmerHeading(
                              color: isPresent
                                  ? const Color(0xFF4338CA)
                                  : const Color(0xFFB45309),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nameKh,
                                style: AppTheme.khmerBody(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: const Color(0xFF1E293B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$className • $time',
                                style: AppTheme.khmerBody(
                                  fontSize: 11,
                                  color: const Color(0xFF64748B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isPresent
                                ? const Color(0xFFECFDF5)
                                : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isPresent
                                  ? const Color(0xFFA7F3D0)
                                  : const Color(0xFFFECACA),
                            ),
                          ),
                          child: Text(
                            isPresent ? 'វត្តមាន' : 'អវត្តមាន',
                            style: AppTheme.khmerBody(
                              color: isPresent
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFDC2626),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4F46E5),
                side: const BorderSide(color: Color(0xFFC7D2FE)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => widget.onNavigate?.call(1),
              child: Text(
                'ចូលទៅកាន់ម៉ាស៊ីនស្កេនវត្តមាន',
                style: GoogleFonts.notoSansKhmer(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
