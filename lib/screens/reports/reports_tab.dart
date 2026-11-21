import 'package:school_management_app/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:school_management_app/services/html_print_service.dart';
import 'package:school_management_app/utils/pdf_font_helper.dart';

import '../../utils/translations.dart';

class ReportsTab extends StatefulWidget {
  final dynamic user;
  const ReportsTab({super.key, this.user});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab>
    with SingleTickerProviderStateMixin {
  static String get baseUrl => ApiService.baseUrl;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _generateReportPDF(
    String type,
    String title,
    BuildContext context,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF2563EB)),
      ),
    );

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/reports/summary?type=$type'),
      );
      // ignore: use_build_context_synchronously
      Navigator.pop(context); // Close loading

      if (res.statusCode == 200) {
        final d = jsonDecode(utf8.decode(res.bodyBytes));
        if (d['success'] == true) {
          final data = d['data'];
          _printPDF(title, data);
        }
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      Navigator.pop(context); // Close loading
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('បរាជ័យក្នុងការទាញយករបាយការណ៍!')),
      );
    }
  }

  Future<void> _printPDF(String title, Map<String, dynamic> data) async {
    if (kIsWeb) {
      HtmlPrintService.printGeneralReport(
        title: title,
        subtitle: 'របាយការណ៍ហិរញ្ញវត្ថុ & ចំណូលចំណាយ',
        headers: ['ប្រភេទប្រតិបត្តិការ', 'ចំនួនទឹកប្រាក់ (\$)'],
        rows: [
          ['ចំណូលសរុប (Total Income)', '\$${data['totalIncome']}'],
          ['ចំណាយសរុប (Total Expense)', '\$${data['totalExpense']}'],
          ['ប្រាក់ចំណេញសុទ្ធ (Net Profit)', '\$${data['netProfit']}'],
        ],
      );
      return;
    }

    final pdf = pw.Document();
    final font = await PdfFontHelper.getBoldFont();
    final regular = await PdfFontHelper.getRegularFont();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: regular,
          bold: font,
          fontFallback: [regular, font],
        ),
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'សាលាប្រាយឡាយ',
              style: pw.TextStyle(
                fontSize: 24,
                font: font,
                color: const PdfColor.fromInt(0xFF1E293B),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 18,
                font: regular,
                color: const PdfColor.fromInt(0xFF64748B),
              ),
            ),
            pw.SizedBox(height: 30),
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: const PdfColor.fromInt(0xFFE2E8F0),
                ),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
              ),
              child: pw.Column(
                children: [
                  _pdfRow(
                    'ចំណូលសរុប (Total Income):',
                    '\$${data['totalIncome']}',
                    font,
                    PdfColors.green700,
                  ),
                  pw.Divider(color: const PdfColor.fromInt(0xFFF1F5F9)),
                  _pdfRow(
                    'ចំណាយសរុប (Total Expense):',
                    '\$${data['totalExpense']}',
                    font,
                    PdfColors.red700,
                  ),
                  pw.Divider(color: const PdfColor.fromInt(0xFFF1F5F9)),
                  _pdfRow(
                    'ប្រាក់ចំណេញសុទ្ធ (Net Profit):',
                    '\$${data['netProfit']}',
                    font,
                    PdfColors.blue700,
                  ),
                ],
              ),
            ),
            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'កាលបរិច្ឆេទចេញរបាយការណ៍: ${DateTime.now().toString().split('.')[0]}',
                style: pw.TextStyle(
                  fontSize: 10,
                  font: regular,
                  color: PdfColors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (fmt) async => pdf.save(),
      name: 'bls_report_$title.pdf',
    );
  }

  pw.Widget _pdfRow(
    String label,
    String value,
    pw.Font font,
    PdfColor valueColor,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 14, font: font)),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 16, font: font, color: valueColor),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocaleProvider>(context);
    final lang = loc.locale.languageCode;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Matching Premium Background
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.translate(lang, 'reports'),
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lang == 'km'
                            ? 'គ្រប់គ្រង និងបោះពុម្ពរបាយការណ៍ហិរញ្ញវត្ថុទាំងអស់'
                            : 'Manage and print all financial reports',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.print_rounded, size: 20),
                    label: Text(
                      lang == 'km' ? 'បោះពុម្ពទាំងអស់' : 'Print All',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    onPressed: () => _generateReportPDF(
                      'yearly',
                      'របាយការណ៍សរុបទាំងអស់',
                      context,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              Expanded(
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final crossAxisCount = constraints.maxWidth > 900
                        ? 4
                        : (constraints.maxWidth > 600 ? 2 : 1);
                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      childAspectRatio: 0.9,
                      children: [
                        _buildModernReportCard(
                          lang == 'km'
                              ? 'ប្រចាំថ្ងៃ (Daily)'
                              : 'Daily Closing Report',
                          lang == 'km'
                              ? 'មើលចំណូល-ចំណាយប្រចាំថ្ងៃ'
                              : 'View daily income & expenses',
                          Icons.today_rounded,
                          const Color(0xFF3B82F6),
                          const Color(0xFF2563EB),
                          () => _generateReportPDF(
                            'daily',
                            'របាយការណ៍បិទបញ្ជីប្រចាំថ្ងៃ',
                            context,
                          ),
                        ),
                        _buildModernReportCard(
                          lang == 'km'
                              ? 'ប្រចាំសប្តាហ៍ (Weekly)'
                              : 'Weekly Closing Report',
                          lang == 'km'
                              ? 'សរុបរបាយការណ៍ ៧ ថ្ងៃ'
                              : 'Summary of the last 7 days',
                          Icons.date_range_rounded,
                          const Color(0xFF10B981),
                          const Color(0xFF059669),
                          () => _generateReportPDF(
                            'weekly',
                            'របាយការណ៍បិទបញ្ជីប្រចាំសប្តាហ៍',
                            context,
                          ),
                        ),
                        _buildModernReportCard(
                          lang == 'km'
                              ? 'ប្រចាំខែ (Monthly)'
                              : 'Monthly Closing Report',
                          lang == 'km'
                              ? 'របាយការណ៍សម្រាប់ខែនេះ'
                              : 'Detailed report for the month',
                          Icons.calendar_month_rounded,
                          const Color(0xFFF59E0B),
                          const Color(0xFFD97706),
                          () => _generateReportPDF(
                            'monthly',
                            'របាយការណ៍បិទបញ្ជីប្រចាំខែ',
                            context,
                          ),
                        ),
                        _buildModernReportCard(
                          lang == 'km'
                              ? 'ប្រចាំឆ្នាំ (Yearly)'
                              : 'Yearly Closing Report',
                          lang == 'km'
                              ? 'សរុបរបាយការណ៍ប្រចាំឆ្នាំ'
                              : 'Total annual summary report',
                          Icons.analytics_rounded,
                          const Color(0xFF8B5CF6),
                          const Color(0xFF7C3AED),
                          () => _generateReportPDF(
                            'yearly',
                            'របាយការណ៍បិទបញ្ជីប្រចាំឆ្នាំ',
                            context,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernReportCard(
    String title,
    String subtitle,
    IconData icon,
    Color startColor,
    Color endColor,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          // ignore: deprecated_member_use
          BoxShadow(
            // ignore: deprecated_member_use
            color: endColor.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          // ignore: deprecated_member_use
          hoverColor: startColor.withOpacity(0.05),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon inside an animated gradient container
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [startColor, endColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      // ignore: deprecated_member_use
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: endColor.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 30, color: Colors.white),
                ),
                const Spacer(),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      'បង្កើតរបាយការណ៍ PDF',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: endColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: endColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
