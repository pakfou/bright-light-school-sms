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
      @page {
        size: A4 portrait;
        margin: 12mm 15mm 15mm 15mm;
      }
      @page landscape-page {
        size: A4 landscape;
        margin: 12mm 15mm 12mm 15mm;
      }
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
    final landscapeStyle =
        customPageStyle ??
        (isLandscape
            ? '<style>@page { size: A4 landscape; margin: 12mm; }</style>'
            : '');

    final fullHtml =
        '''
      <!DOCTYPE html>
      <html lang="km">
      <head>
        <meta charset="utf-8">
        <title>$title</title>
        $_fontStyles
        $landscapeStyle
        <script>
          function runPrint() {
            setTimeout(function() {
              try {
                window.focus();
                window.print();
              } catch (e) {
                console.error('Print trigger failed: ', e);
              }
            }, 450);
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

    const defaultAvatarSvg =
        'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="%2394a3b8"><path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/></svg>';
    final photoMarkup = resolvedPhoto.isNotEmpty
        ? '<img src="$resolvedPhoto" style="width: 100%; height: 100%; object-fit: cover; display: block;" onerror="this.onerror=null; this.src=\'$defaultAvatarSvg\';" />'
        : '<img src="$defaultAvatarSvg" style="width: 70%; height: 70%; object-fit: contain; margin: auto; display: block;" />';

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
      <div class="id-card" style="width: $cardWidth; height: $cardHeight; box-sizing: border-box; border-radius: 3.5mm; background: #ffffff; box-shadow: 0 4px 14px rgba(0,0,0,0.12); position: relative; overflow: hidden; border: 1.2px solid rgba(37,99,235,0.35); page-break-inside: avoid; -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important;">
        $frontWatermarkLogo

        <!-- Left Blue Gradient Curved Sidebar -->
        <div style="position: absolute; left: 0; top: 0; bottom: 0; width: 28mm; background: linear-gradient(180deg, $themeColorHex 0%, #0f172a 100%); border-top-right-radius: 4.8mm; border-bottom-right-radius: 11mm; z-index: 2; display: flex; flex-direction: column; align-items: center; justify-content: center; box-shadow: 2px 0 6px rgba(0,0,0,0.15);">
          <!-- Lanyard Slot -->
          <div style="width: 6.5mm; height: 1.5mm; background: #1e293b; border-radius: 0.8mm; border: 0.3mm solid rgba(255,255,255,0.45); margin-bottom: 2mm;"></div>
          <!-- Photo Container -->
          <div style="width: 17mm; height: 21mm; background: #ffffff; border-radius: 1.8mm; border: 1.5px solid #ffffff; box-shadow: 0 2px 6px rgba(0,0,0,0.25); overflow: hidden; display: flex; align-items: center; justify-content: center;">
            $photoMarkup
          </div>
          <!-- Role Badge -->
          <div style="margin-top: 1.8mm; background: #ffffff; color: $themeColorHex; font-family: 'Khmer OS Battambang', 'Battambang', sans-serif; font-size: 5.5px; font-weight: 700; padding: 0.5mm 2.2mm; border-radius: 2mm; box-shadow: 0 1px 3px rgba(0,0,0,0.15); text-align: center; white-space: nowrap;">
            $roleKh • $roleEn
          </div>
          <!-- Code -->
          <div style="margin-top: 1.2mm; font-family: 'Outfit', sans-serif; font-size: 6.8px; font-weight: 800; color: #ffffff; letter-spacing: 0.6px; text-shadow: 0 1px 2px rgba(0,0,0,0.3);">
            $code
          </div>
        </div>

        <!-- Right Side Content -->
        <div style="position: absolute; left: 30.5mm; right: 2.8mm; top: 2.2mm; bottom: 2mm; z-index: 3; display: flex; flex-direction: column; justify-content: space-between;">
          <!-- Header Banner -->
          <div>
            <div style="display: flex; align-items: center; justify-content: space-between; padding-bottom: 0.8mm; border-bottom: 0.8px solid rgba(37,99,235,0.25);">
              <div style="display: flex; align-items: center; gap: 1.6mm;">
                <div style="width: 6.5mm; height: 6.5mm; border-radius: 50%; border: 0.8px solid rgba(37,99,235,0.35); background: #ffffff; display: flex; align-items: center; justify-content: center; overflow: hidden; flex-shrink: 0;">
                  <img src="data:image/png;base64,${AppLogo.base64Data}" style="width: 5.6mm; height: 5.6mm; object-fit: contain;" />
                </div>
                <div style="display: flex; flex-direction: column;">
                  <div style="font-family: 'Khmer OS Battambang', 'Battambang', sans-serif; font-size: 7.5px; font-weight: 700; color: #1e3a8a; line-height: 1.15;">សាលាប្រាយ ឡាយ</div>
                  <div style="font-family: 'Outfit', sans-serif; font-size: 4.8px; font-weight: 800; color: $themeColorHex; letter-spacing: 0.7px; line-height: 1;">BRIGHT LIGHT SCHOOL</div>
                </div>
              </div>
              <div style="background: rgba(37,99,235,0.08); border-radius: 1.2mm; padding: 0.6mm 1.6mm; font-family: 'Outfit', sans-serif; font-size: 5px; font-weight: 700; color: $themeColorHex;">
                $academicYear
              </div>
            </div>

            <!-- Name Section -->
            <div style="margin-top: 1.2mm;">
              <div style="font-family: 'Outfit', sans-serif; font-size: 9px; font-weight: 900; color: #0f172a; letter-spacing: 0.3px; line-height: 1.1; text-transform: uppercase; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">$nameEn</div>
              ${nameKh.isNotEmpty ? '<div style="font-family: \'Khmer OS Battambang\', \'Battambang\', sans-serif; font-size: 7.8px; font-weight: 700; color: #334155; line-height: 1.15; margin-top: 0.2mm; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">$nameKh</div>' : ''}
            </div>
          </div>

          <!-- Details Card Grid -->
          <div style="background: #f8fafc; border: 0.6px solid #e2e8f0; border-radius: 1.6mm; padding: 1mm 1.5mm;">
            <table style="width: 100%; border-collapse: collapse; font-size: 6px; margin: 0;">
              <tr>
                <td style="width: 25mm; padding: 0.4mm 0.5mm; border: none; vertical-align: middle;">
                  <span style="display: inline-block; width: 6.8mm; text-align: center; background: #e2e8f0; color: #64748b; font-family: 'Outfit', sans-serif; font-size: 5.2px; font-weight: 800; border-radius: 0.8mm; padding: 0.2mm 0.5mm; margin-right: 1mm;">ID</span>
                  <strong style="font-family: 'Outfit', sans-serif; font-weight: 800; color: $themeColorHex; font-size: 6.2px;">$code</strong>
                </td>
                <td style="padding: 0.4mm 0.5mm; border: none; vertical-align: middle;">
                  <span style="display: inline-block; width: 7.5mm; text-align: center; background: #e2e8f0; color: #64748b; font-family: 'Outfit', sans-serif; font-size: 5.2px; font-weight: 800; border-radius: 0.8mm; padding: 0.2mm 0.5mm; margin-right: 1mm;">DOB</span>
                  <span style="font-family: 'Outfit', sans-serif; font-weight: 600; color: #334155; font-size: 6px;">${dob?.isNotEmpty == true ? dob : '2019-09-21'}</span>
                </td>
              </tr>
              <tr>
                <td style="width: 25mm; padding: 0.4mm 0.5mm; border: none; vertical-align: middle;">
                  <span style="display: inline-block; width: 6.8mm; text-align: center; background: #e2e8f0; color: #64748b; font-family: 'Outfit', sans-serif; font-size: 5.2px; font-weight: 800; border-radius: 0.8mm; padding: 0.2mm 0.5mm; margin-right: 1mm;">Class</span>
                  <strong style="font-family: 'Khmer OS Battambang', 'Battambang', sans-serif; font-weight: 700; color: #1e293b; font-size: 6px;">$grade</strong>
                </td>
                <td style="padding: 0.4mm 0.5mm; border: none; vertical-align: middle;">
                  <span style="display: inline-block; width: 7.5mm; text-align: center; background: #e2e8f0; color: #64748b; font-family: 'Outfit', sans-serif; font-size: 5.2px; font-weight: 800; border-radius: 0.8mm; padding: 0.2mm 0.5mm; margin-right: 1mm;">Tel</span>
                  <span style="font-family: 'Outfit', sans-serif; font-weight: 600; color: #334155; font-size: 6px;">$phone</span>
                </td>
              </tr>
            </table>
          </div>

          <!-- Bottom Bar: Verified Badge & Scannable QR -->
          <div style="display: flex; align-items: flex-end; justify-content: space-between; padding-top: 0.6mm;">
            <div style="display: flex; align-items: center; gap: 1mm; font-family: 'Outfit', sans-serif; font-size: 4.8px; font-weight: 700; color: #64748b; letter-spacing: 0.4px;">
              <span style="color: #2563eb; font-size: 6px;">✔</span>
              <span>OFFICIAL ID • BRIGHT LIGHT SCHOOL • CR-80</span>
            </div>
            <div style="width: 8.5mm; height: 8.5mm; background: #ffffff; border: 0.6px solid #cbd5e1; border-radius: 1.2mm; padding: 0.4mm; display: flex; align-items: center; justify-content: center; box-shadow: 0 1px 3px rgba(0,0,0,0.06); flex-shrink: 0;">
              $qrMarkup
            </div>
          </div>
        </div>
      </div>
    '''
        : '''
      <!-- Portrait Front Card -->
      <div class="id-card" style="width: $cardWidth; height: $cardHeight; box-sizing: border-box; border-radius: 3.5mm; background: #ffffff; box-shadow: 0 4px 14px rgba(0,0,0,0.12); position: relative; overflow: hidden; display: flex; flex-direction: column; justify-content: space-between; border: 1.2px solid rgba(37,99,235,0.35); page-break-inside: avoid; -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important;">
        $frontWatermarkLogo

        <!-- Top Header Banner -->
        <div style="position: relative; z-index: 2;">
          <div style="background: linear-gradient(135deg, #1e3a8a 0%, $themeColorHex 65%, #0284c7 100%); padding: 2.2mm 2.8mm; display: flex; align-items: center; justify-content: space-between;">
            <div style="display: flex; align-items: center; gap: 1.8mm;">
              <div style="width: 7.5mm; height: 7.5mm; background: #ffffff; border-radius: 50%; border: 1px solid #fbbf24; display: flex; align-items: center; justify-content: center; box-shadow: 0 1.5px 3px rgba(0,0,0,0.25); flex-shrink: 0;">
                <img src="data:image/png;base64,${AppLogo.base64Data}" style="width: 6.5mm; height: 6.5mm; border-radius: 50%; object-fit: contain;" />
              </div>
              <div>
                <div style="font-family: 'Khmer OS Battambang', 'Battambang', sans-serif; font-size: 7.5px; font-weight: 700; color: #ffffff; line-height: 1.15; text-shadow: 0 1px 2px rgba(0,0,0,0.35);">សាលាប្រាយ ឡាយ</div>
                <div style="font-family: 'Outfit', sans-serif; font-size: 4.6px; font-weight: 800; color: #fde68a; letter-spacing: 0.8px;">BRIGHT LIGHT SCHOOL</div>
              </div>
            </div>
            <div style="background: rgba(255,255,255,0.2); border: 0.6px solid rgba(255,255,255,0.45); border-radius: 1.2mm; padding: 0.4mm 1.5mm; text-align: center;">
              <div style="font-family: 'Outfit', sans-serif; font-size: 4.8px; font-weight: 800; color: #ffffff;">$academicYear</div>
            </div>
          </div>
        </div>

        <!-- Portrait Body -->
        <div style="display: flex; flex-direction: column; align-items: center; padding: 1.5mm 2.5mm; position: relative; z-index: 2; flex: 1; justify-content: space-between;">
          <!-- Photo -->
          <div style="width: 20mm; height: 25mm; border-radius: 2mm; border: 1.5px solid $themeColorHex; box-shadow: 0 2px 6px rgba(0,0,0,0.18); overflow: hidden; background: #f8fafc; display: flex; align-items: center; justify-content: center; margin-top: 0.5mm;">
            $photoMarkup
          </div>

          <!-- Names & Role -->
          <div style="text-align: center; margin-top: 0.8mm;">
            <div style="font-family: 'Outfit', sans-serif; font-size: 8.5px; font-weight: 900; color: #0f172a; text-transform: uppercase; letter-spacing: 0.4px;">$nameEn</div>
            ${nameKh.isNotEmpty ? '<div style="font-family: \'Khmer OS Battambang\', \'Battambang\', sans-serif; font-size: 7.5px; font-weight: 700; color: #334155; line-height: 1.15; margin-top: 0.2mm;">$nameKh</div>' : ''}
            <div style="margin-top: 0.6mm; display: inline-block; background: linear-gradient(135deg, $themeColorHex, #1e3a8a); color: #ffffff; font-family: 'Khmer OS Battambang', 'Battambang', sans-serif; font-size: 5.2px; font-weight: 700; padding: 0.3mm 2.5mm; border-radius: 1.5mm;">
              $roleKh • $roleEn
            </div>
          </div>

          <!-- Details Grid -->
          <div style="background: #f8fafc; border: 0.6px solid #e2e8f0; border-radius: 1.5mm; width: 100%; padding: 0.8mm 1.5mm; font-size: 5.8px; line-height: 1.35; margin: 0.6mm 0;">
            <div style="display: flex; justify-content: space-between; padding: 0.2mm 0;">
              <span style="color: #64748b; font-weight: 700; font-family: 'Outfit', sans-serif;">ID:</span>
              <span style="font-family: 'Outfit', sans-serif; font-weight: 800; color: $themeColorHex;">$code</span>
            </div>
            <div style="display: flex; justify-content: space-between; padding: 0.2mm 0;">
              <span style="color: #64748b; font-weight: 700; font-family: 'Outfit', sans-serif;">CLASS:</span>
              <span style="font-family: 'Khmer OS Battambang', 'Battambang', sans-serif; font-weight: 700; color: #1e293b;">$grade</span>
            </div>
            <div style="display: flex; justify-content: space-between; padding: 0.2mm 0;">
              <span style="color: #64748b; font-weight: 700; font-family: 'Outfit', sans-serif;">TEL:</span>
              <span style="font-family: 'Outfit', sans-serif; font-weight: 600; color: #334155;">$phone</span>
            </div>
          </div>

          <!-- QR Code & Verified -->
          <div style="display: flex; align-items: center; justify-content: space-between; width: 100%; padding: 0 1mm 0.5mm 1mm;">
            <div style="font-family: 'Outfit', sans-serif; font-size: 4.5px; font-weight: 700; color: #64748b;">
              <span style="color: #2563eb;">✔</span> CR-80 SECURE
            </div>
            <div style="width: 8.5mm; height: 8.5mm; background: #ffffff; border: 0.6px solid #cbd5e1; border-radius: 1.2mm; padding: 0.4mm; display: flex; align-items: center; justify-content: center;">
              $qrMarkup
            </div>
          </div>
        </div>

        <!-- Bottom Footer -->
        <div style="height: 3mm; background: #0f172a; color: #94a3b8; display: flex; justify-content: space-between; align-items: center; padding: 0 2.5mm; font-size: 4.5px; font-family: 'Outfit', sans-serif; position: relative; z-index: 2;">
          <span style="color: #cbd5e1; font-weight: 600;">OFFICIAL IDENTITY CARD</span>
          <span style="color: #fbbf24; font-weight: 700;">BRIGHT LIGHT SCHOOL</span>
        </div>
      </div>
    ''';

    // Back Card HTML
    final backCardHtml = isLandscape
        ? '''
      <div class="id-card" style="width: $cardWidth; height: $cardHeight; box-sizing: border-box; border-radius: 3.5mm; background: #ffffff; box-shadow: 0 4px 14px rgba(0,0,0,0.12); position: relative; overflow: hidden; display: flex; flex-direction: column; justify-content: space-between; border: 1.2px solid rgba(37,99,235,0.35); page-break-inside: avoid; -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important;">
        $backWatermarkLogo

        <!-- Top Dark Bar with Lanyard Slot -->
        <div style="height: 5.5mm; background: linear-gradient(90deg, #1e293b 0%, #0f172a 100%); display: flex; align-items: center; justify-content: center; position: relative; z-index: 2;">
          <div style="width: 7mm; height: 1.6mm; background: #0f172a; border-radius: 0.8mm; border: 0.3mm solid rgba(255,255,255,0.3);"></div>
        </div>

        <!-- School Title Row -->
        <div style="display: flex; align-items: center; justify-content: center; gap: 1.6mm; padding: 1.2mm 0 0.8mm 0; position: relative; z-index: 2;">
          <div style="width: 5.2mm; height: 5.2mm; border-radius: 50%; overflow: hidden; display: flex; align-items: center; justify-content: center; flex-shrink: 0;">
            <img src="data:image/png;base64,${AppLogo.base64Data}" style="width: 100%; height: 100%; object-fit: contain;" />
          </div>
          <span style="font-family: 'Khmer OS Battambang', 'Battambang', sans-serif; font-size: 6.8px; font-weight: 700; color: #1e3a8a;">សាលាប្រាយ ឡាយ</span>
          <span style="color: #64748b; font-size: 6px;">•</span>
          <span style="font-family: 'Outfit', sans-serif; font-size: 5.6px; font-weight: 800; color: $themeColorHex; letter-spacing: 0.6px;">BRIGHT LIGHT SCHOOL</span>
        </div>

        <!-- Center 2-Column Body -->
        <div style="padding: 0 2.5mm; position: relative; z-index: 2; flex: 1; display: flex; justify-content: space-between; gap: 2.2mm;">
          <!-- Left Rules Box -->
          <div style="width: 46mm; background: #f8fafc; border: 0.6px solid #e2e8f0; border-radius: 1.8mm; padding: 1.2mm 1.6mm; display: flex; flex-direction: column; justify-content: space-between;">
            <div>
              <div style="font-family: 'Khmer OS Battambang', 'Battambang', sans-serif; font-size: 6px; font-weight: 700; color: $themeColorHex; margin-bottom: 0.6mm;">
                • វិន័យ និងបទបញ្ជាផ្ទៃក្នុង •
              </div>
              <div style="font-family: 'Khmer OS Battambang', 'Battambang', sans-serif; font-size: 4.8px; color: #334155; line-height: 1.38;">
                <div>១. ត្រូវពាក់ប័ណ្ណនេះជាប់ខ្លួនជានិច្ចពេលនៅក្នុងសាលា។</div>
                <div>២. ហាមកែប្រែ ក្លែងបន្លំ ឬប្រគល់ឱ្យអ្នកដទៃប្រើប្រាស់។</div>
                <div>៣. ករណីបាត់បង់ សូមរាយការណ៍មកការិយាល័យជាបន្ទាន់។</div>
                <div>៤. ប័ណ្ណនេះជាសម្បត្តិផ្លូវការរបស់សាលាប្រាយ ឡាយ។</div>
              </div>
            </div>
            <div style="margin-top: 0.8mm; background: #eff6ff; border: 0.4px solid #bfdbfe; border-radius: 1.2mm; padding: 0.3mm 0.8mm; text-align: center; font-family: 'Outfit', sans-serif; font-size: 4.2px; font-weight: 800; color: #1d4ed8; letter-spacing: 0.4px;">
              • DISCIPLINE • RESPECT • HONESTY • INTEGRITY •
            </div>
          </div>

          <!-- Right Administration & Principal Authorization -->
          <div style="flex: 1; display: flex; flex-direction: column; justify-content: space-between; padding: 0.5mm 0.5mm 0.5mm 0;">
            <div>
              <div style="font-family: 'Khmer OS Battambang', 'Battambang', sans-serif; font-size: 5.2px; font-weight: 700; color: #2563eb;">ទូរស័ព្ទទំនាក់ទំនង (Hotline):</div>
              <div style="font-family: 'Outfit', sans-serif; font-size: 5.8px; font-weight: 800; color: #0f172a; margin-top: 0.3mm;">078 350 908 / 088 757 4732</div>
              <div style="font-family: 'Khmer OS Battambang', 'Battambang', sans-serif; font-size: 4.8px; color: #64748b; margin-top: 0.4mm;">អាសយដ្ឋាន៖ រាជធានីភ្នំពេញ, កម្ពុជា</div>
            </div>

            <div style="display: flex; flex-direction: column; align-items: center; margin-top: 1mm;">
              <div style="font-family: 'Khmer OS Battambang', 'Battambang', sans-serif; font-size: 5.2px; font-weight: 700; color: #0f172a;">នាយកសាលា / Principal</div>
              <div style="margin-top: 1.2mm; border: 0.5px solid #fca5a5; background: #fef2f2; border-radius: 1mm; padding: 0.3mm 1.5mm; text-align: center;">
                <span style="font-family: 'Khmer OS Battambang', 'Battambang', sans-serif; font-size: 4.6px; font-weight: 700; color: #dc2626;">[ ត្រា & ហត្ថលេខាផ្លូវការ ]</span>
              </div>
              <div style="font-size: 4.2px; color: #94a3b8; font-family: 'Khmer OS Battambang', 'Battambang', sans-serif; margin-top: 0.4mm;">ហត្ថលេខា & ត្រា (Seal)</div>
            </div>
          </div>
        </div>

        <!-- Bottom Return Notice Pill -->
        <div style="margin: 0 2.5mm 1.6mm 2.5mm; background: #f1f5f9; border-radius: 1.5mm; padding: 0.6mm 1mm; text-align: center; font-family: 'Khmer OS Battambang', 'Battambang', sans-serif; font-size: 4.6px; color: #64748b; position: relative; z-index: 2;">
          បើបានរើស សូមប្រគល់ជូនសាលាវិញ (If found, please return to Bright Light School)
        </div>
      </div>
    '''
        : '''
      <!-- Portrait Back Card -->
      <div class="id-card" style="width: $cardWidth; height: $cardHeight; box-sizing: border-box; border-radius: 3.5mm; background: #ffffff; box-shadow: 0 4px 14px rgba(0,0,0,0.12); position: relative; overflow: hidden; display: flex; flex-direction: column; justify-content: space-between; border: 1.2px solid rgba(37,99,235,0.35); page-break-inside: avoid; -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important;">
        $backWatermarkLogo

        <!-- Top Header -->
        <div style="height: 6mm; background: linear-gradient(90deg, #1e293b 0%, #0f172a 100%); display: flex; align-items: center; justify-content: space-between; padding: 0 2.5mm; position: relative; z-index: 2;">
          <div style="display: flex; align-items: center; gap: 1.5mm;">
            <img src="data:image/png;base64,${AppLogo.base64Data}" style="width: 4.5mm; height: 4.5mm; border-radius: 50%;" />
            <span style="font-family: 'Outfit', sans-serif; font-size: 5px; font-weight: 700; color: #fbbf24; letter-spacing: 0.6px;">BRIGHT LIGHT SCHOOL</span>
          </div>
          <span style="font-family: 'Outfit', monospace; font-size: 5px; font-weight: 700; color: #94a3b8;">$code</span>
        </div>

        <!-- Portrait Regulations Body -->
        <div style="padding: 1.8mm 2.5mm; position: relative; z-index: 2; flex: 1; display: flex; flex-direction: column; justify-content: space-between;">
          <div style="background: #f8fafc; border: 0.6px solid #e2e8f0; border-radius: 1.8mm; padding: 1.2mm 1.6mm;">
            <div style="font-family: 'Khmer OS Battambang', 'Battambang', sans-serif; font-size: 6px; font-weight: 700; color: $themeColorHex; text-align: center; margin-bottom: 0.8mm;">
              • បទបញ្ជាផ្ទៃក្នុងសាលា •
            </div>
            <div style="font-family: 'Khmer OS Battambang', 'Battambang', sans-serif; font-size: 4.8px; color: #334155; line-height: 1.4;">
              <div>១. ត្រូវពាក់ប័ណ្ណនេះជាប់ខ្លួនជានិច្ចពេលនៅក្នុងសាលា។</div>
              <div>២. ហាមកែប្រែ ក្លែងបន្លំ ឬប្រគល់ឱ្យអ្នកដទៃប្រើប្រាស់។</div>
              <div>៣. ករណីបាត់បង់ សូមរាយការណ៍មកការិយាល័យជាបន្ទាន់។</div>
              <div>៤. ប័ណ្ណនេះជាសម្បត្តិផ្លូវការរបស់សាលាប្រាយ ឡាយ។</div>
            </div>
            <div style="margin-top: 0.8mm; background: #eff6ff; border: 0.4px solid #bfdbfe; border-radius: 1mm; padding: 0.3mm 0.8mm; text-align: center; font-family: 'Outfit', sans-serif; font-size: 4.2px; font-weight: 700; color: #1d4ed8;">
              DISCIPLINE • RESPECT • HONESTY
            </div>
          </div>

          <div style="font-size: 5px; line-height: 1.35; color: #475569; margin: 1mm 0;">
            <div style="font-weight: 700; color: #0f172a; font-family: 'Khmer OS Battambang', 'Battambang', sans-serif;">ការិយាល័យរដ្ឋបាល:</div>
            <div style="font-family: 'Outfit', sans-serif; font-weight: 700; color: #2563eb;">078 350 908 / 088 757 4732</div>
            <div style="font-family: 'Khmer OS Battambang', 'Battambang', sans-serif; color: #64748b;">រាជធានីភ្នំពេញ, កម្ពុជា</div>
          </div>

          <div style="display: flex; flex-direction: column; align-items: center; margin-bottom: 0.8mm;">
            <div style="font-family: 'Khmer OS Battambang', 'Battambang', sans-serif; font-size: 5.2px; font-weight: 700; color: #0f172a;">នាយកសាលា / Principal</div>
            <div style="margin-top: 1.2mm; border: 0.5px solid #fca5a5; background: #fef2f2; border-radius: 1mm; padding: 0.3mm 1.5mm; text-align: center;">
              <span style="font-family: 'Khmer OS Battambang', 'Battambang', sans-serif; font-size: 4.5px; color: #dc2626; font-weight: 700;">[ ត្រា & ហត្ថលេខាផ្លូវការ ]</span>
            </div>
          </div>
        </div>

        <!-- Bottom Return Notice -->
        <div style="height: 3.2mm; background: #f1f5f9; border-top: 0.5px solid #e2e8f0; display: flex; justify-content: center; align-items: center; padding: 0 2mm; font-size: 4.5px; font-family: 'Khmer OS Battambang', 'Battambang', sans-serif; color: #64748b; position: relative; z-index: 2;">
          បើបានរើស សូមប្រគល់ជូនសាលាវិញ
        </div>
      </div>
    ''';

    final htmlContent = sheetA4
        ? '''
      <style>
        @media print {
          body { 
            background: #ffffff !important; 
            padding: 0 !important;
            margin: 0 !important;
          }
          .no-print-bg { 
            background: transparent !important; 
            box-shadow: none !important;
            padding: 0 !important;
          }
          .print-wrapper {
            min-height: auto !important;
            height: auto !important;
            padding: 2mm 0 !important;
          }
          .page-break-card { 
            page-break-after: always !important; 
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
      <div class="print-wrapper no-print-bg" style="min-height: 100vh; padding: 8mm; background: #f1f5f9; display: flex; flex-direction: column; align-items: center; justify-content: center;">
        
        <!-- Sheet Instruction Banner -->
        <div style="text-align: center; margin-bottom: 5mm;">
          <div style="display: flex; align-items: center; justify-content: center; gap: 2.5mm; margin-bottom: 1mm;">
            <img src="data:image/png;base64,${AppLogo.base64Data}" style="width: 7mm; height: 7mm; border-radius: 50%;" />
            <span class="khmer-muol" style="font-size: 13px; color: #1e3a8a;">សាលាប្រាយ ឡាយ • សន្លឹកបោះពុម្ពប័ណ្ណសម្គាល់ខ្លួនផ្លូវការ</span>
          </div>
          <div style="font-family: 'Outfit', sans-serif; font-size: 7.5px; color: #475569; font-weight: 700; letter-spacing: 0.8px;">
            BRIGHT LIGHT SCHOOL • HIGH-DEFINITION OFFICIAL ID CARDS (ISO CR-80)
          </div>
          <div style="font-size: 7.2px; color: #64748b; margin-top: 0.8mm;">
            ✂️ កាត់តាមបន្ទាត់ដាច់ៗ (Crop Marks) រួចបត់ចូលគ្នា ឬអ៊ុតប្លាស្ទិក (Laminate) កម្រាស់ 80 - 125 Micron
          </div>
        </div>

        <!-- Cards Row / Column -->
        <div style="display: flex; flex-wrap: wrap; justify-content: center; align-items: center; gap: 8mm;">
          ${showFront ? '''
          <div style="display: flex; flex-direction: column; align-items: center;">
            <div style="font-size: 7.5px; font-weight: 700; color: #334155; margin-bottom: 1.2mm; font-family: 'Outfit', sans-serif;">
              --- ខាងមុខ (FRONT SIDE) ---
            </div>
            <div class="cutting-guide">
              $frontCardHtml
            </div>
          </div>
          ''' : ''}

          ${showBack ? '''
          <div style="display: flex; flex-direction: column; align-items: center;">
            <div style="font-size: 7.5px; font-weight: 700; color: #334155; margin-bottom: 1.2mm; font-family: 'Outfit', sans-serif;">
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
          .page-break-card { 
            page-break-after: always !important; 
          }
        }
      </style>
      <div style="display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 4mm;">
        ${showFront ? '<div class="${showBack ? 'page-break-card' : ''}" style="width: $cardWidth; height: $cardHeight;">$frontCardHtml</div>' : ''}
        ${showBack ? '<div style="width: $cardWidth; height: $cardHeight;">$backCardHtml</div>' : ''}
      </div>
    ''';

    final pageStyle = sheetA4
        ? '<style>@page { size: A4 landscape; margin: 8mm; } * { -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important; color-adjust: exact !important; } body { margin: 0; padding: 0; background: #ffffff; }</style>'
        : '<style>@page { size: $cardWidth $cardHeight; margin: 0; } * { -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important; color-adjust: exact !important; } body { margin: 0; padding: 0; background: #ffffff; }</style>';

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
