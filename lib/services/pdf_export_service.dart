import 'package:flutter/foundation.dart';
import 'package:school_management_app/utils/app_logo.dart';
import 'package:school_management_app/utils/csv_exporter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:school_management_app/services/html_print_service.dart';
import 'package:school_management_app/utils/pdf_font_helper.dart';

class PdfExportService {
  static Future<void> printTeacherReport(List<dynamic> teachers) async {
    if (kIsWeb) {
      HtmlPrintService.printTeacherReport(teachers);
      return;
    }

    final pdf = pw.Document();
    final fontBold = await PdfFontHelper.getBoldFont();
    final fontRegular = await PdfFontHelper.getRegularFont();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
          fontFallback: [fontRegular, fontBold],
        ),
        build: (pw.Context ctx) => pw.Padding(
          padding: const pw.EdgeInsets.all(16),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Image(AppLogo.pdfImage, width: 36, height: 36),
                    pw.SizedBox(width: 10),
                    pw.Text(
                      'សាលាប្រាយឡាយ - បញ្ជីឈ្មោះបុគ្គលិកអប់រំ និងគ្រូបង្រៀន',
                      style: pw.TextStyle(fontSize: 16, font: fontBold),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),
              pw.TableHelper.fromTextArray(
                headers: [
                  'អត្តលេខ',
                  'ឈ្មោះខ្មែរ',
                  'ឈ្មោះឡាតាំង',
                  'ភេទ',
                  'លេខទូរស័ព្ទ',
                  'មុខវិជ្ជា',
                  'ប្រាក់ខែ (\$)',
                  'ថ្ងៃចូលធ្វើការ',
                ],
                headerStyle: pw.TextStyle(
                  font: fontBold,
                  color: PdfColors.white,
                  fontSize: 10,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF4F46E5),
                ),
                cellStyle: pw.TextStyle(font: fontRegular, fontSize: 9),
                data: teachers
                    .map(
                      (t) => [
                        t['teacher_code'] ?? '',
                        t['name_kh'] ?? '',
                        t['name_en'] ?? '',
                        t['gender'] == 'Male' ? 'ប្រុស' : 'ស្រី',
                        t['phone'] ?? '',
                        t['specialized_subject'] ?? '',
                        '\$${t['base_salary'] ?? 0}',
                        t['hire_date'] ?? t['joined_date'] ?? '',
                      ],
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
    await Printing.layoutPdf(
      onLayout: (fmt) => pdf.save(),
      name: 'teachers_report.pdf',
    );
  }

  static void exportCsv(String fileName, String csvContent) {
    downloadCsv(csvContent, fileName);
  }
}
