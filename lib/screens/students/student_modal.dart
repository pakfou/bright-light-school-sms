import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../widgets/web_photo_uploader.dart';
import '../../services/api_service.dart';

class StudentModal extends StatefulWidget {
  final Map<String, dynamic>? student;
  final VoidCallback onSaved;

  const StudentModal({super.key, this.student, required this.onSaved});

  @override
  State<StudentModal> createState() => _StudentModalState();
}

class _StudentModalState extends State<StudentModal> {
  static String get baseUrl => ApiService.baseUrl;

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codeCtrl;
  late TextEditingController _nameKhCtrl;
  late TextEditingController _nameEnCtrl;
  late TextEditingController _pobCtrl;
  late TextEditingController _parentNameCtrl;
  late TextEditingController _parentPhoneCtrl;
  late TextEditingController _photoUrlCtrl;

  String _gender = 'Female';
  DateTime? _dob;
  String _studyType = 'Full-Time'; // 'Full-Time' or 'Part-Time'
  String _shift = 'Morning'; // 'Morning', 'Afternoon', 'Both'
  String _partTimeCourse = 'Computer'; // 'English', 'Chinese', 'Computer'
  int? _selectedClassroomId;

  List<dynamic> _classrooms = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    final rCode =
        'BLS-${1000 + (DateTime.now().millisecondsSinceEpoch % 9000)}';

    _codeCtrl = TextEditingController(text: s?['student_code'] ?? rCode);
    _nameKhCtrl = TextEditingController(text: s?['name_kh'] ?? '');
    _nameEnCtrl = TextEditingController(text: s?['name_en'] ?? '');
    _pobCtrl = TextEditingController(text: s?['pob'] ?? '');
    _parentNameCtrl = TextEditingController(text: s?['parent_name'] ?? '');
    _parentPhoneCtrl = TextEditingController(text: s?['parent_phone'] ?? '');
    _photoUrlCtrl = TextEditingController(text: s?['photo_url'] ?? '');

    _gender = (s?['gender'] == 'Male') ? 'Male' : 'Female';
    _studyType = (s?['study_type'] == 'Part-Time') ? 'Part-Time' : 'Full-Time';
    _shift = (s?['shift'] == 'Afternoon' || s?['shift'] == 'Both')
        ? s!['shift']
        : 'Morning';
    _partTimeCourse = s?['part_time_course'] ?? 'Computer';
    if (_partTimeCourse == 'None' || _partTimeCourse.trim().isEmpty) {
      _partTimeCourse = 'Computer';
    }

    if (s?['classroom_id'] != null) {
      _selectedClassroomId = s!['classroom_id'] is int
          ? s['classroom_id'] as int
          : int.tryParse(s['classroom_id'].toString());
    }

    if (s?['dob'] != null) {
      _dob = DateTime.tryParse(s!['dob'].toString());
    }
    _fetchClassrooms();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameKhCtrl.dispose();
    _nameEnCtrl.dispose();
    _pobCtrl.dispose();
    _parentNameCtrl.dispose();
    _parentPhoneCtrl.dispose();
    _photoUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchClassrooms() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/classrooms'));
      if (res.statusCode == 200) {
        final d = jsonDecode(utf8.decode(res.bodyBytes));
        if (mounted) {
          setState(() {
            _classrooms = d['data'] ?? [];
            if (_selectedClassroomId == null && _classrooms.isNotEmpty) {
              _selectedClassroomId = _classrooms[0]['id'];
            }
          });
        }
      }
    } catch (_) {}
  }

  List<DropdownMenuItem<int>> _buildClassroomItems() {
    final items = <DropdownMenuItem<int>>[];
    final seenIds = <int>{};

    // Always provide an unassigned option (value: 0)
    items.add(
      const DropdownMenuItem<int>(
        value: 0,
        child: Text('មិនទាន់កំណត់ថ្នាក់រៀន (Unassigned)', overflow: TextOverflow.ellipsis),
      ),
    );
    seenIds.add(0);

    for (final c in _classrooms) {
      if (c == null) continue;
      final id = c['id'] is int
          ? c['id'] as int
          : int.tryParse(c['id'].toString());
      if (id != null && seenIds.add(id)) {
        final name = c['class_name']?.toString() ?? 'ថ្នាក់ $id';
        final shift = c['shift']?.toString();
        final shiftText = (shift != null && shift.isNotEmpty)
            ? ' ($shift)'
            : '';
        items.add(
          DropdownMenuItem<int>(
            value: id,
            child: Text('$name$shiftText', overflow: TextOverflow.ellipsis),
          ),
        );
      }
    }

    // Safeguard: If student has a classroom_id that isn't yet in _classrooms, add it!
    if (_selectedClassroomId != null && seenIds.add(_selectedClassroomId!)) {
      final fallbackName =
          widget.student?['class_name']?.toString() ??
          'ថ្នាក់បន្ទប់ ID: $_selectedClassroomId';
      items.add(
        DropdownMenuItem<int>(
          value: _selectedClassroomId,
          child: Text(
            '$fallbackName (បច្ចុប្បន្ន)',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    return items;
  }

  int _getEffectiveClassroomId(List<DropdownMenuItem<int>> items) {
    if (_selectedClassroomId != null &&
        items.any((i) => i.value == _selectedClassroomId)) {
      return _selectedClassroomId!;
    }
    return 0;
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(2015, 1, 1),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final payload = {
      'student_code': _codeCtrl.text.trim(),
      'name_kh': _nameKhCtrl.text.trim(),
      'name_en': _nameEnCtrl.text.trim(),
      'gender': _gender,
      'dob': _dob?.toIso8601String(),
      'pob': _pobCtrl.text.trim(),
      'parent_name': _parentNameCtrl.text.trim(),
      'parent_phone': _parentPhoneCtrl.text.trim(),
      'study_type': _studyType,
      'shift': _shift,
      'part_time_course': _studyType == 'Part-Time' ? _partTimeCourse : 'None',
      'classroom_id': (_selectedClassroomId == 0) ? null : _selectedClassroomId,
      'photo_url': _photoUrlCtrl.text.trim().isEmpty
          ? null
          : _photoUrlCtrl.text.trim(),
    };

    try {
      final url = widget.student != null
          ? '$baseUrl/students/${widget.student!['id']}'
          : '$baseUrl/students';
      final method = widget.student != null ? http.put : http.post;

      final res = await method(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode(payload),
      );

      String responseBody = utf8.decode(res.bodyBytes);
      dynamic data;
      try {
        data = jsonDecode(responseBody);
      } catch (e) {
        throw Exception('Server returned invalid JSON: $responseBody');
      }

      if ((res.statusCode == 200 || res.statusCode == 201) &&
          data['success'] == true) {
        if (!mounted) return;
        Navigator.pop(context);
        widget.onSaved();
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
                Text(
                  data['message'] ?? 'បានរក្សាទុកជោគជ័យ!',
                  style: const TextStyle(
                    fontFamily: 'Khmer OS Battambang',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['error'] ?? 'បរាជ័យក្នុងការរក្សាទុក!'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('កំហុស Server: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.student != null;
    final classroomItems = _buildClassroomItems();
    final effectiveClassroomId = _getEffectiveClassroomId(classroomItems);

    final validGenders = ['Female', 'Male'];
    final effectiveGender = validGenders.contains(_gender) ? _gender : 'Female';

    final validShifts = ['Morning', 'Afternoon', 'Both'];
    final effectiveShift = validShifts.contains(_shift) ? _shift : 'Morning';

    final validCourses = ['Computer', 'English', 'Chinese'];
    final effectiveCourse = validCourses.contains(_partTimeCourse)
        ? _partTimeCourse
        : 'Computer';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: MediaQuery.of(context).size.width > 780
            ? 740
            : MediaQuery.of(context).size.width * 0.95,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 740,
        ),
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF3730A3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x334F46E5),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing
                              ? 'កែប្រែព័ត៌មានសិស្ស (Edit Student Profile)'
                              : 'ចុះឈ្មោះសិស្សថ្មី (Student Registration)',
                          style: GoogleFonts.notoSansKhmer(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'សាលាប្រាយឡាយ • Bright Light School',
                          style: GoogleFonts.notoSansKhmer(
                            fontSize: 11.5,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF94A3B8),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24, color: Color(0xFFE2E8F0)),

              // Scrollable Body
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo Upload & Preview
                      WebPhotoUploader(
                        photoController: _photoUrlCtrl,
                        title: 'រូបថតសិស្ស (Student Photo):',
                      ),
                      const SizedBox(height: 18),

                      // Code & Khmer Name
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _codeCtrl,
                              label: 'អត្តលេខសិស្ស (Student ID)',
                              icon: Icons.tag_rounded,
                              readOnly: true,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildTextField(
                              controller: _nameKhCtrl,
                              label: 'ឈ្មោះខ្មែរ (Khmer Name) *',
                              icon: Icons.person_rounded,
                              validator: (v) => v!.trim().isEmpty
                                  ? 'សូមបញ្ចូលឈ្មោះជាភាសាខ្មែរ'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // English Name & Gender
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _nameEnCtrl,
                              label: 'ឈ្មោះឡាតាំង (English Name)',
                              icon: Icons.translate_rounded,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              // ignore: deprecated_member_use
                              value: effectiveGender,
                              decoration: _inputStyle(
                                'ភេទ (Gender)',
                                Icons.transgender_rounded,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Female',
                                  child: Text('ស្រី (Female)'),
                                ),
                                DropdownMenuItem(
                                  value: 'Male',
                                  child: Text('ប្រុស (Male)'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _gender = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // DOB & POB
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context),
                              borderRadius: BorderRadius.circular(10),
                              child: InputDecorator(
                                decoration: _inputStyle(
                                  'ថ្ងៃខែឆ្នាំកំណើត (DOB)',
                                  Icons.cake_rounded,
                                ),
                                child: Text(
                                  _dob == null
                                      ? 'ជ្រើសរើសថ្ងៃ...'
                                      : DateFormat('dd/MM/yyyy').format(_dob!),
                                  style: GoogleFonts.notoSansKhmer(
                                    fontSize: 13,
                                    color: _dob == null
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildTextField(
                              controller: _pobCtrl,
                              label: 'ទីកន្លែងកំណើត (POB)',
                              icon: Icons.location_on_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Study Type Choice Chips
                      Text(
                        'ប្រភេទការសិក្សា (Study Type):',
                        style: GoogleFonts.notoSansKhmer(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              avatar: Icon(
                                Icons.school_rounded,
                                size: 18,
                                color: _studyType == 'Full-Time'
                                    ? const Color(0xFF4F46E5)
                                    : const Color(0xFF64748B),
                              ),
                              label: Center(
                                child: Text('សិស្សពេញម៉ោង (ចំណេះទូទៅ)'),
                              ),
                              selected: _studyType == 'Full-Time',
                              selectedColor: const Color(0xFFEEF2FF),
                              backgroundColor: const Color(0xFFF8FAFC),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: _studyType == 'Full-Time'
                                      ? const Color(0xFF4F46E5)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              labelStyle: GoogleFonts.notoSansKhmer(
                                color: _studyType == 'Full-Time'
                                    ? const Color(0xFF4F46E5)
                                    : const Color(0xFF475569),
                                fontWeight: _studyType == 'Full-Time'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 12,
                              ),
                              onSelected: (_) =>
                                  setState(() => _studyType = 'Full-Time'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ChoiceChip(
                              avatar: Icon(
                                Icons.laptop_mac_rounded,
                                size: 18,
                                color: _studyType == 'Part-Time'
                                    ? const Color(0xFF0D9488)
                                    : const Color(0xFF64748B),
                              ),
                              label: Center(
                                child: Text('សិស្សក្រៅម៉ោង (Skill Courses)'),
                              ),
                              selected: _studyType == 'Part-Time',
                              selectedColor: const Color(0xFFCCFBF1),
                              backgroundColor: const Color(0xFFF8FAFC),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: _studyType == 'Part-Time'
                                      ? const Color(0xFF0D9488)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              labelStyle: GoogleFonts.notoSansKhmer(
                                color: _studyType == 'Part-Time'
                                    ? const Color(0xFF0D9488)
                                    : const Color(0xFF475569),
                                fontWeight: _studyType == 'Part-Time'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 12,
                              ),
                              onSelected: (_) =>
                                  setState(() => _studyType = 'Part-Time'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Shift / Course & Classroom Selection
                      if (_studyType == 'Full-Time')
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                // ignore: deprecated_member_use
                                value: effectiveShift,
                                decoration: _inputStyle(
                                  'វេនសិក្សា (Shift)',
                                  Icons.access_time_rounded,
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
                                  DropdownMenuItem(
                                    value: 'Both',
                                    child: Text(
                                      'ពេញមួយថ្ងៃ (Morning & Afternoon)',
                                    ),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v != null) setState(() => _shift = v);
                                },
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                // ignore: deprecated_member_use
                                value: effectiveClassroomId,
                                isExpanded: true,
                                decoration: _inputStyle(
                                  'បន្ទប់ថ្នាក់រៀន',
                                  Icons.meeting_room_outlined,
                                ),
                                items: classroomItems,
                                onChanged: (v) => setState(
                                  () => _selectedClassroomId = (v == 0
                                      ? null
                                      : v),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                // ignore: deprecated_member_use
                                value: effectiveCourse,
                                decoration: _inputStyle(
                                  'វគ្គសិក្សាក្រៅម៉ោង',
                                  Icons.menu_book_rounded,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Computer',
                                    child: Text(
                                      'ថ្នាក់កុំព្យូទ័ររដ្ឋបាល/បច្ចេកវិទ្យា',
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'English',
                                    child: Text(
                                      'ភាសាអង់គ្លេសទូទៅ (General English)',
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Chinese',
                                    child: Text('ភាសាចិន (Chinese Course)'),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _partTimeCourse = v);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                // ignore: deprecated_member_use
                                value: effectiveClassroomId,
                                isExpanded: true,
                                decoration: _inputStyle(
                                  'បន្ទប់សិក្សា',
                                  Icons.meeting_room_outlined,
                                ),
                                items: classroomItems,
                                onChanged: (v) => setState(
                                  () => _selectedClassroomId = (v == 0
                                      ? null
                                      : v),
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 14),

                      // Parent Name & Phone
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _parentNameCtrl,
                              label: 'ឈ្មោះអាណាព្យាបាល',
                              icon: Icons.family_restroom_rounded,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildTextField(
                              controller: _parentPhoneCtrl,
                              label: 'លេខទូរស័ព្ទអាណាព្យាបាល',
                              icon: Icons.phone_android_rounded,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // Actions (Cancel & Save)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'បោះបង់ (Cancel)',
                      style: GoogleFonts.notoSansKhmer(
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _isLoading ? null : _saveStudent,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      isEditing ? 'រក្សាទុកការកែប្រែ' : 'ចុះឈ្មោះសិស្ស',
                      style: GoogleFonts.notoSansKhmer(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
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
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontFamily: 'Khmer OS Battambang',
        fontSize: 12,
        color: Color(0xFF64748B),
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF4F46E5), size: 18),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool readOnly = false,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      validator: validator,
      onChanged: onChanged,
      style: const TextStyle(
        fontFamily: 'Khmer OS Battambang',
        fontSize: 13,
        color: Color(0xFF1E293B),
      ),
      decoration: _inputStyle(label, icon ?? Icons.edit).copyWith(
        fillColor: readOnly ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
      ),
    );
  }
}
