// ignore: unused_import
import 'package:flutter/foundation.dart';
import '../utils/app_logo.dart';
import 'api_config.dart';
import 'print_platform_stub.dart'
    if (dart.library.html) 'print_platform_web.dart'
    as platform_print;

/// High-Fidelity Khmer HTML Print Service
/// Employs the browser's native HarfBuzz OpenType shaping engine to guarantee
/// 100% flawless Khmer script ligatures, subscripts (ជើង), and vowel stacking.
class HtmlPrintService {
  // ignore: unused_field
  static const String _fontStyles = '''
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Battambang:wght@400;700&family=Moul&family=Kantumruy+Pro:wght@400;600;700&family=Outfit:wght@400;600;700;800&display=swap" rel="stylesheet">
    <style>
      * {
        box-sizing: border-box;
        -webkit-print-color-adjust: exact !important;
        print-color-adjust: exact !important;
        color-adjust: exact !important;
      }
      @media print {
        * {
          -webkit-print-color-adjust: exact !important;
          print-color-adjust: exact !important;
          color-adjust: exact !important;
        }
      }
      body {
        font-family: 'Khmer OS Battambang', 'Battambang', 'Kantumruy Pro', sans-serif;
        color: #0f172a;
        background: #ffffff;
        margin: 0;
        padding: 0;
        font-size: 12.5px;
        line-height: 1.5;
        -webkit-font-smoothing: antialiased;
      }
      .khmer-muol {
        font-family: 'Khmer OS Muol Light', 'Moul', 'Khmer OS Muol', serif;
        font-weight: 700;
        letter-spacing: 0.2px;
      }
      .en-calibri {
        font-family: 'Calibri Light', 'Segoe UI Light', 'Calibri', sans-serif;
      }
      .header-container {
        display: flex;
        justify-content: space-between;
        align-items: center;
        border-bottom: 2px solid #e2e8f0;
        padding-bottom: 12px;
        margin-bottom: 20px;
      }
      .school-title {
        font-size: 20px;
        color: #0f172a;
        margin: 0 0 4px 0;
      }
      .report-subtitle {
        font-size: 11.5px;
        color: #64748b;
        font-weight: 500;
      }
      .date-badge {
        background: #eef2ff;
        color: #4f46e5;
        border: 1px solid #c7d2fe;
        padding: 6px 14px;
        border-radius: 8px;
        font-weight: 600;
        font-size: 11px;
      }
      .section-heading {
        font-size: 14px;
        color: #1e293b;
        margin: 20px 0 10px 0;
        font-weight: 700;
      }
      table {
        width: 100%;
        border-collapse: collapse;
        margin-bottom: 18px;
        font-size: 11.5px;
      }
      th {
        background-color: #4f46e5;
        color: #ffffff;
        font-weight: 700;
        text-align: left;
        padding: 9px 12px;
        border: 1px solid #4338ca;
        font-family: 'Khmer OS Battambang', 'Battambang', sans-serif;
      }
      th.teal-header {
        background-color: #0d9488;
        border-color: #0f766e;
      }
      td {
        padding: 8px 12px;
        border: 1px solid #cbd5e1;
        color: #1e293b;
      }
      tr:nth-child(even) td {
        background-color: #f8fafc;
      }
      .signatures-row {
        display: flex;
        justify-content: space-between;
        margin-top: 40px;
        padding: 0 40px;
      }
      .sig-column {
        text-align: center;
        width: 220px;
      }
      .sig-title {
        font-weight: 700;
        font-size: 12px;
        margin-bottom: 50px;
        color: #334155;
      }
      .sig-dots {
        color: #94a3b8;
        font-size: 11px;
      }
    </style>
  ''';

  /// Execute HTML Print via hidden iframe
  static void printHtml(
    String bodyContent, {
    String title = 'BLS Report',
    bool isLandscape = false,
    String? customPageStyle,
  }) {
    final pageStyle = customPageStyle ??
        (isLandscape
            ? '<style>@page { size: A4 landscape; margin: 12mm; }</style>'
            : '<style>@page { size: A4 portrait; margin: 12mm 15mm 15mm 15mm; }</style>');

    final fullHtml =
        '''
      <!DOCTYPE html>
      <html lang="km">
      <head>
        <meta charset="utf-8">
        <title>$title</title>
        $pageStyle
        $_fontStyles
        <script>
          function runPrint() {
            var doPrint = function() {
              setTimeout(function() {
                try {
                  window.focus();
                  window.print();
                } catch (e) {
                  console.error('Print trigger failed: ', e);
                }
              }, 120);
            };
            if (document.fonts && document.fonts.ready) {
              document.fonts.ready.then(doPrint).catch(doPrint);
            } else {
              setTimeout(doPrint, 400);
            }
          }
          if (document.readyState === 'complete') {
            runPrint();
          } else {
            window.addEventListener('load', runPrint);
          }
        </script>
      </head>
      <body>
        $bodyContent
      </body>
      </html>
    ''';

    platform_print.executePrint(fullHtml, title, isLandscape);
  }

  /// 1. Print Dashboard Overview Report (Flawless Khmer Text)
  static void printDashboardOverviewReport({
    required Map<String, dynamic> stats,
    required List<dynamic> trends,
  }) {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final totalStudents = stats['totalStudents'] ?? 0;
    final fullTimeStudents = stats['fullTimeStudents'] ?? 0;
    final partTimeStudents = stats['partTimeStudents'] ?? 0;
    final totalTeachers = stats['totalTeachers'] ?? 0;
    final activeTeachers = stats['activeTeachers'] ?? 0;
    final totalClassrooms = stats['totalClassrooms'] ?? 0;
    final fullTimeRooms = stats['fullTimeRooms'] ?? 0;
    final partTimeRooms = stats['partTimeRooms'] ?? 0;
    final todayAttendance = stats['todayAttendance'] ?? 0;
    final attendanceRate = stats['attendanceRate'] ?? 0;
    final absentCount = stats['absentCount'] ?? 0;

    String trendsRowsHtml = '';
    if (trends.isEmpty) {
      trendsRowsHtml =
          '<tr><td colspan="4" style="text-align: center; color: #64748b; padding: 16px;">មិនទាន់មានទិន្នន័យនិន្នាការវត្តមានប្រចាំសប្តាហ៍ទេ</td></tr>';
    } else {
      for (final t in trends) {
        final d = t['date']?.toString() ?? '-';
        final s = t['presentCount'] ?? t['presentStudents'] ?? 0;
        final tc = t['presentTeachers'] ?? 0;
        trendsRowsHtml +=
            '''
          <tr>
            <td style="font-weight: 500;">$d</td>
            <td>$s នាក់</td>
            <td>$tc នាក់</td>
            <td><span style="color: #0d9488; font-weight: 600;">បានកត់ត្រា</span></td>
          </tr>
        ''';
      }
    }

    final htmlContent =
        '''
      <div class="header-container">
        <div style="display: flex; align-items: center; gap: 14px;">
          <img src="data:image/png;base64,${AppLogo.base64Data}" style="width: 52px; height: 52px; border-radius: 50%; object-fit: contain;" />
          <div>
            <h1 class="school-title khmer-muol">សាលាប្រាយឡាយ</h1>
            <div class="report-subtitle">Bright Light School - Dashboard Overview Report</div>
          </div>
        </div>
        <div class="date-badge">
          កាលបរិច្ឆេទ: $dateStr
        </div>
      </div>

      <div class="section-heading khmer-muol">១. ស្ថិតិទូទៅប្រចាំសាលា (Key Performance Metrics)</div>
      <table>
        <thead>
          <tr>
            <th style="width: 30%;">ប្រភេទស្ថិតិ (Metric)</th>
            <th style="width: 18%;">ចំនួនសរុប (Total)</th>
            <th style="width: 36%;">ព័ត៌មានលម្អិត (Details)</th>
            <th style="width: 16%;">ស្ថានភាព (Status)</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><strong>សិស្សសរុប (Students)</strong></td>
            <td>$totalStudents នាក់</td>
            <td>ពេញម៉ោង: $fullTimeStudents | ក្រៅម៉ោង: $partTimeStudents</td>
            <td><span style="color: #10b981; font-weight: 600;">សកម្ម (Active)</span></td>
          </tr>
          <tr>
            <td><strong>គ្រូបង្រៀន (Teachers)</strong></td>
            <td>$totalTeachers នាក់</td>
            <td>សកម្ម: $activeTeachers នាក់</td>
            <td><span style="color: #3b82f6; font-weight: 600;">ពេញសិទ្ធិ</span></td>
          </tr>
          <tr>
            <td><strong>បន្ទប់រៀន (Classrooms)</strong></td>
            <td>$totalClassrooms បន្ទប់</td>
            <td>វេនព្រឹក: $fullTimeRooms | វេនរសៀល: $partTimeRooms</td>
            <td><span style="color: #6366f1; font-weight: 600;">ដំណើរការ</span></td>
          </tr>
          <tr>
            <td><strong>វត្តមានថ្ងៃនេះ (Today Attendance)</strong></td>
            <td>$todayAttendance នាក់</td>
            <td>អត្រាវត្តមាន: $attendanceRate%</td>
            <td><span style="color: #f59e0b; font-weight: 600;">អវត្តមាន: $absentCount នាក់</span></td>
          </tr>
        </tbody>
      </table>

      <div class="section-heading khmer-muol">២. និន្នាការវត្តមាន ៧ ថ្ងៃចុងក្រោយ (Weekly Attendance Trends)</div>
      <table>
        <thead>
          <tr>
            <th class="teal-header" style="width: 25%;">កាលបរិច្ឆេទ (Date)</th>
            <th class="teal-header" style="width: 25%;">សិស្សមានវត្តមាន (Students)</th>
            <th class="teal-header" style="width: 25%;">គ្រូមានវត្តមាន (Teachers)</th>
            <th class="teal-header" style="width: 25%;">ស្ថានភាព</th>
          </tr>
        </thead>
        <tbody>
          $trendsRowsHtml
        </tbody>
      </table>

      <div class="signatures-row">
        <div class="sig-column">
          <div class="sig-title khmer-muol">អ្នករៀបចំរបាយការណ៍</div>
          <div class="sig-dots">(..................................................)</div>
        </div>
        <div class="sig-column">
          <div class="sig-title khmer-muol">នាយកសាលា / គណៈគ្រប់គ្រង</div>
          <div class="sig-dots">(..................................................)</div>
        </div>
      </div>
    ''';

    printHtml(htmlContent, title: 'BLS_Overview_Report_$dateStr');
  }

  /// 2. Print Teacher Report (Landscape)
  static void printTeacherReport(List<dynamic> teachers) {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    String rowsHtml = '';
    for (int i = 0; i < teachers.length; i++) {
      final t = teachers[i];
      final code = t['teacher_code'] ?? '-';
      final nameKh = t['name_kh'] ?? '-';
      final nameEn = t['name_en'] ?? '-';
      final gender = (t['gender'] == 'Male' || t['gender'] == 'ប្រុស')
          ? 'ប្រុស'
          : 'ស្រី';
      final phone = t['phone'] ?? '-';
      final subject = t['specialized_subject'] ?? '-';
      final salary = t['base_salary'] ?? 0;
      final hireDate =
          (t['hire_date'] ?? t['joined_date'])?.toString().split('T')[0] ?? '-';

      rowsHtml +=
          '''
        <tr>
          <td style="text-align: center;">${i + 1}</td>
          <td><strong>$code</strong></td>
          <td><strong>$nameKh</strong></td>
          <td>$nameEn</td>
          <td style="text-align: center;">$gender</td>
          <td>$phone</td>
          <td>$subject</td>
          <td style="font-weight: 600; color: #10b981;">\$$salary</td>
          <td>$hireDate</td>
        </tr>
      ''';
    }

    final htmlContent =
        '''
      <div class="header-container">
        <div style="display: flex; align-items: center; gap: 14px;">
          <img src="data:image/png;base64,${AppLogo.base64Data}" style="width: 52px; height: 52px; border-radius: 50%; object-fit: contain;" />
          <div>
            <h1 class="school-title khmer-muol">សាលាប្រាយឡាយ</h1>
            <div class="report-subtitle">បញ្ជីឈ្មោះបុគ្គលិកអប់រំ និងគ្រូបង្រៀន (Faculty & Staff Directory)</div>
          </div>
        </div>
        <div class="date-badge">កាលបរិច្ឆេទ: $dateStr</div>
      </div>

      <table>
        <thead>
          <tr>
            <th style="width: 5%; text-align: center;">ល.រ</th>
            <th style="width: 11%;">អត្តលេខ</th>
            <th style="width: 17%;">ឈ្មោះខ្មែរ</th>
            <th style="width: 17%;">ឈ្មោះឡាតាំង</th>
            <th style="width: 8%; text-align: center;">ភេទ</th>
            <th style="width: 13%;">លេខទូរស័ព្ទ</th>
            <th style="width: 14%;">មុខវិជ្ជាឯកទេស</th>
            <th style="width: 8%;">ប្រាក់ខែ</th>
            <th style="width: 9%;">ថ្ងៃចូលការងារ</th>
          </tr>
        </thead>
        <tbody>
          $rowsHtml
        </tbody>
      </table>

      <div class="signatures-row" style="margin-top: 30px;">
        <div class="sig-column">
          <div class="sig-title khmer-muol">អ្នករៀបចំបញ្ជី</div>
          <div class="sig-dots">(..................................................)</div>
        </div>
        <div class="sig-column">
          <div class="sig-title khmer-muol">នាយកសាលា</div>
          <div class="sig-dots">(..................................................)</div>
        </div>
      </div>
    ''';

    printHtml(
      htmlContent,
      title: 'BLS_Teachers_Report_$dateStr',
      isLandscape: true,
    );
  }

  /// 3. Print General Table Report (Reports View & Reports Tab)
  static void printGeneralReport({
    required String title,
    required String subtitle,
    required List<String> headers,
    required List<List<String>> rows,
    bool isLandscape = false,
  }) {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    String headersHtml = headers.map((h) => '<th>$h</th>').join();
    String rowsHtml = '';
    for (int i = 0; i < rows.length; i++) {
      final r = rows[i];
      final cells = r.map((c) => '<td>$c</td>').join();
      rowsHtml += '<tr>$cells</tr>';
    }

    final htmlContent =
        '''
      <div class="header-container">
        <div style="display: flex; align-items: center; gap: 14px;">
          <img src="data:image/png;base64,${AppLogo.base64Data}" style="width: 52px; height: 52px; border-radius: 50%; object-fit: contain;" />
          <div>
            <h1 class="school-title khmer-muol">សាលាប្រាយឡាយ</h1>
            <div class="report-subtitle">$title - $subtitle</div>
          </div>
        </div>
        <div class="date-badge">កាលបរិច្ឆេទ: $dateStr</div>
      </div>

      <table>
        <thead><tr>$headersHtml</tr></thead>
        <tbody>$rowsHtml</tbody>
      </table>

      <div class="signatures-row">
        <div class="sig-column">
          <div class="sig-title khmer-muol">ហត្ថលេខាអ្នករៀបចំ</div>
          <div class="sig-dots">(..................................................)</div>
        </div>
        <div class="sig-column">
          <div class="sig-title khmer-muol">ហត្ថលេខានាយកសាលា</div>
          <div class="sig-dots">(..................................................)</div>
        </div>
      </div>
    ''';

    printHtml(
      htmlContent,
      title: 'BLS_${title}_$dateStr',
      isLandscape: isLandscape,
    );
  }

  /// 4. Print Student Report Card (Official Transcript)
  static void printStudentReportCard({
    required String nameKh,
    required String nameEn,
    required String studentCode,
    required String className,
    required List<List<String>> scores,
    String? photoUrl,
  }) {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    String rowsHtml = '';
    double totalScore = 0;
    for (final s in scores) {
      final subj = s[0];
      final sc = double.tryParse(s[1]) ?? 0.0;
      final grade = s.length > 2
          ? s[2]
          : (sc >= 85 ? 'A' : (sc >= 70 ? 'B' : (sc >= 50 ? 'C' : 'F')));
      totalScore += sc;
      rowsHtml +=
          '''
        <tr>
          <td><strong>$subj</strong></td>
          <td style="text-align: center; font-weight: 600;">\${sc.toStringAsFixed(1)}</td>
          <td style="text-align: center; font-weight: 700; color: \${grade == 'A' ? '#10b981' : (grade == 'B' ? '#3b82f6' : (grade == 'C' ? '#f59e0b' : '#ef4444'))};">$grade</td>
        </tr>
      ''';
    }

    final avg = scores.isNotEmpty
        ? (totalScore / scores.length).toStringAsFixed(1)
        : '0.0';
    final avgNum = double.tryParse(avg) ?? 0.0;
    final avgGrade = avgNum >= 85
        ? 'A'
        : (avgNum >= 70 ? 'B' : (avgNum >= 50 ? 'C' : 'F'));

    final photoHtml = (photoUrl != null && photoUrl.isNotEmpty)
        ? '<img src="$photoUrl" style="width: 50px; height: 60px; object-fit: cover; border-radius: 6px; border: 1.5px solid #cbd5e1;" />'
        : '';

    final htmlContent =
        '''
      <div style="display: flex; justify-content: center; align-items: center; gap: 16px; margin-bottom: 20px;">
        <img src="data:image/png;base64,${AppLogo.base64Data}" style="width: 60px; height: 60px; border-radius: 50%; object-fit: contain;" />
        <div style="text-align: center;">
          <div class="khmer-muol" style="font-size: 15px; color: #1e293b; margin-bottom: 4px;">ព្រះរាជាណាចក្រកម្ពុជា<br>ជាតិ សាសនា ព្រះមហាក្សត្រ</div>
          <div style="width: 60px; height: 2px; background: #cbd5e1; margin: 8px auto;"></div>
          <h1 class="school-title khmer-muol" style="font-size: 20px; color: #1e3a8a; margin: 6px 0;">សាលាប្រាយឡាយ</h1>
          <div style="font-size: 13px; font-weight: 700; color: #475569; letter-spacing: 0.5px;">សន្លឹកលទ្ធផលប្រឡងផ្លូវការ / OFFICIAL REPORT CARD</div>
        </div>
      </div>

      <div style="display: flex; justify-content: space-between; align-items: center; border: 1px solid #cbd5e1; border-radius: 8px; padding: 12px 18px; margin-bottom: 18px; background: #f8fafc;">
        <div style="display: flex; align-items: center; gap: 14px;">
          $photoHtml
          <div>
            <div style="margin-bottom: 4px;"><strong>ឈ្មោះសិស្ស៖</strong> <span class="khmer-muol" style="color: #1e3a8a;">$nameKh</span> ($nameEn)</div>
            <div><strong>អត្តលេខ៖</strong> <span>$studentCode</span></div>
          </div>
        </div>
        <div style="text-align: right;">
          <div style="margin-bottom: 4px;"><strong>ថ្នាក់រៀន៖</strong> <strong>$className</strong></div>
          <div><strong>កាលបរិច្ឆេទ៖</strong> <span>$dateStr</span></div>
        </div>
      </div>

      <table>
        <thead>
          <tr>
            <th style="width: 50%;">មុខវិជ្ជា (Subject)</th>
            <th style="width: 25%; text-align: center;">ពិន្ទុ (Score)</th>
            <th style="width: 25%; text-align: center;">និទ្ទេស (Grade)</th>
          </tr>
        </thead>
        <tbody>
          $rowsHtml
          <tr style="background: #eef2ff; font-weight: 700;">
            <td><strong>ពិន្ទុសរុប & មធ្យមភាគ (Average)</strong></td>
            <td style="text-align: center; color: #4f46e5;">$avg / 100</td>
            <td style="text-align: center; color: #4f46e5;">$avgGrade</td>
          </tr>
        </tbody>
      </table>

      <div class="signatures-row" style="margin-top: 50px;">
        <div class="sig-column">
          <div class="sig-title khmer-muol">ហត្ថលេខាគ្រូបន្ទុកថ្នាក់</div>
          <div class="sig-dots">(..................................................)</div>
        </div>
        <div class="sig-column">
          <div class="sig-title khmer-muol">ហត្ថលេខានិងត្រានាយកសាលា</div>
          <div class="sig-dots">(..................................................)</div>
        </div>
      </div>
    ''';

    printHtml(htmlContent, title: 'BLS_ReportCard_${studentCode}_$dateStr');
  }

  /// 5.0 Print Directly Captured ID Card Design (Pixel-perfect WYSIWYG)
  static void printCapturedIdCards({
    String? frontPngBase64,
    String? backPngBase64,
    required String code,
    required String name,
    bool isLandscape = true,
    String cardSide = 'Both',
    bool sheetA4 = true,
  }) {
    final showFront = (cardSide == 'Front' || cardSide == 'Both') &&
        (frontPngBase64 != null && frontPngBase64.isNotEmpty);
    final showBack = (cardSide == 'Back' || cardSide == 'Both') &&
        (backPngBase64 != null && backPngBase64.isNotEmpty);

    final cardWidth = isLandscape ? '85.6mm' : '53.98mm';
    final cardHeight = isLandscape ? '53.98mm' : '85.6mm';

    final frontCardImg = showFront
        ? '<img src="data:image/png;base64,$frontPngBase64" style="width: $cardWidth; height: $cardHeight; object-fit: contain; border-radius: 3.2mm; display: block; box-shadow: 0 4px 12px rgba(0,0,0,0.15);" />'
        : '';

    final backCardImg = showBack
        ? '<img src="data:image/png;base64,$backPngBase64" style="width: $cardWidth; height: $cardHeight; object-fit: contain; border-radius: 3.2mm; display: block; box-shadow: 0 4px 12px rgba(0,0,0,0.15);" />'
        : '';

    final frontCardSection = showFront
        ? '''
          <div style="display: flex; flex-direction: column; align-items: center;">
            <div style="font-size: 7.5px; font-weight: 800; color: #334155; margin-bottom: 1.5mm; font-family: 'Outfit', sans-serif; letter-spacing: 0.5px;">
              --- ខាងមុខ (FRONT SIDE) ---
            </div>
            <div class="cutting-guide">
              $frontCardImg
            </div>
          </div>
          '''
        : '';

    final backCardSection = showBack
        ? '''
          <div style="display: flex; flex-direction: column; align-items: center;">
            <div style="font-size: 7.5px; font-weight: 800; color: #334155; margin-bottom: 1.5mm; font-family: 'Outfit', sans-serif; letter-spacing: 0.5px;">
              --- ខាងក្រោយ (BACK SIDE) ---
            </div>
            <div class="cutting-guide">
              $backCardImg
            </div>
          </div>
          '''
        : '';

    final pvcFrontSection = showFront
        ? '<div class="pvc-card-page"><img src="data:image/png;base64,$frontPngBase64" style="width:100%;height:100%;object-fit:cover;display:block;" /></div>'
        : '';
    final pvcBackSection = showBack
        ? '<div class="pvc-card-page" style="page-break-after: avoid; break-after: avoid;"><img src="data:image/png;base64,$backPngBase64" style="width:100%;height:100%;object-fit:cover;display:block;" /></div>'
        : '';

    final htmlContent = sheetA4
        ? '''
      <style>
        * { box-sizing: border-box; }
        html, body {
          margin: 0 !important;
          padding: 0 !important;
          width: 100% !important;
          height: auto !important;
          background: #ffffff !important;
        }
        @media print {
          html, body {
            width: 100% !important;
            height: auto !important;
            margin: 0 !important;
            padding: 0 !important;
            overflow: hidden !important;
          }
          .print-wrapper {
            page-break-after: avoid !important;
            break-after: avoid !important;
            page-break-inside: avoid !important;
            break-inside: avoid !important;
          }
        }
        .cutting-guide {
          padding: 1.5mm;
          border: 1.2px dashed #94a3b8;
          border-radius: 4.5mm;
          background: #ffffff;
          box-shadow: 0 2px 8px rgba(0,0,0,0.06);
          display: inline-block;
        }
      </style>
      <div class="print-wrapper" style="padding: 4mm 6mm; background: #ffffff; display: flex; flex-direction: column; align-items: center; justify-content: flex-start; box-sizing: border-box;">
        
        <!-- Sheet Instruction Banner -->
        <div style="text-align: center; margin-bottom: 3mm;">
          <div style="display: flex; align-items: center; justify-content: center; gap: 2.5mm; margin-bottom: 0.8mm;">
            <img src="data:image/png;base64,${AppLogo.base64Data}" style="width: 6mm; height: 6mm; border-radius: 50%;" />
            <span class="khmer-muol" style="font-size: 11px; color: #1e3a8a;">សាលាប្រាយ ឡាយ • សន្លឹកបោះពុម្ពប័ណ្ណសម្គាល់ខ្លួនផ្លូវការ</span>
          </div>
          <div style="font-family: 'Outfit', sans-serif; font-size: 7px; color: #475569; font-weight: 700; letter-spacing: 0.8px;">
            BRIGHT LIGHT INTERNATIONAL SCHOOL • HIGH-DEFINITION OFFICIAL ID CARDS (ISO CR-80)
          </div>
          <div style="font-size: 6.5px; color: #64748b; margin-top: 0.4mm;">
            ✂️ កាត់តាមបន្ទាត់ដាច់ៗ (Crop Marks) រួចបត់ចូលគ្នា ឬអ៊ុតប្លាស្ទិក (Laminate) កម្រាស់ 80 - 125 Micron
          </div>
        </div>

        <!-- Cards Row Side-by-Side -->
        <div style="display: flex; flex-wrap: nowrap; justify-content: center; align-items: flex-start; gap: 6mm;">
          $frontCardSection
          $backCardSection
        </div>
      </div>
    '''
        : '''
      <style>
        * { box-sizing: border-box; }
        @media print {
          body { 
            background: #ffffff !important; 
            padding: 0 !important;
            margin: 0 !important;
          }
          .pvc-card-page { 
            width: $cardWidth !important;
            height: $cardHeight !important;
            page-break-after: always !important; 
            break-after: page !important;
            margin: 0 !important;
            padding: 0 !important;
            overflow: hidden !important;
            display: flex !important;
            align-items: center !important;
            justify-content: center !important;
          }
        }
      </style>
      <div style="margin: 0; padding: 0;">
        $pvcFrontSection
        $pvcBackSection
      </div>
    ''';

    final pageStyle = sheetA4
        ? '<style>@page { size: A4 landscape; margin: 6mm; } html, body { margin: 0; padding: 0; height: auto; overflow: hidden; } * { -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important; color-adjust: exact !important; }</style>'
        : '<style>@page { size: $cardWidth $cardHeight ${isLandscape ? "landscape" : "portrait"}; margin: 0; } * { -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important; color-adjust: exact !important; } body { margin: 0; padding: 0; background: #ffffff; }</style>';

    printHtml(
      htmlContent,
      title: 'BLS_ID_Card_$code',
      isLandscape: isLandscape,
      customPageStyle: pageStyle,
    );
  }

  /// 5. Print Official ID Card (ISO/IEC 7810 ID-1 Standard CR-80)
  static void printIdCard({
    required String nameKh,
    required String nameEn,
    required String code,
    required String role,
    required String grade,
    required String phone,
    String? dob,
    String? gender,
    String? photoUrl,
    String? qrBase64,
    bool isLandscape = true,
    String cardSide = 'Both',
    String themeColorHex = '#2563eb',
    String academicYear = '2025-2026',
    bool sheetA4 = true,
  }) {
    String resolvedPhoto = (photoUrl ?? '').trim();
    if (resolvedPhoto.isNotEmpty &&
        !resolvedPhoto.startsWith('http://') &&
        !resolvedPhoto.startsWith('https://') &&
        !resolvedPhoto.startsWith('data:image')) {
      final origin = ApiConfig.baseUrl.replaceAll('/api', '');
      resolvedPhoto =
          '$origin/${resolvedPhoto.startsWith('/') ? resolvedPhoto.substring(1) : resolvedPhoto}';
    }

    // Clean, modern CSS-only fallback with zero onerror scripts
    final photoMarkup = resolvedPhoto.isNotEmpty
        ? '''
          <div style="width:100%;height:100%;overflow:hidden;background:#e2e8f0;display:flex;align-items:center;justify-content:center;">
            <img src="$resolvedPhoto" style="width:100%;height:100%;object-fit:cover;display:block;" />
          </div>'''
        : '''
          <div style="width:100%;height:100%;display:flex;align-items:center;justify-content:center;background:#e2e8f0;">
            <svg xmlns="http://www.w3.org/2000/svg" width="45%" height="45%" viewBox="0 0 24 24" fill="#94a3b8"><path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/></svg>
          </div>''';

    final showFront = cardSide == 'Front' || cardSide == 'Both';
    final showBack = cardSide == 'Back' || cardSide == 'Both';

    final cardWidth = isLandscape ? '85.6mm' : '53.98mm';
    final cardHeight = isLandscape ? '53.98mm' : '85.6mm';
    final isTeacher =
        role.contains('គ្រូ') ||
        role.toLowerCase().contains('teacher') ||
        role.toLowerCase().contains('faculty');
    final roleKh = isTeacher
        ? (role.contains('គ្រូ') ? role : 'គ្រូបង្រៀន')
        : (role.isNotEmpty && role != 'សិស្សានុសិស្ស' && role != 'សិស្ស'
              ? role
              : 'សិស្សពេញសិទ្ធ');
    final roleEn = isTeacher ? 'FACULTY' : 'STUDENT';

    // SVG Metallic Gold Smart Card Chip
    // ignore: unused_local_variable
    const smartChipSvg = '''
      <svg width="28" height="19" viewBox="0 0 28 19" fill="none" xmlns="http://www.w3.org/2000/svg" style="display: block; width: 100%; height: 100%;">
        <rect width="28" height="19" rx="2.5" fill="url(#chipGrad)" stroke="#b45309" stroke-width="0.7"/>
        <rect x="4.5" y="2.5" width="8" height="5" rx="0.8" fill="#fde047" stroke="#b45309" stroke-width="0.4"/>
        <rect x="15.5" y="2.5" width="8" height="5" rx="0.8" fill="#fde047" stroke="#b45309" stroke-width="0.4"/>
        <rect x="4.5" y="11.5" width="8" height="5" rx="0.8" fill="#fde047" stroke="#b45309" stroke-width="0.4"/>
        <rect x="15.5" y="11.5" width="8" height="5" rx="0.8" fill="#fde047" stroke="#b45309" stroke-width="0.4"/>
        <path d="M12.5 5H15.5M12.5 14H15.5M14 0V19" stroke="#b45309" stroke-width="0.5"/>
        <defs>
          <linearGradient id="chipGrad" x1="0" y1="0" x2="28" y2="19" gradientUnits="userSpaceOnUse">
            <stop stop-color="#fef08a"/>
            <stop offset="0.5" stop-color="#f59e0b"/>
            <stop offset="1" stop-color="#d97706"/>
          </linearGradient>
        </defs>
      </svg>
    ''';

    final frontWatermarkLogo =
        '''
      <div style="position: absolute; right: 5mm; bottom: 3mm; width: 36mm; height: 36mm; opacity: 0.055; pointer-events: none; z-index: 1;">
        <img src="data:image/png;base64,${AppLogo.base64Data}" style="width: 100%; height: 100%; object-fit: contain; filter: grayscale(100%);" />
      </div>
    ''';

    final backWatermarkLogo =
        '''
      <div style="position: absolute; left: 50%; top: 52%; transform: translate(-50%, -50%); width: 34mm; height: 34mm; opacity: 0.05; pointer-events: none; z-index: 1;">
        <img src="data:image/png;base64,${AppLogo.base64Data}" style="width: 100%; height: 100%; object-fit: contain; filter: grayscale(100%);" />
      </div>
    ''';

    final qrMarkup = (qrBase64 != null && qrBase64.isNotEmpty)
        ? '<img src="data:image/png;base64,$qrBase64" style="width: 100%; height: 100%; object-fit: contain;" />'
        : '<img src="https://api.qrserver.com/v1/create-qr-code/?size=100x100&data=$code" style="width: 100%; height: 100%; object-fit: contain;" />';

    // Front Card HTML
    final frontCardHtml = isLandscape
        ? '''
      <div class="id-card" style="width: $cardWidth; height: $cardHeight; box-sizing: border-box; border-radius: 3.2mm; background: #ffffff; box-shadow: 0 4px 14px rgba(0,0,0,0.12); position: relative; overflow: hidden; border: 1px solid #cbd5e1; page-break-inside: avoid; -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important;">
        $frontWatermarkLogo

        <!-- Left Sidebar (Hero Photo & Identity Block) -->
        <div style="position: absolute; left: 0; top: 0; bottom: 0; width: 29.5mm; background: linear-gradient(180deg, $themeColorHex 0%, #0f172a 100%); z-index: 2; display: flex; flex-direction: column; align-items: center; justify-content: center; box-shadow: 2px 0 8px rgba(0,0,0,0.2);">
          
          <!-- Photo Container (Centered, 3:4 aspect, double border) -->
          <div style="width: 18.5mm; height: 23.5mm; background: #ffffff; border-radius: 2mm; border: 1.5px solid #ffffff; box-shadow: 0 2px 8px rgba(0,0,0,0.3); overflow: hidden; display: flex; align-items: center; justify-content: center; margin-bottom: 2mm;">
            $photoMarkup
          </div>

          <!-- Role Badge Pill -->
          <div style="background: rgba(255,255,255,0.96); color: #0f172a; font-family: 'Outfit', 'Khmer OS Battambang', 'Battambang', sans-serif; font-size: 5.6px; font-weight: 800; padding: 0.6mm 2.2mm; border-radius: 2mm; box-shadow: 0 1px 3px rgba(0,0,0,0.2); text-align: center; white-space: nowrap; letter-spacing: 0.3px; border: 0.5px solid rgba(0,0,0,0.06);">
            <span style="color: $themeColorHex;">●</span> $roleKh • $roleEn
          </div>

          <!-- Cardholder Code -->
          <div style="margin-top: 1.4mm; font-family: 'Outfit', sans-serif; font-size: 7.2px; font-weight: 900; color: #ffffff; letter-spacing: 0.8px; text-shadow: 0 1px 2px rgba(0,0,0,0.5);">
            $code
          </div>
        </div>

        <!-- Gold Hairline Divider -->
        <div style="position: absolute; left: 29.5mm; top: 0; bottom: 0; width: 0.8mm; background: linear-gradient(180deg, #f59e0b 0%, #fbbf24 50%, #d97706 100%); z-index: 3;"></div>

        <!-- Right Content Block -->
        <div style="position: absolute; left: 32.5mm; right: 3mm; top: 2.2mm; bottom: 2.2mm; z-index: 4; display: flex; flex-direction: column; justify-content: space-between;">
          
          <!-- Header Row -->
          <div>
            <div style="display: flex; align-items: center; justify-content: space-between; padding-bottom: 0.9mm; border-bottom: 0.8px solid #e2e8f0;">
              <div style="display: flex; align-items: center; gap: 1.8mm;">
                <div style="width: 6.8mm; height: 6.8mm; border-radius: 50%; border: 0.8px solid $themeColorHex; background: #ffffff; display: flex; align-items: center; justify-content: center; overflow: hidden; flex-shrink: 0; box-shadow: 0 1px 3px rgba(0,0,0,0.08);">
                  <img src="data:image/png;base64,${AppLogo.base64Data}" style="width: 5.8mm; height: 5.8mm; object-fit: contain;" />
                </div>
                <div style="display: flex; flex-direction: column;">
                  <div style="font-family: 'Khmer OS Muol Light', 'Moul', 'Khmer OS Battambang', sans-serif; font-size: 7.6px; font-weight: 700; color: #1e3a8a; line-height: 1.2;">សាលាប្រាយ ឡាយ</div>
                  <div style="font-family: 'Outfit', sans-serif; font-size: 4.8px; font-weight: 800; color: $themeColorHex; letter-spacing: 0.8px; line-height: 1.1;">BRIGHT LIGHT INTERNATIONAL SCHOOL</div>
                </div>
              </div>
              <div style="background: #eff6ff; border: 0.5px solid #bfdbfe; border-radius: 1.2mm; padding: 0.5mm 1.8mm; font-family: 'Outfit', sans-serif; font-size: 5.2px; font-weight: 800; color: #1d4ed8;">
                $academicYear
              </div>
            </div>

            <!-- Member Names -->
            <div style="margin-top: 1.2mm;">
              <div style="font-family: 'Outfit', sans-serif; font-size: 10px; font-weight: 900; color: #0f172a; letter-spacing: 0.4px; line-height: 1.1; text-transform: uppercase; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">
                $nameEn
              </div>
              ${nameKh.isNotEmpty ? '<div style="font-family: \'Khmer OS Battambang\', \'Battambang\', sans-serif; font-size: 8px; font-weight: 700; color: #334155; line-height: 1.15; margin-top: 0.3mm; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">$nameKh</div>' : ''}
            </div>
          </div>

          <!-- Data Table Grid -->
          <div style="background: #f8fafc; border: 0.6px solid #e2e8f0; border-radius: 1.8mm; padding: 1.1mm 1.6mm;">
            <table style="width: 100%; border-collapse: collapse; font-size: 6px; margin: 0;">
              <tr>
                <td style="width: 25.5mm; padding: 0.35mm 0.5mm; border: none; vertical-align: middle;">
                  <span style="display: inline-block; width: 7.2mm; color: #64748b; font-family: 'Outfit', sans-serif; font-size: 5.2px; font-weight: 800;">ID NO:</span>
                  <strong style="font-family: 'Outfit', sans-serif; font-weight: 800; color: $themeColorHex; font-size: 6.4px;">$code</strong>
                </td>
                <td style="padding: 0.35mm 0.5mm; border: none; vertical-align: middle;">
                  <span style="display: inline-block; width: 7.2mm; color: #64748b; font-family: 'Outfit', sans-serif; font-size: 5.2px; font-weight: 800;">DOB:</span>
                  <span style="font-family: 'Outfit', sans-serif; font-weight: 700; color: #1e293b; font-size: 6px;">${dob?.isNotEmpty == true ? dob : '2004-09-24'}</span>
                </td>
              </tr>
              <tr>
                <td style="width: 25.5mm; padding: 0.35mm 0.5mm; border: none; vertical-align: middle;">
                  <span style="display: inline-block; width: 7.2mm; color: #64748b; font-family: 'Outfit', sans-serif; font-size: 5.2px; font-weight: 800;">${isTeacher ? 'DEPT:' : 'CLASS:'}</span>
                  <strong style="font-family: 'Khmer OS Battambang', 'Battambang', sans-serif; font-weight: 700; color: #1e293b; font-size: 6px;">$grade</strong>
                </td>
                <td style="padding: 0.35mm 0.5mm; border: none; vertical-align: middle;">
                  <span style="display: inline-block; width: 7.2mm; color: #64748b; font-family: 'Outfit', sans-serif; font-size: 5.2px; font-weight: 800;">TEL:</span>
                  <span style="font-family: 'Outfit', sans-serif; font-weight: 700; color: #1e293b; font-size: 6px;">$phone</span>
                </td>
              </tr>
            </table>
          </div>

          <!-- Bottom Bar: Verified Security Pill & QR Code -->
          <div style="display: flex; align-items: center; justify-content: space-between; padding-top: 0.4mm;">
            <div style="display: flex; align-items: center; gap: 1.2mm;">
              <span style="display: inline-flex; align-items: center; justify-content: center; width: 3.5mm; height: 3.5mm; border-radius: 50%; background: #2563eb; color: #ffffff; font-size: 3.5px; font-weight: 900;">✓</span>
              <div style="display: flex; flex-direction: column;">
                <span style="font-family: 'Outfit', sans-serif; font-size: 4.8px; font-weight: 800; color: #334155; letter-spacing: 0.4px;">OFFICIAL SECURE CREDENTIAL</span>
                <span style="font-family: 'Outfit', sans-serif; font-size: 4.2px; font-weight: 600; color: #94a3b8; letter-spacing: 0.3px;">BRIGHT LIGHT SCHOOL • ISO CR-80</span>
              </div>
            </div>
            <div style="width: 8.8mm; height: 8.8mm; background: #ffffff; border: 0.7px solid #cbd5e1; border-radius: 1.4mm; padding: 0.4mm; display: flex; align-items: center; justify-content: center; box-shadow: 0 1px 3px rgba(0,0,0,0.06); flex-shrink: 0;">
              $qrMarkup
            </div>
          </div>
        </div>
      </div>
    '''
        : '''
      <!-- Portrait Front Card -->
      <div class="id-card" style="width: $cardWidth; height: $cardHeight; box-sizing: border-box; border-radius: 3.2mm; background: #ffffff; box-shadow: 0 4px 14px rgba(0,0,0,0.12); position: relative; overflow: hidden; display: flex; flex-direction: column; justify-content: space-between; border: 1px solid #cbd5e1; page-break-inside: avoid; -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important;">
        $frontWatermarkLogo

        <!-- Top Header Banner -->
        <div style="position: relative; z-index: 2;">
          <div style="background: linear-gradient(135deg, #1e3a8a 0%, $themeColorHex 65%, #0284c7 100%); padding: 2.2mm 2.8mm; display: flex; align-items: center; justify-content: space-between; box-shadow: 0 2px 6px rgba(0,0,0,0.15);">
            <div style="display: flex; align-items: center; gap: 1.8mm;">
              <div style="width: 7.2mm; height: 7.2mm; background: #ffffff; border-radius: 50%; border: 1px solid #fbbf24; display: flex; align-items: center; justify-content: center; box-shadow: 0 1.5px 3px rgba(0,0,0,0.25); flex-shrink: 0;">
                <img src="data:image/png;base64,${AppLogo.base64Data}" style="width: 6.2mm; height: 6.2mm; border-radius: 50%; object-fit: contain;" />
              </div>
              <div>
                <div style="font-family: 'Khmer OS Muol Light', 'Moul', 'Khmer OS Battambang', sans-serif; font-size: 7.5px; font-weight: 700; color: #ffffff; line-height: 1.15; text-shadow: 0 1px 2px rgba(0,0,0,0.35);">សាលាប្រាយ ឡាយ</div>
                <div style="font-family: 'Outfit', sans-serif; font-size: 4.6px; font-weight: 800; color: #fde68a; letter-spacing: 0.8px;">BRIGHT LIGHT SCHOOL</div>
              </div>
            </div>
            <div style="background: rgba(255,255,255,0.2); border: 0.6px solid rgba(255,255,255,0.45); border-radius: 1.2mm; padding: 0.4mm 1.5mm; text-align: center;">
              <div style="font-family: 'Outfit', sans-serif; font-size: 4.8px; font-weight: 800; color: #ffffff;">$academicYear</div>
            </div>
          </div>
          <!-- Gold accent line -->
          <div style="height: 0.7mm; background: linear-gradient(90deg, #f59e0b, #fbbf24, #d97706);"></div>
        </div>

        <!-- Portrait Body -->
        <div style="display: flex; flex-direction: column; align-items: center; padding: 1.5mm 2.8mm; position: relative; z-index: 2; flex: 1; justify-content: space-between;">
          
          <!-- Photo Box -->
          <div style="width: 20mm; height: 25mm; border-radius: 2mm; border: 1.5px solid #ffffff; box-shadow: 0 2px 8px rgba(0,0,0,0.25); overflow: hidden; background: #f8fafc; display: flex; align-items: center; justify-content: center; margin-top: 0.8mm;">
            $photoMarkup
          </div>

          <!-- Names & Role -->
          <div style="text-align: center; margin-top: 0.8mm;">
            <div style="font-family: 'Outfit', sans-serif; font-size: 9.5px; font-weight: 900; color: #0f172a; text-transform: uppercase; letter-spacing: 0.4px;">$nameEn</div>
            ${nameKh.isNotEmpty ? '<div style="font-family: \'Khmer OS Battambang\', \'Battambang\', sans-serif; font-size: 7.8px; font-weight: 700; color: #334155; line-height: 1.15; margin-top: 0.2mm;">$nameKh</div>' : ''}
            <div style="margin-top: 0.6mm; display: inline-block; background: linear-gradient(135deg, $themeColorHex, #0f172a); color: #ffffff; font-family: 'Outfit', 'Khmer OS Battambang', sans-serif; font-size: 5.2px; font-weight: 800; padding: 0.4mm 2.5mm; border-radius: 1.8mm; letter-spacing: 0.4px; box-shadow: 0 1px 3px rgba(0,0,0,0.15);">
              $roleKh • $roleEn
            </div>
          </div>

          <!-- Details Grid -->
          <div style="background: #f8fafc; border: 0.6px solid #e2e8f0; border-radius: 1.6mm; width: 100%; padding: 0.9mm 1.8mm; font-size: 5.8px; line-height: 1.35; margin: 0.6mm 0;">
            <div style="display: flex; justify-content: space-between; padding: 0.2mm 0;">
              <span style="color: #64748b; font-weight: 800; font-family: 'Outfit', sans-serif;">ID NO:</span>
              <span style="font-family: 'Outfit', sans-serif; font-weight: 800; color: $themeColorHex;">$code</span>
            </div>
            <div style="display: flex; justify-content: space-between; padding: 0.2mm 0;">
              <span style="color: #64748b; font-weight: 800; font-family: 'Outfit', sans-serif;">${isTeacher ? 'DEPT:' : 'CLASS:'}</span>
              <span style="font-family: 'Khmer OS Battambang', 'Battambang', sans-serif; font-weight: 700; color: #1e293b;">$grade</span>
            </div>
            <div style="display: flex; justify-content: space-between; padding: 0.2mm 0;">
              <span style="color: #64748b; font-weight: 800; font-family: 'Outfit', sans-serif;">DOB:</span>
              <span style="font-family: 'Outfit', sans-serif; font-weight: 700; color: #1e293b;">${dob?.isNotEmpty == true ? dob : '2004-09-24'}</span>
            </div>
            <div style="display: flex; justify-content: space-between; padding: 0.2mm 0;">
              <span style="color: #64748b; font-weight: 800; font-family: 'Outfit', sans-serif;">TEL:</span>
              <span style="font-family: 'Outfit', sans-serif; font-weight: 700; color: #1e293b;">$phone</span>
            </div>
          </div>

          <!-- QR Code & Verified -->
          <div style="display: flex; align-items: center; justify-content: space-between; width: 100%; padding: 0 1mm 0.5mm 1mm;">
            <div style="display: flex; flex-direction: column;">
              <span style="font-family: 'Outfit', sans-serif; font-size: 4.8px; font-weight: 800; color: #334155;">OFFICIAL CREDENTIAL</span>
              <span style="font-family: 'Outfit', sans-serif; font-size: 4px; font-weight: 600; color: #94a3b8;">ISO CR-80 SECURE</span>
            </div>
            <div style="width: 8.8mm; height: 8.8mm; background: #ffffff; border: 0.6px solid #cbd5e1; border-radius: 1.2mm; padding: 0.4mm; display: flex; align-items: center; justify-content: center; box-shadow: 0 1px 3px rgba(0,0,0,0.06);">
              $qrMarkup
            </div>
          </div>
        </div>

        <!-- Bottom Footer -->
        <div style="height: 3.2mm; background: #0f172a; color: #94a3b8; display: flex; justify-content: space-between; align-items: center; padding: 0 2.5mm; font-size: 4.6px; font-family: 'Outfit', sans-serif; position: relative; z-index: 2;">
          <span style="color: #cbd5e1; font-weight: 600;">OFFICIAL IDENTITY CARD</span>
          <span style="color: #fbbf24; font-weight: 700;">BRIGHT LIGHT SCHOOL</span>
        </div>
      </div>
    ''';

    // Back Card HTML
    final backCardHtml = isLandscape
        ? '''
      <div class="id-card" style="width: $cardWidth; height: $cardHeight; box-sizing: border-box; border-radius: 3.2mm; background: #ffffff; box-shadow: 0 4px 14px rgba(0,0,0,0.12); position: relative; overflow: hidden; display: flex; flex-direction: column; justify-content: space-between; border: 1px solid #cbd5e1; page-break-inside: avoid; -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important;">
        $backWatermarkLogo

        <!-- Top Dark Header Banner -->
        <div style="height: 5.2mm; background: linear-gradient(90deg, #1e3a8a 0%, $themeColorHex 50%, #0f172a 100%); display: flex; align-items: center; justify-content: space-between; padding: 0 3mm; position: relative; z-index: 2;">
          <div style="display: flex; align-items: center; gap: 1.5mm;">
            <img src="data:image/png;base64,${AppLogo.base64Data}" style="width: 4.2mm; height: 4.2mm; border-radius: 50%; border: 0.6px solid #fbbf24;" />
            <span style="font-family: 'Khmer OS Battambang', 'Battambang', sans-serif; font-size: 5.5px; font-weight: 700; color: #ffffff;">សាលាប្រាយ ឡាយ</span>
            <span style="color: rgba(255,255,255,0.6); font-size: 5px;">•</span>
            <span style="font-family: 'Outfit', sans-serif; font-size: 5px; font-weight: 800; color: #fde68a; letter-spacing: 0.6px;">BRIGHT LIGHT SCHOOL</span>
          </div>
          <span style="font-family: 'Outfit', monospace; font-size: 5px; font-weight: 800; color: #ffffff;">$code</span>
        </div>

        <!-- Center 2-Column Body -->
        <div style="padding: 1.2mm 2.8mm; position: relative; z-index: 2; flex: 1; display: flex; justify-content: space-between; gap: 2.5mm;">
          
          <!-- Left Rules Box -->
          <div style="flex: 1.15; background: #f8fafc; border: 0.6px solid #e2e8f0; border-radius: 1.8mm; padding: 1.4mm 1.8mm; display: flex; flex-direction: column; justify-content: space-between;">
            <div>
              <div style="font-family: 'Khmer OS Battambang', 'Battambang', sans-serif; font-size: 5.8px; font-weight: 700; color: $themeColorHex; margin-bottom: 0.8mm; text-align: center; border-bottom: 0.5px solid #e2e8f0; padding-bottom: 0.5mm;">
                • វិន័យ និងបទបញ្ជាផ្ទៃក្នុង •
              </div>
              <div style="font-family: 'Khmer OS Battambang', 'Battambang', sans-serif; font-size: 4.8px; color: #334155; line-height: 1.48; text-align: left; padding: 0 0.5mm;">
                <div style="margin-bottom: 0.5mm;">១. ត្រូវពាក់ប័ណ្ណនេះជាប់ខ្លួនជានិច្ចពេលនៅក្នុងសាលា។</div>
                <div style="margin-bottom: 0.5mm;">២. ហាមកែប្រែ ក្លែងបន្លំ ឬប្រគល់ឱ្យអ្នកដទៃប្រើប្រាស់។</div>
                <div style="margin-bottom: 0.5mm;">៣. ករណីបាត់បង់ សូមរាយការណ៍មកការិយាល័យជាបន្ទាន់។</div>
                <div>៤. ប័ណ្ណនេះជាសម្បត្តិផ្លូវការរបស់សាលាប្រាយ ឡាយ។</div>
              </div>
            </div>
            <div style="margin-top: 1mm; background: #eff6ff; border: 0.4px solid #bfdbfe; border-radius: 1mm; padding: 0.4mm 0.8mm; text-align: center; font-family: 'Outfit', sans-serif; font-size: 4.4px; font-weight: 800; color: #1d4ed8; letter-spacing: 0.4px;">
              DISCIPLINE • RESPECT • INTEGRITY • EXCELLENCE
            </div>
          </div>

          <!-- Right Administration & Principal Approval -->
          <div style="flex: 0.95; display: flex; flex-direction: column; justify-content: space-between; padding: 0.4mm 0;">
            <div>
              <div style="font-family: 'Khmer OS Battambang', 'Battambang', sans-serif; font-size: 5.2px; font-weight: 700; color: #2563eb;">ការិយាល័យរដ្ឋបាល (Hotline):</div>
              <div style="font-family: 'Outfit', sans-serif; font-size: 6px; font-weight: 800; color: #0f172a; margin-top: 0.2mm;">078 350 908 / 088 757 4732</div>
              <div style="font-family: 'Khmer OS Battambang', 'Battambang', sans-serif; font-size: 4.6px; color: #64748b; margin-top: 0.3mm;">អាសយដ្ឋាន៖ រាជធានីភ្នំពេញ, កម្ពុជា</div>
            </div>

            <!-- Principal Seal & Signature -->
            <div style="display: flex; flex-direction: column; align-items: center; margin-top: 0.5mm;">
              <div style="font-family: 'Outfit', 'Khmer OS Battambang', sans-serif; font-size: 5.2px; font-weight: 700; color: #0f172a;">នាយកសាលា / Principal</div>
              <div style="position: relative; width: 22mm; height: 11mm; display: flex; align-items: center; justify-content: center; margin: 0.3mm 0;">
                <!-- SVG Official Red Stamp Graphic -->
                <svg width="40" height="40" viewBox="0 0 100 100" style="position: absolute; opacity: 0.85; transform: rotate(-6deg);">
                  <circle cx="50" cy="50" r="46" fill="none" stroke="#dc2626" stroke-width="2.5" stroke-dasharray="4,2"/>
                  <circle cx="50" cy="50" r="40" fill="none" stroke="#dc2626" stroke-width="1.5"/>
                  <path id="sealPathLand" d="M 22,50 A 28,28 0 1,1 78,50" fill="none"/>
                  <text font-family="'Khmer OS Battambang', sans-serif" font-size="7.5" fill="#dc2626" font-weight="bold" text-anchor="middle">
                    <textPath href="#sealPathLand" startOffset="50%">សាលាប្រាយ ឡាយ</textPath>
                  </text>
                  <circle cx="50" cy="50" r="21" fill="#fef2f2" stroke="#dc2626" stroke-width="1"/>
                  <text x="50" y="47" font-family="'Outfit', sans-serif" font-size="6.5" font-weight="900" fill="#dc2626" text-anchor="middle">★ BLS ★</text>
                  <text x="50" y="56" font-family="'Khmer OS Battambang', sans-serif" font-size="5.2" font-weight="bold" fill="#dc2626" text-anchor="middle">ត្រាផ្លូវការ</text>
                  <text x="50" y="80" font-family="'Outfit', sans-serif" font-size="5.2" font-weight="bold" fill="#dc2626" text-anchor="middle">OFFICIAL SEAL</text>
                </svg>
                <!-- Signature Line Overlay -->
                <svg width="55" height="22" viewBox="0 0 110 36" style="position: relative; z-index: 2;">
                  <path d="M 12 22 Q 30 4 45 18 T 68 15 T 90 10 Q 95 24 75 20 T 100 16" fill="none" stroke="#1d4ed8" stroke-width="1.8" stroke-linecap="round"/>
                </svg>
              </div>
              <div style="width: 26mm; height: 0.5px; background: #94a3b8; margin-top: 0.2mm;"></div>
              <div style="font-size: 4px; color: #64748b; font-family: 'Outfit', sans-serif; font-weight: 600; margin-top: 0.3mm;">Authorized Signature & Seal</div>
            </div>
          </div>
        </div>

        <!-- Bottom Return Notice Strip -->
        <div style="margin: 0 2.8mm 1.5mm 2.8mm; background: #f1f5f9; border-radius: 1.2mm; padding: 0.5mm 1mm; text-align: center; font-family: 'Khmer OS Battambang', 'Battambang', sans-serif; font-size: 4.6px; color: #64748b; position: relative; z-index: 2;">
          បើបានរើស សូមប្រគល់ជូនសាលាវិញ (If found, please return to Bright Light School) • Hotline: 078 350 908
        </div>
      </div>
    '''
        : '''
      <!-- Portrait Back Card -->
      <div class="id-card" style="width: $cardWidth; height: $cardHeight; box-sizing: border-box; border-radius: 3.2mm; background: #ffffff; box-shadow: 0 4px 14px rgba(0,0,0,0.12); position: relative; overflow: hidden; display: flex; flex-direction: column; justify-content: space-between; border: 1px solid #cbd5e1; page-break-inside: avoid; -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important;">
        $backWatermarkLogo

        <!-- Top Header -->
        <div style="height: 6mm; background: linear-gradient(90deg, #1e293b 0%, #0f172a 100%); display: flex; align-items: center; justify-content: space-between; padding: 0 2.5mm; position: relative; z-index: 2;">
          <div style="display: flex; align-items: center; gap: 1.5mm;">
            <img src="data:image/png;base64,${AppLogo.base64Data}" style="width: 4.5mm; height: 4.5mm; border-radius: 50%; border: 0.5px solid #fbbf24;" />
            <span style="font-family: 'Outfit', sans-serif; font-size: 5px; font-weight: 700; color: #fbbf24; letter-spacing: 0.6px;">BRIGHT LIGHT SCHOOL</span>
          </div>
          <span style="font-family: 'Outfit', monospace; font-size: 5px; font-weight: 700; color: #94a3b8;">$code</span>
        </div>

        <!-- Portrait Regulations Body -->
        <div style="padding: 1.5mm 2.5mm; position: relative; z-index: 2; flex: 1; display: flex; flex-direction: column; justify-content: space-between;">
          <div style="background: #f8fafc; border: 0.6px solid #e2e8f0; border-radius: 1.8mm; padding: 1.2mm 1.6mm;">
            <div style="font-family: 'Khmer OS Battambang', 'Battambang', sans-serif; font-size: 5.8px; font-weight: 700; color: $themeColorHex; text-align: center; margin-bottom: 0.8mm;">
              • បទបញ្ជាផ្ទៃក្នុង & លក្ខខណ្ឌ •
            </div>
            <div style="font-family: 'Khmer OS Battambang', 'Battambang', sans-serif; font-size: 4.7px; color: #334155; line-height: 1.4; text-align: center;">
              <div>១. ត្រូវពាក់ប័ណ្ណនេះជាប់ខ្លួនជានិច្ចពេលនៅក្នុងសាលា។</div>
              <div>២. ហាមកែប្រែ ក្លែងបន្លំ ឬប្រគល់ឱ្យអ្នកដទៃប្រើប្រាស់។</div>
              <div>៣. ករណីបាត់បង់ សូមរាយការណ៍មកការិយាល័យជាបន្ទាន់។</div>
              <div>៤. ប័ណ្ណនេះជាសម្បត្តិផ្លូវការរបស់សាលាប្រាយ ឡាយ។</div>
            </div>
            <div style="margin-top: 0.8mm; background: #eff6ff; border: 0.4px solid #bfdbfe; border-radius: 1mm; padding: 0.3mm 0.8mm; text-align: center; font-family: 'Outfit', sans-serif; font-size: 4.2px; font-weight: 700; color: #1d4ed8;">
              DISCIPLINE • RESPECT • HONESTY
            </div>
          </div>

          <div style="font-size: 5px; line-height: 1.35; color: #475569; margin: 0.8mm 0;">
            <div style="font-weight: 700; color: #0f172a; font-family: 'Khmer OS Battambang', 'Battambang', sans-serif;">ការិយាល័យរដ្ឋបាល:</div>
            <div style="font-family: 'Outfit', sans-serif; font-weight: 700; color: #2563eb;">078 350 908 / 088 757 4732</div>
            <div style="font-family: 'Khmer OS Battambang', 'Battambang', sans-serif; color: #64748b;">រាជធានីភ្នំពេញ, កម្ពុជា</div>
          </div>

          <!-- Principal Stamp & Signature -->
          <div style="display: flex; flex-direction: column; align-items: center; margin-bottom: 0.8mm;">
            <div style="font-family: 'Khmer OS Battambang', 'Battambang', sans-serif; font-size: 5.2px; font-weight: 700; color: #0f172a;">នាយកសាលា / Principal</div>
            <div style="position: relative; width: 20mm; height: 11mm; display: flex; align-items: center; justify-content: center; margin: 0.3mm 0;">
              <svg width="36" height="36" viewBox="0 0 100 100" style="position: absolute; opacity: 0.85; transform: rotate(-6deg);">
                <circle cx="50" cy="50" r="46" fill="none" stroke="#dc2626" stroke-width="2.5" stroke-dasharray="4,2"/>
                <circle cx="50" cy="50" r="40" fill="none" stroke="#dc2626" stroke-width="1.5"/>
                <path id="sealPathPort" d="M 22,50 A 28,28 0 1,1 78,50" fill="none"/>
                <text font-family="'Khmer OS Battambang', sans-serif" font-size="7.5" fill="#dc2626" font-weight="bold" text-anchor="middle">
                  <textPath href="#sealPathPort" startOffset="50%">សាលាប្រាយ ឡាយ</textPath>
                </text>
                <circle cx="50" cy="50" r="21" fill="#fef2f2" stroke="#dc2626" stroke-width="1"/>
                <text x="50" y="47" font-family="'Outfit', sans-serif" font-size="6.5" font-weight="900" fill="#dc2626" text-anchor="middle">★ BLS ★</text>
                <text x="50" y="56" font-family="'Khmer OS Battambang', sans-serif" font-size="5.2" font-weight="bold" fill="#dc2626" text-anchor="middle">ត្រាផ្លូវការ</text>
                <text x="50" y="80" font-family="'Outfit', sans-serif" font-size="5.2" font-weight="bold" fill="#dc2626" text-anchor="middle">OFFICIAL SEAL</text>
              </svg>
              <svg width="50" height="20" viewBox="0 0 110 36" style="position: relative; z-index: 2;">
                <path d="M 12 22 Q 30 4 45 18 T 68 15 T 90 10 Q 95 24 75 20 T 100 16" fill="none" stroke="#1d4ed8" stroke-width="1.8" stroke-linecap="round"/>
              </svg>
            </div>
            <div style="width: 25mm; height: 0.5px; background: #94a3b8; margin-top: 0.2mm;"></div>
            <div style="font-size: 4px; color: #64748b; font-family: 'Outfit', sans-serif; margin-top: 0.3mm;">Authorized Signature & Seal</div>
          </div>
        </div>

        <!-- Bottom Return Notice -->
        <div style="height: 3.2mm; background: #f1f5f9; border-top: 0.5px solid #e2e8f0; display: flex; justify-content: center; align-items: center; padding: 0 2mm; font-size: 4.5px; font-family: 'Khmer OS Battambang', 'Battambang', sans-serif; color: #64748b; position: relative; z-index: 2;">
          បើបានរើស សូមប្រគល់ជូនសាលាវិញ (Hotline: 078 350 908)
        </div>
      </div>
    ''';

    final htmlContent = sheetA4
        ? '''
      <style>
        * { box-sizing: border-box; }
        html, body {
          margin: 0 !important;
          padding: 0 !important;
          width: 100% !important;
          height: auto !important;
          overflow: visible !important;
        }
        @media print {
          html, body {
            width: 100% !important;
            height: auto !important;
            margin: 0 !important;
            padding: 0 !important;
            overflow: hidden !important;
          }
          .print-wrapper {
            min-height: auto !important;
            height: auto !important;
            page-break-after: avoid !important;
            break-after: avoid !important;
            page-break-inside: avoid !important;
            break-inside: avoid !important;
          }
          .cutting-guide {
            border: 1px dashed #94a3b8 !important;
          }
        }
        .cutting-guide {
          padding: 1.8mm;
          border: 1.2px dashed #94a3b8;
          border-radius: 4.5mm;
          background: #ffffff;
          box-shadow: 0 2px 8px rgba(0,0,0,0.06);
          position: relative;
        }
      </style>
      <div class="print-wrapper" style="padding: 4mm 6mm; background: #ffffff; display: flex; flex-direction: column; align-items: center; justify-content: flex-start; box-sizing: border-box;">
        
        <!-- Sheet Instruction Banner -->
        <div style="text-align: center; margin-bottom: 2.5mm;">
          <div style="display: flex; align-items: center; justify-content: center; gap: 2.5mm; margin-bottom: 0.8mm;">
            <img src="data:image/png;base64,${AppLogo.base64Data}" style="width: 6mm; height: 6mm; border-radius: 50%;" />
            <span class="khmer-muol" style="font-size: 11px; color: #1e3a8a;">សាលាប្រាយ ឡាយ • សន្លឹកបោះពុម្ពប័ណ្ណសម្គាល់ខ្លួនផ្លូវការ</span>
          </div>
          <div style="font-family: 'Outfit', sans-serif; font-size: 7px; color: #475569; font-weight: 700; letter-spacing: 0.8px;">
            BRIGHT LIGHT INTERNATIONAL SCHOOL • HIGH-DEFINITION OFFICIAL ID CARDS (ISO CR-80)
          </div>
          <div style="font-size: 6.5px; color: #64748b; margin-top: 0.4mm;">
            ✂️ កាត់តាមបន្ទាត់ដាច់ៗ (Crop Marks) រួចបត់ចូលគ្នា ឬអ៊ុតប្លាស្ទិក (Laminate) កម្រាស់ 80 - 125 Micron
          </div>
        </div>

        <!-- Cards Row / Column Side-by-Side (Fits on 1 Single Page!) -->
        <div style="display: flex; flex-wrap: nowrap; justify-content: center; align-items: flex-start; gap: 5mm;">
          ${showFront ? '''
          <div style="display: flex; flex-direction: column; align-items: center;">
            <div style="font-size: 7.5px; font-weight: 800; color: #334155; margin-bottom: 1.2mm; font-family: 'Outfit', sans-serif; letter-spacing: 0.5px;">
              --- ខាងមុខ (FRONT SIDE) ---
            </div>
            <div class="cutting-guide">
              $frontCardHtml
            </div>
          </div>
          ''' : ''}

          ${showBack ? '''
          <div style="display: flex; flex-direction: column; align-items: center;">
            <div style="font-size: 7.5px; font-weight: 800; color: #334155; margin-bottom: 1.2mm; font-family: 'Outfit', sans-serif; letter-spacing: 0.5px;">
              --- ខាងក្រោយ (BACK SIDE) ---
            </div>
            <div class="cutting-guide">
              $backCardHtml
            </div>
          </div>
          ''' : ''}
        </div>
      </div>
    '''
        : '''
      <style>
        @media print {
          body { 
            background: #ffffff !important; 
            padding: 0 !important;
            margin: 0 !important;
          }
          .pvc-card-page { 
            width: $cardWidth !important;
            height: $cardHeight !important;
            page-break-after: always !important; 
            break-after: page !important;
            margin: 0 !important;
            padding: 0 !important;
            overflow: hidden !important;
          }
        }
      </style>
      <div style="margin: 0; padding: 0;">
        ${showFront ? '<div class="pvc-card-page">$frontCardHtml</div>' : ''}
        ${showBack ? '<div class="pvc-card-page" style="page-break-after: avoid; break-after: avoid;">$backCardHtml</div>' : ''}
      </div>
    ''';

    final pageStyle = sheetA4
        ? '<style>@page { size: A4 landscape; margin: 6mm; } html, body { margin: 0; padding: 0; height: auto; overflow: hidden; } * { -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important; color-adjust: exact !important; }</style>'
        : '<style>@page { size: $cardWidth $cardHeight ${isLandscape ? "landscape" : "portrait"}; margin: 0; } * { -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important; color-adjust: exact !important; } body { margin: 0; padding: 0; background: #ffffff; }</style>';

    printHtml(
      htmlContent,
      title: 'BLS_ID_Card_$code',
      isLandscape: isLandscape,
      customPageStyle: pageStyle,
    );
  }

  /// 6. Print Payment Receipt (Invoice)
  static void printPaymentReceipt({
    required String receiptNo,
    required String studentName,
    required String studentCode,
    String? grade,
    required String amount,
    required String paymentMethod,
    required String date,
    required String receivedBy,
    String? notes,
  }) {
    final htmlContent =
        '''
      <div style="max-width: 650px; margin: 0 auto; border: 1.5px solid #cbd5e1; border-radius: 12px; padding: 28px; background: #ffffff;">
        <div style="display: flex; justify-content: space-between; align-items: flex-start; border-bottom: 2px solid #2563eb; padding-bottom: 16px; margin-bottom: 20px;">
          <div style="display: flex; align-items: center; gap: 14px;">
            <img src="data:image/png;base64,${AppLogo.base64Data}" style="width: 52px; height: 52px; border-radius: 50%; object-fit: contain;" />
            <div>
              <div class="khmer-muol" style="font-size: 18px; color: #1e3a8a;">សាលាប្រាយឡាយ</div>
              <div style="font-size: 11px; color: #64748b; font-weight: 600;">BRIGHT LIGHT SCHOOL</div>
              <div style="font-size: 11px; color: #94a3b8; margin-top: 4px;">អាសយដ្ឋាន៖ រាជធានីភ្នំពេញ | ទូរស័ព្ទ៖ 012 345 678</div>
            </div>
          </div>
          <div style="text-align: right;">
            <div class="khmer-muol" style="font-size: 16px; color: #2563eb;">បង្កាន់ដៃបង់ប្រាក់</div>
            <div style="font-size: 11px; color: #64748b; font-weight: 600;">OFFICIAL RECEIPT</div>
            <div style="margin-top: 6px; font-weight: 700; color: #0f172a; font-size: 13px;">លេខ៖ #$receiptNo</div>
          </div>
        </div>

        <table style="width: 100%; margin-bottom: 20px; border-collapse: collapse;">
          <tr>
            <td style="border: none; padding: 6px 0; width: 50%;"><strong>ឈ្មោះសិស្ស៖</strong> <span class="khmer-muol">$studentName</span></td>
            <td style="border: none; padding: 6px 0; width: 50%; text-align: right;"><strong>កាលបរិច្ឆេទ៖</strong> $date</td>
          </tr>
          <tr>
            <td style="border: none; padding: 6px 0;"><strong>អត្តលេខសិស្ស៖</strong> $studentCode</td>
            <td style="border: none; padding: 6px 0; text-align: right;"><strong>កម្រិតថ្នាក់៖</strong> <span style="color: #2563eb; font-weight: 700;">${grade ?? 'ថ្នាក់ទី ១A'}</span></td>
          </tr>
          <tr>
            <td style="border: none; padding: 6px 0;"><strong>វិធីសាស្ត្របង់ប្រាក់៖</strong> $paymentMethod</td>
            <td style="border: none; padding: 6px 0; text-align: right;"><strong>ស្ថានភាព៖</strong> <span style="color: #16a34a; font-weight: 700;">បានបង់រួច (Paid)</span></td>
          </tr>
        </table>

        <table>
          <thead>
            <tr>
              <th style="width: 10%;">ល.រ</th>
              <th style="width: 60%;">បរិយាយ (Description)</th>
              <th style="width: 30%; text-align: right;">ចំនួនទឹកប្រាក់ (Amount)</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td style="text-align: center;">1</td>
              <td>
                <strong>ថ្លៃសិក្សា / វគ្គបំប៉នសាលា</strong><br>
                <span style="font-size: 10.5px; color: #64748b;">${notes ?? 'ការបង់ប្រាក់ថ្លៃសិក្សាផ្លូវការ'}</span>
              </td>
              <td style="text-align: right; font-weight: 700; color: #16a34a; font-size: 14px;">\$$amount</td>
            </tr>
            <tr style="background: #f1f5f9; font-weight: 700;">
              <td colspan="2" style="text-align: right;"><strong>សរុបរួម (TOTAL PAID):</strong></td>
              <td style="text-align: right; color: #2563eb; font-size: 16px;">\$$amount</td>
            </tr>
          </tbody>
        </table>

        <div style="display: flex; justify-content: space-between; margin-top: 35px; padding: 0 20px;">
          <div style="text-align: center; width: 180px;">
            <div style="font-size: 11px; color: #64748b;">អ្នកបង់ប្រាក់ / សិស្ស-អាណាព្យាបាល</div>
            <div style="margin-top: 45px; border-top: 1px dotted #94a3b8; padding-top: 4px; font-size: 11px;">ហត្ថលេខា</div>
          </div>
          <div style="text-align: center; width: 180px;">
            <div style="font-size: 11px; color: #64748b;">បេឡាធិការទទួលប្រាក់ (${receivedBy.isNotEmpty ? receivedBy : 'Admin'})</div>
            <div style="margin-top: 45px; border-top: 1px dotted #94a3b8; padding-top: 4px; font-size: 11px;">ហត្ថលេខា និងត្រា</div>
          </div>
        </div>

        <div style="text-align: center; margin-top: 25px; font-size: 10px; color: #94a3b8; border-top: 1px dashed #e2e8f0; padding-top: 8px;">
          សូមអរគុណចំពោះការបង់ប្រាក់! សូមរក្សាទុកបង្កាន់ដៃនេះជាភស្តុតាង។ • Bright Light School
        </div>
      </div>
    ''';

    printHtml(htmlContent, title: 'BLS_Receipt_$receiptNo');
  }

  /// 7. Print Salary Slip (Payslip)
  static void printSalarySlip({
    required String slipNo,
    required String teacherName,
    required String teacherCode,
    required String forMonth,
    required String amount,
    required String paymentMethod,
    required String date,
    String? notes,
  }) {
    final htmlContent =
        '''
      <div style="max-width: 650px; margin: 0 auto; border: 1.5px solid #cbd5e1; border-radius: 12px; padding: 28px; background: #ffffff;">
        <div style="display: flex; justify-content: space-between; align-items: flex-start; border-bottom: 2px solid #0d9488; padding-bottom: 16px; margin-bottom: 20px;">
          <div style="display: flex; align-items: center; gap: 14px;">
            <img src="data:image/png;base64,${AppLogo.base64Data}" style="width: 52px; height: 52px; border-radius: 50%; object-fit: contain;" />
            <div>
              <div class="khmer-muol" style="font-size: 18px; color: #0f766e;">សាលាប្រាយឡាយ</div>
              <div style="font-size: 11px; color: #64748b; font-weight: 600;">BRIGHT LIGHT SCHOOL</div>
              <div style="font-size: 11px; color: #94a3b8; margin-top: 4px;">ផ្នែករដ្ឋបាល និងហិរញ្ញវត្ថុបុគ្គលិក</div>
            </div>
          </div>
          <div style="text-align: right;">
            <div class="khmer-muol" style="font-size: 16px; color: #0d9488;">ប័ណ្ណបើកប្រាក់បៀវត្សរ៍</div>
            <div style="font-size: 11px; color: #64748b; font-weight: 600;">SALARY PAYSLIP</div>
            <div style="margin-top: 6px; font-weight: 700; color: #0f172a; font-size: 13px;">លេខប័ណ្ណ៖ #$slipNo</div>
          </div>
        </div>

        <table style="width: 100%; margin-bottom: 20px; border-collapse: collapse;">
          <tr>
            <td style="border: none; padding: 6px 0; width: 50%;"><strong>ឈ្មោះគ្រូបង្រៀន៖</strong> <span class="khmer-muol">$teacherName</span></td>
            <td style="border: none; padding: 6px 0; width: 50%; text-align: right;"><strong>ប្រចាំខែ៖</strong> <span style="color: #0f766e; font-weight: 700;">$forMonth</span></td>
          </tr>
          <tr>
            <td style="border: none; padding: 6px 0;"><strong>អត្តលេខគ្រូ៖</strong> $teacherCode</td>
            <td style="border: none; padding: 6px 0; text-align: right;"><strong>កាលបរិច្ឆេទបើក៖</strong> $date</td>
          </tr>
          <tr>
            <td style="border: none; padding: 6px 0;"><strong>វិធីសាស្ត្របើក៖</strong> $paymentMethod</td>
            <td style="border: none; padding: 6px 0; text-align: right;"><strong>ស្ថានភាព៖</strong> <span style="color: #16a34a; font-weight: 700;">រួចរាល់ (Paid)</span></td>
          </tr>
        </table>

        <table>
          <thead>
            <tr>
              <th class="teal-header" style="width: 10%;">ល.រ</th>
              <th class="teal-header" style="width: 60%;">បរិយាយប្រាក់បៀវត្សរ៍ (Description)</th>
              <th class="teal-header" style="width: 30%; text-align: right;">ទឹកប្រាក់ (Amount)</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td style="text-align: center;">1</td>
              <td>
                <strong>ប្រាក់ខែគោល & ប្រាក់បង្រៀនបន្ថែម (Base Salary & Allowances)</strong><br>
                <span style="font-size: 10.5px; color: #64748b;">${notes ?? 'ប្រាក់បៀវត្សរ៍ពេញសិទ្ធិប្រចាំខែ $forMonth'}</span>
              </td>
              <td style="text-align: right; font-weight: 700; color: #0f172a; font-size: 14px;">\$$amount</td>
            </tr>
            <tr style="background: #f0fdf4; font-weight: 700;">
              <td colspan="2" style="text-align: right; color: #065f46;"><strong>ប្រាក់ខែជាក់ស្តែងទទួលបាន (NET SALARY):</strong></td>
              <td style="text-align: right; color: #0d9488; font-size: 16px;">\$$amount</td>
            </tr>
          </tbody>
        </table>

        <div style="display: flex; justify-content: space-between; margin-top: 35px; padding: 0 20px;">
          <div style="text-align: center; width: 180px;">
            <div style="font-size: 11px; color: #64748b;">ហត្ថលេខាគ្រូបង្រៀនទទួលប្រាក់</div>
            <div style="margin-top: 45px; border-top: 1px dotted #94a3b8; padding-top: 4px; font-size: 11px;">$teacherName</div>
          </div>
          <div style="text-align: center; width: 180px;">
            <div style="font-size: 11px; color: #64748b;">គណនេយ្យករ / នាយកសាលា</div>
            <div style="margin-top: 45px; border-top: 1px dotted #94a3b8; padding-top: 4px; font-size: 11px;">ហត្ថលេខានិងត្រាផ្លូវការ</div>
          </div>
        </div>
      </div>
    ''';

    printHtml(htmlContent, title: 'BLS_Payslip_$slipNo');
  }
}
