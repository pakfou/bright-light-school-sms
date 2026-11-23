import 'package:school_management_app/services/api_service.dart';
import 'package:school_management_app/utils/csv_exporter.dart';
import 'package:school_management_app/models/app_models.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ClassroomsManagerView extends StatefulWidget {
  const ClassroomsManagerView({super.key});

  @override
  State<ClassroomsManagerView> createState() => _ClassroomsManagerViewState();
}

class _ClassroomsManagerViewState extends State<ClassroomsManagerView>
    with SingleTickerProviderStateMixin {
  static String get baseUrl => ApiService.baseUrl;
  List<dynamic> _levels = [];
  List<dynamic> _classes = [];
  bool _isLoading = true;
  late TabController _tabController;
  bool _countMergedRooms = true;
  bool _showInsights = true;

  String _selectedAcademicYear = '2025-2026';
  final List<String> _academicYears = [
    'ទាំងអស់ (All Years)',
    '2024-2025',
    '2025-2026',
    '2026-2027',
  ];

  final List<String> _teacherNames = [
    'ហាក់ ប៉ាក់ហ៊្វូរ',
    'សន ចរិយា',
    'ចាន់ សុវណ្ណារ៉ា',
    'ទូច ស្រីមុំ (Tous Sreymom)',
    'ភី ស្រីនុច (Phi Sreynuch)',
    'រី ស្រីនាង (Ry Sreyneang)',
    'សុផាន់ ម៉ៃ (Sophann May)',
    'អ៊ាត សុជា (Eat Sochea)',
    'វ៉ែន លាភហេង (Ven Leapheng)',
    'ប៉ែន រីណា (Pen Rina)',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        http.get(Uri.parse('$baseUrl/grade-levels')),
        http.get(Uri.parse('$baseUrl/classrooms')),
        http.get(Uri.parse('$baseUrl/teachers')).catchError((_) => http.Response('{"data":[]}', 200)),
      ]);
      final lRes = results[0];
      final cRes = results[1];
      final tRes = results[2];

      if (mounted) {
        setState(() {
          if (lRes.statusCode == 200) {
            try {
              final d = jsonDecode(utf8.decode(lRes.bodyBytes))['data'];
              if (d is List && d.isNotEmpty) _levels = d;
            } catch (_) {}
          }
          if (cRes.statusCode == 200) {
            try {
              final d = jsonDecode(utf8.decode(cRes.bodyBytes))['data'];
              if (d is List && d.isNotEmpty) _classes = d;
            } catch (_) {}
          }
          if (tRes.statusCode == 200) {
            try {
              final td = jsonDecode(utf8.decode(tRes.bodyBytes))['data'];
              if (td is List && td.isNotEmpty) {
                for (var t in td) {
                  final name = t['name_kh'] ?? t['name'] ?? t['fullName'];
                  if (name != null && !_teacherNames.contains(name.toString())) {
                    _teacherNames.add(name.toString());
                  }
                }
              }
            } catch (_) {}
          }

          // Ensure default teacher and academic year values exist for display
          if (_classes.isNotEmpty) {
            for (var c in _classes) {
              if (c['academic_year'] == null || c['academic_year'].toString().isEmpty) {
                c['academic_year'] = '2025-2026';
              }
              if (c['teacher_name'] == null || c['teacher_name'].toString().isEmpty) {
                final cName = c['class_name']?.toString() ?? '';
                if (cName.contains('05') || cName.contains('O5')) {
                  c['teacher_name'] = 'ទូច ស្រីមុំ (Tous Sreymom)';
                } else if (cName.contains('02') || cName.contains('O2')) {
                  c['teacher_name'] = 'ភី ស្រីនុច (Phi Sreynuch)';
                } else if (cName.contains('01') || cName.contains('O1')) {
                  c['teacher_name'] = 'រី ស្រីនាង (Ry Sreyneang)';
                } else if (cName.contains('រដ្ឋបាល')) {
                  c['teacher_name'] = 'ហាក់ ប៉ាក់ហ៊្វូរ (Admin)';
                } else {
                  c['teacher_name'] = 'ហាក់ ប៉ាក់ហ៊្វូរ';
                }
              }
            }
          }
          if (_levels.isEmpty) {
            _levels = [
              {
                'id': 1,
                'name': 'ថ្នាក់ទី ១ (Grade 1)',
                'study_type': 'Full-Time',
                'description': 'បឋមសិក្សា',
              },
              {
                'id': 2,
                'name': 'ថ្នាក់ទី ២ (Grade 2)',
                'study_type': 'Full-Time',
                'description': 'បឋមសិក្សា',
              },
              {
                'id': 3,
                'name': 'ថ្នាក់ទី ៣ (Grade 3)',
                'study_type': 'Full-Time',
                'description': 'បឋមសិក្សា',
              },
              {
                'id': 4,
                'name': 'ថ្នាក់ទី ៧ (Grade 7)',
                'study_type': 'Full-Time',
                'description': 'អនុវិទ្យាល័យ',
              },
              {
                'id': 5,
                'name': 'ថ្នាក់ទី ៨ (Grade 8)',
                'study_type': 'Full-Time',
                'description': 'អនុវិទ្យាល័យ',
              },
              {
                'id': 6,
                'name': 'ថ្នាក់ទី ១២ (Grade 12)',
                'study_type': 'Full-Time',
                'description': 'វិទ្យាល័យ',
              },
              {
                'id': 7,
                'name': 'ភាសាអង់គ្លេសទូទៅ (GEP)',
                'study_type': 'Part-Time',
                'description': 'ក្រៅម៉ោង',
              },
            ];
          }
          if (_classes.isEmpty) {
            _classes = [
              {
                'id': 25,
                'class_name': '05 (Going Place 3)',
                'grade_level': 'ភាសាអង់គ្លេសទូទៅ (GEP)',
                'room_number': 'Room-01',
                'shift': 'Afternoon',
                'teacher_name': 'ទូច ស្រីមុំ (Tous Sreymom)',
                'academic_year': '2025-2026',
                'students_count': 20,
              },
              {
                'id': 24,
                'class_name': '02 (EFL 5A)',
                'grade_level': 'ភាសាអង់គ្លេសទូទៅ (GEP)',
                'room_number': 'Room 01',
                'shift': 'Afternoon',
                'teacher_name': 'ភី ស្រីនុច (Phi Sreynuch)',
                'academic_year': '2025-2026',
                'students_count': 20,
              },
              {
                'id': 23,
                'class_name': '01 (EFL 3B)',
                'grade_level': 'ភាសាអង់គ្លេសទូទៅ (GEP)',
                'room_number': 'Room-01',
                'shift': 'Afternoon',
                'teacher_name': 'រី ស្រីនាង / ប៉ែន រីណា',
                'academic_year': '2025-2026',
                'students_count': 12,
              },
              {
                'id': 1,
                'class_name': 'ថ្នាក់ទី ១A',
                'grade_level': 'ថ្នាក់ទី ១ (Grade 1)',
                'room_number': 'Room-101',
                'shift': 'Morning',
                'teacher_name': 'ហាក់ ប៉ាក់ហ៊្វូរ',
                'academic_year': '2025-2026',
                'students_count': 28,
              },
              {
                'id': 2,
                'class_name': 'ថ្នាក់ទី ២A',
                'grade_level': 'ថ្នាក់ទី ២ (Grade 2)',
                'room_number': 'Room-102',
                'shift': 'Morning',
                'teacher_name': 'សន ចរិយា',
                'academic_year': '2025-2026',
                'students_count': 25,
              },
              {
                'id': 6,
                'class_name': 'ថ្នាក់ទី ១២A',
                'grade_level': 'ថ្នាក់ទី ១២ (Grade 12)',
                'room_number': 'Room-201',
                'shift': 'Morning',
                'teacher_name': 'ចាន់ សុវណ្ណារ៉ា',
                'academic_year': '2025-2026',
                'students_count': 18,
              },
              {
                'id': 13,
                'class_name': 'បន្ទប់ការិយាល័យ & រដ្ឋបាល',
                'grade_level': 'ភាសាចិន (Chinese Program)',
                'room_number': 'Admin-01',
                'shift': 'Morning',
                'teacher_name': 'ហាក់ ប៉ាក់ហ៊្វូរ (Admin)',
                'academic_year': '2025-2026',
                'students_count': 1,
              },
            ];
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          if (_levels.isEmpty) {
            _levels = [
              {
                'id': 1,
                'name': 'ថ្នាក់ទី ១ (Grade 1)',
                'study_type': 'Full-Time',
                'description': 'បឋមសិក្សា',
              },
              {
                'id': 2,
                'name': 'ថ្នាក់ទី ២ (Grade 2)',
                'study_type': 'Full-Time',
                'description': 'បឋមសិក្សា',
              },
              {
                'id': 3,
                'name': 'ថ្នាក់ទី ៣ (Grade 3)',
                'study_type': 'Full-Time',
                'description': 'បឋមសិក្សា',
              },
              {
                'id': 4,
                'name': 'ថ្នាក់ទី ៧ (Grade 7)',
                'study_type': 'Full-Time',
                'description': 'អនុវិទ្យាល័យ',
              },
              {
                'id': 5,
                'name': 'ថ្នាក់ទី ៨ (Grade 8)',
                'study_type': 'Full-Time',
                'description': 'អនុវិទ្យាល័យ',
              },
              {
                'id': 6,
                'name': 'ថ្នាក់ទី ១២ (Grade 12)',
                'study_type': 'Full-Time',
                'description': 'វិទ្យាល័យ',
              },
              {
                'id': 7,
                'name': 'ភាសាអង់គ្លេសទូទៅ (GEP)',
                'study_type': 'Part-Time',
                'description': 'ក្រៅម៉ោង',
              },
            ];
          }
          if (_classes.isEmpty) {
            _classes = [
              {
                'id': 25,
                'class_name': '05 (Going Place 3)',
                'grade_level': 'ភាសាអង់គ្លេសទូទៅ (GEP)',
                'room_number': 'Room-01',
                'shift': 'Afternoon',
                'teacher_name': 'ទូច ស្រីមុំ (Tous Sreymom)',
                'academic_year': '2025-2026',
                'students_count': 20,
              },
              {
                'id': 24,
                'class_name': '02 (EFL 5A)',
                'grade_level': 'ភាសាអង់គ្លេសទូទៅ (GEP)',
                'room_number': 'Room 01',
                'shift': 'Afternoon',
                'teacher_name': 'ភី ស្រីនុច (Phi Sreynuch)',
                'academic_year': '2025-2026',
                'students_count': 20,
              },
              {
                'id': 23,
                'class_name': '01 (EFL 3B)',
                'grade_level': 'ភាសាអង់គ្លេសទូទៅ (GEP)',
                'room_number': 'Room-01',
                'shift': 'Afternoon',
                'teacher_name': 'រី ស្រីនាង / ប៉ែន រីណា',
                'academic_year': '2025-2026',
                'students_count': 12,
              },
              {
                'id': 1,
                'class_name': 'ថ្នាក់ទី ១A',
                'grade_level': 'ថ្នាក់ទី ១ (Grade 1)',
                'room_number': 'Room-101',
                'shift': 'Morning',
                'teacher_name': 'ហាក់ ប៉ាក់ហ៊្វូរ',
                'academic_year': '2025-2026',
                'students_count': 28,
              },
              {
                'id': 2,
                'class_name': 'ថ្នាក់ទី ២A',
                'grade_level': 'ថ្នាក់ទី ២ (Grade 2)',
                'room_number': 'Room-102',
                'shift': 'Morning',
                'teacher_name': 'សន ចរិយា',
                'academic_year': '2025-2026',
                'students_count': 25,
              },
              {
                'id': 6,
                'class_name': 'ថ្នាក់ទី ១២A',
                'grade_level': 'ថ្នាក់ទី ១២ (Grade 12)',
                'room_number': 'Room-201',
                'shift': 'Morning',
                'teacher_name': 'ចាន់ សុវណ្ណារ៉ា',
                'academic_year': '2025-2026',
                'students_count': 18,
              },
              {
                'id': 13,
                'class_name': 'បន្ទប់ការិយាល័យ & រដ្ឋបាល',
                'grade_level': 'ភាសាចិន (Chinese Program)',
                'room_number': 'Admin-01',
                'shift': 'Morning',
                'teacher_name': 'ហាក់ ប៉ាក់ហ៊្វូរ (Admin)',
                'academic_year': '2025-2026',
                'students_count': 1,
              },
            ];
          }
          _isLoading = false;
        });
      }
    }
  }

  void _exportCSV() {
    final buf = StringBuffer();
    buf.writeln(
      '\uFEFFឈ្មោះថ្នាក់រៀន,កម្រិតសិក្សា,ប្រភេទកម្មវិធី,លេខបន្ទប់,ចំណុះសិស្ស,វេនសិក្សា',
    );
    for (var c in _classes) {
      buf.writeln(
        '"${c['class_name']}","${c['grade_level_name'] ?? ''}","${c['study_type'] ?? ''}","${c['room_number'] ?? ''}",${c['capacity'] ?? 0},"${c['shift'] ?? ''}"',
      );
    }
    downloadCsv(buf.toString(), 'classrooms_data.csv');
  }

  void _addGradeLevelDialog() {
    final nameCtrl = TextEditingController();
    String type = 'Full-Time';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.layers,
                        color: Color(0xFF4F46E5),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'បញ្ចូលកម្រិតសិក្សាថ្មី',
                      style: TextStyle(
                        fontFamily: 'Khmer OS Muol Light',
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText:
                        'ឈ្មោះកម្រិត (ឧ. ថ្នាក់ទី១, កុំព្យូទ័រ Level 1)...',
                    labelStyle: const TextStyle(
                      fontFamily: 'Khmer OS Battambang',
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: type,
                  decoration: InputDecoration(
                    labelText: 'ប្រភេទសិក្សា',
                    labelStyle: const TextStyle(
                      fontFamily: 'Khmer OS Battambang',
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Full-Time',
                      child: Text(
                        'សម្រាប់សិស្សពេញម៉ោង (Full-Time)',
                        style: TextStyle(
                          fontFamily: 'Khmer OS Battambang',
                          fontSize: 13,
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Part-Time',
                      child: Text(
                        'សម្រាប់សិស្សក្រៅម៉ោង (Part-Time)',
                        style: TextStyle(
                          fontFamily: 'Khmer OS Battambang',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) => setM(() => type = v!),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          'បោះបង់',
                          style: TextStyle(
                            fontFamily: 'Khmer OS Battambang',
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          if (nameCtrl.text.isEmpty) return;
                          await http.post(
                            Uri.parse('$baseUrl/grade-levels'),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({
                              'name': nameCtrl.text.trim(),
                              'study_type': type,
                            }),
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          _loadAll();
                        },
                        child: const Text(
                          'រក្សាទុក',
                          style: TextStyle(
                            fontFamily: 'Khmer OS Battambang',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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

  void _addClassroomDialog() {
    final nameCtrl = TextEditingController();
    final roomCtrl = TextEditingController(text: 'Room-01');
    int? selLevel = _levels.isNotEmpty ? _levels[0]['id'] : null;
    String shift = 'Morning';
    String selectedTeacher = _teacherNames.first;
    String academicYear = _selectedAcademicYear == 'ទាំងអស់ (All Years)' ? '2025-2026' : _selectedAcademicYear;

    if (_levels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'សូមបញ្ចូលកម្រិតសិក្សាជាមុនសិន!',
            style: TextStyle(fontFamily: 'Khmer OS Battambang'),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: 440,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.meeting_room,
                          color: Color(0xFF10B981),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'បង្កើតបន្ទប់ថ្នាក់រៀនថ្មី',
                        style: TextStyle(
                          fontFamily: 'Khmer OS Muol Light',
                          fontSize: 16,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'ឈ្មោះថ្នាក់ (ឧ. ថ្នាក់ទី១ ក / O5)...',
                      labelStyle: const TextStyle(
                        fontFamily: 'Khmer OS Battambang',
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Builder(
                    builder: (_) {
                      final levelItems = <DropdownMenuItem<int>>[];
                      final seenLevelIds = <int>{};
                      for (final l in _levels) {
                        final id = l['id'] is int
                            ? l['id'] as int
                            : int.tryParse(l['id'].toString());
                        if (id != null && seenLevelIds.add(id)) {
                          levelItems.add(
                            DropdownMenuItem<int>(
                              value: id,
                              child: Text(
                                '${l['name']} (${l['study_type']})',
                                style: const TextStyle(
                                  fontFamily: 'Khmer OS Battambang',
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }
                      }
                      final effectiveLevel =
                          levelItems.any((i) => i.value == selLevel)
                          ? selLevel
                          : (levelItems.isNotEmpty
                                ? levelItems.first.value
                                : null);

                      return DropdownButtonFormField<int>(
                        // ignore: deprecated_member_use
                        initialValue: effectiveLevel,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'ជ្រើសរើសកម្រិតសិក្សា',
                          labelStyle: const TextStyle(
                            fontFamily: 'Khmer OS Battambang',
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                        items: levelItems,
                        onChanged: (v) => setM(() => selLevel = v),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: roomCtrl,
                          decoration: InputDecoration(
                            labelText: 'លេខបន្ទប់',
                            labelStyle: const TextStyle(
                              fontFamily: 'Khmer OS Battambang',
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          // ignore: deprecated_member_use
                          initialValue: shift,
                          decoration: InputDecoration(
                            labelText: 'វេនសិក្សា',
                            labelStyle: const TextStyle(
                              fontFamily: 'Khmer OS Battambang',
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Morning',
                              child: Text(
                                'វេនព្រឹក',
                                style: TextStyle(
                                  fontFamily: 'Khmer OS Battambang',
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Afternoon',
                              child: Text(
                                'វេនរសៀល',
                                style: TextStyle(
                                  fontFamily: 'Khmer OS Battambang',
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Both',
                              child: Text(
                                'ពេញមួយថ្ងៃ',
                                style: TextStyle(
                                  fontFamily: 'Khmer OS Battambang',
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (v) => setM(() => shift = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Dropdown គ្រូទទួលបន្ទុក
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    initialValue: selectedTeacher,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'គ្រូទទួលបន្ទុក (In-charge Teacher)',
                      prefixIcon: const Icon(Icons.person_outline, size: 20, color: Color(0xFF4F46E5)),
                      labelStyle: const TextStyle(
                        fontFamily: 'Khmer OS Battambang',
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    items: _teacherNames.map((t) {
                      return DropdownMenuItem<String>(
                        value: t,
                        child: Text(t, style: const TextStyle(fontFamily: 'Khmer OS Battambang', fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (v) => setM(() => selectedTeacher = v!),
                  ),
                  const SizedBox(height: 18),
                  // Dropdown ឆ្នាំសិក្សា
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    initialValue: academicYear,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'ឆ្នាំសិក្សា (Academic Year)',
                      prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF10B981)),
                      labelStyle: const TextStyle(
                        fontFamily: 'Khmer OS Battambang',
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: '2024-2025', child: Text('ឆ្នាំសិក្សា ២០២៤ - ២០២៥')),
                      DropdownMenuItem(value: '2025-2026', child: Text('ឆ្នាំសិក្សា ២០២៥ - ២០២៦')),
                      DropdownMenuItem(value: '2026-2027', child: Text('ឆ្នាំសិក្សា ២០២៦ - ២០២៧')),
                    ],
                    onChanged: (v) => setM(() => academicYear = v!),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            'បោះបង់',
                            style: TextStyle(
                              fontFamily: 'Khmer OS Battambang',
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            if (nameCtrl.text.isEmpty) return;
                            try {
                              final res = await http.post(
                                Uri.parse('$baseUrl/classrooms'),
                                headers: {'Content-Type': 'application/json'},
                                body: jsonEncode({
                                  'class_name': nameCtrl.text.trim(),
                                  'grade_level_id': selLevel,
                                  'room_number': roomCtrl.text.trim(),
                                  'shift': shift,
                                  'teacher_name': selectedTeacher,
                                  'academic_year': academicYear,
                                }),
                              );
                              final d = jsonDecode(utf8.decode(res.bodyBytes));
                              if ((res.statusCode == 200 || res.statusCode == 201) && d['success'] == true) {
                                if (ctx.mounted) Navigator.pop(ctx);
                                _loadAll();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(d['message'] ?? 'បានបង្កើតបន្ទប់រៀនជោគជ័យ!'),
                                      backgroundColor: const Color(0xFF16A34A),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              } else {
                                final errMsg = d['message'] ?? d['error'] ?? 'បរាជ័យក្នុងការរក្សាទុក!';
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text('កំហុសពី Server: $errMsg'),
                                      backgroundColor: const Color(0xFFDC2626),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'មិនអាចរក្សាទុកថ្នាក់រៀនបានទេ៖ $e',
                                      style: const TextStyle(
                                        fontFamily: 'Khmer OS Battambang',
                                      ),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text(
                            'រក្សាទុក',
                            style: TextStyle(
                              fontFamily: 'Khmer OS Battambang',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _viewClassroomDialog(Map<String, dynamic> c) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.meeting_room_outlined, color: Color(0xFF3B82F6), size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c['class_name']?.toString() ?? 'ថ្នាក់រៀន',
                          style: const TextStyle(
                            fontFamily: 'Khmer OS Muol Light',
                            fontSize: 16,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          'បន្ទប់៖ ${c['room_number'] ?? 'N/A'} | ឆ្នាំសិក្សា៖ ${c['academic_year'] ?? '2025-2026'}',
                          style: const TextStyle(
                            fontFamily: 'Khmer OS Battambang',
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
              const Divider(height: 28),
              _detailRow('កម្រិតថ្នាក់', c['grade_level_name'] ?? c['grade_level'] ?? 'មិនទាន់កំណត់'),
              _detailRow('គ្រូបន្ទុកថ្នាក់', c['teacher_name'] ?? 'មិនទាន់កំណត់'),
              _detailRow('វេនសិក្សា', c['shift'] == 'Morning' ? 'ព្រឹក (Morning)' : (c['shift'] == 'Afternoon' ? 'រសៀល (Afternoon)' : 'យប់ (Evening)')),
              _detailRow('ចំណុះសិស្សអតិបរមា', '${c['capacity'] ?? 30} នាក់'),
              _detailRow('ចំនួនសិស្សជាក់ស្តែង', '${c['students_count'] ?? 0} នាក់'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('យល់ព្រម', style: TextStyle(fontFamily: 'Khmer OS Battambang', fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Khmer OS Battambang', color: Color(0xFF64748B), fontSize: 13)),
          Text(value, style: const TextStyle(fontFamily: 'Khmer OS Battambang', fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 13)),
        ],
      ),
    );
  }

  void _editClassroomDialog(Map<String, dynamic> c) {
    final nameCtrl = TextEditingController(text: c['class_name']?.toString() ?? '');
    final roomCtrl = TextEditingController(text: c['room_number']?.toString() ?? 'Room-01');
    int? selLevel = c['grade_level_id'] is int
        ? c['grade_level_id'] as int
        : int.tryParse(c['grade_level_id']?.toString() ?? '');
    String shift = c['shift']?.toString() ?? 'Morning';
    String selectedTeacher = c['teacher_name']?.toString() ?? _teacherNames.first;
    if (!_teacherNames.contains(selectedTeacher)) {
      _teacherNames.add(selectedTeacher);
    }
    String academicYear = c['academic_year']?.toString() ?? '2025-2026';
    if (!['2024-2025', '2025-2026', '2026-2027'].contains(academicYear)) {
      academicYear = '2025-2026';
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: 440,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.edit_note,
                          color: Color(0xFF3B82F6),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'កែប្រែទិន្នន័យថ្នាក់រៀន',
                        style: TextStyle(
                          fontFamily: 'Khmer OS Muol Light',
                          fontSize: 16,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'ឈ្មោះថ្នាក់',
                      labelStyle: const TextStyle(
                        fontFamily: 'Khmer OS Battambang',
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Builder(
                    builder: (_) {
                      final levelItems = <DropdownMenuItem<int>>[];
                      final seenLevelIds = <int>{};
                      for (final l in _levels) {
                        final id = l['id'] is int ? l['id'] as int : int.tryParse(l['id'].toString());
                        if (id != null && seenLevelIds.add(id)) {
                          levelItems.add(
                            DropdownMenuItem<int>(
                              value: id,
                              child: Text(
                                '${l['name']} (${l['study_type']})',
                                style: const TextStyle(fontFamily: 'Khmer OS Battambang', fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }
                      }
                      final effectiveLevel = levelItems.any((i) => i.value == selLevel)
                          ? selLevel
                          : (levelItems.isNotEmpty ? levelItems.first.value : null);

                      return DropdownButtonFormField<int>(
                        // ignore: deprecated_member_use
                        initialValue: effectiveLevel,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'ជ្រើសរើសកម្រិតសិក្សា',
                          labelStyle: const TextStyle(fontFamily: 'Khmer OS Battambang', fontSize: 13, color: Color(0xFF64748B)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        items: levelItems,
                        onChanged: (v) => setM(() => selLevel = v),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: roomCtrl,
                          decoration: InputDecoration(
                            labelText: 'លេខបន្ទប់',
                            labelStyle: const TextStyle(fontFamily: 'Khmer OS Battambang', fontSize: 13, color: Color(0xFF64748B)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          // ignore: deprecated_member_use
                          initialValue: shift,
                          decoration: InputDecoration(
                            labelText: 'វេនសិក្សា',
                            labelStyle: const TextStyle(fontFamily: 'Khmer OS Battambang', fontSize: 13, color: Color(0xFF64748B)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Morning', child: Text('វេនព្រឹក', style: TextStyle(fontFamily: 'Khmer OS Battambang', fontSize: 13))),
                            DropdownMenuItem(value: 'Afternoon', child: Text('វេនរសៀល', style: TextStyle(fontFamily: 'Khmer OS Battambang', fontSize: 13))),
                            DropdownMenuItem(value: 'Both', child: Text('ពេញមួយថ្ងៃ', style: TextStyle(fontFamily: 'Khmer OS Battambang', fontSize: 13))),
                          ],
                          onChanged: (v) => setM(() => shift = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Dropdown គ្រូទទួលបន្ទុក
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    initialValue: selectedTeacher,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'គ្រូទទួលបន្ទុក (In-charge Teacher)',
                      prefixIcon: const Icon(Icons.person_outline, size: 20, color: Color(0xFF4F46E5)),
                      labelStyle: const TextStyle(fontFamily: 'Khmer OS Battambang', fontSize: 13, color: Color(0xFF64748B)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    items: _teacherNames.map((t) {
                      return DropdownMenuItem<String>(
                        value: t,
                        child: Text(t, style: const TextStyle(fontFamily: 'Khmer OS Battambang', fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (v) => setM(() => selectedTeacher = v!),
                  ),
                  const SizedBox(height: 18),
                  // Dropdown ឆ្នាំសិក្សា
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    initialValue: academicYear,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'ឆ្នាំសិក្សា (Academic Year)',
                      prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF10B981)),
                      labelStyle: const TextStyle(fontFamily: 'Khmer OS Battambang', fontSize: 13, color: Color(0xFF64748B)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: '2024-2025', child: Text('ឆ្នាំសិក្សា ២០២៤ - ២០២៥')),
                      DropdownMenuItem(value: '2025-2026', child: Text('ឆ្នាំសិក្សា ២០២៥ - ២០២៦')),
                      DropdownMenuItem(value: '2026-2027', child: Text('ឆ្នាំសិក្សា ២០២៦ - ២០២៧')),
                    ],
                    onChanged: (v) => setM(() => academicYear = v!),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('បោះបង់', style: TextStyle(fontFamily: 'Khmer OS Battambang', fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            if (nameCtrl.text.isEmpty) return;
                            try {
                              final res = await http.put(
                                Uri.parse('$baseUrl/classrooms/${c['id']}'),
                                headers: {'Content-Type': 'application/json'},
                                body: jsonEncode({
                                  'class_name': nameCtrl.text.trim(),
                                  'grade_level_id': selLevel,
                                  'room_number': roomCtrl.text.trim(),
                                  'shift': shift,
                                  'capacity': c['capacity'] ?? 30,
                                  'teacher_name': selectedTeacher,
                                  'academic_year': academicYear,
                                }),
                              );
                              final d = jsonDecode(utf8.decode(res.bodyBytes));
                              if ((res.statusCode == 200 || res.statusCode == 201) && d['success'] == true) {
                                if (ctx.mounted) Navigator.pop(ctx);
                                _loadAll();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(d['message'] ?? 'បានកែប្រែបន្ទប់រៀនជោគជ័យ!'),
                                      backgroundColor: const Color(0xFF16A34A),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              } else {
                                final errMsg = d['message'] ?? d['error'] ?? 'បរាជ័យក្នុងការរក្សាទុក!';
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text('កំហុសពី Server: $errMsg'),
                                      backgroundColor: const Color(0xFFDC2626),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text('មិនអាចកែប្រែថ្នាក់រៀនបានទេ៖ $e', style: const TextStyle(fontFamily: 'Khmer OS Battambang')),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text('រក្សាទុកការកែប្រែ', style: TextStyle(fontFamily: 'Khmer OS Battambang', fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  void _editGradeLevelDialog(Map<String, dynamic> level) {
    final nameCtrl = TextEditingController(text: level['name'] ?? '');
    String type = level['study_type'] ?? 'Full-Time';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.edit_note,
                        color: Color(0xFF4F46E5),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'កែប្រែកម្រិតសិក្សា',
                      style: TextStyle(
                        fontFamily: 'Khmer OS Muol Light',
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'ឈ្មោះកម្រិតសិក្សា *',
                    labelStyle: const TextStyle(
                      fontFamily: 'Khmer OS Battambang',
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: type,
                  decoration: InputDecoration(
                    labelText: 'ប្រភេទកម្មវិធីសិក្សា',
                    labelStyle: const TextStyle(
                      fontFamily: 'Khmer OS Battambang',
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Full-Time',
                      child: Text(
                        'សម្រាប់សិស្សពេញម៉ោង (Full-Time)',
                        style: TextStyle(
                          fontFamily: 'Khmer OS Battambang',
                          fontSize: 13,
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Part-Time',
                      child: Text(
                        'សម្រាប់សិស្សក្រៅម៉ោង (Part-Time)',
                        style: TextStyle(
                          fontFamily: 'Khmer OS Battambang',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) => setM(() => type = v!),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          'បោះបង់',
                          style: TextStyle(
                            fontFamily: 'Khmer OS Battambang',
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          if (nameCtrl.text.isEmpty) return;
                          await http.put(
                            Uri.parse('$baseUrl/grade-levels/${level['id']}'),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({
                              'name': nameCtrl.text.trim(),
                              'study_type': type,
                            }),
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          _loadAll();
                        },
                        child: const Text(
                          'រក្សាទុក',
                          // ignore: deprecated_member_use
                          style: TextStyle(
                            fontFamily: 'Khmer OS Battambang',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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

  Future<void> _deleteLevel(int id, String name) async {
    final ok = await _confirmDelete(name);
    if (ok == true) {
      try {
        final res = await http.delete(
          Uri.parse('$baseUrl/grade-levels/$id'),
          headers: {'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 30));
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        if (res.statusCode == 200 && data['success'] == true) {
          _loadAll();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'លុបកម្រិតថ្នាក់បានជោគជ័យ!'),
                backgroundColor: const Color(0xFF10B981),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? data['error'] ?? 'បរាជ័យក្នុងការលុប'),
                backgroundColor: const Color(0xFFEF4444),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('កំហុសបណ្តាញ: $e'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteClass(int id, String name) async {
    final ok = await _confirmDelete(name);
    if (ok == true) {
      try {
        final res = await http.delete(
          Uri.parse('$baseUrl/classrooms/$id'),
          headers: {'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 30));
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        if (res.statusCode == 200 && data['success'] == true) {
          _loadAll();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'លុបបន្ទប់រៀនបានជោគជ័យ!'),
                backgroundColor: const Color(0xFF10B981),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? data['error'] ?? 'បរាជ័យក្នុងការលុបបន្ទប់រៀន'),
                backgroundColor: const Color(0xFFEF4444),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('កំហុសបណ្តាញ: $e'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    }
  }

  Future<bool?> _confirmDelete(String name) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text(
              'បញ្ជាក់ការលុប',
              style: TextStyle(
                fontFamily: 'Khmer OS Battambang',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'តើអ្នកពិតជាចង់លុប "$name" មែនទេ?\nសកម្មភាពនេះមិនអាចត្រឡប់វិញបានទេ។',
          style: const TextStyle(
            fontFamily: 'Khmer OS Battambang',
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'បោះបង់',
              style: TextStyle(
                fontFamily: 'Khmer OS Battambang',
                color: Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'លុបចេញ',
              style: TextStyle(
                fontFamily: 'Khmer OS Battambang',
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
      backgroundColor: const Color(0xFFF1F5F9),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.domain,
                          color: Color(0xFF10B981),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'គ្រប់គ្រងថ្នាក់រៀន និងកម្រិតសិក្សា',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Khmer OS Muol Light',
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'រៀបចំកម្រិតថ្នាក់ចំណេះទូទៅ វគ្គខ្លី និងបន្ទប់រៀន',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                              fontFamily: 'Khmer OS Battambang',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1E293B),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        icon: const Icon(Icons.download_rounded, size: 20),
                        label: const Text(
                          'ទាញយក CSV',
                          style: TextStyle(
                            fontFamily: 'Khmer OS Battambang',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: _exportCSV,
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text(
                          'បន្ថែមទីធ្លា/ថ្នាក់',
                          style: TextStyle(
                            fontFamily: 'Khmer OS Battambang',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: _addClassroomDialog,
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.layers_rounded, size: 20),
                        label: const Text(
                          'បន្ថែមកម្រិតសិក្សា',
                          style: TextStyle(
                            fontFamily: 'Khmer OS Battambang',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: _addGradeLevelDialog,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Custom TabBar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF4F46E5),
                indicatorWeight: 3,
                labelColor: const Color(0xFF4F46E5),
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(
                  fontFamily: 'Khmer OS Battambang',
                  fontWeight: FontWeight.bold,
                ),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.meeting_room_outlined, size: 18),
                    text: 'បញ្ជីថ្នាក់រៀន (Classrooms)',
                  ),
                  Tab(
                    icon: Icon(Icons.layers_outlined, size: 18),
                    text: 'កម្រិតសិក្សា (Grade Levels)',
                  ),
                  Tab(
                    icon: Icon(Icons.table_chart_outlined, size: 18),
                    text: 'តារាងរៀបចំថ្នាក់រៀន (Class Arrangement)',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Tab Views
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF10B981),
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildClassroomsTab(),
                        _buildLevelsTab(),
                        _buildArrangementTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelsTab() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(
              color: const Color(0xFFF8FAFC),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  _headerCol('ID', 1),
                  _headerCol('ឈ្មោះកម្រិតសិក្សា', 3),
                  _headerCol('ប្រភេទសិក្សា', 2),
                  _headerCol('ចំនួនថ្នាក់ចំណុះ', 2),
                  _headerCol('សកម្មភាព', 1, align: TextAlign.right),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Expanded(
              child: _levels.isEmpty
                  ? const Center(
                      child: Text(
                        'មិនទាន់មានកម្រិតសិក្សាទេ',
                        style: TextStyle(
                          fontFamily: 'Khmer OS Battambang',
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _levels.length,
                      // ignore: unnecessary_underscores
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (ctx, i) {
                        final l = _levels[i];
                        final typeColor = l['study_type'] == 'Full-Time'
                            ? const Color(0xFF4F46E5)
                            : const Color(0xFFF59E0B);
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Text(
                                  '#${l['id']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  l['name'],
                                  style: const TextStyle(
                                    fontFamily: 'Khmer OS Battambang',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        // ignore: deprecated_member_use
                                        color: typeColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${l['study_type']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: typeColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${l['class_count'] ?? 0} ថ្នាក់',
                                  style: const TextStyle(
                                    fontFamily: 'Khmer OS Battambang',
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    _actionBtn(
                                      Icons.delete_outline_rounded,
                                      const Color(0xFFEF4444),
                                      () => _deleteLevel(l['id'], l['name']),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassroomsTab() {
    final filteredClasses = _classes.where((c) {
      if (_selectedAcademicYear == 'ទាំងអស់ (All Years)') return true;
      final year = c['academic_year']?.toString();
      return year == null || year.isEmpty || year == _selectedAcademicYear;
    }).toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Filter Bar for Academic Year
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt_outlined, size: 18, color: Color(0xFF4F46E5)),
                  const SizedBox(width: 8),
                  const Text(
                    'ជ្រើសរើសឆ្នាំសិក្សា៖ ',
                    style: TextStyle(
                      fontFamily: 'Khmer OS Battambang',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedAcademicYear,
                        isDense: true,
                        style: const TextStyle(
                          fontFamily: 'Khmer OS Battambang',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                        items: _academicYears
                            .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _selectedAcademicYear = v);
                          }
                        },
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'សរុប៖ ${filteredClasses.length} ថ្នាក់',
                    style: const TextStyle(
                      fontFamily: 'Khmer OS Battambang',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: const Color(0xFFF8FAFC),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  _headerCol('ថ្នាក់រៀន', 2),
                  _headerCol('កម្រិតសិក្សា', 2),
                  _headerCol('វេន/លេខបន្ទប់', 2),
                  _headerCol('គ្រូទទួលបន្ទុក', 2),
                  _headerCol('ឆ្នាំសិក្សា', 2),
                  _headerCol('ចំនួនសិស្ស', 1),
                  _headerCol('សកម្មភាព', 1, align: TextAlign.right),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Expanded(
              child: filteredClasses.isEmpty
                  ? const Center(
                      child: Text(
                        'មិនទាន់មានថ្នាក់រៀនសម្រាប់ឆ្នាំសិក្សានេះទេ',
                        style: TextStyle(
                          fontFamily: 'Khmer OS Battambang',
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filteredClasses.length,
                      // ignore: unnecessary_underscores
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (ctx, i) {
                        final c = filteredClasses[i];
                        final teacherName = (c['teacher_name'] ?? '').toString().trim();
                        final academicYear = (c['academic_year'] ?? '2025-2026').toString().trim();
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.meeting_room_outlined,
                                        color: Color(0xFF3B82F6),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        c['class_name'] ?? '',
                                        style: const TextStyle(
                                          fontFamily: 'Khmer OS Battambang',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Color(0xFF1E293B),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  c['grade_level'] ?? 'N/A',
                                  style: const TextStyle(
                                    fontFamily: 'Khmer OS Battambang',
                                    color: Color(0xFF475569),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'បន្ទប់៖ ${c['room_number'] ?? 'N/A'}',
                                      style: const TextStyle(
                                        fontFamily: 'Khmer OS Battambang',
                                        color: Color(0xFF1E293B),
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      'វេន៖ ${c['shift'] ?? 'Morning'}',
                                      style: const TextStyle(
                                        fontFamily: 'Khmer OS Battambang',
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: const Color(0xFFEEF2FF),
                                      child: Text(
                                        teacherName.isNotEmpty
                                            ? teacherName.characters.first
                                            : 'T',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF4F46E5),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        teacherName.isNotEmpty
                                            ? teacherName
                                            : 'មិនទាន់ចាត់តាំង',
                                        style: TextStyle(
                                          fontFamily: 'Khmer OS Battambang',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: teacherName.isNotEmpty
                                              ? const Color(0xFF1E293B)
                                              : const Color(0xFF94A3B8),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    child: Text(
                                      academicYear.isNotEmpty
                                          ? academicYear
                                          : '2025-2026',
                                      style: const TextStyle(
                                        fontFamily: 'Khmer OS Battambang',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.people,
                                        size: 14,
                                        color: Color(0xFF10B981),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${c['students_count'] ?? 0}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    _actionBtn(
                                      Icons.visibility_outlined,
                                      const Color(0xFF4F46E5),
                                      () => _viewClassroomDialog(c),
                                    ),
                                    const SizedBox(width: 6),
                                    _actionBtn(
                                      Icons.edit_outlined,
                                      const Color(0xFF3B82F6),
                                      () => _editClassroomDialog(c),
                                    ),
                                    const SizedBox(width: 6),
                                    _actionBtn(
                                      Icons.delete_outline_rounded,
                                      const Color(0xFFEF4444),
                                      () => _deleteClass(
                                        c['id'],
                                        c['class_name'],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCol(
    String label,
    int flex, {
    TextAlign align = TextAlign.left,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: align,
        style: const TextStyle(
          fontFamily: 'Khmer OS Battambang',
          fontWeight: FontWeight.bold,
          color: Color(0xFF475569),
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _buildArrangementTab() {
    final store = AppDataStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (ctx, _) {
        const oldStudentsTotal = 88;
        const newStudentsMerged = 97;
        const newStudentsSeparate = 109;
        final activeNewTotal =
            _countMergedRooms ? newStudentsMerged : newStudentsSeparate;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top Toolbar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.verified,
                                  size: 16, color: Color(0xFF2563EB)),
                              SizedBox(width: 6),
                              Text(
                                'ឯកសាររៀបចំថ្នាក់ផ្លូវការ (Official Arrangement Doc)',
                                style: TextStyle(
                                  fontFamily: 'Khmer OS Battambang',
                                  color: Color(0xFF1D4ED8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFD97706),
                            side: const BorderSide(color: Color(0xFFFBBF24)),
                          ),
                          icon: Icon(
                            _showInsights
                                ? Icons.visibility_off_outlined
                                : Icons.lightbulb_outline,
                            size: 16,
                          ),
                          label: Text(
                            _showInsights
                                ? 'លាក់ផ្ទាំងវិភាគ'
                                : 'បង្ហាញការវិភាគ (Insights)',
                            style: const TextStyle(
                                fontFamily: 'Khmer OS Battambang',
                                fontSize: 12),
                          ),
                          onPressed: () =>
                              setState(() => _showInsights = !_showInsights),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text(
                            'បន្ថែមជួរថ្មី',
                            style: TextStyle(
                                fontFamily: 'Khmer OS Battambang',
                                fontSize: 12),
                          ),
                          onPressed: () => _openAddArrangementRowModal(),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                          ),
                          icon: const Icon(Icons.print,
                              color: Colors.white, size: 16),
                          label: const Text(
                            'បោះពុម្ពឯកសារ (Print Sheet)',
                            style: TextStyle(
                              fontFamily: 'Khmer OS Battambang',
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'កំពុងបញ្ជូនឯកសារ English Class Arrangement ទៅកាន់ម៉ាស៊ីនបោះពុម្ព...'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),

                // KEY INSIGHTS & ANOMALIES
                if (_showInsights) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFFDE68A), width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    color: Color(0xFFD97706), size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'ចំណុចសំខាន់ៗ និងភាពមិនប្រក្រតីដែលគួរកត់សម្គាល់ (Key Insights & Anomalies)',
                                  style: TextStyle(
                                    fontFamily: 'Khmer OS Battambang',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: const Color(0xFFFCD34D)),
                              ),
                              child: Row(
                                children: [
                                  const Text(
                                    'រាប់ជាថ្នាក់ប្តូរវេន (Handover): ',
                                    style: TextStyle(
                                      fontFamily: 'Khmer OS Battambang',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF78350F),
                                    ),
                                  ),
                                  Switch(
                                    value: _countMergedRooms,
                                    activeThumbColor: const Color(0xFFD97706),
                                    onChanged: (v) =>
                                        setState(() => _countMergedRooms = v),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.meeting_room,
                                      size: 16, color: Color(0xFFDC2626)),
                                  SizedBox(width: 6),
                                  Text(
                                    '១. ការជាន់គ្នានៃបន្ទប់រៀន និងកម្រិតសិក្សា (ជួរទី ៣ និងទី ៧)៖',
                                    style: TextStyle(
                                      fontFamily: 'Khmer OS Battambang',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                '• គ្រូឈ្មោះ Ry Sreyneang (ល.រ ទី ៣) និងគ្រូឈ្មោះ Pen Rina (ល.រ ទី ៧) ត្រូវបានដាក់ឱ្យបង្រៀនកម្រិត EFL3B នៅ បន្ទប់ 01 និងមានចំនួនសិស្ស ១២ នាក់ ដូចគ្នាបេះបិទ។',
                                style: TextStyle(
                                  fontFamily: 'Khmer OS Battambang',
                                  fontSize: 12,
                                  height: 1.4,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                '• ការសន្និដ្ឋាន & ដោះស្រាយ៖ នេះជាការប្តូរវេនគ្រូបង្រៀន (ពី Ry Sreyneang មក Pen Rina ទើបមានសញ្ញាធីក ✓ នៅជួរទី ៧) ឬជាការបង្រៀនឆ្លាស់ថ្ងៃគ្នា (ចន្ទ-ពុធ-សុក្រ និង អង្គារ-ព្រហស្បតិ៍) ដើម្បីកុំឱ្យជាន់បន្ទប់ 01។',
                                style: TextStyle(
                                  fontFamily: 'Khmer OS Battambang',
                                  fontSize: 12,
                                  height: 1.4,
                                  color: Color(0xFF0F766E),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.merge_type,
                                      size: 16, color: Color(0xFF2563EB)),
                                  SizedBox(width: 6),
                                  Text(
                                    '២. ការបង្រួមថ្នាក់រៀន (Class Merging)៖',
                                    style: TextStyle(
                                      fontFamily: 'Khmer OS Battambang',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Color(0xFF1D4ED8),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                '• គ្រូ Phi Sreynuch៖ កាលពីវគ្គចាស់គាត់បង្រៀន ២ ថ្នាក់ផ្សេងគ្នា (EFL 3A និង EFL 5B) ប៉ុន្តែវគ្គថ្មីនេះត្រូវបានបង្រួមឱ្យបង្រៀនតែ ១ ថ្នាក់គត់គឺ EFL 5A ដែលមានសិស្សសរុប ២០ នាក់ (កើនពី ១៦ នាក់)។',
                                style: TextStyle(
                                  fontFamily: 'Khmer OS Battambang',
                                  fontSize: 12,
                                  height: 1.4,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                '• គ្រូ Sophann May៖ ចំនួនសិស្សកើនឡើងទ្វេដងពី ១០ នាក់ ដល់ ២២ នាក់ (ច្រើនជាងគេក្នុងតារាង) ដោយសារមានការបូកបញ្ចូលសិស្សពីថ្នាក់របស់គ្រូ Tous Sreymom ("Added Mom\'s class")។',
                                style: TextStyle(
                                  fontFamily: 'Khmer OS Battambang',
                                  fontSize: 12,
                                  height: 1.4,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // KPI Stat Cards
                Row(
                  children: [
                    _buildKpiCard('សិស្សវគ្គចាស់ (Old Term)',
                        '$oldStudentsTotal នាក់', Icons.history,
                        const Color(0xFF64748B)),
                    _buildKpiCard(
                      _countMergedRooms
                          ? 'សិស្សវគ្គថ្មី (Handover Mode)'
                          : 'សិស្សវគ្គថ្មី (Separate Mode)',
                      '$activeNewTotal នាក់',
                      Icons.groups,
                      const Color(0xFF2563EB),
                      subtitle: _countMergedRooms
                          ? 'កើនឡើង ៩ នាក់ (+10.2%)'
                          : 'កើនឡើង ២១ នាក់ (+23.8%)',
                    ),
                    _buildKpiCard(
                        'បន្ទប់រៀនសរុប (Rooms)',
                        '៦ បន្ទប់ (O1 - O6)',
                        Icons.meeting_room,
                        const Color(0xFFD97706)),
                    _buildKpiCard(
                        'គ្រូបង្រៀនទទួលបន្ទុក',
                        '${store.classArrangements.length} រូប',
                        Icons.badge,
                        const Color(0xFF0D9488)),
                  ],
                ),
                const SizedBox(height: 24),

                // Document Header (Matching the Paper Photo)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF1E3A8A)
                                .withValues(alpha: 0.08),
                            border: Border.all(
                                color: const Color(0xFF1E3A8A), width: 1.5),
                          ),
                          child: const Center(
                            child: Icon(Icons.school,
                                color: Color(0xFF1E3A8A), size: 32),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Bright Light School',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Color(0xFF0F172A)),
                        ),
                        const Text(
                          'Ochrov Campus',
                          style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    const Expanded(
                      child: Column(
                        children: [
                          Text(
                            'English Class Arrangement Term 3 Year 4',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                              letterSpacing: 0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 4),
                          Text(
                            '(ការរៀបចំថ្នាក់ភាសាអង់គ្លេស ត្រីមាសទី ៣ ឆ្នាំទី ៤)',
                            style: TextStyle(
                              fontFamily: 'Khmer OS Muol Light',
                              fontSize: 14,
                              color: Color(0xFF1E3A8A),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Evening Classes (ថ្នាក់ពេលល្ងាច)',
                            style: TextStyle(
                              fontFamily: 'Khmer OS Battambang',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 78),
                  ],
                ),
                const SizedBox(height: 20),

                // Table
                Table(
                  border: TableBorder.all(
                    color: const Color(0xFF0F172A),
                    width: 1.0,
                  ),
                  columnWidths: const {
                    0: FixedColumnWidth(46),
                    1: FlexColumnWidth(1.6),
                    2: FlexColumnWidth(1.8),
                    3: FixedColumnWidth(90),
                    4: FlexColumnWidth(1.6),
                    5: FixedColumnWidth(70),
                    6: FixedColumnWidth(90),
                    7: FlexColumnWidth(1.8),
                    8: FixedColumnWidth(64),
                  },
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(color: Color(0xFFF1F5F9)),
                      children: [
                        _ArrangementTableHeaderCell('Nº'),
                        _ArrangementTableHeaderCell("Teacher's name"),
                        _ArrangementTableHeaderCell('Old term level'),
                        _ArrangementTableHeaderCell('Students amount'),
                        _ArrangementTableHeaderCell('New term level'),
                        _ArrangementTableHeaderCell('Room'),
                        _ArrangementTableHeaderCell('Students amount'),
                        _ArrangementTableHeaderCell('Others'),
                        _ArrangementTableHeaderCell('សកម្មភាព'),
                      ],
                    ),
                    ...store.classArrangements.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      final isOthersHighlighted =
                          item.others.contains("Mom's");
                      final isRoomConflict = item.room == 'O1';

                      return TableRow(
                        decoration: isRoomConflict
                            ? BoxDecoration(
                                color: const Color(0xFFFEF2F2)
                                    .withValues(alpha: 0.5))
                            : null,
                        children: [
                          _ArrangementTableCell('${item.no}', isCenter: true),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.teacherName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                                if (item.no == 3)
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      '⚠️ ជាន់បន្ទប់ O1 ជាមួយ ល.រ 7',
                                      style: TextStyle(
                                        fontFamily: 'Khmer OS Battambang',
                                        fontSize: 9,
                                        color: Color(0xFFB45309),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                if (item.no == 7)
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      '✓ ប្តូរវេនពី Ry Sreyneang',
                                      style: TextStyle(
                                        fontFamily: 'Khmer OS Battambang',
                                        fontSize: 9,
                                        color: Color(0xFF15803D),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.oldTermLevel,
                                    style: const TextStyle(fontSize: 12.5)),
                                if (item.no == 2)
                                  const Text(
                                    '🔗 បង្រួមពី ២ ថ្នាក់ (16នាក់)',
                                    style: TextStyle(
                                      fontFamily: 'Khmer OS Battambang',
                                      fontSize: 9.5,
                                      color: Color(0xFF2563EB),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          _ArrangementTableCell(item.oldStudentsCount,
                              isCenter: true),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 10),
                            color:
                                const Color(0xFFDCFCE7).withValues(alpha: 0.6),
                            child: Text(
                              item.newTermLevel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Color(0xFF065F46),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 10),
                            color: isRoomConflict
                                ? const Color(0xFFFCA5A5)
                                    .withValues(alpha: 0.5)
                                : const Color(0xFFFED7AA)
                                    .withValues(alpha: 0.6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item.room,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isRoomConflict
                                        ? const Color(0xFF991B1B)
                                        : const Color(0xFF9A3412),
                                  ),
                                ),
                                if (isRoomConflict) ...[
                                  const SizedBox(width: 2),
                                  const Icon(Icons.error_outline,
                                      size: 12, color: Color(0xFFDC2626)),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 10),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item.newStudentsCount,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                                if (item.no == 7) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.check,
                                      size: 14, color: Color(0xFF16A34A)),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 10),
                            color: isOthersHighlighted
                                ? const Color(0xFFFEF08A)
                                : Colors.transparent,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item.others,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isOthersHighlighted
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isOthersHighlighted
                                        ? const Color(0xFF854D0E)
                                        : const Color(0xFF334155),
                                  ),
                                ),
                                if (item.no == 4)
                                  const Text(
                                    '👥 ២២ នាក់ (ច្រើនជាងគេ)',
                                    style: TextStyle(
                                      fontFamily: 'Khmer OS Battambang',
                                      fontSize: 9,
                                      color: Color(0xFF1D4ED8),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                InkWell(
                                  onTap: () =>
                                      _openAddArrangementRowModal(item, idx),
                                  child: const Icon(Icons.edit,
                                      size: 16, color: Color(0xFF2563EB)),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () =>
                                      store.deleteClassArrangement(idx),
                                  child: const Icon(Icons.delete_outline,
                                      size: 16, color: Color(0xFFDC2626)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 36),

                // Signature & Approval
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 320,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Date: ${store.classArrangementApprovedDate}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Seen and Approved (អ្នកពិនិត្យ និងអនុម័ត):',
                            style: TextStyle(
                              fontFamily: 'Khmer OS Battambang',
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (store.isClassArrangementApproved)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: const Color(0xFF86EFAC)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified,
                                      color: Color(0xFF16A34A), size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    '[ បានអនុម័ត & ចុះហត្ថលេខារួច ]',
                                    style: TextStyle(
                                      fontFamily: 'Khmer OS Battambang',
                                      color: Color(0xFF16A34A),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.check_circle_outline,
                                  size: 16),
                              label: const Text(
                                'ចុចអនុម័ត និងចុះហត្ថលេខា',
                                style: TextStyle(
                                    fontFamily: 'Khmer OS Battambang',
                                    fontSize: 12),
                              ),
                              onPressed: () =>
                                  store.toggleArrangementApproval(),
                            ),
                          const SizedBox(height: 16),
                          Container(
                            height: 1,
                            width: 180,
                            color: const Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            store.classArrangementApprovedBy,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 320,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Date: ${store.classArrangementPreparedDate}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Prepare by (អ្នករៀបចំ):',
                            style: TextStyle(
                              fontFamily: 'Khmer OS Battambang',
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.draw,
                                    color: Color(0xFF2563EB), size: 18),
                                SizedBox(width: 8),
                                Text(
                                  '✍️ Ven Leapheng (ហត្ថលេខាមានស្រាប់)',
                                  style: TextStyle(
                                    fontFamily: 'Khmer OS Battambang',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 1,
                            width: 180,
                            color: const Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            store.classArrangementPreparedBy,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openAddArrangementRowModal(
      [ClassArrangementRow? existingRow, int? editIndex]) {
    final store = AppDataStore.instance;
    final teacherCtrl =
        TextEditingController(text: existingRow?.teacherName ?? '');
    final oldLevelCtrl =
        TextEditingController(text: existingRow?.oldTermLevel ?? '');
    final oldStudentsCtrl =
        TextEditingController(text: existingRow?.oldStudentsCount ?? '');
    final newLevelCtrl =
        TextEditingController(text: existingRow?.newTermLevel ?? '');
    final roomCtrl =
        TextEditingController(text: existingRow?.room ?? 'O1');
    final newStudentsCtrl =
        TextEditingController(text: existingRow?.newStudentsCount ?? '');
    final othersCtrl =
        TextEditingController(text: existingRow?.others ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          editIndex == null
              ? 'បន្ថែមជួររៀបចំថ្នាក់រៀនថ្មី'
              : 'កែប្រែទិន្នន័យរៀបចំថ្នាក់រៀន',
          style:
              const TextStyle(fontFamily: 'Khmer OS Muol Light', fontSize: 16),
        ),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: teacherCtrl,
                  decoration: const InputDecoration(
                    labelText: "Teacher's name (ឈ្មោះគ្រូបង្រៀន)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: oldLevelCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Old term level',
                            border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: oldStudentsCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Old Students',
                            border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: newLevelCtrl,
                        decoration: const InputDecoration(
                            labelText: 'New term level',
                            border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: roomCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Room (ឧ. O1-O6)',
                            border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: newStudentsCtrl,
                        decoration: const InputDecoration(
                            labelText: 'New Students',
                            border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: othersCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Others (ផ្សេងៗ)',
                            border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('បោះបង់',
                style: TextStyle(fontFamily: 'Khmer OS Battambang')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A)),
            onPressed: () {
              if (teacherCtrl.text.isNotEmpty && newLevelCtrl.text.isNotEmpty) {
                final row = ClassArrangementRow(
                  no: editIndex != null
                      ? existingRow!.no
                      : store.classArrangements.length + 1,
                  teacherName: teacherCtrl.text,
                  oldTermLevel:
                      oldLevelCtrl.text.isEmpty ? '-' : oldLevelCtrl.text,
                  oldStudentsCount:
                      oldStudentsCtrl.text.isEmpty ? '-' : oldStudentsCtrl.text,
                  newTermLevel: newLevelCtrl.text,
                  room: roomCtrl.text,
                  newStudentsCount: newStudentsCtrl.text,
                  others: othersCtrl.text,
                );

                if (editIndex == null) {
                  store.addClassArrangement(row);
                } else {
                  store.updateClassArrangement(editIndex, row);
                }
                Navigator.pop(ctx);
              }
            },
            child: const Text('រក្សាទុក',
                style: TextStyle(
                    color: Colors.white, fontFamily: 'Khmer OS Battambang')),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color,
      {String? subtitle}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Khmer OS Battambang',
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontFamily: 'Khmer OS Battambang',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Khmer OS Battambang',
                        fontSize: 10,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArrangementTableHeaderCell extends StatelessWidget {
  final String title;
  const _ArrangementTableHeaderCell(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: Color(0xFF0F172A),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ArrangementTableCell extends StatelessWidget {
  final String text;
  final bool isCenter;

  const _ArrangementTableCell(this.text, {this.isCenter = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        text,
        textAlign: isCenter ? TextAlign.center : TextAlign.start,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }
}
