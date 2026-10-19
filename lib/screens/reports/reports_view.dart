import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';
import 'package:school_management_app/services/api_service.dart';
import 'package:school_management_app/services/html_print_service.dart';
import 'package:school_management_app/services/pdf_export_service.dart';
import 'package:school_management_app/utils/app_logo.dart';
import 'package:school_management_app/utils/app_theme.dart';
import 'package:school_management_app/utils/pdf_font_helper.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  int _selectedTab = 0;
  bool _isDateRange = false;
  bool _isLoading = true;
  bool _isFormalTableView = true;

  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();
  String _quickFilter = 'all';
  String _selectedStatus = 'ទាំងអស់';
  final TextEditingController _searchCtrl = TextEditingController();

  Map<String, dynamic> _summary = {
    'totalStudents': 0,
    'maleStudents': 0,
    'femaleStudents': 0,
    'totalTeachers': 0,
    'totalClassrooms': 0,
    'todayPresent': 0,
    'todayAbsent': 0,
    'todayPermission': 0,
    'totalRevenue': 0,
    'totalSalaries': 0,
    'netBalance': 0,
  };

  List<dynamic> _attendanceRecords = [];
  List<dynamic> _paymentRecords = [];
  // ignore: unused_field
  List<dynamic> _salaryRecords = [];
  List<dynamic> _classroomRecords = [];

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchReportData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        http.get(Uri.parse('${ApiService.baseUrl}/reports/summary')),
        http.get(Uri.parse('${ApiService.baseUrl}/payments/students')),
        http.get(Uri.parse('${ApiService.baseUrl}/payments/teacher-salaries')),
        http.get(Uri.parse('${ApiService.baseUrl}/classrooms')),
      ]);
      final summaryRes = results[0];
      final payRes = results[1];
      final salRes = results[2];
      final classRes = results[3];

      if (mounted) {
        setState(() {
          if (summaryRes.statusCode == 200) {
            final data = jsonDecode(utf8.decode(summaryRes.bodyBytes));
            if (data['summary'] != null) {
              _summary = Map<String, dynamic>.from(data['summary']);
            }
            if (data['recentAttendance'] != null) {
              _attendanceRecords = List<dynamic>.from(data['recentAttendance']);
            }
          }

          if (payRes.statusCode == 200) {
            final pData = jsonDecode(utf8.decode(payRes.bodyBytes));
            _paymentRecords = pData['data'] ?? [];
          }

          if (salRes.statusCode == 200) {
            final sData = jsonDecode(utf8.decode(salRes.bodyBytes));
            _salaryRecords = sData['data'] ?? [];
          }

          if (classRes.statusCode == 200) {
            final cData = jsonDecode(utf8.decode(classRes.bodyBytes));
            _classroomRecords = cData['data'] ?? [];
          }

          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> _getFilteredAttendance() {
    final query = _searchCtrl.text.trim().toLowerCase();
    return _attendanceRecords.where((r) {
      final sCode = (r['student_code'] ?? '').toString().toLowerCase();
      final nameKh = (r['name_kh'] ?? '').toString().toLowerCase();
      final nameEn = (r['name_en'] ?? '').toString().toLowerCase();
      final cName = (r['class_name'] ?? '').toString().toLowerCase();
      final status = (r['status'] ?? '').toString();

      final matchesSearch =
          query.isEmpty ||
          sCode.contains(query) ||
          nameKh.contains(query) ||
          nameEn.contains(query) ||
          cName.contains(query);

      final matchesStatus =
          _selectedStatus == 'ទាំងអស់' ||
          (_selectedStatus == 'វត្តមាន' && status == 'Present') ||
          (_selectedStatus == 'អវត្តមាន' && status == 'Absent') ||
          (_selectedStatus == 'ច្បាប់' && status == 'Permission');

      return matchesSearch && matchesStatus;
    }).toList();
  }

  List<dynamic> _getFilteredPayments() {
    final query = _searchCtrl.text.trim().toLowerCase();
    return _paymentRecords.where((p) {
      final nameKh = (p['student_name_kh'] ?? p['name_kh'] ?? '')
          .toString()
          .toLowerCase();
      final code = (p['student_code'] ?? p['receipt_no'] ?? '')
          .toString()
          .toLowerCase();
      final method = (p['payment_method'] ?? '').toString().toLowerCase();

      return query.isEmpty ||
          nameKh.contains(query) ||
          code.contains(query) ||
          method.contains(query);
    }).toList();
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1D4ED8),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
          if (_fromDate.isAfter(_toDate)) _toDate = _fromDate;
        } else {
          _toDate = picked;
          if (_toDate.isBefore(_fromDate)) _fromDate = _toDate;
        }
      });
    }
  }

  void _applyQuickFilter(String type) {
    final now = DateTime.now();
    setState(() {
      _quickFilter = type;
      if (type == 'today') {
        _fromDate = now;
        _toDate = now;
      } else if (type == '7days') {
        _fromDate = now.subtract(const Duration(days: 7));
        _toDate = now;
      } else if (type == '30days') {
        _fromDate = now.subtract(const Duration(days: 30));
        _toDate = now;
      } else if (type == 'month') {
        _fromDate = DateTime(now.year, now.month, 1);
        _toDate = now;
      } else {
        _fromDate = DateTime(2025, 1, 1);
        _toDate = now;
      }
    });
  }

  Future<void> _printReport() async {
    try {
      final pdf = pw.Document();
      final fontBold = await PdfFontHelper.getBoldFont();
      final fontRegular = await PdfFontHelper.getRegularFont();

      final todayStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
      String title = 'របាយការណ៍វត្តមានប្រចាំថ្ងៃ (Daily Attendance Report)';
      List<String> headers = [
        'អត្តលេខ',
        'ឈ្មោះសិស្ស',
        'ភេទ',
        'ថ្នាក់',
        'វេន',
        'ស្ថានភាព',
        'កាលបរិច្ឆេទ',
        'ម៉ោង',
      ];
      List<List<String>> dataRows = [];

      if (_selectedTab == 0 || _selectedTab == 1 || _selectedTab == 2) {
        title = _selectedTab == 0
            ? 'របាយការណ៍វត្តមានប្រចាំថ្ងៃ និងតាមកាលបរិច្ឆេទ'
            : (_selectedTab == 1
                  ? 'របាយការណ៍វត្តមានប្រចាំខែតាមថ្នាក់'
                  : 'របាយការណ៍វិភាគអវត្តមានសិស្ស');
        final list = _getFilteredAttendance();
        for (var r in list) {
          dataRows.add([
            (r['student_code'] ?? 'N/A').toString(),
            (r['name_kh'] ?? r['name_en'] ?? '').toString(),
            (r['gender'] == 'Male' ? 'ប្រុស' : 'ស្រី'),
            (r['class_name'] ?? 'ទូទៅ').toString(),
            (r['shift'] ?? 'ព្រឹក').toString(),
            _translateStatus(r['status']),
            (r['date'] ?? '').toString(),
            (r['time'] ?? '').toString(),
          ]);
        }
      } else if (_selectedTab == 3) {
        title = 'របាយការណ៍ការបង់ប្រាក់សិស្ស (Student Payments Report)';
        headers = [
          'បង្កាន់ដៃ',
          'ឈ្មោះសិស្ស',
          'អត្តលេខ',
          'ចំនួនទឹកប្រាក់',
          'វិធីសាស្ត្រ',
          'កាលបរិច្ឆេទ',
        ];
        final list = _getFilteredPayments();
        for (var p in list) {
          dataRows.add([
            (p['receipt_no'] ?? '-').toString(),
            (p['student_name_kh'] ?? p['name_kh'] ?? '').toString(),
            (p['student_code'] ?? '').toString(),
            '\$${(p['amount'] ?? 0).toString()}',
            (p['payment_method'] ?? 'សាច់ប្រាក់').toString(),
            (p['payment_date'] != null
                ? p['payment_date'].toString().split('T')[0]
                : ''),
          ]);
        }
      } else {
        title = 'របាយការណ៍ស្ថិតិថ្នាក់រៀន និងប្រជាសាស្ត្រសាលា';
        headers = [
          'ឈ្មោះថ្នាក់រៀន',
          'កម្រិតថ្នាក់',
          'បន្ទប់លេខ',
          'សមត្ថភាពផ្ទុក',
          'វេនសិក្សា',
        ];
        for (var c in _classroomRecords) {
          dataRows.add([
            (c['class_name'] ?? '').toString(),
            (c['grade_name'] ?? '').toString(),
            (c['room_number'] ?? '-').toString(),
            '${c['capacity'] ?? 30} នាក់',
            (c['shift'] ?? 'ពេញម៉ោង').toString(),
          ]);
        }
      }

      if (kIsWeb) {
        HtmlPrintService.printGeneralReport(
          title: title,
          subtitle: 'របាយការណ៍ផ្លូវការសាលារៀន',
          headers: headers,
          rows: dataRows,
          isLandscape: true,
        );
        return;
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          theme: pw.ThemeData.withFont(
            base: fontRegular,
            bold: fontBold,
            fontFallback: [fontRegular, fontBold],
          ),
          build: (pw.Context ctx) => [
            pw.Row(
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
                          'សាលាប្រាយឡាយ (Bright Light School)',
                          style: pw.TextStyle(font: fontBold, fontSize: 16),
                        ),
                        pw.Text(
                          'BRIGHT LIGHT PRIMARY & SECONDARY SCHOOL',
                          style: pw.TextStyle(
                            font: fontRegular,
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          'លេខកូដសាលា៖ BLS-2026 | រាជធានីភ្នំពេញ ព្រះរាជាណាចក្រកម្ពុជា',
                          style: pw.TextStyle(
                            font: fontRegular,
                            fontSize: 9,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      title,
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 13,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.Text(
                      'កាលបរិច្ឆេទបង្កើត៖ $todayStr',
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Text(
                      'ចំនួនទិន្នន័យសរុប៖ ${dataRows.length} ជួរ',
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Divider(thickness: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: dataRows.isEmpty
                  ? [List.filled(headers.length, 'មិនមានទិន្នន័យ')]
                  : dataRows,
              headerStyle: pw.TextStyle(
                font: fontBold,
                fontSize: 10,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF1D4ED8),
              ),
              cellStyle: pw.TextStyle(font: fontRegular, fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'ហត្ថលេខាអ្នករៀបចំ',
                  style: pw.TextStyle(font: fontBold, fontSize: 10),
                ),
                pw.Text(
                  'ហត្ថលេខានាយកសាលា',
                  style: pw.TextStyle(font: fontBold, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (fmt) => pdf.save(),
        name:
            'school_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('បរាជ័យក្នុងការបោះពុម្ព៖ $e')));
      }
    }
  }

  void _exportCsv() {
    final buffer = StringBuffer();
    // Add UTF-8 BOM so Excel opens Khmer characters properly
    buffer.write('\uFEFF');

    if (_selectedTab == 0 || _selectedTab == 1 || _selectedTab == 2) {
      buffer.writeln(
        'Student Code,Khmer Name,English Name,Gender,Class,Shift,Status,Date,Time',
      );
      final list = _getFilteredAttendance();
      for (var r in list) {
        buffer.writeln(
          '"${r['student_code'] ?? ''}","${r['name_kh'] ?? ''}","${r['name_en'] ?? ''}","${r['gender'] ?? ''}","${r['class_name'] ?? ''}","${r['shift'] ?? ''}","${_translateStatus(r['status'])}","${r['date'] ?? ''}","${r['time'] ?? ''}"',
        );
      }
    } else if (_selectedTab == 3) {
      buffer.writeln(
        'Receipt No,Student Name,Student Code,Amount,Payment Method,Payment Date',
      );
      final list = _getFilteredPayments();
      for (var p in list) {
        buffer.writeln(
          '"${p['receipt_no'] ?? ''}","${p['student_name_kh'] ?? p['name_kh'] ?? ''}","${p['student_code'] ?? ''}","${p['amount'] ?? 0}","${p['payment_method'] ?? ''}","${p['payment_date'] ?? ''}"',
        );
      }
    } else {
      buffer.writeln('Classroom Name,Grade Level,Room Number,Capacity,Shift');
      for (var c in _classroomRecords) {
        buffer.writeln(
          '"${c['class_name'] ?? ''}","${c['grade_name'] ?? ''}","${c['room_number'] ?? ''}","${c['capacity'] ?? ''}","${c['shift'] ?? ''}"',
        );
      }
    }

    final filename =
        'school_report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
    PdfExportService.exportCsv(filename, buffer.toString());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'បានទាញយកឯកសារ CSV ($filename) ជោគជ័យ!',
              style: GoogleFonts.notoSansKhmer(),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _translateStatus(dynamic status) {
    final s = status.toString();
    if (s == 'Present') return 'វត្តមាន';
    if (s == 'Absent') return 'អវត្តមាន';
    if (s == 'Permission') return 'ច្បាប់';
    return s.isNotEmpty ? s : 'វត្តមាន';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1D4ED8)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderBanner(),
                  const SizedBox(height: 24),
                  _buildTopTabs(),
                  const SizedBox(height: 24),
                  _buildFilters(),
                  const SizedBox(height: 24),
                  _buildReportContent(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderBanner() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 800;
        return Container(
          padding: EdgeInsets.all(isNarrow ? 16 : 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1D4ED8).withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.assessment_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'របាយការណ៍បិទបញ្ជី និងស្ថិតិសាលារៀន',
                          style: AppTheme.khmerHeading(
                            fontSize: isNarrow ? 16 : 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ទាញយកទិន្នន័យផ្លូវការ វត្តមានប្រចាំថ្ងៃ ការបង់ប្រាក់សិស្ស បៀវត្សរ៍ និងប្រជាសាស្ត្រ',
                          style: AppTheme.khmerBody(
                            fontSize: isNarrow ? 11.5 : 13,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!isNarrow) ...[
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _fetchReportData,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(
                        'ផ្ទុកទិន្នន័យឡើងវិញ',
                        style: AppTheme.khmerBody(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E3A8A),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1D4ED8),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ],
              ),
              if (isNarrow) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _fetchReportData,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(
                      'ផ្ទុកទិន្នន័យឡើងវិញ',
                      style: AppTheme.khmerBody(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1D4ED8),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopTabs() {
    final tabs = [
      {
        'icon': Icons.calendar_month,
        'label': 'របាយការណ៍វត្តមានប្រចាំថ្ងៃ / Attendance',
      },
      {
        'icon': Icons.grid_on,
        'label': 'វត្តមានប្រចាំខែតាមថ្នាក់ / Monthly Grid',
      },
      {
        'icon': Icons.warning_amber_rounded,
        'label': 'វិភាគអវត្តមាន / Absence Alerts',
      },
      {'icon': Icons.attach_money, 'label': 'ការបង់ប្រាក់សិស្ស / Payments'},
      {'icon': Icons.layers, 'label': 'ស្ថិតិថ្នាក់រៀន / Occupancy'},
      {
        'icon': Icons.people_alt_outlined,
        'label': 'ប្រជាសាស្ត្រទូទៅ / Demographics',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10),
        ],
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: List.generate(tabs.length, (i) {
          final isSelected = _selectedTab == i;
          return InkWell(
            onTap: () => setState(() => _selectedTab = i),
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1D4ED8)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1D4ED8)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    tabs[i]['icon'] as IconData,
                    size: 18,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tabs[i]['label'] as String,
                    style: GoogleFonts.notoSansKhmer(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFilters() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleButton(
                      'ថ្ងៃកាល (Single Date)',
                      !_isDateRange,
                      () => setState(() => _isDateRange = false),
                    ),
                    _buildToggleButton(
                      'ចន្លោះកាលបរិច្ឆេទ (Date Range)',
                      _isDateRange,
                      () => setState(() => _isDateRange = true),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _pickDate(true),
                child: _buildDateChip(
                  'ចាប់ពី (From):',
                  dateFormat.format(_fromDate),
                ),
              ),
              if (_isDateRange)
                InkWell(
                  onTap: () => _pickDate(false),
                  child: _buildDateChip(
                    'ដល់ (To):',
                    dateFormat.format(_toDate),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'លឿនៗ / Quick:',
                style: GoogleFonts.notoSansKhmer(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
              _buildQuickFilterBtn(
                'ថ្ងៃនេះ (Today)',
                _quickFilter == 'today',
                () => _applyQuickFilter('today'),
              ),
              _buildQuickFilterBtn(
                '៧ ថ្ងៃ (7 Days)',
                _quickFilter == '7days',
                () => _applyQuickFilter('7days'),
              ),
              _buildQuickFilterBtn(
                '៣០ ថ្ងៃ (30 Days)',
                _quickFilter == '30days',
                () => _applyQuickFilter('30days'),
              ),
              _buildQuickFilterBtn(
                'ខែនេះ (This Month)',
                _quickFilter == 'month',
                () => _applyQuickFilter('month'),
              ),
              _buildQuickFilterBtn(
                'ទាំងអស់ (All Time)',
                _quickFilter == 'all',
                () => _applyQuickFilter('all'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (ctx, filterConstraints) {
              final isFilterNarrow = filterConstraints.maxWidth < 650;
              final statusDropdown = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ស្ថានភាព / STATUS:',
                    style: GoogleFonts.notoSansKhmer(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _selectedStatus,
                    underline: const SizedBox(),
                    items: ['ទាំងអស់', 'វត្តមាន', 'អវត្តមាន', 'ច្បាប់']
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              s,
                              style: GoogleFonts.notoSansKhmer(fontSize: 12),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedStatus = val);
                    },
                  ),
                ],
              );

              final searchField = TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'ស្វែងរកតាមលេខកូដសិស្ស ឈ្មោះ ឬថ្នាក់រៀន...',
                  hintStyle: GoogleFonts.notoSansKhmer(
                    fontSize: 13,
                    color: const Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF94A3B8),
                    size: 18,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              );

              if (isFilterNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    statusDropdown,
                    const SizedBox(height: 12),
                    searchField,
                  ],
                );
              }

              return Row(
                children: [
                  statusDropdown,
                  const SizedBox(width: 24),
                  Expanded(child: searchField),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          // Action Buttons: Print, PDF, CSV, Table View
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: () =>
                    setState(() => _isFormalTableView = !_isFormalTableView),
                icon: Icon(
                  _isFormalTableView ? Icons.table_chart : Icons.view_agenda,
                  size: 18,
                ),
                label: Text(
                  _isFormalTableView
                      ? 'ទម្រង់តារាងផ្លូវការ (Formal Table)'
                      : 'ទម្រង់កាតសង្ខេប (Card View)',
                  style: GoogleFonts.notoSansKhmer(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _printReport,
                icon: const Icon(Icons.print, size: 18),
                label: Text(
                  'បោះពុម្ព (Print)',
                  style: GoogleFonts.notoSansKhmer(fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF334155),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _printReport,
                icon: const Icon(Icons.picture_as_pdf, size: 18),
                label: Text(
                  'ទាញយក PDF',
                  style: GoogleFonts.notoSansKhmer(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE11D48),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _exportCsv,
                icon: const Icon(Icons.download, size: 18),
                label: Text(
                  'ទាញយក CSV',
                  style: GoogleFonts.notoSansKhmer(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1D4ED8) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSansKhmer(
            fontSize: 12,
            color: isSelected ? Colors.white : const Color(0xFF475569),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDateChip(String label, String date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_month, color: Color(0xFF1D4ED8), size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.notoSansKhmer(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            date,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterBtn(
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1D4ED8)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSansKhmer(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? const Color(0xFF1D4ED8)
                : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  String _getReportTitle() {
    switch (_selectedTab) {
      case 0:
        return 'របាយការណ៍វត្តមានប្រចាំថ្ងៃ និងតាមកាលបរិច្ឆេទ';
      case 1:
        return 'វត្តមានប្រចាំខែតាមថ្នាក់ (Monthly Grid)';
      case 2:
        return 'វិភាគអវត្តមាន & សិស្សប្រឈម (Absence Alerts)';
      case 3:
        return 'របាយការណ៍ការបង់ប្រាក់សិស្ស (Student Payments)';
      case 4:
        return 'ស្ថិតិថ្នាក់រៀន & ចុះឈ្មោះ (Classroom Occupancy)';
      default:
        return 'ស្ថិតិប្រជាសាស្ត្រសាលារួម (Demographics)';
    }
  }

  Widget _buildReportContent() {
    final todayPresent = _summary['todayPresent'] ?? 0;
    final totalStudents = _summary['totalStudents'] ?? 0;
    final todayAbsent = _summary['todayAbsent'] ?? 0;
    final todayPermission = _summary['todayPermission'] ?? 0;
    final rate = totalStudents > 0
        ? ((todayPresent / totalStudents) * 100).toStringAsFixed(1)
        : '100.0';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 750;
        final isMobile = constraints.maxWidth < 550;

        return Container(
          padding: EdgeInsets.all(isMobile ? 16 : 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Official Header
              if (isNarrow)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppLogo.widget(
                          width: 48,
                          height: 48,
                          shape: BoxShape.circle,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'សាលាប្រាយឡាយ',
                                style: GoogleFonts.notoSansKhmer(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'BRIGHT LIGHT PRIMARY & SECONDARY SCHOOL',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF64748B),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'លេខកូដសាលា៖ BLS-2026 • វិថីព្រះនរោត្តម រាជធានីភ្នំពេញ',
                                style: GoogleFonts.notoSansKhmer(
                                  fontSize: 10,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'របាយការណ៍ផ្លូវការ / Official School Report',
                            style: GoogleFonts.notoSansKhmer(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'កាលបរិច្ឆេទបង្កើត៖ ${DateFormat('dd/MM/yyyy • hh:mm a').format(DateTime.now())}',
                            style: GoogleFonts.notoSansKhmer(
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'បង្កើតដោយស្វ័យប្រវត្តពីប្រព័ន្ធទិន្នន័យផ្ទាល់ (Live Database)',
                            style: GoogleFonts.notoSansKhmer(
                              fontSize: 10,
                              color: const Color(0xFF059669),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          AppLogo.widget(
                            width: 56,
                            height: 56,
                            shape: BoxShape.circle,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'សាលាប្រាយឡាយ',
                                  style: GoogleFonts.notoSansKhmer(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'BRIGHT LIGHT PRIMARY & SECONDARY SCHOOL',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'លេខកូដសាលា៖ BLS-2026 • វិថីព្រះនរោត្តម រាជធានីភ្នំពេញ ព្រះរាជាណាចក្រកម្ពុជា',
                                  style: GoogleFonts.notoSansKhmer(
                                    fontSize: 11,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'របាយការណ៍ផ្លូវការ / Official School Report',
                          style: GoogleFonts.notoSansKhmer(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'កាលបរិច្ឆេទបង្កើត៖ ${DateFormat('dd/MM/yyyy • hh:mm a').format(DateTime.now())}',
                          style: GoogleFonts.notoSansKhmer(
                            fontSize: 11,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'បង្កើតដោយស្វ័យប្រវត្តពីប្រព័ន្ធទិន្នន័យផ្ទាល់ (Live Database)',
                          style: GoogleFonts.notoSansKhmer(
                            fontSize: 10,
                            color: const Color(0xFF059669),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 20),

              // Report Title & Metric Banner
              if (isNarrow)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.description,
                            color: Color(0xFF1D4ED8),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getReportTitle(),
                                style: GoogleFonts.notoSansKhmer(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'បង្ហាញទិន្នន័យជាក់ស្តែងពីមូលដ្ឋានទិន្នន័យ MySQL (Live Records)',
                                style: GoogleFonts.notoSansKhmer(
                                  fontSize: 11,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'អត្រាវត្តមានរួម៖ ',
                            style: GoogleFonts.notoSansKhmer(
                              fontSize: 12,
                              color: const Color(0xFF1D4ED8),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$rate%',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.description,
                        color: Color(0xFF1D4ED8),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getReportTitle(),
                            style: GoogleFonts.notoSansKhmer(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'បង្ហាញទិន្នន័យជាក់ស្តែងពីមូលដ្ឋានទិន្នន័យ MySQL (Live Records)',
                            style: GoogleFonts.notoSansKhmer(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'អត្រាវត្តមានរួម',
                            style: GoogleFonts.notoSansKhmer(
                              fontSize: 11,
                              color: const Color(0xFF1D4ED8),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$rate%',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),

              // Summary Boxes
              if (constraints.maxWidth < 680)
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryBox(
                            'សិស្សសរុប (TOTAL)',
                            '$totalStudents នាក់',
                            const Color(0xFFEFF6FF),
                            const Color(0xFF1D4ED8),
                            const Color(0xFFBFDBFE),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryBox(
                            'វត្តមានថ្ងៃនេះ (PRESENT)',
                            '$todayPresent នាក់',
                            const Color(0xFFF0FDF4),
                            const Color(0xFF10B981),
                            const Color(0xFFBBF7D0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryBox(
                            'ច្បាប់ (PERMISSION)',
                            '$todayPermission នាក់',
                            const Color(0xFFFFFBEB),
                            const Color(0xFFD97706),
                            const Color(0xFFFDE68A),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryBox(
                            'អវត្តមាន (ABSENT)',
                            '$todayAbsent នាក់',
                            const Color(0xFFFEF2F2),
                            const Color(0xFFEF4444),
                            const Color(0xFFFECACA),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryBox(
                        'សិស្សសរុប (TOTAL)',
                        '$totalStudents នាក់',
                        const Color(0xFFEFF6FF),
                        const Color(0xFF1D4ED8),
                        const Color(0xFFBFDBFE),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildSummaryBox(
                        'វត្តមានថ្ងៃនេះ (PRESENT)',
                        '$todayPresent នាក់',
                        const Color(0xFFF0FDF4),
                        const Color(0xFF10B981),
                        const Color(0xFFBBF7D0),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildSummaryBox(
                        'ច្បាប់ (PERMISSION)',
                        '$todayPermission នាក់',
                        const Color(0xFFFFFBEB),
                        const Color(0xFFD97706),
                        const Color(0xFFFDE68A),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildSummaryBox(
                        'អវត្តមាន (ABSENT)',
                        '$todayAbsent នាក់',
                        const Color(0xFFFEF2F2),
                        const Color(0xFFEF4444),
                        const Color(0xFFFECACA),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 28),

              // Switch between tab views
              if (_selectedTab == 0 || _selectedTab == 1 || _selectedTab == 2)
                _buildAttendanceTable()
              else if (_selectedTab == 3)
                _buildPaymentsTable()
              else if (_selectedTab == 4)
                _buildClassroomsTable()
              else
                _buildDemographicsTable(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttendanceTable() {
    final list = _getFilteredAttendance();

    if (list.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 48,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 12),
            Text(
              'មិនមានទិន្នន័យវត្តមានត្រូវនឹងលក្ខខណ្ឌស្វែងរកទេ',
              style: GoogleFonts.notoSansKhmer(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth =
            constraints.maxWidth < 880 ? 880.0 : constraints.maxWidth;
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Table(
          columnWidths: const {
            0: FixedColumnWidth(110),
            1: FlexColumnWidth(2),
            2: FixedColumnWidth(80),
            3: FlexColumnWidth(1.5),
            4: FixedColumnWidth(90),
            5: FixedColumnWidth(130),
            6: FixedColumnWidth(110),
            7: FixedColumnWidth(100),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
              children: [
                _buildHeaderCell('អត្តលេខ ID'),
                _buildHeaderCell('ឈ្មោះសិស្ស'),
                _buildHeaderCell('ភេទ', align: TextAlign.center),
                _buildHeaderCell('ថ្នាក់រៀន (Class)'),
                _buildHeaderCell('វេនសិក្សា', align: TextAlign.center),
                _buildHeaderCell('ស្ថានភាពវត្តមាន', align: TextAlign.center),
                _buildHeaderCell('កាលបរិច្ឆេទ', align: TextAlign.center),
                _buildHeaderCell('ម៉ោងស្កេន', align: TextAlign.right),
              ],
            ),
            ...list.map((r) {
              final status = (r['status'] ?? 'Present').toString();
              Color badgeBg = const Color(0xFFDCFCE7);
              Color badgeFg = const Color(0xFF16A34A);
              IconData badgeIcon = Icons.check_circle_outline;

              if (status == 'Absent') {
                badgeBg = const Color(0xFFFEE2E2);
                badgeFg = const Color(0xFFDC2626);
                badgeIcon = Icons.cancel_outlined;
              } else if (status == 'Permission') {
                badgeBg = const Color(0xFFFEF3C7);
                badgeFg = const Color(0xFFD97706);
                badgeIcon = Icons.info_outline;
              }

              return TableRow(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      r['student_code'] ?? 'N/A',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r['name_kh'] ?? '',
                          style: GoogleFonts.notoSansKhmer(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        if (r['name_en'] != null &&
                            r['name_en'].toString().isNotEmpty)
                          Text(
                            r['name_en'],
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          r['gender'] == 'Male' ? 'ប្រុស' : 'ស្រី',
                          style: GoogleFonts.notoSansKhmer(
                            fontSize: 11,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      r['class_name'] ?? 'ទូទៅ',
                      style: GoogleFonts.notoSansKhmer(
                        fontSize: 13,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Center(
                      child: Text(
                        r['shift'] ?? 'ព្រឹក',
                        style: GoogleFonts.notoSansKhmer(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(badgeIcon, size: 13, color: badgeFg),
                            const SizedBox(width: 4),
                            Text(
                              _translateStatus(status),
                              style: GoogleFonts.notoSansKhmer(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: badgeFg,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Center(
                      child: Text(
                        r['date'] ?? '-',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      r['time'] ?? '-',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    ),
  ),
);
      },
    );
  }

  Widget _buildPaymentsTable() {
    final list = _getFilteredPayments();

    if (list.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Text(
            'មិនមានទិន្នន័យបង់ប្រាក់សិស្សទេ',
            style: GoogleFonts.notoSansKhmer(color: const Color(0xFF64748B)),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth =
            constraints.maxWidth < 850 ? 850.0 : constraints.maxWidth;
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Table(
          columnWidths: const {
            0: FixedColumnWidth(140),
            1: FlexColumnWidth(2),
            2: FixedColumnWidth(120),
            3: FixedColumnWidth(120),
            4: FixedColumnWidth(140),
            5: FixedColumnWidth(130),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
              children: [
                _buildHeaderCell('លេខបង្កាន់ដៃ'),
                _buildHeaderCell('ឈ្មោះសិស្ស'),
                _buildHeaderCell('អត្តលេខ'),
                _buildHeaderCell('ចំនួនទឹកប្រាក់', align: TextAlign.right),
                _buildHeaderCell('វិធីសាស្ត្រ', align: TextAlign.center),
                _buildHeaderCell('កាលបរិច្ឆេទ', align: TextAlign.right),
              ],
            ),
            ...list.map(
              (p) => TableRow(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      p['receipt_no'] ?? '-',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      p['student_name_kh'] ?? p['name_kh'] ?? 'សិស្ស',
                      style: GoogleFonts.notoSansKhmer(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      p['student_code'] ?? '-',
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      '\$${p['amount'] ?? 0}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF059669),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          p['payment_method'] ?? 'Cash',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      p['payment_date'] != null
                          ? p['payment_date'].toString().split('T')[0]
                          : '-',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
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
  ),
);
      },
    );
  }

  Widget _buildClassroomsTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth =
            constraints.maxWidth < 750 ? 750.0 : constraints.maxWidth;
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1.5),
            2: FixedColumnWidth(120),
            3: FixedColumnWidth(120),
            4: FixedColumnWidth(140),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
              children: [
                _buildHeaderCell('ឈ្មោះថ្នាក់រៀន'),
                _buildHeaderCell('កម្រិតថ្នាក់'),
                _buildHeaderCell('បន្ទប់លេខ', align: TextAlign.center),
                _buildHeaderCell('ចំណុះអតិបរមា', align: TextAlign.center),
                _buildHeaderCell('វេនសិក្សា', align: TextAlign.right),
              ],
            ),
            ..._classroomRecords.map(
              (c) => TableRow(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      c['class_name'] ?? '',
                      style: GoogleFonts.notoSansKhmer(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      c['grade_name'] ?? '',
                      style: GoogleFonts.notoSansKhmer(
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Center(
                      child: Text(
                        c['room_number'] ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Center(
                      child: Text(
                        '${c['capacity'] ?? 30} នាក់',
                        style: GoogleFonts.notoSansKhmer(
                          color: const Color(0xFF1D4ED8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      c['shift'] ?? 'ព្រឹក',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.notoSansKhmer(
                        color: const Color(0xFF64748B),
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
  ),
);
      },
    );
  }

  Widget _buildDemographicsTable() {
    final male = _summary['maleStudents'] ?? 0;
    final female = _summary['femaleStudents'] ?? 0;
    final total = _summary['totalStudents'] ?? 0;
    final teachers = _summary['totalTeachers'] ?? 0;
    final classrooms = _summary['totalClassrooms'] ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 750;
        final card1 = _buildDemographicCard(
          'សមាមាត្រយេនឌ័រសិស្ស',
          'ប្រុស: $male នាក់ • ស្រី: $female នាក់',
          Icons.wc,
          const Color(0xFF3B82F6),
        );
        final card2 = _buildDemographicCard(
          'បុគ្គលិក និងគ្រូបង្រៀន',
          'សរុប $teachers នាក់',
          Icons.school,
          const Color(0xFF10B981),
        );
        final card3 = _buildDemographicCard(
          'សមាមាត្រសិស្សក្នុងមួយបន្ទប់',
          classrooms > 0
              ? '${(total / classrooms).toStringAsFixed(1)} នាក់/បន្ទប់'
              : '0',
          Icons.meeting_room,
          const Color(0xFFF59E0B),
        );

        if (isNarrow) {
          return Column(
            children: [
              card1,
              const SizedBox(height: 12),
              card2,
              const SizedBox(height: 12),
              card3,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: card1),
            const SizedBox(width: 16),
            Expanded(child: card2),
            const SizedBox(width: 16),
            Expanded(child: card3),
          ],
        );
      },
    );
  }

  Widget _buildDemographicCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.notoSansKhmer(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.notoSansKhmer(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBox(
    String title,
    String value,
    Color bgColor,
    Color fgColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: GoogleFonts.notoSansKhmer(
              fontSize: 11,
              color: fgColor,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.notoSansKhmer(
                fontSize: 20,
                color: fgColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Text(
        text,
        textAlign: align,
        style: GoogleFonts.notoSansKhmer(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF475569),
        ),
      ),
    );
  }
}
