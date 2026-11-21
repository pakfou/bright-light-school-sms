import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:school_management_app/services/api_service.dart';
import 'package:school_management_app/utils/app_theme.dart';
import 'package:school_management_app/utils/csv_exporter.dart';

class WeeklyScheduleView extends StatefulWidget {
  const WeeklyScheduleView({super.key});

  @override
  State<WeeklyScheduleView> createState() => _WeeklyScheduleViewState();
}

class _WeeklyScheduleViewState extends State<WeeklyScheduleView> {
  static String get baseUrl => ApiService.baseUrl;

  // Day configuration
  String _selectedDay = 'Mon';
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  final Map<String, String> _dayLabels = {
    'Mon': 'ច័ន្ទ (Mon)',
    'Tue': 'អង្គារ (Tue)',
    'Wed': 'ពុធ (Wed)',
    'Thu': 'ព្រហស្បតិ៍ (Thu)',
    'Fri': 'សុក្រ (Fri)',
    'Sat': 'សៅរ៍ (Sat)',
  };

  // Main Tab Navigation: 0 = Class Schedules, 1 = Duty Roster
  int _selectedMainTab = 0;

  // Filters
  int? _filterClassroomId;
  // ignore: unused_field
  int? _filterTeacherId;
  String _filterShift = 'All';
  final TextEditingController _searchCtrl = TextEditingController();
  String _dutyFilter = 'All'; // All, Pending, Completed

  // Data collections
  List<dynamic> _classrooms = [];
  List<dynamic> _teachers = [];
  List<dynamic> _schedules = [];
  bool _isLoading = true;
  // ignore: unused_field
  bool _isSaving = false;

  // Form Fields (For Modal Schedule Dialog)
  int? _selectedClassroomId;
  int? _selectedTeacherId;
  String _selectedDayOfWeek = 'Mon';
  final TextEditingController _subjectCtrl = TextEditingController();
  final TextEditingController _startTimeCtrl = TextEditingController(
    text: '08:00',
  );
  final TextEditingController _endTimeCtrl = TextEditingController(
    text: '09:30',
  );
  String _selectedShift = 'Morning';

  // Duty Roster Checklist
  final List<Map<String, dynamic>> _dutyRoster = [
    {
      'title': 'សម្រួលសណ្តាប់ធ្នាប់សិស្សពេលព្រឹក (Gate Duty)',
      'location': 'ច្រកទ្វារធំសាលា',
      'teacher': 'លោកគ្រូ សុខ ចាន់',
      'time': '06:45 - 07:15 AM',
      'completed': true,
    },
    {
      'title': 'ត្រួតពិនិត្យអនាម័យ និងទីធ្លាសាលា (Campus Hygiene)',
      'location': 'បរិវេណតារាងបាល់ & អាហារដ្ឋាន',
      'teacher': 'អ្នកគ្រូ លី ណារី',
      'time': '09:30 - 10:00 AM',
      'completed': false,
    },
    {
      'title': 'សម្រួលចរាចរណ៍សិស្សចេញពីរៀន (Dismissal Supervision)',
      'location': 'ច្រកចេញ & ចំណតយានយន្ត',
      'teacher': 'លោកគ្រូ អ៊ុំ វណ្ណៈ',
      'time': '11:00 - 11:30 AM',
      'completed': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _subjectCtrl.dispose();
    _startTimeCtrl.dispose();
    _endTimeCtrl.dispose();
    super.dispose();
  }

  void _exportCSV() {
    final buf = StringBuffer();
    if (_selectedMainTab == 0) {
      buf.writeln(
        '\uFEFFថ្ងៃសិក្សា,ម៉ោងចាប់ផ្ដើម,ម៉ោងបញ្ចប់,មុខវិជ្ជា,ថ្នាក់រៀន,គ្រូបង្រៀន,វេន',
      );
      for (var s in _schedules) {
        final dayKh = _dayLabels[s['day_of_week']] ?? (s['day_of_week'] ?? '');
        buf.writeln(
          '"$dayKh","${s['start_time'] ?? ''}","${s['end_time'] ?? ''}","${s['subject_name'] ?? ''}","${s['class_name'] ?? ''}","${s['teacher_name'] ?? ''}","${s['shift'] ?? ''}"',
        );
      }
      downloadCsv(
        buf.toString(),
        'weekly_schedules_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
    } else {
      buf.writeln(
        '\uFEFFល.រ,ឈ្មោះភារកិច្ច,ទីតាំង,ពេលវេលា,គ្រូទទួលបន្ទុក,ស្ថានភាព',
      );
      for (int i = 0; i < _dutyRoster.length; i++) {
        final d = _dutyRoster[i];
        final status = d['completed'] == true ? 'រួចរាល់' : 'កំពុងរង់ចាំ';
        buf.writeln(
          '${i + 1},"${d['title']}","${d['location']}","${d['time']}","${d['teacher']}","$status"',
        );
      }
      downloadCsv(
        buf.toString(),
        'duty_roster_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
    }

    _showSnackbar('បានទាញយកទិន្នន័យជា CSV ដោយជោគជ័យ!', const Color(0xFF10B981));
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        http.get(Uri.parse('$baseUrl/classrooms')),
        http.get(Uri.parse('$baseUrl/teachers')),
        http.get(Uri.parse('$baseUrl/schedules')),
      ]);
      final cRes = results[0];
      final tRes = results[1];
      final sRes = results[2];

      if (mounted) {
        setState(() {
          if (cRes.statusCode == 200) {
            _classrooms = jsonDecode(utf8.decode(cRes.bodyBytes))['data'] ?? [];
            if (_classrooms.isNotEmpty && _selectedClassroomId == null) {
              _selectedClassroomId = _classrooms[0]['id'];
            }
          }
          if (tRes.statusCode == 200) {
            _teachers = jsonDecode(utf8.decode(tRes.bodyBytes))['data'] ?? [];
            if (_teachers.isNotEmpty && _selectedTeacherId == null) {
              _selectedTeacherId = _teachers[0]['id'];
            }
          }
          if (sRes.statusCode == 200) {
            _schedules = jsonDecode(utf8.decode(sRes.bodyBytes))['data'] ?? [];
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
    if ((_classrooms.isEmpty || _teachers.isEmpty) && mounted) {
      setState(() {
        if (_classrooms.isEmpty) {
          _classrooms = [
            {'id': 1, 'class_name': 'ថ្នាក់ទី ១A'},
            {'id': 2, 'class_name': 'ថ្នាក់ទី ២A'},
            {'id': 23, 'class_name': '01 (EFL 3B)'},
            {'id': 24, 'class_name': '02 (EFL 5A)'},
            {'id': 25, 'class_name': '05 (Going Place 3)'},
          ];
          _selectedClassroomId = 1;
        }
        if (_teachers.isEmpty) {
          _teachers = [
            {'id': 1, 'name_kh': 'ហាក់ ប៉ាក់ហ៊្វូរ'},
            {'id': 2, 'name_kh': 'សន ចរិយា'},
            {'id': 3, 'name_kh': 'ទូច ស្រីមុំ'},
            {'id': 4, 'name_kh': 'ភី ស្រីនុច'},
            {'id': 5, 'name_kh': 'រី ស្រីនាង'},
          ];
          _selectedTeacherId = 1;
        }
        if (_schedules.isEmpty) {
          _schedules = [
            {
              'id': 1,
              'classroom_id': 1,
              'class_name': 'ថ្នាក់ទី ១A',
              'teacher_id': 1,
              'teacher_name': 'ហាក់ ប៉ាក់ហ៊្វូរ',
              'subject_name': 'ភាសាខ្មែរ',
              'day_of_week': 'Mon',
              'start_time': '07:30',
              'end_time': '09:00',
              'shift': 'Morning',
            },
            {
              'id': 2,
              'classroom_id': 1,
              'class_name': 'ថ្នាក់ទី ១A',
              'teacher_id': 2,
              'teacher_name': 'សន ចរិយា',
              'subject_name': 'គណិតវិទ្យា',
              'day_of_week': 'Mon',
              'start_time': '09:15',
              'end_time': '10:45',
              'shift': 'Morning',
            },
            {
              'id': 3,
              'classroom_id': 25,
              'class_name': '05 (Going Place 3)',
              'teacher_id': 3,
              'teacher_name': 'ទូច ស្រីមុំ',
              'subject_name': 'English Going Place 3',
              'day_of_week': 'Tue',
              'start_time': '17:30',
              'end_time': '18:45',
              'shift': 'Evening',
            },
          ];
        }
        _isLoading = false;
      });
    }
  }

  Future<bool> _saveSchedule({int? editId}) async {
    final subject = _subjectCtrl.text.trim();
    if (subject.isEmpty) {
      _showSnackbar('សូមបញ្ចូលឈ្មោះមុខវិជ្ជា!', Colors.orange);
      return false;
    }
    if (_selectedClassroomId == null) {
      _showSnackbar('សូមជ្រើសរើសថ្នាក់រៀន!', Colors.orange);
      return false;
    }
    if (_selectedTeacherId == null) {
      _showSnackbar('សូមជ្រើសរើសគ្រូបង្រៀន!', Colors.orange);
      return false;
    }

    setState(() => _isSaving = true);
    try {
      final isEdit = editId != null;
      final url = isEdit ? '$baseUrl/schedules/$editId' : '$baseUrl/schedules';
      final body = jsonEncode({
        'classroom_id': _selectedClassroomId,
        'teacher_id': _selectedTeacherId,
        'subject_name': subject,
        'day_of_week': _selectedDayOfWeek,
        'start_time': _startTimeCtrl.text.trim(),
        'end_time': _endTimeCtrl.text.trim(),
        'shift': _selectedShift,
      });

      final res = isEdit
          ? await http.put(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: body,
            )
          : await http.post(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: body,
            );

      final d = jsonDecode(utf8.decode(res.bodyBytes));
      if (res.statusCode == 200 && d['success'] == true) {
        _subjectCtrl.clear();
        _showSnackbar(
          isEdit ? 'បានកែប្រែកាលវិភាគជោគជ័យ!' : 'បានបង្កើតកាលវិភាគថ្មីដោយជោគជ័យ!',
          const Color(0xFF10B981),
        );
        await _loadAllData();
        return true;
      } else {
        _showSnackbar(d['error'] ?? 'បរាជ័យក្នុងការរក្សាទុក!', Colors.red);
        return false;
      }
    } catch (e) {
      _showSnackbar('មិនអាចភ្ជាប់ទៅកាន់ Server: $e', Colors.red);
      return false;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickTime(
    BuildContext context,
    TextEditingController controller,
  ) async {
    TimeOfDay initial = const TimeOfDay(hour: 8, minute: 0);
    final parts = controller.text.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0].trim());
      final m = int.tryParse(parts[1].trim());
      if (h != null && m != null) {
        initial = TimeOfDay(hour: h, minute: m);
      }
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF4F46E5),
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Color(0xFF1E293B),
              ),
            ),
            child: child!,
          ),
        );
      },
    );
    if (picked != null) {
      final hh = picked.hour.toString().padLeft(2, '0');
      final mm = picked.minute.toString().padLeft(2, '0');
      controller.text = '$hh:$mm';
    }
  }

  void _duplicateSchedule(Map<String, dynamic> schedule) {
    _openScheduleDialog(
      schedule: {
        'classroom_id': schedule['classroom_id'],
        'teacher_id': schedule['teacher_id'],
        'subject_name': schedule['subject_name'],
        'day_of_week': schedule['day_of_week'],
        'start_time': schedule['start_time'],
        'end_time': schedule['end_time'],
        'shift': schedule['shift'],
      },
    );
  }

  Future<void> _deleteSchedule(int id, String subject) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text(
              'បញ្ជាក់ការលុបកាលវិភាគ',
              style: TextStyle(
                fontFamily: 'Khmer OS Battambang',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Text(
          'តើអ្នកពិតជាចង់លុបម៉ោងបង្រៀនមុខវិជ្ជា "$subject" នេះមែនទេ?',
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

    if (confirm == true) {
      try {
        final res = await http.delete(Uri.parse('$baseUrl/schedules/$id'));
        if (res.statusCode == 200) {
          _showSnackbar('បានលុបកាលវិភាគជោគជ័យ!', const Color(0xFF10B981));
          _loadAllData();
        }
      } catch (e) {
        _showSnackbar('កំហុស៖ $e', Colors.red);
      }
    }
  }

  void _openAddScheduleDialog() {
    _openScheduleDialog();
  }

  void _openScheduleDialog({Map<String, dynamic>? schedule}) {
    final isEdit = schedule != null && schedule['id'] != null;
    final int? editId = isEdit
        ? (schedule['id'] is int
            ? schedule['id'] as int
            : int.tryParse(schedule['id'].toString()))
        : null;

    if (schedule != null) {
      _subjectCtrl.text = schedule['subject_name'] ?? '';
      _selectedClassroomId = schedule['classroom_id'] is int
          ? schedule['classroom_id']
          : int.tryParse(schedule['classroom_id']?.toString() ?? '');
      _selectedTeacherId = schedule['teacher_id'] is int
          ? schedule['teacher_id']
          : int.tryParse(schedule['teacher_id']?.toString() ?? '');
      _selectedDayOfWeek = schedule['day_of_week'] ?? _selectedDay;
      _startTimeCtrl.text = schedule['start_time'] ?? '08:00';
      _endTimeCtrl.text = schedule['end_time'] ?? '09:30';
      _selectedShift = schedule['shift'] ?? 'Morning';
    } else {
      _subjectCtrl.clear();
      _selectedDayOfWeek = _days.contains(_selectedDay) ? _selectedDay : 'Mon';
      _startTimeCtrl.text = '08:00';
      _endTimeCtrl.text = '09:30';
      _selectedShift = 'Morning';
      if (_filterClassroomId != null &&
          _classrooms.any((c) => c['id'] == _filterClassroomId)) {
        _selectedClassroomId = _filterClassroomId;
      } else if (_classrooms.isNotEmpty &&
          (_selectedClassroomId == null ||
              !_classrooms.any((c) => c['id'] == _selectedClassroomId))) {
        _selectedClassroomId = _classrooms.first['id'];
      }
      if (_filterTeacherId != null &&
          _teachers.any((t) => t['id'] == _filterTeacherId)) {
        _selectedTeacherId = _filterTeacherId;
      } else if (_teachers.isNotEmpty &&
          (_selectedTeacherId == null ||
              !_teachers.any((t) => t['id'] == _selectedTeacherId))) {
        _selectedTeacherId = _teachers.first['id'];
      }
    }

    final commonSubjects = [
      'គណិតវិទ្យា',
      'ភាសាខ្មែរ',
      'រូបវិទ្យា',
      'គីមីវិទ្យា',
      'ជីវវិទ្យា',
      'ភាសាអង់គ្លេស',
      'ប្រវត្តិវិទ្យា',
      'ព័ត៌មានវិទ្យា',
      'កីឡា',
    ];

    final timePresets = [
      {
        'label': '07:30 - 09:00',
        'start': '07:30',
        'end': '09:00',
        'shift': 'Morning'
      },
      {
        'label': '09:15 - 10:45',
        'start': '09:15',
        'end': '10:45',
        'shift': 'Morning'
      },
      {
        'label': '13:30 - 15:00',
        'start': '13:30',
        'end': '15:00',
        'shift': 'Afternoon'
      },
      {
        'label': '15:15 - 16:45',
        'start': '15:15',
        'end': '16:45',
        'shift': 'Afternoon'
      },
    ];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) {
          final classroomItems = <DropdownMenuItem<int>>[];
          final seenClassIds = <int>{};
          for (final c in _classrooms) {
            final id = c['id'] is int
                ? c['id'] as int
                : int.tryParse(c['id'].toString());
            if (id != null && seenClassIds.add(id)) {
              final className = c['class_name'] ?? 'Class';
              final room =
                  c['room_number'] != null ? ' (${c['room_number']})' : '';
              classroomItems.add(
                DropdownMenuItem<int>(
                  value: id,
                  child: Text(
                    '$className$room',
                    style: GoogleFonts.notoSansKhmer(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              );
            }
          }
          final effectiveClassId =
              (classroomItems.any((i) => i.value == _selectedClassroomId))
                  ? _selectedClassroomId
                  : (classroomItems.isNotEmpty
                      ? classroomItems.first.value
                      : null);

          final teacherItems = <DropdownMenuItem<int>>[];
          final seenTeacherIds = <int>{};
          for (final t in _teachers) {
            final id = t['id'] is int
                ? t['id'] as int
                : int.tryParse(t['id'].toString());
            if (id != null && seenTeacherIds.add(id)) {
              final name = t['name_kh'] ?? t['name_en'] ?? 'គ្រូ';
              final code =
                  t['teacher_code'] != null ? ' (${t['teacher_code']})' : '';
              teacherItems.add(
                DropdownMenuItem<int>(
                  value: id,
                  child: Text(
                    '$name$code',
                    style: GoogleFonts.notoSansKhmer(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              );
            }
          }
          final effectiveTeacherId =
              (teacherItems.any((i) => i.value == _selectedTeacherId))
                  ? _selectedTeacherId
                  : (teacherItems.isNotEmpty
                      ? teacherItems.first.value
                      : null);

          final effectiveDay = _days.contains(_selectedDayOfWeek)
              ? _selectedDayOfWeek
              : _days.first;
          final effectiveShift =
              ['Morning', 'Afternoon'].contains(_selectedShift)
                  ? _selectedShift
                  : 'Morning';

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 12,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Container(
                padding: const EdgeInsets.all(26),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isEdit
                                      ? const Color(0xFFFEF3C7)
                                      : const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  isEdit
                                      ? Icons.edit_calendar_rounded
                                      : Icons.add_circle_outline_rounded,
                                  color: isEdit
                                      ? const Color(0xFFD97706)
                                      : const Color(0xFF4F46E5),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEdit
                                        ? 'កែប្រែកាលវិភាគសិក្សា'
                                        : 'បង្កើតម៉ោងសិក្សាថ្មី',
                                    style: GoogleFonts.notoSansKhmer(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isEdit
                                        ? 'Update existing timetable entry'
                                        : 'Add new weekly schedule entry',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF94A3B8),
                            ),
                            tooltip: 'បិទ',
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // Classroom & Day Row
                      LayoutBuilder(
                        builder: (ctx, constraints) {
                          final isNarrow = constraints.maxWidth < 460;
                          final classWidget = DropdownButtonFormField<int>(
                            // ignore: deprecated_member_use
                            value: effectiveClassId,
                            isExpanded: true,
                            menuMaxHeight: 320,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF64748B),
                            ),
                            decoration: InputDecoration(
                              labelText: 'ជ្រើសរើសថ្នាក់រៀន *',
                              labelStyle:
                                  GoogleFonts.notoSansKhmer(fontSize: 12),
                              prefixIcon: const Icon(
                                Icons.meeting_room_outlined,
                                size: 20,
                                color: Color(0xFF4F46E5),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF4F46E5),
                                  width: 1.8,
                                ),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                            selectedItemBuilder: (c) {
                              return classroomItems.map((item) {
                                return Text(
                                  (item.child as Text).data ?? '',
                                  style: GoogleFonts.notoSansKhmer(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                );
                              }).toList();
                            },
                            items: classroomItems,
                            onChanged: (v) {
                              _selectedClassroomId = v;
                              setM(() {});
                            },
                          );

                          final dayWidget = DropdownButtonFormField<String>(
                            // ignore: deprecated_member_use
                            value: effectiveDay,
                            isExpanded: true,
                            menuMaxHeight: 320,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF64748B),
                            ),
                            decoration: InputDecoration(
                              labelText: 'ថ្ងៃសិក្សា *',
                              labelStyle:
                                  GoogleFonts.notoSansKhmer(fontSize: 12),
                              prefixIcon: const Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                                color: Color(0xFF4F46E5),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF4F46E5),
                                  width: 1.8,
                                ),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                            selectedItemBuilder: (c) {
                              return _days.map((d) {
                                return Text(
                                  _dayLabels[d]!,
                                  style: GoogleFonts.notoSansKhmer(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                );
                              }).toList();
                            },
                            items: _days.map((d) {
                              return DropdownMenuItem(
                                value: d,
                                child: Text(
                                  _dayLabels[d]!,
                                  style: GoogleFonts.notoSansKhmer(
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              );
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) {
                                _selectedDayOfWeek = v;
                                setM(() {});
                              }
                            },
                          );

                          if (isNarrow) {
                            return Column(
                              children: [
                                classWidget,
                                const SizedBox(height: 14),
                                dayWidget,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: classWidget),
                              const SizedBox(width: 14),
                              Expanded(child: dayWidget),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Subject Title Input
                      TextField(
                        controller: _subjectCtrl,
                        onChanged: (_) => setM(() {}),
                        decoration: InputDecoration(
                          labelText: 'ឈ្មោះមុខវិជ្ជា / Subject Title *',
                          labelStyle:
                              GoogleFonts.notoSansKhmer(fontSize: 12),
                          hintText: 'ឧ. គណិតវិទ្យា, ភាសាខ្មែរ...',
                          hintStyle: GoogleFonts.notoSansKhmer(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                          prefixIcon: const Icon(
                            Icons.menu_book_rounded,
                            size: 20,
                            color: Color(0xFF4F46E5),
                          ),
                          suffixIcon: _subjectCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    _subjectCtrl.clear();
                                    setM(() {});
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF4F46E5),
                              width: 1.8,
                            ),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Quick Subject Suggestion Chips
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: commonSubjects.map((sub) {
                          final isSel = _subjectCtrl.text.trim() == sub;
                          return InkWell(
                            onTap: () {
                              _subjectCtrl.text = sub;
                              setM(() {});
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? const Color(0xFFEEF2FF)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSel
                                      ? const Color(0xFF6366F1)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                sub,
                                style: GoogleFonts.notoSansKhmer(
                                  fontSize: 11,
                                  fontWeight: isSel
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSel
                                      ? const Color(0xFF4F46E5)
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Teacher & Shift Row
                      LayoutBuilder(
                        builder: (ctx, constraints) {
                          final isNarrow = constraints.maxWidth < 460;
                          final teacherWidget = DropdownButtonFormField<int>(
                            // ignore: deprecated_member_use
                            value: effectiveTeacherId,
                            isExpanded: true,
                            menuMaxHeight: 320,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF64748B),
                            ),
                            decoration: InputDecoration(
                              labelText: 'គ្រូបង្រៀន *',
                              labelStyle:
                                  GoogleFonts.notoSansKhmer(fontSize: 12),
                              prefixIcon: const Icon(
                                Icons.badge_outlined,
                                size: 20,
                                color: Color(0xFF4F46E5),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF4F46E5),
                                  width: 1.8,
                                ),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                            selectedItemBuilder: (c) {
                              return teacherItems.map((item) {
                                return Text(
                                  (item.child as Text).data ?? '',
                                  style: GoogleFonts.notoSansKhmer(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                );
                              }).toList();
                            },
                            items: teacherItems,
                            onChanged: (v) {
                              _selectedTeacherId = v;
                              setM(() {});
                            },
                          );

                          final shiftWidget = DropdownButtonFormField<String>(
                            // ignore: deprecated_member_use
                            value: effectiveShift,
                            isExpanded: true,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF64748B),
                            ),
                            decoration: InputDecoration(
                              labelText: 'វេនសិក្សា *',
                              labelStyle:
                                  GoogleFonts.notoSansKhmer(fontSize: 12),
                              prefixIcon: Icon(
                                effectiveShift == 'Morning'
                                    ? Icons.wb_sunny_outlined
                                    : Icons.nights_stay_outlined,
                                size: 20,
                                color: effectiveShift == 'Morning'
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFF4F46E5),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF4F46E5),
                                  width: 1.8,
                                ),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Morning',
                                child: Text('វេនព្រឹក (Morning)'),
                              ),
                              DropdownMenuItem(
                                value: 'Afternoon',
                                child: Text('វេនរសៀល (Afternoon)'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                _selectedShift = v;
                                setM(() {});
                              }
                            },
                          );

                          if (isNarrow) {
                            return Column(
                              children: [
                                teacherWidget,
                                const SizedBox(height: 14),
                                shiftWidget,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: teacherWidget),
                              const SizedBox(width: 14),
                              Expanded(child: shiftWidget),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Start & End Time
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                await _pickTime(ctx, _startTimeCtrl);
                                setM(() {});
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: IgnorePointer(
                                child: TextField(
                                  controller: _startTimeCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'ម៉ោងចាប់ផ្ដើម *',
                                    labelStyle: GoogleFonts.notoSansKhmer(
                                      fontSize: 12,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.access_time_rounded,
                                      size: 18,
                                      color: Color(0xFF4F46E5),
                                    ),
                                    suffixIcon: const Icon(
                                      Icons.schedule_rounded,
                                      size: 18,
                                      color: Color(0xFF94A3B8),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                await _pickTime(ctx, _endTimeCtrl);
                                setM(() {});
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: IgnorePointer(
                                child: TextField(
                                  controller: _endTimeCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'ម៉ោងបញ្ចប់ *',
                                    labelStyle: GoogleFonts.notoSansKhmer(
                                      fontSize: 12,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.access_time_filled_rounded,
                                      size: 18,
                                      color: Color(0xFF4F46E5),
                                    ),
                                    suffixIcon: const Icon(
                                      Icons.schedule_rounded,
                                      size: 18,
                                      color: Color(0xFF94A3B8),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Quick Time Presets
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'ម៉ោងស្តង់ដារ៖',
                            style: GoogleFonts.notoSansKhmer(
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          ...timePresets.map((tp) {
                            final isCur = _startTimeCtrl.text == tp['start'] &&
                                _endTimeCtrl.text == tp['end'];
                            return InkWell(
                              onTap: () {
                                _startTimeCtrl.text = tp['start']!;
                                _endTimeCtrl.text = tp['end']!;
                                _selectedShift = tp['shift']!;
                                setM(() {});
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isCur
                                      ? const Color(0xFFEEF2FF)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isCur
                                        ? const Color(0xFF4F46E5)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Text(
                                  tp['label']!,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: isCur
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isCur
                                        ? const Color(0xFF4F46E5)
                                        : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                            ),
                            child: Text(
                              'បោះបង់',
                              style: GoogleFonts.notoSansKhmer(
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isEdit
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            onPressed: _isSaving
                                ? null
                                : () async {
                                    final success =
                                        await _saveSchedule(editId: editId);
                                    if (success && ctx.mounted) {
                                      Navigator.pop(ctx);
                                    }
                                  },
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isEdit
                                            ? Icons.check_circle_rounded
                                            : Icons.save_rounded,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isEdit
                                            ? 'កែប្រែកាលវិភាគ'
                                            : 'រក្សាទុកកាលវិភាគ',
                                        style: GoogleFonts.notoSansKhmer(
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
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openAddDutyDialog() {
    final titleCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final timeCtrl = TextEditingController(text: '07:00 - 07:30 AM');
    String teacherName = _teachers.isNotEmpty
        ? (_teachers[0]['name_kh'] ??
            _teachers[0]['name_en'] ??
            'លោកគ្រូ សុខ ចាន់')
        : 'លោកគ្រូ សុខ ចាន់';

    final dutyPresets = [
      'សម្រួលសណ្តាប់ធ្នាប់សិស្ស',
      'ត្រួតពិនិត្យអនាម័យសាលា',
      'សម្រួលចរាចរណ៍ចេញពីរៀន',
      'ប្រចាំការបណ្ណាល័យ',
    ];

    final dutyTimePresets = [
      '06:45 - 07:15 AM',
      '09:30 - 10:00 AM',
      '11:00 - 11:30 AM',
      '04:30 - 05:00 PM',
    ];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 12,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: const EdgeInsets.all(26),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.security_rounded,
                                color: Color(0xFF10B981),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'បន្ថែមភារកិច្ចប្រចាំថ្ងៃថ្មី',
                                  style: GoogleFonts.notoSansKhmer(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Assign new daily teacher duty',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF94A3B8),
                          ),
                          tooltip: 'បិទ',
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    TextField(
                      controller: titleCtrl,
                      onChanged: (_) => setM(() {}),
                      decoration: InputDecoration(
                        labelText: 'ឈ្មោះភារកិច្ច (Task Name) *',
                        labelStyle: GoogleFonts.notoSansKhmer(fontSize: 12),
                        hintText: 'ឧ. សម្រួលសណ្តាប់ធ្នាប់សិស្សពេលព្រឹក...',
                        hintStyle: GoogleFonts.notoSansKhmer(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(
                          Icons.task_alt_rounded,
                          size: 20,
                          color: Color(0xFF10B981),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF10B981),
                            width: 1.8,
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: dutyPresets.map((dp) {
                        final isSel = titleCtrl.text.trim() == dp;
                        return InkWell(
                          onTap: () {
                            titleCtrl.text = dp;
                            setM(() {});
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? const Color(0xFFECFDF5)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSel
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              dp,
                              style: GoogleFonts.notoSansKhmer(
                                fontSize: 11,
                                fontWeight: isSel
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSel
                                    ? const Color(0xFF059669)
                                    : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: locCtrl,
                      decoration: InputDecoration(
                        labelText: 'ទីតាំងទទួលខុសត្រូវ (Location)',
                        labelStyle: GoogleFonts.notoSansKhmer(fontSize: 12),
                        hintText: 'ឧ. ច្រកទ្វារធំ / តារាងបាល់ / អាហារដ្ឋាន...',
                        hintStyle: GoogleFonts.notoSansKhmer(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(
                          Icons.place_outlined,
                          size: 20,
                          color: Color(0xFF10B981),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF10B981),
                            width: 1.8,
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: timeCtrl,
                            decoration: InputDecoration(
                              labelText: 'ពេលវេលា (Time) *',
                              labelStyle:
                                  GoogleFonts.notoSansKhmer(fontSize: 12),
                              prefixIcon: const Icon(
                                Icons.access_time_rounded,
                                size: 18,
                                color: Color(0xFF10B981),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Builder(
                            builder: (_) {
                              final dutyTeacherItems =
                                  <DropdownMenuItem<String>>[];
                              final seenTeacherNames = <String>{};
                              for (final t in _teachers) {
                                final name = t['name_kh']?.toString();
                                if (name != null &&
                                    name.trim().isNotEmpty &&
                                    seenTeacherNames.add(name.trim())) {
                                  dutyTeacherItems.add(
                                    DropdownMenuItem(
                                      value: name.trim(),
                                      child: Text(
                                        name.trim(),
                                        style: GoogleFonts.notoSansKhmer(
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  );
                                }
                              }
                              if (!seenTeacherNames.contains(teacherName)) {
                                dutyTeacherItems.insert(
                                  0,
                                  DropdownMenuItem(
                                    value: teacherName,
                                    child: Text(
                                      teacherName,
                                      style: GoogleFonts.notoSansKhmer(
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                );
                              }
                              final effectiveName = dutyTeacherItems
                                      .any((i) => i.value == teacherName)
                                  ? teacherName
                                  : dutyTeacherItems.first.value!;

                              return DropdownButtonFormField<String>(
                                // ignore: deprecated_member_use
                                value: effectiveName,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'គ្រូទទួលបន្ទុក *',
                                  labelStyle:
                                      GoogleFonts.notoSansKhmer(fontSize: 12),
                                  prefixIcon: const Icon(
                                    Icons.person_outline,
                                    size: 20,
                                    color: Color(0xFF10B981),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFCBD5E1)),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                ),
                                selectedItemBuilder: (c) {
                                  return dutyTeacherItems.map((item) {
                                    return Text(
                                      item.value ?? '',
                                      style: GoogleFonts.notoSansKhmer(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF0F172A),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    );
                                  }).toList();
                                },
                                items: dutyTeacherItems,
                                onChanged: (v) {
                                  if (v != null) setM(() => teacherName = v);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: dutyTimePresets.map((tp) {
                        final isCur = timeCtrl.text.trim() == tp;
                        return InkWell(
                          onTap: () {
                            timeCtrl.text = tp;
                            setM(() {});
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isCur
                                  ? const Color(0xFFECFDF5)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isCur
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              tp,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: isCur
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isCur
                                    ? const Color(0xFF059669)
                                    : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            'បោះបង់',
                            style: GoogleFonts.notoSansKhmer(
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 14,
                            ),
                            elevation: 2,
                          ),
                          onPressed: () {
                            final title = titleCtrl.text.trim();
                            if (title.isEmpty) {
                              _showSnackbar(
                                'សូមបញ្ចូលឈ្មោះភារកិច្ច!',
                                Colors.orange,
                              );
                              return;
                            }
                            setState(() {
                              _dutyRoster.add({
                                'title': title,
                                'location': locCtrl.text.trim().isEmpty
                                    ? 'បរិវេណសាលា'
                                    : locCtrl.text.trim(),
                                'teacher': teacherName,
                                'time': timeCtrl.text.trim(),
                                'completed': false,
                              });
                            });
                            Navigator.pop(ctx);
                            _showSnackbar(
                              'បានបន្ថែមភារកិច្ចថ្មីដោយជោគជ័យ!',
                              const Color(0xFF10B981),
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_task_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'បន្ថែមភារកិច្ច',
                                style: GoogleFonts.notoSansKhmer(
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackbar(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.notoSansKhmer()),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  int _countForDay(String day) {
    return _schedules.where((s) {
      final d = (s['day_of_week'] ?? '').toString().toLowerCase();
      final matchesDay = d == day.toLowerCase();
      final matchesClass =
          _filterClassroomId == null || s['classroom_id'] == _filterClassroomId;
      final matchesTeacher =
          _filterTeacherId == null || s['teacher_id'] == _filterTeacherId;
      final matchesShift =
          _filterShift == 'All' ||
          (s['shift'] ?? '').toString().toLowerCase() ==
              _filterShift.toLowerCase();
      return matchesDay && matchesClass && matchesTeacher && matchesShift;
    }).length;
  }

  List<dynamic> get _filteredSchedules {
    return _schedules.where((s) {
      final day = (s['day_of_week'] ?? '').toString().toLowerCase();
      final matchesDay = day == _selectedDay.toLowerCase();
      final matchesClass =
          _filterClassroomId == null || s['classroom_id'] == _filterClassroomId;
      final matchesTeacher =
          _filterTeacherId == null || s['teacher_id'] == _filterTeacherId;
      final matchesShift =
          _filterShift == 'All' ||
          (s['shift'] ?? '').toString().toLowerCase() ==
              _filterShift.toLowerCase();
      final query = _searchCtrl.text.trim().toLowerCase();
      final matchesQuery =
          query.isEmpty ||
          (s['subject_name'] ?? '').toString().toLowerCase().contains(query) ||
          (s['teacher_name'] ?? '').toString().toLowerCase().contains(query) ||
          (s['class_name'] ?? '').toString().toLowerCase().contains(query);
      return matchesDay &&
          matchesClass &&
          matchesTeacher &&
          matchesShift &&
          matchesQuery;
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredDutyRoster {
    if (_dutyFilter == 'Completed') {
      return _dutyRoster.where((d) => d['completed'] == true).toList();
    } else if (_dutyFilter == 'Pending') {
      return _dutyRoster.where((d) => d['completed'] != true).toList();
    }
    return _dutyRoster;
  }

  @override
  Widget build(BuildContext context) {
    final totalClasses = _schedules.length;
    final scheduledClassrooms = _schedules
        .map((s) => s['classroom_id'])
        .toSet()
        .length;
    final activeInstructors = _schedules
        .map((s) => s['teacher_id'])
        .toSet()
        .length;
    final completedDuties = _dutyRoster
        .where((d) => d['completed'] == true)
        .length;

    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header Section ───
            Container(
              padding: EdgeInsets.all(isMobile ? 14 : 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: const Color(0xFF0F172A).withOpacity(0.02),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: isMobile
                        ? MainAxisSize.max
                        : MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(isMobile ? 10 : 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.calendar_month_rounded,
                          color: const Color(0xFF4F46E5),
                          size: isMobile ? 24 : 30,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'កាលវិភាគប្រចាំសប្តាហ៍',
                                  style: AppTheme.khmerHeading(
                                    fontSize: isMobile ? 16 : 19,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                if (!isMobile) ...[
                                  const SizedBox(width: 8),
                                  const Text(
                                    '/',
                                    style: TextStyle(
                                      color: Color(0xFFCBD5E1),
                                      fontWeight: FontWeight.w300,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Weekly Timetable',
                                    style: AppTheme.englishHeading(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ពិនិត្យ រៀបចំ និងកែសម្រួលកាលវិភាគបង្រៀន និងបញ្ជីវេនប្រចាំការគ្រូយ៉ាងងាយស្រួល',
                              style: AppTheme.khmerBody(
                                fontSize: isMobile ? 11 : 13,
                                color: const Color(0xFF64748B),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _exportCSV,
                        icon: const Icon(
                          Icons.file_download_outlined,
                          size: 18,
                        ),
                        label: Text(
                          'ទាញយក CSV',
                          style: AppTheme.khmerBody(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1E293B),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _openAddScheduleDialog,
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: Text(
                          'បង្កើតម៉ោងសិក្សាថ្មី',
                          style: AppTheme.khmerBody(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: _loadAllData,
                        tooltip: 'ផ្ទុកទិន្នន័យឡើងវិញ',
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: Color(0xFF64748B),
                        ),
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(12),
                          backgroundColor: const Color(0xFFF1F5F9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ─── KPI Metric Cards ───
            LayoutBuilder(
              builder: (ctx, constraints) {
                final card1 = _buildKpiCard(
                  'ម៉ោងបង្រៀនសរុប',
                  '$totalClasses ម៉ោង',
                  'កាលវិភាគក្នុងសប្តាហ៍',
                  Icons.schedule_rounded,
                  const Color(0xFF3B82F6),
                );
                final card2 = _buildKpiCard(
                  'ថ្នាក់រៀនមានកាលវិភាគ',
                  '$scheduledClassrooms ថ្នាក់',
                  'នៃបន្ទប់សិក្សាសរុប',
                  Icons.meeting_room_outlined,
                  const Color(0xFF10B981),
                );
                final card3 = _buildKpiCard(
                  'គ្រូបង្រៀនសកម្ម',
                  '$activeInstructors នាក់',
                  'មានម៉ោងបង្រៀន',
                  Icons.badge_outlined,
                  const Color(0xFF8B5CF6),
                );
                final card4 = _buildKpiCard(
                  'វេនប្រចាំការ',
                  '$completedDuties/${_dutyRoster.length} ភារកិច្ច',
                  'បានបំពេញរួចរាល់',
                  Icons.security_rounded,
                  const Color(0xFFF59E0B),
                );

                if (constraints.maxWidth < 900) {
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: card1,
                      ),
                      SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: card2,
                      ),
                      SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: card3,
                      ),
                      SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: card4,
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: card1),
                    const SizedBox(width: 14),
                    Expanded(child: card2),
                    const SizedBox(width: 14),
                    Expanded(child: card3),
                    const SizedBox(width: 14),
                    Expanded(child: card4),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // ─── Segmented Tab Switcher (Schedules vs Duty Roster) ───
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTabPill(
                    title: 'កាលវិភាគបង្រៀន (Class Timetables)',
                    icon: Icons.grid_view_rounded,
                    isSelected: _selectedMainTab == 0,
                    onTap: () => setState(() => _selectedMainTab = 0),
                  ),
                  const SizedBox(width: 4),
                  _buildTabPill(
                    title: 'បញ្ជីវេនប្រចាំការគ្រូ (Teacher Duty Roster)',
                    icon: Icons.checklist_rounded,
                    isSelected: _selectedMainTab == 1,
                    onTap: () => setState(() => _selectedMainTab = 1),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ─── Main Content View ───
            if (_selectedMainTab == 0)
              _buildSchedulesTab()
            else
              _buildDutyRosterTab(),
          ],
        ),
      ),
    );
  }

  // ─── Tab 0: Class Timetables ───
  Widget _buildSchedulesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter & Toolbar Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final searchField = SizedBox(
                width: constraints.maxWidth < 800 ? double.infinity : 260,
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'ស្វែងរកមុខវិជ្ជា ឬឈ្មោះគ្រូ...',
                    hintStyle: GoogleFonts.notoSansKhmer(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 18,
                      color: Color(0xFF94A3B8),
                    ),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () =>
                                setState(() => _searchCtrl.clear()),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
              );

              final classFilter = DropdownButton<int?>(
                value: _filterClassroomId,
                hint: Text(
                  'គ្រប់ថ្នាក់រៀន (All Classes)',
                  style: GoogleFonts.notoSansKhmer(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
                underline: const SizedBox(),
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(
                      'គ្រប់ថ្នាក់រៀន (All Classes)',
                      style: GoogleFonts.notoSansKhmer(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ..._classrooms.map(
                    (c) => DropdownMenuItem<int?>(
                      value: c['id'],
                      child: Text(
                        c['class_name'] ?? 'Class',
                        style: GoogleFonts.notoSansKhmer(fontSize: 12),
                      ),
                    ),
                  ),
                ],
                onChanged: (val) => setState(() => _filterClassroomId = val),
              );

              final teacherFilter = DropdownButton<int?>(
                value: _filterTeacherId,
                hint: Text(
                  'គ្រប់គ្រូបង្រៀន (All Teachers)',
                  style: GoogleFonts.notoSansKhmer(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
                underline: const SizedBox(),
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(
                      'គ្រប់គ្រូបង្រៀន (All Teachers)',
                      style: GoogleFonts.notoSansKhmer(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ..._teachers.map((t) {
                    final id = t['id'] is int
                        ? t['id'] as int
                        : int.tryParse(t['id'].toString());
                    final name = t['name_kh'] ?? t['name_en'] ?? 'គ្រូ';
                    final code = t['teacher_code'] != null ? ' (${t['teacher_code']})' : '';
                    return DropdownMenuItem<int?>(
                      value: id,
                      child: Text(
                        '$name$code',
                        style: GoogleFonts.notoSansKhmer(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                ],
                onChanged: (val) => setState(() => _filterTeacherId = val),
              );

              final shiftFilter = DropdownButton<String>(
                value: _filterShift,
                underline: const SizedBox(),
                items: [
                  DropdownMenuItem(
                    value: 'All',
                    child: Text(
                      'គ្រប់វេន (All Shifts)',
                      style: GoogleFonts.notoSansKhmer(fontSize: 12),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Morning',
                    child: Text(
                      'វេនព្រឹក (Morning)',
                      style: GoogleFonts.notoSansKhmer(fontSize: 12),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Afternoon',
                    child: Text(
                      'វេនរសៀល (Afternoon)',
                      style: GoogleFonts.notoSansKhmer(fontSize: 12),
                    ),
                  ),
                ],
                onChanged: (val) => setState(() => _filterShift = val ?? 'All'),
              );

              final isFiltered = _filterClassroomId != null ||
                  _filterTeacherId != null ||
                  _filterShift != 'All' ||
                  _searchCtrl.text.isNotEmpty;

              return Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  searchField,
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: classFilter,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: teacherFilter,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: shiftFilter,
                      ),
                      if (isFiltered)
                        InkWell(
                          onTap: () {
                            setState(() {
                              _filterClassroomId = null;
                              _filterTeacherId = null;
                              _filterShift = 'All';
                              _searchCtrl.clear();
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFFECACA),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.filter_alt_off_rounded,
                                  size: 14,
                                  color: Color(0xFFDC2626),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'សម្អាតតម្រង',
                                  style: GoogleFonts.notoSansKhmer(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),

        const SizedBox(height: 18),

        // Day Selection Pills (Mon to Sat) with badge counts
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _days.map((day) {
            final isSelected = _selectedDay == day;
            final count = _countForDay(day);
            return InkWell(
              onTap: () => setState(() => _selectedDay = day),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF4F46E5)
                        : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? const Color(0xFF4F46E5).withValues(alpha: 0.35)
                          : Colors.black.withValues(alpha: 0.03),
                      blurRadius: isSelected ? 12 : 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _dayLabels[day]!,
                      style: GoogleFonts.notoSansKhmer(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.25)
                            : (count > 0
                                ? const Color(0xFFEEF2FF)
                                : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$count',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : (count > 0
                                  ? const Color(0xFF4F46E5)
                                  : const Color(0xFF94A3B8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // Schedule Grid
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(60),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
            ),
          )
        else if (_filteredSchedules.isEmpty)
          Container(
            padding: const EdgeInsets.all(48),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    size: 36,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'មិនទាន់មានកាលវិភាគសម្រាប់ថ្ងៃ ${_dayLabels[_selectedDay]} ទេ',
                  style: GoogleFonts.notoSansKhmer(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'សូមចុចប៊ូតុងខាងក្រោមដើម្បីបង្កើតម៉ោងសិក្សាថ្មីសម្រាប់ថ្នាក់រៀន',
                  style: GoogleFonts.notoSansKhmer(
                    fontSize: 12,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _openAddScheduleDialog,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    'បង្កើតម៉ោងសិក្សាថ្មី',
                    style: GoogleFonts.notoSansKhmer(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: _filteredSchedules.map((s) {
              return SizedBox(width: 370, child: _buildRealScheduleCard(s));
            }).toList(),
          ),
      ],
    );
  }

  // ─── Tab 1: Teacher Duty Roster ───
  Widget _buildDutyRosterTab() {
    final filtered = _filteredDutyRoster;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Roster Action Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  _buildDutyFilterPill('ទាំងអស់', 'All'),
                  _buildDutyFilterPill('កំពុងរង់ចាំ', 'Pending'),
                  _buildDutyFilterPill('រួចរាល់', 'Completed'),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _openAddDutyDialog,
                icon: const Icon(Icons.add_task_rounded, size: 18),
                label: Text(
                  'បន្ថែមភារកិច្ចថ្មី',
                  style: GoogleFonts.notoSansKhmer(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(48),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 40,
                  color: Color(0xFF10B981),
                ),
                const SizedBox(height: 12),
                Text(
                  'គ្មានភារកិច្ចក្នុងប្រភេទនេះទេ',
                  style: GoogleFonts.notoSansKhmer(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          )
        else
          for (final task in filtered) _buildDutyCard(task),
      ],
    );
  }

  // ─── Individual Schedule Card ───
  Widget _buildRealScheduleCard(Map<String, dynamic> s) {
    final startTime = s['start_time'] ?? '08:00';
    final endTime = s['end_time'] ?? '09:30';
    final subject = s['subject_name'] ?? 'General Subject';
    final className = s['class_name'] ?? 'បន្ទប់សិក្សា';
    final teacherName = s['teacher_name'] ?? 'លោកគ្រូ/អ្នកគ្រូ';
    final shift = s['shift'] ?? 'Morning';

    final isMorning = shift == 'Morning';
    final primaryColor =
        isMorning ? const Color(0xFF4F46E5) : const Color(0xFF0D9488);
    final accentBg =
        isMorning ? const Color(0xFFEEF2FF) : const Color(0xFFCCFBF1);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openScheduleDialog(schedule: s),
        borderRadius: BorderRadius.circular(18),
        // ignore: deprecated_member_use
        hoverColor: primaryColor.withOpacity(0.04),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: const Color(0xFF0F172A).withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Time & Shift & Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: accentBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$startTime - $endTime',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isMorning
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isMorning ? 'វេនព្រឹក' : 'វេនរសៀល',
                          style: GoogleFonts.notoSansKhmer(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isMorning
                                ? const Color(0xFFB45309)
                                : const Color(0xFF047857),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: Color(0xFF4F46E5),
                          ),
                          tooltip: 'កែសម្រួល / Edit',
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                          onPressed: () => _openScheduleDialog(schedule: s),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.content_copy_rounded,
                            size: 15,
                            color: Color(0xFF64748B),
                          ),
                          tooltip: 'ចម្លង / Duplicate',
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                          onPressed: () => _duplicateSchedule(s),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: Color(0xFFDC2626),
                          ),
                          tooltip: 'លុប / Delete',
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                          onPressed: () => _deleteSchedule(s['id'], subject),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Subject Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.auto_stories_rounded,
                      size: 16,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      subject,
                      style: GoogleFonts.notoSansKhmer(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Class & Teacher Info Container
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.meeting_room_outlined,
                          size: 14,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ថ្នាក់រៀន៖ $className',
                            style: GoogleFonts.notoSansKhmer(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF475569),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.badge_outlined,
                          size: 14,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'គ្រូបង្រៀន៖ $teacherName',
                            style: GoogleFonts.notoSansKhmer(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2563EB),
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

              const SizedBox(height: 10),
              // Hint Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.touch_app_outlined,
                    size: 12,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'ចុចលើកាតដើម្បីកែប្រែ',
                    style: GoogleFonts.notoSansKhmer(
                      fontSize: 10,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Individual Duty Card ───
  Widget _buildDutyCard(Map<String, dynamic> task) {
    final bool isDone = task['completed'] ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone ? const Color(0xFF6EE7B7) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: const Color(0xFF0F172A).withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Checkbox(
            value: isDone,
            activeColor: const Color(0xFF10B981),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            onChanged: (val) {
              setState(() {
                task['completed'] = val;
              });
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['title'] ?? '',
                  style: GoogleFonts.notoSansKhmer(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 14,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          task['location'] ?? '',
                          style: GoogleFonts.notoSansKhmer(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          task['time'] ?? '',
                          style: GoogleFonts.notoSansKhmer(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 14,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          task['teacher'] ?? '',
                          style: GoogleFonts.notoSansKhmer(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDone ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isDone ? 'រួចរាល់' : 'កំពុងរង់ចាំ',
              style: GoogleFonts.notoSansKhmer(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDone
                    ? const Color(0xFF059669)
                    : const Color(0xFFD97706),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(
              Icons.close_rounded,
              size: 16,
              color: Color(0xFF94A3B8),
            ),
            tooltip: 'លុបភារកិច្ច',
            onPressed: () {
              setState(() {
                _dutyRoster.remove(task);
              });
            },
          ),
        ],
      ),
    );
  }

  // ─── Component Helpers ───
  Widget _buildKpiCard(
    String title,
    String val,
    String sub,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: const Color(0xFF0F172A).withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.notoSansKhmer(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  val,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  sub,
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
    );
  }

  Widget _buildTabPill({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          // ignore: deprecated_member_use
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? const Color(0xFF4F46E5)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.notoSansKhmer(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF4F46E5)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDutyFilterPill(String label, String value) {
    final isSelected = _dutyFilter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.notoSansKhmer(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFFECFDF5),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF059669) : const Color(0xFF64748B),
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
      ),
      onSelected: (_) => setState(() => _dutyFilter = value),
    );
  }
}
