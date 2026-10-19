import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../services/api_service.dart';
import '../../services/html_print_service.dart';
import '../../utils/app_logo.dart';
import '../../utils/csv_exporter.dart';
import '../../utils/pdf_font_helper.dart';
import '../../widgets/app_avatar.dart';

class GradesEntryView extends StatefulWidget {
  const GradesEntryView({super.key});

  @override
  State<GradesEntryView> createState() => _GradesEntryViewState();
}

class _GradesEntryViewState extends State<GradesEntryView> {
  static String baseUrl = ApiService.baseUrl;

  int _selectedTab = 0;
  int _selectedStudentIndex = 0;

  List<dynamic> _students = [];
  List<dynamic> _classrooms = [];
  bool _isLoading = true;
  bool _isSavingBatch = false;
  bool _isSavingStudent = false;

  final TextEditingController _searchCtrl = TextEditingController();

  String _selectedAcademicYear = '២០២៥-២០២៦ (2025-2026)';
  String _selectedExamCategory = 'ប្រចាំខែ (Monthly Exam)';
  String _selectedExamPeriod = 'មករា (January)';
  String _selectedGradeLevel = 'គ្រប់ថ្នាក់រៀន (All Grades)';

  final List<String> _academicYearOptions = [
    '២០២៥-២០២៦ (2025-2026)',
    '២០២៤-២០២៥ (2024-2025)',
    '២០២៣-២០២៤ (2023-2024)',
  ];

  final List<String> _examCategoryOptions = [
    'ប្រចាំខែ (Monthly Exam)',
    'ឆមាសទី១ (Semester 1)',
    'ឆមាសទី២ (Semester 2)',
    'ប្រចាំឆ្នាំ (Annual Exam)',
  ];

  final List<String> _examPeriodOptions = [
    'មករា (January)',
    'កុម្ភៈ (February)',
    'មីនា (March)',
    'មេសា (April)',
    'ឧសភា (May)',
    'មិថុនា (June)',
    'កក្កដា (July)',
    'សីហា (August)',
    'កញ្ញា (September)',
    'តុលា (October)',
    'វិច្ឆិកា (November)',
    'ធ្នូ (December)',
  ];

  List<String> get _gradeLevelOptions {
    final set = <String>{'គ្រប់ថ្នាក់រៀន (All Grades)'};
    for (final c in _classrooms) {
      final name = c['class_name']?.toString() ?? '';
      if (name.isNotEmpty) set.add(name);
    }
    for (final s in _students) {
      final cls = (s['class_name'] ?? s['grade'] ?? '').toString();
      if (cls.isNotEmpty) set.add(cls);
    }
    if (set.length == 1) {
      set.addAll([
        'ថ្នាក់ទី ១A',
        'ថ្នាក់ទី ២A',
        'ថ្នាក់ទី ៣A',
        'ថ្នាក់ទី ៤A',
        'ថ្នាក់ទី ៥A',
        'ថ្នាក់ទី ៦A',
      ]);
    }
    return set.toList();
  }

  final List<String> _subjects = [
    'ភាសាខ្មែរ (Khmer Literature)',
    'គណិតវិទ្យា (Mathematics)',
    'វិទ្យាសាស្ត្រ (General Science)',
    'សង្គមវិទ្យា (Social Studies)',
    'ភាសាអង់គ្លេស (English Language)',
    'កុំព្យូទ័រ (Computer Studies)',
    'អាកប្បកិរិយា (Conduct & Ethics)',
  ];

  final Map<String, IconData> _subjectIcons = {
    'ភាសាខ្មែរ (Khmer Literature)': Icons.auto_stories_rounded,
    'គណិតវិទ្យា (Mathematics)': Icons.calculate_rounded,
    'វិទ្យាសាស្ត្រ (General Science)': Icons.science_rounded,
    'សង្គមវិទ្យា (Social Studies)': Icons.public_rounded,
    'ភាសាអង់គ្លេស (English Language)': Icons.language_rounded,
    'កុំព្យូទ័រ (Computer Studies)': Icons.laptop_mac_rounded,
    'អាកប្បកិរិយា (Conduct & Ethics)': Icons.favorite_rounded,
  };

  final Map<String, Color> _subjectColors = {
    'ភាសាខ្មែរ (Khmer Literature)': Color(0xFF4F46E5),
    'គណិតវិទ្យា (Mathematics)': Color(0xFF2563EB),
    'វិទ្យាសាស្ត្រ (General Science)': Color(0xFF0D9488),
    'សង្គមវិទ្យា (Social Studies)': Color(0xFFD97706),
    'ភាសាអង់គ្លេស (English Language)': Color(0xFF7C3AED),
    'កុំព្យូទ័រ (Computer Studies)': Color(0xFF0284C7),
    'អាកប្បកិរិយា (Conduct & Ethics)': Color(0xFFE11D48),
  };

  final Map<int, Map<String, TextEditingController>> _studentScoreControllers =
      {};

  final TextEditingController _teacherRemarksCtrl = TextEditingController(
    text: 'សិស្សខិតខំប្រឹងប្រែងរៀនសូត្រ មានអាកប្បកិរិយាល្អ និងគោរពវិន័យសាលា។',
  );
  final TextEditingController _principalRemarksCtrl = TextEditingController(
    text: 'សូមបន្តការខិតខំប្រឹងប្រែងដើម្បីទទួលបានលទ្ធផលកាន់តែប្រសើរ! (Passed)',
  );

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    for (final map in _studentScoreControllers.values) {
      for (final c in map.values) {
        c.dispose();
      }
    }
    _teacherRemarksCtrl.dispose();
    _principalRemarksCtrl.dispose();
    super.dispose();
  }

  Map<String, TextEditingController> _getControllersForStudent(
    Map<String, dynamic> student,
  ) {
    final id = student['id'] as int? ?? 0;
    if (!_studentScoreControllers.containsKey(id)) {
      final seed = (id * 7) % 25;
      final baseScores = [
        (82.0 + (seed % 15)).clamp(50.0, 99.0),
        (85.0 + ((seed + 3) % 14)).clamp(50.0, 98.0),
        (88.0 - ((seed + 1) % 16)).clamp(50.0, 96.0),
        (80.0 + ((seed + 5) % 17)).clamp(50.0, 97.0),
        (90.0 - ((seed + 2) % 15)).clamp(50.0, 98.0),
        (92.0 - ((seed + 4) % 13)).clamp(50.0, 99.0),
        (85.0 + (seed % 10)).clamp(60.0, 99.0),
      ];
      final map = <String, TextEditingController>{};
      for (int i = 0; i < _subjects.length; i++) {
        map[_subjects[i]] = TextEditingController(
          text: baseScores[i].toStringAsFixed(0),
        );
      }
      _studentScoreControllers[id] = map;
    }
    return _studentScoreControllers[id]!;
  }

  double _getStudentTotal(Map<String, dynamic> student) {
    final ctrls = _getControllersForStudent(student);
    double sum = 0;
    for (final c in ctrls.values) {
      sum += double.tryParse(c.text) ?? 0.0;
    }
    return sum;
  }

  double _getStudentAverage(Map<String, dynamic> student) {
    if (_subjects.isEmpty) return 0;
    return _getStudentTotal(student) / _subjects.length;
  }

  String _getGradeLetter(double avg) {
    if (avg >= 85) return 'A';
    if (avg >= 75) return 'B';
    if (avg >= 65) return 'C';
    if (avg >= 50) return 'D';
    return 'F';
  }

  Color _getGradeColor(String letter) {
    switch (letter) {
      case 'A':
        return const Color(0xFF059669);
      case 'B':
        return const Color(0xFF2563EB);
      case 'C':
        return const Color(0xFFD97706);
      case 'D':
        return const Color(0xFFEA580C);
      default:
        return const Color(0xFFDC2626);
    }
  }

  bool _isStudentPassed(double avg) {
    return avg >= 50.0;
  }

  List<dynamic> get _filteredStudents {
    final query = _searchCtrl.text.trim().toLowerCase();
    return _students.where((s) {
      final nameKh = (s['name_kh'] ?? '').toString().toLowerCase();
      final nameEn = (s['name_en'] ?? '').toString().toLowerCase();
      final code = (s['student_code'] ?? '').toString().toLowerCase();
      final className = (s['class_name'] ?? s['grade'] ?? '').toString();

      final matchesQuery =
          query.isEmpty ||
          nameKh.contains(query) ||
          nameEn.contains(query) ||
          code.contains(query);

      final cleanFilter = _selectedGradeLevel
          .replaceAll(RegExp(r'\(.*?\)'), '')
          .trim();
      final matchesGrade =
          _selectedGradeLevel == 'គ្រប់ថ្នាក់រៀន (All Grades)' ||
          className.contains(cleanFilter);

      return matchesQuery && matchesGrade;
    }).toList();
  }

  List<Map<String, dynamic>> get _rankedStudents {
    final list = List<Map<String, dynamic>>.from(
      _filteredStudents.map((e) => Map<String, dynamic>.from(e)),
    );
    list.sort((a, b) => _getStudentTotal(b).compareTo(_getStudentTotal(a)));
    return list;
  }

  int _getStudentRank(Map<String, dynamic> student) {
    final ranked = _rankedStudents;
    final idx = ranked.indexWhere((item) => item['id'] == student['id']);
    return idx == -1 ? 1 : idx + 1;
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final sRes = await http.get(Uri.parse('$baseUrl/students'));
      if (sRes.statusCode == 200) {
        final data = jsonDecode(utf8.decode(sRes.bodyBytes))['data'];
        if (data != null && data is List) {
          _students = data.map((item) {
            final m = Map<String, dynamic>.from(item);
            final p = m['photo_url'] ?? m['photo'];
            m['photo'] = p;
            m['photo_url'] = p;
            return m;
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('Error loading students: $e');
    }

    try {
      final cRes = await http.get(Uri.parse('$baseUrl/classrooms'));
      if (cRes.statusCode == 200) {
        final data = jsonDecode(utf8.decode(cRes.bodyBytes))['data'];
        if (data != null && data is List) {
          _classrooms = data;
        }
      }
    } catch (e) {
      debugPrint('Error loading classrooms: $e');
    }

    try {
      final gRes = await http.get(Uri.parse('$baseUrl/grades'));
      if (gRes.statusCode == 200) {
        final gData = jsonDecode(utf8.decode(gRes.bodyBytes))['data'];
        if (gData != null && gData is List) {
          for (final item in gData) {
            final sId = item['student_id'] as int?;
            final subj = item['subject_name']?.toString() ?? '';
            final scoreVal = item['score'];
            if (sId != null && subj.isNotEmpty && scoreVal != null) {
              Map<String, dynamic>? student;
              for (final s in _students) {
                if (s['id'] == sId) {
                  student = s;
                  break;
                }
              }
              if (student != null) {
                final ctrls = _getControllersForStudent(student);
                if (ctrls.containsKey(subj)) {
                  ctrls[subj]!.text = scoreVal.toString();
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading grades: $e');
    }

    if (_students.isEmpty) {
      _students = [
        {
          'id': 1,
          'student_code': 'STU1001',
          'name_kh': 'សុខ ម៉ារី',
          'name_en': 'Sok Mary',
          'gender': 'ស្រី',
          'grade': 'ថ្នាក់ទី ៤A',
          'class_name': 'ថ្នាក់ទី ៤A',
          'photo': null,
        },
        {
          'id': 2,
          'student_code': 'STU1002',
          'name_kh': 'ចាន់ ករុណា',
          'name_en': 'Chan Karuna',
          'gender': 'ប្រុស',
          'grade': 'ថ្នាក់ទី ៥A',
          'class_name': 'ថ្នាក់ទី ៥A',
          'photo': null,
        },
        {
          'id': 3,
          'student_code': 'STU1003',
          'name_kh': 'គីម សេង',
          'name_en': 'Kim Seng',
          'gender': 'ប្រុស',
          'grade': 'ថ្នាក់ទី ៣A',
          'class_name': 'ថ្នាក់ទី ៣A',
          'photo': null,
        },
      ];
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _showSuccessSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  fontFamily: 'Khmer OS Battambang',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _saveExamRecord(Map<String, dynamic> student) async {
    setState(() => _isSavingStudent = true);
    try {
      final ctrls = _getControllersForStudent(student);
      for (final entry in ctrls.entries) {
        final val = double.tryParse(entry.value.text) ?? 0.0;
        await http.post(
          Uri.parse('$baseUrl/grades'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'student_id': student['id'],
            'classroom_id': student['classroom_id'],
            'subject_name': entry.key,
            'month_name': _selectedExamPeriod,
            'score': val,
            'remarks': _teacherRemarksCtrl.text,
          }),
        );
      }
      _showSuccessSnack(
        'បានរក្សាទុកពិន្ទុ និងមតិយោបល់សិស្ស ${student['name_kh'] ?? student['name_en'] ?? ''} ជោគជ័យ!',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('កំហុស៖ $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingStudent = false);
    }
  }

  Future<void> _saveAllBatch() async {
    setState(() => _isSavingBatch = true);
    try {
      final allGrades = <Map<String, dynamic>>[];
      for (final s in _filteredStudents) {
        final ctrls = _getControllersForStudent(s);
        for (final entry in ctrls.entries) {
          allGrades.add({
            'student_id': s['id'],
            'classroom_id': s['classroom_id'],
            'subject_name': entry.key,
            'month_name': _selectedExamPeriod,
            'score': double.tryParse(entry.value.text) ?? 0.0,
            'remarks': _teacherRemarksCtrl.text,
          });
        }
      }
      final res = await http.post(
        Uri.parse('$baseUrl/grades/batch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'grades': allGrades}),
      );
      if (res.statusCode == 200) {
        _showSuccessSnack(
          'បានរក្សាទុកពិន្ទុសិស្សទាំងអស់ (${_filteredStudents.length} នាក់) ជោគជ័យ!',
        );
      } else {
        throw Exception('Server error: ${res.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('កំហុស៖ $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingBatch = false);
    }
  }

  void _exportGradesCSV(Map<String, dynamic> student) {
    final buf = StringBuffer();
    final nameKh = student['name_kh'] ?? '';
    final nameEn = student['name_en'] ?? '';
    final code = student['student_code'] ?? '';
    final grade =
        student['class_name'] ??
        student['grade'] ??
        student['grade_level_name'] ??
        'ថ្នាក់ទី ១A';

    buf.writeln(
      '\uFEFFអត្តលេខសិស្ស,ឈ្មោះខ្មែរ,ឈ្មោះអង់គ្លេស,ថ្នាក់,មុខវិជ្ជា,ពិន្ទុ,និទ្ទេស',
    );
    final ctrls = _getControllersForStudent(student);
    for (final entry in ctrls.entries) {
      final sc = double.tryParse(entry.value.text) ?? 0.0;
      final letter = _getGradeLetter(sc);
      buf.writeln(
        '"$code","$nameKh","$nameEn","$grade","${entry.key}",$sc,"$letter"',
      );
    }
    downloadCsv(
      buf.toString(),
      'grades_${code}_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    _showSuccessSnack('បានទាញយកពិន្ទុសិស្ស $nameKh ជា CSV ដោយជោគជ័យ');
  }

  void _exportBatchCSV() {
    final buf = StringBuffer();
    buf.writeln(
      '\uFEFFល.រ,អត្តលេខ,ឈ្មោះខ្មែរ,ឈ្មោះអង់គ្លេស,ថ្នាក់,ភេទ,ភាសាខ្មែរ,គណិតវិទ្យា,វិទ្យាសាស្ត្រ,សង្គមវិទ្យា,ភាសាអង់គ្លេស,កុំព្យូទ័រ,អាកប្បកិរិយា,ពិន្ទុសរុប,មធ្យមភាគ,និទ្ទេស,ចំណាត់ថ្នាក់',
    );
    final students = _filteredStudents;
    for (int i = 0; i < students.length; i++) {
      final s = students[i];
      final ctrls = _getControllersForStudent(s);
      final total = _getStudentTotal(s);
      final avg = _getStudentAverage(s);
      final grade = _getGradeLetter(avg);
      final rank = _getStudentRank(s);
      final code = s['student_code'] ?? '';
      final nameKh = s['name_kh'] ?? '';
      final nameEn = s['name_en'] ?? '';
      final cls = s['class_name'] ?? s['grade'] ?? '';
      final gender = s['gender'] ?? '';

      final scores = _subjects
          .map(
            (subj) => (double.tryParse(ctrls[subj]?.text ?? '0') ?? 0.0)
                .toStringAsFixed(1),
          )
          .join(',');
      buf.writeln(
        '${i + 1},"$code","$nameKh","$nameEn","$cls","$gender",$scores,${total.toStringAsFixed(1)},${avg.toStringAsFixed(1)}%,"$grade",#$rank',
      );
    }
    downloadCsv(
      buf.toString(),
      'class_grades_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    _showSuccessSnack('បានទាញយកពិន្ទុថ្នាក់ជា CSV ដោយជោគជ័យ');
  }

  void _exportRankingsCSV() {
    final buf = StringBuffer();
    buf.writeln(
      '\uFEFFចំណាត់ថ្នាក់,អត្តលេខ,ឈ្មោះខ្មែរ,ឈ្មោះអង់គ្លេស,ថ្នាក់,ពិន្ទុសរុប,មធ្យមភាគ,និទ្ទេស,កិត្តិយស',
    );
    final ranked = _rankedStudents;
    for (int i = 0; i < ranked.length; i++) {
      final s = ranked[i];
      final total = _getStudentTotal(s);
      final avg = _getStudentAverage(s);
      final grade = _getGradeLetter(avg);
      final code = s['student_code'] ?? '';
      final nameKh = s['name_kh'] ?? '';
      final nameEn = s['name_en'] ?? '';
      final cls = s['class_name'] ?? s['grade'] ?? '';
      String honor = 'និទ្ទេសមធ្យម (Fair)';
      if (grade == 'A') {
        honor = 'សិស្សឆ្នើម (Honor Roll)';
      } else if (grade == 'B') {
        honor = 'សិស្សពូកែ (Distinction)';
      } else if (grade == 'C') {
        honor = 'សិស្សល្អ (Good)';
      } else if (grade == 'F') {
        honor = 'ត្រូវខិតខំបន្ថែម (Needs Improvement)';
      }

      buf.writeln(
        '${i + 1},"$code","$nameKh","$nameEn","$cls",${total.toStringAsFixed(1)},${avg.toStringAsFixed(1)}%,"$grade","$honor"',
      );
    }
    downloadCsv(
      buf.toString(),
      'class_rankings_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    _showSuccessSnack('បានទាញយកតារាងចំណាត់ថ្នាក់ជា CSV ដោយជោគជ័យ');
  }

  Future<void> _printStudentReport(Map<String, dynamic> student) async {
    try {
      final nameKh = student['name_kh'] ?? 'សិស្សទូទៅ';
      final nameEn = student['name_en'] ?? '';
      final code = student['student_code'] ?? 'STU-001';
      final className =
          student['class_name'] ?? student['grade'] ?? 'បឋមសិក្សា';

      final ctrls = _getControllersForStudent(student);
      final tableData = _subjects.map((subj) {
        final sc = double.tryParse(ctrls[subj]?.text ?? '0') ?? 0.0;
        final grade = _getGradeLetter(sc);
        return [subj, sc.toStringAsFixed(1), grade];
      }).toList();

      final photoUrl = (student['photo_url'] ?? student['photo'])?.toString();
      if (kIsWeb) {
        HtmlPrintService.printStudentReportCard(
          nameKh: nameKh,
          nameEn: nameEn,
          studentCode: code,
          className: className,
          scores: tableData,
          photoUrl: photoUrl,
        );
        return;
      }

      final pdf = pw.Document();
      final fontBold = await PdfFontHelper.getBoldFont();
      final fontRegular = await PdfFontHelper.getRegularFont();

      pw.MemoryImage? studentPhotoImg;
      if (photoUrl != null && photoUrl.trim().isNotEmpty) {
        final rawPhoto = photoUrl.trim();
        try {
          if (rawPhoto.startsWith('data:image')) {
            final comma = rawPhoto.indexOf(',');
            final base64Str = comma != -1
                ? rawPhoto.substring(comma + 1)
                : rawPhoto;
            studentPhotoImg = pw.MemoryImage(base64Decode(base64Str));
          } else if (rawPhoto.length > 100 &&
              !rawPhoto.contains(' ') &&
              !rawPhoto.startsWith('http')) {
            studentPhotoImg = pw.MemoryImage(base64Decode(rawPhoto));
          } else if (rawPhoto.startsWith('http')) {
            final res = await http
                .get(Uri.parse(rawPhoto))
                .timeout(const Duration(seconds: 4));
            if (res.statusCode == 200) {
              studentPhotoImg = pw.MemoryImage(res.bodyBytes);
            }
          }
        } catch (_) {}
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          theme: pw.ThemeData.withFont(
            base: fontRegular,
            bold: fontBold,
            fontFallback: [fontRegular, fontBold],
          ),
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'ព្រះរាជាណាចក្រកម្ពុជា\nជាតិ សាសនា ព្រះមហាក្សត្រ',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(font: fontBold, fontSize: 13),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Image(AppLogo.pdfImage, width: 46, height: 46),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'សាលាប្រាយឡាយ',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 16,
                          color: const PdfColor.fromInt(0xFF1E3A8A),
                        ),
                      ),
                      pw.Text(
                        'សន្លឹកលទ្ធផលប្រឡងផ្លូវការ / OFFICIAL REPORT CARD',
                        style: pw.TextStyle(fontSize: 11, font: fontBold),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(6),
                    color: PdfColors.grey50,
                  ),
                  child: pw.Row(
                    children: [
                      if (studentPhotoImg != null)
                        pw.Container(
                          width: 48,
                          height: 60,
                          margin: const pw.EdgeInsets.only(right: 14),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(
                              color: const PdfColor.fromInt(0xFF2563EB),
                              width: 1,
                            ),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.ClipRRect(
                            horizontalRadius: 3,
                            verticalRadius: 3,
                            child: pw.Image(
                              studentPhotoImg,
                              fit: pw.BoxFit.cover,
                            ),
                          ),
                        )
                      else
                        pw.Container(
                          width: 48,
                          height: 60,
                          margin: const pw.EdgeInsets.only(right: 14),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(
                              color: PdfColors.grey400,
                              width: 0.8,
                            ),
                            borderRadius: pw.BorderRadius.circular(4),
                            color: PdfColors.grey200,
                          ),
                          child: pw.Center(
                            child: pw.Text(
                              'រូបថត\nPhoto',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                font: fontRegular,
                                fontSize: 8,
                                color: PdfColors.grey600,
                              ),
                            ),
                          ),
                        ),
                      pw.Expanded(
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'ឈ្មោះសិស្ស៖ $nameKh ($nameEn)',
                                  style: pw.TextStyle(
                                    font: fontBold,
                                    fontSize: 11,
                                  ),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  'អត្តលេខ៖ $code',
                                  style: pw.TextStyle(
                                    font: fontBold,
                                    fontSize: 10,
                                    color: const PdfColor.fromInt(0xFF1D4ED8),
                                  ),
                                ),
                              ],
                            ),
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'ថ្នាក់រៀន៖ $className',
                                  style: pw.TextStyle(
                                    font: fontBold,
                                    fontSize: 11,
                                  ),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  'កាលបរិច្ឆេទ៖ ${DateTime.now().toString().substring(0, 10)}',
                                  style: pw.TextStyle(font: fontRegular, fontSize: 10),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.TableHelper.fromTextArray(
                  headers: ['មុខវិជ្ជា', 'ពិន្ទុ (Score)', 'និទ្ទេស (Grade)'],
                  headerStyle: pw.TextStyle(
                    font: fontBold,
                    color: PdfColors.white,
                    fontSize: 11,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF2563EB),
                  ),
                  cellStyle: pw.TextStyle(font: fontRegular, fontSize: 10),
                  data: tableData,
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'មតិយោបល់គ្រូបន្ទុកថ្នាក់៖ ${_teacherRemarksCtrl.text}',
                  style: pw.TextStyle(fontSize: 10, font: fontRegular),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'មតិយោបល់នាយកសាលា៖ ${_principalRemarksCtrl.text}',
                  style: pw.TextStyle(fontSize: 10, font: fontRegular),
                ),
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text(
                          'ហត្ថលេខាគ្រូបន្ទុកថ្នាក់',
                          style: pw.TextStyle(font: fontBold, fontSize: 10),
                        ),
                        pw.SizedBox(height: 35),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text(
                          'ហត្ថលេខានិងត្រានាយកសាលា',
                          style: pw.TextStyle(font: fontBold, fontSize: 10),
                        ),
                        pw.SizedBox(height: 35),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (fmt) => pdf.save(),
        name: 'report_$code.pdf',
      );
    } catch (e) {
      debugPrint('Print error: $e');
    }
  }

  Future<void> _printBatchGradeSheet() async {
    try {
      final pdf = pw.Document();
      final fontBold = await PdfFontHelper.getBoldFont();
      final fontRegular = await PdfFontHelper.getRegularFont();
      final students = _filteredStudents;

      final headers = [
        'ល.រ',
        'អត្តលេខ',
        'ឈ្មោះសិស្ស',
        'ភេទ',
        'ខ្មែរ',
        'គណិត',
        'វិទ្យា',
        'សង្គម',
        'អង់គ្លេស',
        'កុំព្យូទ័រ',
        'វិន័យ',
        'សរុប',
        'មធ្យមភាគ',
        'និទ្ទេស',
        'ចំណាត់ថ្នាក់',
      ];

      final data = students.asMap().entries.map((e) {
        final idx = e.key + 1;
        final s = e.value;
        final ctrls = _getControllersForStudent(s);
        final total = _getStudentTotal(s);
        final avg = _getStudentAverage(s);
        final grade = _getGradeLetter(avg);
        final rank = _getStudentRank(s);

        return [
          idx.toString(),
          s['student_code']?.toString() ?? '',
          s['name_kh']?.toString() ?? s['name_en']?.toString() ?? '',
          s['gender']?.toString() ?? '',
          ..._subjects.map(
            (subj) => (double.tryParse(ctrls[subj]?.text ?? '0') ?? 0)
                .toStringAsFixed(0),
          ),
          total.toStringAsFixed(0),
          '${avg.toStringAsFixed(1)}%',
          grade,
          '#$rank',
        ];
      }).toList();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          theme: pw.ThemeData.withFont(
            base: fontRegular,
            bold: fontBold,
            fontFallback: [fontRegular, fontBold],
          ),
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(
                      children: [
                        pw.Image(AppLogo.pdfImage, width: 36, height: 36),
                        pw.SizedBox(width: 10),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'សាលាប្រាយឡាយ / BRIGHT LIGHT SCHOOL',
                              style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 13,
                                color: const PdfColor.fromInt(0xFF1E3A8A),
                              ),
                            ),
                            pw.Text(
                              'តារាងពិន្ទុ និងលទ្ធផលប្រឡងប្រចាំថ្នាក់ (CLASS GRADE SHEET)',
                              style: pw.TextStyle(font: fontBold, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'ឆ្នាំសិក្សា៖ $_selectedAcademicYear  |  វគ្គ៖ $_selectedExamPeriod',
                          style: pw.TextStyle(font: fontRegular, fontSize: 10),
                        ),
                        pw.Text(
                          'កាលបរិច្ឆេទ៖ ${DateTime.now().toString().substring(0, 10)}',
                          style: pw.TextStyle(font: fontRegular, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.TableHelper.fromTextArray(
                  headers: headers,
                  headerStyle: pw.TextStyle(
                    font: fontBold,
                    color: PdfColors.white,
                    fontSize: 8,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF2563EB),
                  ),
                  cellStyle: pw.TextStyle(font: fontRegular, fontSize: 8),
                  data: data,
                  cellAlignment: pw.Alignment.center,
                ),
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text(
                          'គ្រូបន្ទុកថ្នាក់',
                          style: pw.TextStyle(font: fontBold, fontSize: 10),
                        ),
                        pw.SizedBox(height: 30),
                        pw.Text(
                          '..........................................',
                          style: pw.TextStyle(font: fontRegular, fontSize: 9),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text(
                          'ការិយាល័យសិក្សា',
                          style: pw.TextStyle(font: fontBold, fontSize: 10),
                        ),
                        pw.SizedBox(height: 30),
                        pw.Text(
                          '..........................................',
                          style: pw.TextStyle(font: fontRegular, fontSize: 9),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text(
                          'នាយកសាលា',
                          style: pw.TextStyle(font: fontBold, fontSize: 10),
                        ),
                        pw.SizedBox(height: 30),
                        pw.Text(
                          '..........................................',
                          style: pw.TextStyle(font: fontRegular, fontSize: 9),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (fmt) => pdf.save(),
        name: 'Class_Grades_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      debugPrint('Print class error: $e');
    }
  }

  Future<void> _printHonorRoll() async {
    try {
      final pdf = pw.Document();
      final fontBold = await PdfFontHelper.getBoldFont();
      final fontRegular = await PdfFontHelper.getRegularFont();
      final ranked = _rankedStudents;

      final headers = [
        'ចំណាត់ថ្នាក់ (Rank)',
        'អត្តលេខ',
        'ឈ្មោះសិស្ស (Student Name)',
        'ថ្នាក់រៀន',
        'ពិន្ទុសរុប',
        'មធ្យមភាគ',
        'និទ្ទេស',
        'កិត្តិយស (Honor Award)',
      ];

      final data = ranked.asMap().entries.map((e) {
        final rank = e.key + 1;
        final s = e.value;
        final total = _getStudentTotal(s);
        final avg = _getStudentAverage(s);
        final grade = _getGradeLetter(avg);
        String honor = 'និទ្ទេសមធ្យម (Fair)';
        if (grade == 'A') {
          honor = 'សិស្សឆ្នើម (Honor Roll)';
        } else if (grade == 'B') {
          honor = 'សិស្សពូកែ (Distinction)';
        } else if (grade == 'C') {
          honor = 'សិស្សល្អ (Good)';
        } else if (grade == 'F') {
          honor = 'ត្រូវខិតខំ (Needs Effort)';
        }

        return [
          rank == 1
              ? 'លេខ ១ 🥇'
              : (rank == 2
                    ? 'លេខ ២ 🥈'
                    : (rank == 3 ? 'លេខ ៣ 🥉' : 'លេខ $rank')),
          s['student_code']?.toString() ?? '',
          '${s['name_kh'] ?? ''} (${s['name_en'] ?? ''})',
          s['class_name'] ?? s['grade'] ?? 'បឋមសិក្សា',
          total.toStringAsFixed(1),
          '${avg.toStringAsFixed(1)}%',
          grade,
          honor,
        ];
      }).toList();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          theme: pw.ThemeData.withFont(
            base: fontRegular,
            bold: fontBold,
            fontFallback: [fontRegular, fontBold],
          ),
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'ព្រះរាជាណាចក្រកម្ពុជា\nជាតិ សាសនា ព្រះមហាក្សត្រ',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(font: fontBold, fontSize: 12),
                ),
                pw.SizedBox(height: 8),
                pw.Image(AppLogo.pdfImage, width: 42, height: 42),
                pw.SizedBox(height: 6),
                pw.Text(
                  'តារាងកិត្តិយសសិស្សឆ្នើមប្រចាំវគ្គ (HONOR ROLL LEADERBOARD)',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 14,
                    color: const PdfColor.fromInt(0xFF1E3A8A),
                  ),
                ),
                pw.Text(
                  'ឆ្នាំសិក្សា៖ $_selectedAcademicYear  |  វគ្គប្រឡង៖ $_selectedExamPeriod',
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.TableHelper.fromTextArray(
                  headers: headers,
                  headerStyle: pw.TextStyle(
                    font: fontBold,
                    color: PdfColors.white,
                    fontSize: 9,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFD97706),
                  ),
                  cellStyle: pw.TextStyle(font: fontRegular, fontSize: 8.5),
                  data: data,
                  cellAlignment: pw.Alignment.center,
                ),
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text(
                          'ប្រធានគណៈកម្មការវាយតម្លៃ',
                          style: pw.TextStyle(font: fontBold, fontSize: 10),
                        ),
                        pw.SizedBox(height: 35),
                        pw.Text(
                          '..........................................',
                          style: pw.TextStyle(font: fontRegular, fontSize: 9),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text(
                          'ហត្ថលេខា និងត្រានាយកសាលា',
                          style: pw.TextStyle(font: fontBold, fontSize: 10),
                        ),
                        pw.SizedBox(height: 35),
                        pw.Text(
                          '..........................................',
                          style: pw.TextStyle(font: fontRegular, fontSize: 9),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (fmt) => pdf.save(),
        name: 'Honor_Roll_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      debugPrint('Print honor roll error: $e');
    }
  }

  Widget _buildReportStudentPhoto(
    dynamic photoUrl, {
    double width = 80,
    double height = 100,
  }) {
    final str = (photoUrl ?? '').toString().trim();
    final fallback = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person,
            size: width * 0.45,
            color: const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 4),
          const Text(
            'រូបថតសិស្ស',
            style: TextStyle(
              fontFamily: 'Khmer OS Battambang',
              fontSize: 9,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
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

    Widget img;
    if (bytes != null) {
      img = Image.memory(
        bytes,
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    } else if (str.startsWith('http')) {
      img = Image.network(
        str,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    } else {
      img = Image.asset(
        str,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(6.5), child: img),
    );
  }

  void _showReportCard(Map<String, dynamic> student) {
    final ctrls = _getControllersForStudent(student);
    final totalScore = _getStudentTotal(student);
    final avgScore = _getStudentAverage(student);
    final rank = _getStudentRank(student);
    final isPassed = _isStudentPassed(avgScore);
    final maxScore = _subjects.length * 100;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 820,
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.assignment_turned_in_rounded,
                            color: Color(0xFF4F46E5),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'សន្លឹកលទ្ធផលប្រឡងផ្លូវការ / OFFICIAL STUDENT REPORT SLIP',
                            style: TextStyle(
                              fontFamily: 'Khmer OS Muol Light',
                              fontSize: 14,
                              color: Color(0xFF1E293B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE11D48),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => _printStudentReport(student),
                        icon: const Icon(
                          Icons.picture_as_pdf_rounded,
                          size: 16,
                        ),
                        label: const Text(
                          'ទាញយក PDF',
                          style: TextStyle(fontFamily: 'Khmer OS Battambang'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => _printStudentReport(student),
                        icon: const Icon(Icons.print_rounded, size: 16),
                        label: const Text(
                          'បោះពុម្ព (Print)',
                          style: TextStyle(fontFamily: 'Khmer OS Battambang'),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(36),
                    child: Column(
                      children: [
                        // Header
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF2563EB),
                                width: 2,
                              ),
                            ),
                            child: AppLogo.widget(
                              width: 72,
                              height: 72,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'ព្រះរាជាណាចក្រកម្ពុជា\nជាតិ សាសនា ព្រះមហាក្សត្រ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Khmer OS Muol Light',
                            fontSize: 14,
                            color: Color(0xFF1E293B),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'សាលាប្រាយឡាយ (BRIGHT LIGHT SCHOOL)',
                          style: TextStyle(
                            fontFamily: 'Khmer OS Muol Light',
                            fontSize: 16,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'ប័ណ្ណប្រកាសលទ្ធផលការសិក្សាផ្លូវការ / OFFICIAL ACADEMIC REPORT CARD',
                          style: TextStyle(
                            fontFamily: 'Khmer OS Battambang',
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          'ឆ្នាំសិក្សា: $_selectedAcademicYear • វគ្គប្រឡង: $_selectedExamPeriod',
                          style: const TextStyle(
                            fontFamily: 'Khmer OS Battambang',
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Student Info
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              _buildReportStudentPhoto(
                                student['photo_url'] ?? student['photo'],
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInfoRow(
                                      'ឈ្មោះសិស្ស:',
                                      '${student['name_kh'] ?? ''} (${student['name_en'] ?? ''})',
                                    ),
                                    const Divider(
                                      height: 12,
                                      color: Color(0xFFE2E8F0),
                                    ),
                                    _buildInfoRow(
                                      'អត្តលេខសិស្ស:',
                                      student['student_code'] ?? 'N/A',
                                    ),
                                    const Divider(
                                      height: 12,
                                      color: Color(0xFFE2E8F0),
                                    ),
                                    _buildInfoRow(
                                      'កម្រិតថ្នាក់រៀន:',
                                      (student['class_name'] ??
                                              student['grade'] ??
                                              student['grade_level_name'] ??
                                              'ថ្នាក់ទី ១A')
                                          .toString(),
                                    ),
                                    const Divider(
                                      height: 12,
                                      color: Color(0xFFE2E8F0),
                                    ),
                                    _buildInfoRow(
                                      'ភេទ / ថ្ងៃកំណើត:',
                                      '${student['gender'] ?? 'ស្រី'} / ${student['dob'] ?? '12-05-2010'}',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Table
                        Table(
                          border: TableBorder.all(
                            color: const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          columnWidths: const {
                            0: FixedColumnWidth(50),
                            1: FlexColumnWidth(),
                            2: FixedColumnWidth(110),
                            3: FixedColumnWidth(110),
                            4: FixedColumnWidth(90),
                          },
                          children: [
                            TableRow(
                              decoration: const BoxDecoration(
                                color: Color(0xFF1E293B),
                              ),
                              children: const [
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Text(
                                    'ល.រ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Khmer OS Battambang',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    'មុខវិជ្ជា (Subject)',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Khmer OS Battambang',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Text(
                                    'ពិន្ទុអតិបរមា',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Khmer OS Battambang',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Text(
                                    'ពិន្ទុទទួលបាន',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Khmer OS Battambang',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Text(
                                    'និទ្ទេស',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Khmer OS Battambang',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                            ..._subjects.asMap().entries.map((e) {
                              final idx = e.key + 1;
                              final subj = e.value;
                              final scText = ctrls[subj]?.text ?? '0';
                              final scVal = double.tryParse(scText) ?? 0.0;
                              final subLetter = _getGradeLetter(scVal);

                              return TableRow(
                                decoration: BoxDecoration(
                                  color: idx.isEven
                                      ? const Color(0xFFF8FAFC)
                                      : Colors.white,
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      '$idx',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      subj,
                                      style: const TextStyle(
                                        fontFamily: 'Khmer OS Battambang',
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      '100',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      scVal.toStringAsFixed(1),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      subLetter,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: _getGradeColor(subLetter),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                            TableRow(
                              decoration: const BoxDecoration(
                                color: Color(0xFFEFF6FF),
                              ),
                              children: [
                                const SizedBox(),
                                const Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: Text(
                                    'ពិន្ទុសរុប & មធ្យមភាគ (Total & Average):',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontFamily: 'Khmer OS Battambang',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Color(0xFF1E3A8A),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Text(
                                    '$maxScore',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Text(
                                    totalScore.toStringAsFixed(1),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Color(0xFFE11D48),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Text(
                                    _getGradeLetter(avgScore),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: _getGradeColor(
                                        _getGradeLetter(avgScore),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Summary Ribbon
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFFBBF24)),
                            borderRadius: BorderRadius.circular(12),
                            color: const Color(0xFFFFFBEB),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                children: [
                                  const Text(
                                    'មធ្យមភាគ',
                                    style: TextStyle(
                                      fontFamily: 'Khmer OS Battambang',
                                      fontSize: 12,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${avgScore.toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                height: 36,
                                width: 1,
                                color: const Color(0xFFFDE68A),
                              ),
                              Column(
                                children: [
                                  const Text(
                                    'ចំណាត់ថ្នាក់ក្នុងថ្នាក់',
                                    style: TextStyle(
                                      fontFamily: 'Khmer OS Battambang',
                                      fontSize: 12,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    rank == 1
                                        ? '🥇 លេខ ១'
                                        : (rank == 2
                                              ? '🥈 លេខ ២'
                                              : (rank == 3
                                                    ? '🥉 លេខ ៣'
                                                    : 'លេខ $rank')),
                                    style: const TextStyle(
                                      fontFamily: 'Khmer OS Muol Light',
                                      fontSize: 18,
                                      color: Color(0xFFD97706),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                height: 36,
                                width: 1,
                                color: const Color(0xFFFDE68A),
                              ),
                              Column(
                                children: [
                                  const Text(
                                    'លទ្ធផលរួម',
                                    style: TextStyle(
                                      fontFamily: 'Khmer OS Battambang',
                                      fontSize: 12,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isPassed
                                        ? 'ជាប់ (PASSED)'
                                        : 'ធ្លាក់ (FAILED)',
                                    style: TextStyle(
                                      fontFamily: 'Khmer OS Battambang',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isPassed
                                          ? const Color(0xFF059669)
                                          : const Color(0xFFDC2626),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Remarks
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'មតិយោបល់គ្រូបន្ទុកថ្នាក់៖',
                                style: TextStyle(
                                  fontFamily: 'Khmer OS Battambang',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _teacherRemarksCtrl.text,
                                style: const TextStyle(
                                  fontFamily: 'Khmer OS Battambang',
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'មតិយោបល់នាយកសាលា៖',
                                style: TextStyle(
                                  fontFamily: 'Khmer OS Battambang',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _principalRemarksCtrl.text,
                                style: const TextStyle(
                                  fontFamily: 'Khmer OS Battambang',
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Signatures
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Column(
                              children: [
                                Text(
                                  'គ្រូបន្ទុកថ្នាក់ (Homeroom Teacher)',
                                  style: TextStyle(
                                    fontFamily: 'Khmer OS Battambang',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(height: 50),
                                SizedBox(
                                  width: 160,
                                  child: Divider(color: Colors.black45),
                                ),
                                Text(
                                  'ហត្ថលេខា / Signature',
                                  style: TextStyle(
                                    fontFamily: 'Khmer OS Battambang',
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  'នាយកសាលា (School Principal)',
                                  style: TextStyle(
                                    fontFamily: 'Khmer OS Battambang',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(height: 50),
                                SizedBox(
                                  width: 160,
                                  child: Divider(color: Colors.black45),
                                ),
                                Text(
                                  'ហត្ថលេខានិងត្រា / Signature & Seal',
                                  style: TextStyle(
                                    fontFamily: 'Khmer OS Battambang',
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Khmer OS Battambang',
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Khmer OS Battambang',
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.bold,
                fontSize: 12,
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
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Brand and Tab Controls
            _buildHeader(),
            const SizedBox(height: 20),

            // Filter Bar
            _buildFilterBar(),
            const SizedBox(height: 24),

            // Tab Content
            if (_selectedTab == 0)
              _buildSingleStudentTab()
            else if (_selectedTab == 1)
              _buildBatchClassTab()
            else
              _buildRankingsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final isNarrow = constraints.maxWidth < 900;
          final titleWidget = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3DF59E0B),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'គ្រប់គ្រងលទ្ធផលប្រឡងសិស្ស / Student Exam Results',
                    style: TextStyle(
                      fontFamily: 'Khmer OS Muol Light',
                      fontSize: 16,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'កត់ត្រា បញ្ចូលពិន្ទុ វិភាគចំណាត់ថ្នាក់ និងបោះពុម្ពប័ណ្ណលទ្ធផលសិក្សាផ្លូវការ',
                    style: TextStyle(
                      fontFamily: 'Khmer OS Battambang',
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          );

          final tabSwitcher = Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            padding: const EdgeInsets.all(4),
            child: Wrap(
              spacing: 4,
              children: [
                _buildTabBtn('តាមឈ្មោះសិស្ស (Single)', Icons.person_rounded, 0),
                _buildTabBtn(
                  'បញ្ចូលតាមថ្នាក់ (Batch)',
                  Icons.groups_rounded,
                  1,
                ),
                _buildTabBtn(
                  'ចំណាត់ថ្នាក់ & កិត្តិយស (Rankings)',
                  Icons.emoji_events_rounded,
                  2,
                ),
              ],
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [titleWidget, const SizedBox(height: 16), tabSwitcher],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [titleWidget, tabSwitcher],
          );
        },
      ),
    );
  }

  Widget _buildTabBtn(String label, IconData icon, int index) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Khmer OS Battambang',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final f1 = _buildFilterDropdown(
            label: 'ឆ្នាំសិក្សា / Academic Year',
            icon: Icons.calendar_today_rounded,
            value: _selectedAcademicYear,
            options: _academicYearOptions,
            onChanged: (val) {
              if (val != null) setState(() => _selectedAcademicYear = val);
            },
          );
          final f2 = _buildFilterDropdown(
            label: 'ប្រភេទការប្រឡង / Exam Category',
            icon: Icons.category_rounded,
            value: _selectedExamCategory,
            options: _examCategoryOptions,
            onChanged: (val) {
              if (val != null) setState(() => _selectedExamCategory = val);
            },
          );
          final f3 = _buildFilterDropdown(
            label: 'វគ្គ/ខែប្រឡង / Exam Period',
            icon: Icons.event_note_rounded,
            value: _selectedExamPeriod,
            options: _examPeriodOptions,
            onChanged: (val) {
              if (val != null) setState(() => _selectedExamPeriod = val);
            },
          );
          final f4 = _buildFilterDropdown(
            label: 'កម្រិតថ្នាក់ / Grade Level',
            icon: Icons.meeting_room_rounded,
            value: _selectedGradeLevel,
            options: _gradeLevelOptions,
            onChanged: (val) {
              if (val != null) setState(() => _selectedGradeLevel = val);
            },
          );

          if (constraints.maxWidth < 850) {
            return Column(
              children: [
                f1,
                const SizedBox(height: 12),
                f2,
                const SizedBox(height: 12),
                f3,
                const SizedBox(height: 12),
                f4,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: f1),
              const SizedBox(width: 14),
              Expanded(child: f2),
              const SizedBox(width: 14),
              Expanded(child: f3),
              const SizedBox(width: 14),
              Expanded(child: f4),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    final validOptions = options.toSet().toList();
    final actualValue = validOptions.contains(value)
        ? value
        : (validOptions.isNotEmpty ? validOptions.first : value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Khmer OS Battambang',
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: actualValue,
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
              items: validOptions.map((opt) {
                return DropdownMenuItem<String>(
                  value: opt,
                  child: Text(
                    opt,
                    style: const TextStyle(
                      fontFamily: 'Khmer OS Battambang',
                      fontSize: 12.5,
                      color: Color(0xFF1E293B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSingleStudentTab() {
    final students = _filteredStudents;
    if (_selectedStudentIndex >= students.length) {
      _selectedStudentIndex = 0;
    }

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isNarrow = constraints.maxWidth < 960;
        final studentListWidget = Container(
          width: isNarrow ? double.infinity : 320,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x060F172A),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.people_outline_rounded,
                          color: Color(0xFF2563EB),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'បញ្ជីសិស្ស (${students.length})',
                          style: const TextStyle(
                            fontFamily: 'Khmer OS Muol Light',
                            fontSize: 13,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        // ignore: unnecessary_string_interpolations
                        '$_selectedGradeLevel',
                        style: const TextStyle(
                          fontFamily: 'Khmer OS Battambang',
                          fontSize: 10,
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() {}),
                  style: const TextStyle(
                    fontFamily: 'Khmer OS Battambang',
                    fontSize: 12.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'ស្វែងរកឈ្មោះសិស្ស ឬអត្តលេខ...',
                    hintStyle: const TextStyle(
                      fontFamily: 'Khmer OS Battambang',
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF2563EB)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    fillColor: const Color(0xFFF8FAFC),
                    filled: true,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (students.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(36),
                  child: Center(
                    child: Text(
                      'រកមិនឃើញឈ្មោះសិស្សទេ',
                      style: TextStyle(
                        fontFamily: 'Khmer OS Battambang',
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: students.length,
                  separatorBuilder: (c, i) =>
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (ctx, i) {
                    final s = students[i];
                    final isSelected = _selectedStudentIndex == i;
                    final rank = _getStudentRank(s);
                    final avg = _getStudentAverage(s);

                    return InkWell(
                      onTap: () => setState(() => _selectedStudentIndex = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        margin: isSelected
                            ? const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              )
                            : EdgeInsets.zero,
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF2563EB),
                                    Color(0xFF1D4ED8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isSelected ? null : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                            isSelected ? 10 : 0,
                          ),
                          boxShadow: isSelected
                              ? const [
                                  BoxShadow(
                                    color: Color(0x3D2563EB),
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            AppAvatar(
                              photoUrl: s['photo_url'] ?? s['photo'],
                              radius: 19,
                              fallbackText: s['name_kh'] ?? s['name_en'] ?? '',
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s['name_kh'] ?? s['name_en'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontFamily: 'Khmer OS Muol Light',
                                      fontSize: 12,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF1E293B),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${s['student_code']} • ${s['class_name'] ?? s['grade'] ?? 'ថ្នាក់ទី ១A'}',
                                    style: TextStyle(
                                      fontFamily: 'Calibri Light',
                                      fontSize: 11,
                                      color: isSelected
                                          ? Colors.white70
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white24
                                        : (rank <= 3
                                              ? const Color(0xFFFEF3C7)
                                              : const Color(0xFFF1F5F9)),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    rank == 1
                                        ? '🥇 #1'
                                        : (rank == 2
                                              ? '🥈 #2'
                                              : (rank == 3
                                                    ? '🥉 #3'
                                                    : '#$rank')),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : (rank <= 3
                                                ? const Color(0xFFB45309)
                                                : const Color(0xFF64748B)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${avg.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF2563EB),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        );

        final rightPanelWidget = students.isEmpty
            ? Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Center(
                  child: Text(
                    'មិនមានទិន្នន័យសិស្សត្រូវបង្ហាញឡើយ សូមជ្រើសរើសតម្រងឡើងវិញ',
                    style: TextStyle(
                      fontFamily: 'Khmer OS Battambang',
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              )
            : _buildRightPanel(students[_selectedStudentIndex]);

        if (isNarrow) {
          return Column(
            children: [
              studentListWidget,
              const SizedBox(height: 24),
              rightPanelWidget,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            studentListWidget,
            const SizedBox(width: 24),
            Expanded(child: rightPanelWidget),
          ],
        );
      },
    );
  }

  Widget _buildRightPanel(Map<String, dynamic> student) {
    final ctrls = _getControllersForStudent(student);
    final avg = _getStudentAverage(student);
    final rank = _getStudentRank(student);
    final isPassed = _isStudentPassed(avg);
    final total = _getStudentTotal(student);
    final letter = _getGradeLetter(avg);

    return Column(
      children: [
        // Top Profile Banner Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x260F172A),
                blurRadius: 15,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final isCompact = constraints.maxWidth < 650;
              final profileInfo = Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFBBF24),
                        width: 2.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x3D000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: AppAvatar(
                      photoUrl: student['photo_url'] ?? student['photo'],
                      radius: 34,
                      fallbackText:
                          student['name_en'] ?? student['name_kh'] ?? '',
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              student['name_kh'] ?? 'Unknown',
                              style: const TextStyle(
                                fontFamily: 'Khmer OS Muol Light',
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${student['name_en'] ?? ''})',
                              style: const TextStyle(
                                fontFamily: 'Calibri Light',
                                fontSize: 14,
                                color: Color(0xFFA5B4FC),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _buildBadge(
                              'អត្តលេខ: ${student['student_code']}',
                              const Color(0xFF312E81),
                            ),
                            _buildBadge(
                              'ថ្នាក់: ${student['class_name'] ?? student['grade'] ?? 'ថ្នាក់ទី ១A'}',
                              const Color(0xFF312E81),
                            ),
                            _buildBadge(
                              'ភេទ: ${student['gender'] ?? 'ស្រី'}',
                              const Color(0xFF312E81),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final statsCard = Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1B4B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF4338CA)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'មធ្យមភាគ / AVERAGE',
                      style: TextStyle(
                        fontFamily: 'Khmer OS Battambang',
                        fontSize: 10.5,
                        color: Color(0xFFA5B4FC),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${avg.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFBBF24),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isPassed
                            ? const Color(0xFF059669)
                            : const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${isPassed ? 'ជាប់' : 'ធ្លាក់'} • ចំណាត់ថ្នាក់ទី $rank',
                        style: const TextStyle(
                          fontFamily: 'Khmer OS Battambang',
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    profileInfo,
                    const SizedBox(height: 16),
                    statsCard,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: profileInfo),
                  const SizedBox(width: 16),
                  statsCard,
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        // Grade Entry Form Card
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x060F172A),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: Color(0xFF2563EB),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'បញ្ចូលពិន្ទុតាមមុខវិជ្ជា ($_selectedExamPeriod)',
                        style: const TextStyle(
                          fontFamily: 'Khmer OS Battambang',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      'សរុប: ${total.toStringAsFixed(0)}/${_subjects.length * 100}  •  និទ្ទេស $letter',
                      style: TextStyle(
                        fontFamily: 'Khmer OS Battambang',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getGradeColor(letter),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Subjects Grid
              LayoutBuilder(
                builder: (ctx, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  final itemWidth = isWide
                      ? (constraints.maxWidth - 20) / 2
                      : constraints.maxWidth;

                  return Wrap(
                    spacing: 20,
                    runSpacing: 16,
                    children: _subjects.map((subj) {
                      final ctrl = ctrls[subj]!;
                      final icon = _subjectIcons[subj] ?? Icons.book_rounded;
                      final themeCol =
                          _subjectColors[subj] ?? const Color(0xFF2563EB);
                      final currentVal = double.tryParse(ctrl.text) ?? 0.0;
                      final subjLetter = _getGradeLetter(currentVal);

                      return SizedBox(
                        width: itemWidth,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: themeCol.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(icon, color: themeCol, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      subj,
                                      style: const TextStyle(
                                        fontFamily: 'Khmer OS Battambang',
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF334155),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'និទ្ទេស: $subjLetter',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: _getGradeColor(subjLetter),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 75,
                                height: 42,
                                child: TextField(
                                  controller: ctrl,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF2563EB),
                                  ),
                                  onChanged: (val) => setState(() {}),
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.zero,
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF2563EB),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                '/100',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 28),

              // Remarks Section
              LayoutBuilder(
                builder: (ctx, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  final teacherCol = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'មតិយោបល់គ្រូបន្ទុកថ្នាក់ / Teacher Remarks',
                            style: TextStyle(
                              fontFamily: 'Khmer OS Battambang',
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFF475569),
                            ),
                          ),
                          Wrap(
                            spacing: 6,
                            children: [
                              _buildQuickChip('ខិតខំរៀន', () {
                                setState(() {
                                  _teacherRemarksCtrl.text =
                                      'សិស្សខិតខំប្រឹងប្រែងរៀនសូត្រ មានអាកប្បកិរិយាល្អ និងគោរពវិន័យសាលា។';
                                });
                              }),
                              _buildQuickChip('ពូកែគណិត', () {
                                setState(() {
                                  _teacherRemarksCtrl.text =
                                      'សិស្សមានទេពកោសល្យខ្ពស់លើមុខវិជ្ជាគណិតវិទ្យា និងវិទ្យាសាស្ត្រ។';
                                });
                              }),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _teacherRemarksCtrl,
                        maxLines: 3,
                        style: const TextStyle(
                          fontFamily: 'Khmer OS Battambang',
                          fontSize: 12,
                        ),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          fillColor: const Color(0xFFF8FAFC),
                          filled: true,
                        ),
                      ),
                    ],
                  );

                  final principalCol = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'មតិយោបល់នាយកសាលា / Principal Remarks',
                            style: TextStyle(
                              fontFamily: 'Khmer OS Battambang',
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFF475569),
                            ),
                          ),
                          Wrap(
                            spacing: 6,
                            children: [
                              _buildQuickChip('បន្តខិតខំ', () {
                                setState(() {
                                  _principalRemarksCtrl.text =
                                      'សូមបន្តការខិតខំប្រឹងប្រែងដើម្បីទទួលបានលទ្ធផលកាន់តែប្រសើរ! (Passed)';
                                });
                              }),
                              _buildQuickChip('សរសើរ', () {
                                setState(() {
                                  _principalRemarksCtrl.text =
                                      'សរសើរចំពោះការខិតខំប្រឹងប្រែង និងលទ្ធផលល្អឆ្នើមក្នុងខែនេះ!';
                                });
                              }),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _principalRemarksCtrl,
                        maxLines: 3,
                        style: const TextStyle(
                          fontFamily: 'Khmer OS Battambang',
                          fontSize: 12,
                        ),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          fillColor: const Color(0xFFF8FAFC),
                          filled: true,
                        ),
                      ),
                    ],
                  );

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: teacherCol),
                        const SizedBox(width: 20),
                        Expanded(child: principalCol),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      teacherCol,
                      const SizedBox(height: 16),
                      principalCol,
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),
              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 18),

              // Action Buttons
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      foregroundColor: const Color(0xFF475569),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _exportGradesCSV(student),
                    icon: const Icon(Icons.file_download_outlined, size: 18),
                    label: const Text(
                      'ទាញយក CSV',
                      style: TextStyle(
                        fontFamily: 'Khmer OS Battambang',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      side: const BorderSide(color: Color(0xFF2563EB)),
                      foregroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _showReportCard(student),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text(
                      'មើលសន្លឹកពិន្ទុ (View Slip)',
                      style: TextStyle(
                        fontFamily: 'Khmer OS Battambang',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      side: const BorderSide(color: Color(0xFF059669)),
                      foregroundColor: const Color(0xFF059669),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _printStudentReport(student),
                    icon: const Icon(Icons.print_outlined, size: 18),
                    label: const Text(
                      'បោះពុម្ពប័ណ្ណពិន្ទុ (Print PDF)',
                      style: TextStyle(
                        fontFamily: 'Khmer OS Battambang',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _isSavingStudent
                        ? null
                        : () => _saveExamRecord(student),
                    icon: _isSavingStudent
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(
                      _isSavingStudent
                          ? 'កំពុងរក្សាទុក...'
                          : 'រក្សាទុកពិន្ទុ / Save Record',
                      style: const TextStyle(
                        fontFamily: 'Khmer OS Battambang',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFC7D2FE)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Khmer OS Battambang',
            fontSize: 10,
            color: Color(0xFF4F46E5),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBatchClassTab() {
    final students = _filteredStudents;
    final totalCount = students.length;
    double sumAll = 0;
    int passCount = 0;
    for (final s in students) {
      final a = _getStudentAverage(s);
      sumAll += a;
      if (_isStudentPassed(a)) passCount++;
    }
    final classAvg = totalCount > 0 ? (sumAll / totalCount) : 0.0;
    final failCount = totalCount - passCount;
    final passRate = totalCount > 0 ? (passCount / totalCount * 100) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary KPI Stats Cards
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildStatCard(
              title: 'សិស្សក្នុងថ្នាក់សរុប',
              value: '$totalCount នាក់',
              subtitle: 'កម្រិត: $_selectedGradeLevel',
              icon: Icons.groups_rounded,
              color: const Color(0xFF2563EB),
              bgGradient: const [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
            ),
            _buildStatCard(
              title: 'មធ្យមភាគពិន្ទុថ្នាក់',
              value: '${classAvg.toStringAsFixed(1)}%',
              subtitle: 'ពិន្ទុអតិបរមា: 100%',
              icon: Icons.analytics_rounded,
              color: const Color(0xFF7C3AED),
              bgGradient: const [Color(0xFFF5F3FF), Color(0xFFEDE9FE)],
            ),
            _buildStatCard(
              title: 'សិស្សប្រឡងជាប់',
              value: '$passCount នាក់',
              subtitle: 'អត្រាជាប់: ${passRate.toStringAsFixed(1)}%',
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF059669),
              bgGradient: const [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
            ),
            _buildStatCard(
              title: 'សិស្សធ្លាក់ (ត្រូវខិតខំ)',
              value: '$failCount នាក់',
              subtitle: 'អត្រាធ្លាក់: ${(100 - passRate).toStringAsFixed(1)}%',
              icon: Icons.error_outline_rounded,
              color: const Color(0xFFDC2626),
              bgGradient: const [Color(0xFFFEF2F2), Color(0xFFFEE2E2)],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Action Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x060F172A),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.table_chart_rounded,
                    color: Color(0xFF2563EB),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'តារាងបញ្ចូលពិន្ទុរួម ($totalCount នាក់) • $_selectedExamPeriod',
                    style: const TextStyle(
                      fontFamily: 'Khmer OS Muol Light',
                      fontSize: 13,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      foregroundColor: const Color(0xFF475569),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _exportBatchCSV,
                    icon: const Icon(Icons.file_download_outlined, size: 16),
                    label: const Text(
                      'ទាញយក Class CSV',
                      style: TextStyle(
                        fontFamily: 'Khmer OS Battambang',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      foregroundColor: const Color(0xFF475569),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _printBatchGradeSheet,
                    icon: const Icon(Icons.print_outlined, size: 16),
                    label: const Text(
                      'បោះពុម្ពតារាងពិន្ទុថ្នាក់ (PDF)',
                      style: TextStyle(
                        fontFamily: 'Khmer OS Battambang',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 11,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    onPressed: _isSavingBatch ? null : _saveAllBatch,
                    icon: _isSavingBatch
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded, size: 16),
                    label: Text(
                      _isSavingBatch
                          ? 'កំពុងរក្សាទុក...'
                          : 'រក្សាទុកទាំងអស់ (Save All)',
                      style: const TextStyle(
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
        ),
        const SizedBox(height: 18),

        // Editable Batch Data Grid
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x060F172A),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 1100),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFFF8FAFC),
                  ),
                  headingTextStyle: const TextStyle(
                    fontFamily: 'Khmer OS Battambang',
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: 64,
                  horizontalMargin: 16,
                  columnSpacing: 16,
                  columns: const [
                    DataColumn(label: Text('ល.រ')),
                    DataColumn(label: Text('ព័ត៌មានសិស្ស')),
                    DataColumn(label: Text('ភេទ')),
                    DataColumn(label: Text('ខ្មែរ')),
                    DataColumn(label: Text('គណិត')),
                    DataColumn(label: Text('វិទ្យា')),
                    DataColumn(label: Text('សង្គម')),
                    DataColumn(label: Text('អង់គ្លេស')),
                    DataColumn(label: Text('កុំព្យូទ័រ')),
                    DataColumn(label: Text('វិន័យ')),
                    DataColumn(label: Text('សរុប')),
                    DataColumn(label: Text('មធ្យមភាគ')),
                    DataColumn(label: Text('និទ្ទេស')),
                    DataColumn(label: Text('ចំណាត់ថ្នាក់')),
                    DataColumn(label: Text('សកម្មភាព')),
                  ],
                  rows: students.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final s = entry.value;
                    final ctrls = _getControllersForStudent(s);
                    final total = _getStudentTotal(s);
                    final avg = _getStudentAverage(s);
                    final letter = _getGradeLetter(avg);
                    final rank = _getStudentRank(s);

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            '$idx',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppAvatar(
                                photoUrl: s['photo_url'] ?? s['photo'],
                                radius: 17,
                                fallbackText:
                                    s['name_kh'] ?? s['name_en'] ?? '',
                              ),
                              const SizedBox(width: 8),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s['name_kh'] ?? s['name_en'] ?? '',
                                    style: const TextStyle(
                                      fontFamily: 'Khmer OS Muol Light',
                                      fontSize: 11.5,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  Text(
                                    '${s['student_code']} • ${s['class_name'] ?? s['grade'] ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Text(
                            s['gender'] ?? 'ស្រី',
                            style: const TextStyle(
                              fontFamily: 'Khmer OS Battambang',
                              fontSize: 12,
                            ),
                          ),
                        ),
                        ..._subjects.map((subj) {
                          final c = ctrls[subj]!;
                          return DataCell(
                            Container(
                              width: 58,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: TextField(
                                controller: c,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF2563EB),
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (val) => setState(() {}),
                              ),
                            ),
                          );
                        }),
                        DataCell(
                          Text(
                            total.toStringAsFixed(0),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFFE11D48),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${avg.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _getGradeColor(
                                letter,
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _getGradeColor(
                                  letter,
                                ).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              letter,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: _getGradeColor(letter),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: rank <= 3
                                  ? const Color(0xFFFEF3C7)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: rank <= 3
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Text(
                              rank == 1
                                  ? '🥇 #1'
                                  : (rank == 2
                                        ? '🥈 #2'
                                        : (rank == 3 ? '🥉 #3' : '#$rank')),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: rank <= 3
                                    ? const Color(0xFFB45309)
                                    : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.save_rounded,
                                  size: 18,
                                  color: Color(0xFF2563EB),
                                ),
                                tooltip: 'រក្សាទុកសិស្សនេះ',
                                onPressed: () => _saveExamRecord(s),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.assignment_outlined,
                                  size: 18,
                                  color: Color(0xFF059669),
                                ),
                                tooltip: 'មើលសន្លឹកលទ្ធផល',
                                onPressed: () => _showReportCard(s),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankingsTab() {
    final ranked = _rankedStudents;
    final top1 = ranked.isNotEmpty ? ranked[0] : null;
    final top2 = ranked.length > 1 ? ranked[1] : null;
    final top3 = ranked.length > 2 ? ranked[2] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Champions Podium Top 3 Cards
        if (ranked.isNotEmpty)
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              if (top2 != null)
                _buildPodiumCard(
                  student: top2,
                  rank: 2,
                  medalIcon: '🥈',
                  title: 'ជើងឯកចំណាត់ថ្នាក់លេខ ២',
                  themeColor: const Color(0xFF94A3B8),
                  cardBg: const Color(0xFFF8FAFC),
                  borderColor: const Color(0xFFCBD5E1),
                ),
              if (top1 != null)
                _buildPodiumCard(
                  student: top1,
                  rank: 1,
                  medalIcon: '🥇',
                  title: 'ជើងឯកចំណាត់ថ្នាក់លេខ ១',
                  themeColor: const Color(0xFFD97706),
                  cardBg: const Color(0xFFFFFBEB),
                  borderColor: const Color(0xFFF59E0B),
                  isChampion: true,
                ),
              if (top3 != null)
                _buildPodiumCard(
                  student: top3,
                  rank: 3,
                  medalIcon: '🥉',
                  title: 'ជើងឯកចំណាត់ថ្នាក់លេខ ៣',
                  themeColor: const Color(0xFFB45309),
                  cardBg: const Color(0xFFFFF7ED),
                  borderColor: const Color(0xFFFDBA74),
                ),
            ],
          ),
        const SizedBox(height: 24),

        // Action Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x060F172A),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFFF59E0B),
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'តារាងកិត្តិយស និងចំណាត់ថ្នាក់សិស្ស (${ranked.length} នាក់) • $_selectedExamPeriod',
                    style: const TextStyle(
                      fontFamily: 'Khmer OS Muol Light',
                      fontSize: 13,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 12,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      foregroundColor: const Color(0xFF475569),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _exportRankingsCSV,
                    icon: const Icon(Icons.file_download_outlined, size: 16),
                    label: const Text(
                      'ទាញយកតារាងចំណាត់ថ្នាក់ CSV',
                      style: TextStyle(
                        fontFamily: 'Khmer OS Battambang',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 11,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    onPressed: _printHonorRoll,
                    icon: const Icon(Icons.workspace_premium_rounded, size: 18),
                    label: const Text(
                      'បោះពុម្ពតារាងកិត្តិយស (Print Honor Roll PDF)',
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
        ),
        const SizedBox(height: 18),

        // Full Ranked Leaderboard Table
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x060F172A),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 1000),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFFF8FAFC),
                  ),
                  headingTextStyle: const TextStyle(
                    fontFamily: 'Khmer OS Battambang',
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                  dataRowMinHeight: 56,
                  dataRowMaxHeight: 64,
                  horizontalMargin: 20,
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(label: Text('ចំណាត់ថ្នាក់')),
                    DataColumn(label: Text('ព័ត៌មានសិស្ស')),
                    DataColumn(label: Text('ថ្នាក់រៀន')),
                    DataColumn(label: Text('ពិន្ទុសរុប')),
                    DataColumn(label: Text('មធ្យមភាគ')),
                    DataColumn(label: Text('និទ្ទេស')),
                    DataColumn(label: Text('កិត្តិយស')),
                    DataColumn(label: Text('លទ្ធផល')),
                    DataColumn(label: Text('សកម្មភាព')),
                  ],
                  rows: ranked.asMap().entries.map((entry) {
                    final rank = entry.key + 1;
                    final s = entry.value;
                    final total = _getStudentTotal(s);
                    final avg = _getStudentAverage(s);
                    final letter = _getGradeLetter(avg);
                    final isPassed = _isStudentPassed(avg);

                    String honor = 'និទ្ទេសមធ្យម (Fair)';
                    if (letter == 'A') {
                      honor = 'សិស្សឆ្នើម (Honor Roll)';
                    } else if (letter == 'B') {
                      honor = 'សិស្សពូកែ (Distinction)';
                    } else if (letter == 'C') {
                      honor = 'សិស្សល្អ (Good)';
                    } else if (letter == 'F') {
                      honor = 'ត្រូវខិតខំបន្ថែម';
                    }

                    return DataRow(
                      cells: [
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: rank == 1
                                      ? const Color(0xFFFEF3C7)
                                      : (rank == 2
                                            ? const Color(0xFFF1F5F9)
                                            : (rank == 3
                                                  ? const Color(0xFFFFEDD5)
                                                  : Colors.white)),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: rank == 1
                                        ? const Color(0xFFF59E0B)
                                        : (rank == 2
                                              ? const Color(0xFF94A3B8)
                                              : (rank == 3
                                                    ? const Color(0xFFFB923C)
                                                    : const Color(0xFFE2E8F0))),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    rank == 1
                                        ? '🥇'
                                        : (rank == 2
                                              ? '🥈'
                                              : (rank == 3 ? '🥉' : '$rank')),
                                    style: TextStyle(
                                      fontSize: rank <= 3 ? 14 : 12,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'លេខ $rank',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppAvatar(
                                photoUrl: s['photo_url'] ?? s['photo'],
                                radius: 18,
                                fallbackText:
                                    s['name_kh'] ?? s['name_en'] ?? '',
                              ),
                              const SizedBox(width: 10),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s['name_kh'] ?? s['name_en'] ?? '',
                                    style: const TextStyle(
                                      fontFamily: 'Khmer OS Muol Light',
                                      fontSize: 12,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  Text(
                                    s['student_code'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Text(
                            s['class_name'] ?? s['grade'] ?? 'ថ្នាក់ទី ១A',
                            style: const TextStyle(
                              fontFamily: 'Khmer OS Battambang',
                              fontSize: 12,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            total.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFFE11D48),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${avg.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getGradeColor(
                                letter,
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getGradeColor(
                                  letter,
                                ).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              letter,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: _getGradeColor(letter),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            honor,
                            style: TextStyle(
                              fontFamily: 'Khmer OS Battambang',
                              fontSize: 12,
                              color: letter == 'A'
                                  ? const Color(0xFFB45309)
                                  : const Color(0xFF334155),
                              fontWeight: letter == 'A'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isPassed
                                  ? const Color(0xFFECFDF5)
                                  : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isPassed ? 'ជាប់' : 'ធ្លាក់',
                              style: TextStyle(
                                fontFamily: 'Khmer OS Battambang',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isPassed
                                    ? const Color(0xFF059669)
                                    : const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onPressed: () => _showReportCard(s),
                            icon: const Icon(
                              Icons.assignment_turned_in_outlined,
                              size: 14,
                            ),
                            label: const Text(
                              'មើលសន្លឹកពិន្ទុ',
                              style: TextStyle(
                                fontFamily: 'Khmer OS Battambang',
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Color> bgGradient,
  }) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Khmer OS Battambang',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF475569),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.15),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Khmer OS Battambang',
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumCard({
    required Map<String, dynamic> student,
    required int rank,
    required String medalIcon,
    required String title,
    required Color themeColor,
    required Color cardBg,
    required Color borderColor,
    bool isChampion = false,
  }) {
    final total = _getStudentTotal(student);
    final avg = _getStudentAverage(student);
    final letter = _getGradeLetter(avg);

    return Container(
      width: isChampion ? 320 : 280,
      padding: EdgeInsets.all(isChampion ? 24 : 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: isChampion ? 2.5 : 1.5),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: isChampion ? 0.2 : 0.08),
            blurRadius: isChampion ? 18 : 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: themeColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(medalIcon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Khmer OS Battambang',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: themeColor, width: isChampion ? 3 : 2),
            ),
            child: AppAvatar(
              photoUrl: student['photo_url'] ?? student['photo'],
              radius: isChampion ? 40 : 32,
              fallbackText: student['name_kh'] ?? student['name_en'] ?? '',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            student['name_kh'] ?? student['name_en'] ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Khmer OS Muol Light',
              fontSize: isChampion ? 16 : 14,
              color: const Color(0xFF1E293B),
            ),
          ),
          Text(
            '${student['student_code']} • ${student['class_name'] ?? student['grade'] ?? ''}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      'ពិន្ទុសរុប',
                      style: TextStyle(
                        fontFamily: 'Khmer OS Battambang',
                        fontSize: 10,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      total.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFFE11D48),
                      ),
                    ),
                  ],
                ),
                Container(height: 24, width: 1, color: const Color(0xFFE2E8F0)),
                Column(
                  children: [
                    const Text(
                      'មធ្យមភាគ',
                      style: TextStyle(
                        fontFamily: 'Khmer OS Battambang',
                        fontSize: 10,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '${avg.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
                Container(height: 24, width: 1, color: const Color(0xFFE2E8F0)),
                Column(
                  children: [
                    const Text(
                      'និទ្ទេស',
                      style: TextStyle(
                        fontFamily: 'Khmer OS Battambang',
                        fontSize: 10,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      letter,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _getGradeColor(letter),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: themeColor),
              foregroundColor: themeColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => _showReportCard(student),
            icon: const Icon(Icons.assignment_outlined, size: 14),
            label: const Text(
              'មើលសន្លឹកពិន្ទុ (View Slip)',
              style: TextStyle(fontFamily: 'Khmer OS Battambang', fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Khmer OS Battambang',
          fontSize: 11,
          color: Colors.white,
        ),
      ),
    );
  }
}
