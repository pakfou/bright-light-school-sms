import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:school_management_app/utils/csv_exporter.dart';
import 'package:http/http.dart' as http;
import 'package:school_management_app/services/api_service.dart';
import 'package:school_management_app/widgets/app_avatar.dart';
// ignore: unused_import
import 'package:school_management_app/screens/students/student_modal.dart';

class StudentsManagerView extends StatefulWidget {
  const StudentsManagerView({super.key});

  @override
  State<StudentsManagerView> createState() => _StudentsManagerViewState();
}

class _StudentsManagerViewState extends State<StudentsManagerView> {
  static String get baseUrl => ApiService.baseUrl;
  List<dynamic> _students = [];
  bool _isLoading = true;
  String _search = '';
  String _filterType = 'All';

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse('$baseUrl/students')).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final d = jsonDecode(utf8.decode(res.bodyBytes));
        setState(() => _students = d['data'] ?? []);
      }
    } catch (_) {}
    if (_students.isEmpty && mounted) {
      setState(() {
        _students = [
          {
            'id': 1,
            'student_code': 'BL-2026-001',
            'name_kh': 'សុខ មករា',
            'name_en': 'Sok Makara',
            'gender': 'ប្រុស',
            'study_type': 'Full-Time',
            'shift': 'Morning',
            'class_name': 'ថ្នាក់ទី ១A',
            'classroom_id': 1,
            'phone': '012 345 678',
            'parent_name': 'សុខ សំបូរ',
            'parent_phone': '012 345 678',
            'address': 'ភូមិ១ សង្កាត់បាត់ដំបង',
            'status': 'Active',
          },
          {
            'id': 2,
            'student_code': 'BL-2026-002',
            'name_kh': 'ចាន់ ធារី',
            'name_en': 'Chan Theary',
            'gender': 'ស្រី',
            'study_type': 'Full-Time',
            'shift': 'Morning',
            'class_name': 'ថ្នាក់ទី ២A',
            'classroom_id': 2,
            'phone': '098 765 432',
            'parent_name': 'ចាន់ រតនា',
            'parent_phone': '098 765 432',
            'address': 'ភូមិព្រែកព្រះស្តេច',
            'status': 'Active',
          },
          {
            'id': 3,
            'student_code': 'BL-2026-003',
            'name_kh': 'រ៉េត ពិសិដ្ឋ',
            'name_en': 'Reth Piseth',
            'gender': 'ប្រុស',
            'study_type': 'Part-Time',
            'shift': 'Afternoon',
            'class_name': '02 (EFL 5A)',
            'classroom_id': 24,
            'phone': '088 112 233',
            'parent_name': 'រ៉េត សុខា',
            'parent_phone': '088 112 233',
            'address': 'សង្កាត់ស្វាយប៉ោ',
            'status': 'Active',
          },
          {
            'id': 4,
            'student_code': 'BL-2026-004',
            'name_kh': 'វ៉ាន់ ស្រីម៉ៅ',
            'name_en': 'Vann Sreymao',
            'gender': 'ស្រី',
            'study_type': 'Part-Time',
            'shift': 'Afternoon',
            'class_name': '01 (EFL 3B)',
            'classroom_id': 23,
            'phone': '097 554 433',
            'parent_name': 'វ៉ាន់ ចិន្តា',
            'parent_phone': '097 554 433',
            'address': 'ភូមិអូរដំបង',
            'status': 'Active',
          },
          {
            'id': 5,
            'student_code': 'BL-2026-005',
            'name_kh': 'គឹម សីហា',
            'name_en': 'Kim Seyha',
            'gender': 'ប្រុស',
            'study_type': 'Part-Time',
            'shift': 'Afternoon',
            'class_name': '05 (Going Place 3)',
            'classroom_id': 25,
            'phone': '077 889 900',
            'parent_name': 'គឹម សុផល',
            'parent_phone': '077 889 900',
            'address': 'សង្កាត់រតនៈ',
            'status': 'Active',
          },
        ];
      });
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _exportCSV() {
    final buf = StringBuffer();
    buf.writeln(
      '\uFEFFអត្តលេខ,ឈ្មោះខ្មែរ,ឈ្មោះឡាតាំង,ភេទ,ប្រភេទសិក្សា,វេន/វគ្គ,ថ្នាក់រៀន,ទូរស័ព្ទអាណាព្យាបាល',
    );
    for (var s in _students) {
      buf.writeln(
        '${s['student_code']},"${s['name_kh']}","${s['name_en']}",${s['gender']},${s['study_type']},${s['shift'] ?? s['part_time_course']},"${s['class_name'] ?? ''}","${s['parent_phone'] ?? ''}"',
      );
    }
    downloadCsv(buf.toString(), 'students_data.csv');
  }

  Future<void> _deleteStudent(int id, String name) async {
    final ok = await showDialog<bool>(
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
          'តើអ្នកចង់លុបទិន្នន័យសិស្ស "$name" មែនទេ? \nសកម្មភាពនេះមិនអាចត្រឡប់វិញបានទេ។',
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
              'លុប',
              style: TextStyle(
                fontFamily: 'Khmer OS Battambang',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      final res = await http.delete(Uri.parse('$baseUrl/students/$id'));
      if (res.statusCode == 200) {
        _fetchStudents();
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'បានលុបជោគជ័យ!',
                  style: TextStyle(fontFamily: 'Khmer OS Battambang'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _openDetails(Map<String, dynamic> s) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 480,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.88,
            maxWidth: 480,
          ),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ព័ត៌មានលម្អិតសិស្ស',
                      style: TextStyle(
                        fontFamily: 'Khmer OS Muol Light',
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                AppAvatar(
                  photoUrl: s['photo_url'],
                  radius: 50,
                  fallbackText: s['name_kh'] ?? '',
                ),
                const SizedBox(height: 16),
                Text(
                  '${s['name_kh']} (${s['student_code']})',
                  style: const TextStyle(
                    fontFamily: 'Khmer OS Muol Light',
                    fontSize: 18,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  s['name_en'] ?? '-',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _row(
                        'ភេទ',
                        s['gender'] == 'Male' ? 'ប្រុស (Male)' : 'ស្រី (Female)',
                        Icons.person_outline,
                      ),
                      const Divider(height: 24, color: Color(0xFFE2E8F0)),
                      _row(
                        'ថ្ងៃខែឆ្នាំកំណើត',
                        s['dob'] ?? '-',
                        Icons.cake_outlined,
                      ),
                      const Divider(height: 24, color: Color(0xFFE2E8F0)),
                      _row(
                        'ថ្នាក់រៀន',
                        s['class_name'] ?? 'ទូទៅ',
                        Icons.class_outlined,
                      ),
                      const Divider(height: 24, color: Color(0xFFE2E8F0)),
                      _row(
                        'ប្រភេទសិក្សា',
                        '${s['study_type']} (${s['study_type'] == 'Full-Time' ? s['shift'] : s['part_time_course']})',
                        Icons.school_outlined,
                      ),
                      const Divider(height: 24, color: Color(0xFFE2E8F0)),
                      _row(
                        'អាណាព្យាបាល',
                        '${s['parent_name'] ?? '-'} (${s['parent_phone'] ?? '-'})',
                        Icons.family_restroom_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'បិទ (Close)',
                      style: TextStyle(
                        fontFamily: 'Khmer OS Battambang',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF64748B)),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Khmer OS Battambang',
            fontSize: 13,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'Khmer OS Battambang',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _students.where((s) {
      final q = _search.toLowerCase();
      final matchSearch =
          (s['name_kh'] ?? '').toString().toLowerCase().contains(q) ||
          (s['student_code'] ?? '').toString().toLowerCase().contains(q) ||
          (s['name_en'] ?? '').toString().toLowerCase().contains(q);
      final matchType = _filterType == 'All' || s['study_type'] == _filterType;
      return matchSearch && matchType;
    }).toList();

    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 28),
        child: Column(
          children: [
            // Header Section
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.people_alt,
                                color: Color(0xFF4F46E5),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'គ្រប់គ្រងសិស្សានុសិស្ស',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Khmer OS Muol Light',
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  Text(
                                    'សិស្សពេញម៉ោង និងក្រៅម៉ោង',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 12,
                                      fontFamily: 'Khmer OS Battambang',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF1E293B),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.download_rounded,
                                  size: 18,
                                ),
                                label: const Text(
                                  'CSV',
                                  style: TextStyle(
                                    fontFamily: 'Khmer OS Battambang',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                onPressed: _exportCSV,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4F46E5),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.person_add_rounded,
                                  size: 18,
                                ),
                                label: const Text(
                                  'ចុះឈ្មោះថ្មី',
                                  style: TextStyle(
                                    fontFamily: 'Khmer OS Battambang',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                onPressed: () => _openModal(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 16,
                      runSpacing: 14,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.people_alt,
                                color: Color(0xFF4F46E5),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'គ្រប់គ្រងសិស្សានុសិស្ស (Students Management)',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Khmer OS Muol Light',
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'បែងចែកសិស្សពេញម៉ោង (ចំណេះទូទៅ) និង ក្រៅម៉ោង (Skill Courses)',
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
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1E293B),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(
                                Icons.download_rounded,
                                size: 20,
                              ),
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
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(
                                Icons.person_add_rounded,
                                size: 20,
                              ),
                              label: const Text(
                                'ចុះឈ្មោះសិស្សថ្មី',
                                style: TextStyle(
                                  fontFamily: 'Khmer OS Battambang',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () => _openModal(),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            // Filters Section
            isMobile
                ? Column(
                    children: [
                      TextField(
                        onChanged: (v) => setState(() => _search = v),
                        decoration: InputDecoration(
                          hintText: 'ស្វែងរកសិស្សតាមឈ្មោះ ឬកូដសម្គាល់...',
                          hintStyle: const TextStyle(
                            fontFamily: 'Khmer OS Battambang',
                            color: Color(0xFF94A3B8),
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF94A3B8),
                            size: 20,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
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
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              _buildFilterBtn('ទាំងអស់', 'All'),
                              _buildFilterBtn('ពេញម៉ោង', 'Full-Time'),
                              _buildFilterBtn('ក្រៅម៉ោង', 'Part-Time'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : LayoutBuilder(
                    builder: (context, filterConstraints) {
                      final isNarrow = filterConstraints.maxWidth < 750;
                      if (isNarrow) {
                        return Column(
                          children: [
                            TextField(
                              onChanged: (v) => setState(() => _search = v),
                              decoration: InputDecoration(
                                hintText: 'ស្វែងរកសិស្សតាមឈ្មោះ ឬកូដសម្គាល់...',
                                hintStyle: const TextStyle(
                                  fontFamily: 'Khmer OS Battambang',
                                  color: Color(0xFF94A3B8),
                                  fontSize: 14,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Color(0xFF94A3B8),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
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
                            const SizedBox(height: 10),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildFilterBtn('ទាំងអស់ (All)', 'All'),
                                    _buildFilterBtn('ពេញម៉ោង (Full-Time)', 'Full-Time'),
                                    _buildFilterBtn(
                                      'ក្រៅម៉ោង (Part-Time)',
                                      'Part-Time',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onChanged: (v) => setState(() => _search = v),
                              decoration: InputDecoration(
                                hintText: 'ស្វែងរកសិស្សតាមឈ្មោះ ឬកូដសម្គាល់...',
                                hintStyle: const TextStyle(
                                  fontFamily: 'Khmer OS Battambang',
                                  color: Color(0xFF94A3B8),
                                  fontSize: 14,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Color(0xFF94A3B8),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
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
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildFilterBtn('ទាំងអស់ (All)', 'All'),
                                _buildFilterBtn('ពេញម៉ោង (Full-Time)', 'Full-Time'),
                                _buildFilterBtn(
                                  'ក្រៅម៉ោង (Part-Time)',
                                  'Part-Time',
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
            const SizedBox(height: 16),
            // Data Section (Cards for mobile, Table for desktop)
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4F46E5),
                      ),
                    )
                  : filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 56,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'រកមិនឃើញទិន្នន័យសិស្សទេ',
                            style: TextStyle(
                              fontFamily: 'Khmer OS Battambang',
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    )
                  : isMobile
                  ? ListView.separated(
                      itemCount: filtered.length,
                      // ignore: unnecessary_underscores
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        final s = filtered[i];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x040F172A),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  AppAvatar(
                                    photoUrl: s['photo_url'],
                                    radius: 22,
                                    fallbackText: s['name_kh'] ?? '',
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s['name_kh'] ?? '-',
                                          style: const TextStyle(
                                            fontFamily: 'Khmer OS Muol Light',
                                            fontSize: 14,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${s['student_code']} • ${s['name_en'] ?? ''}',
                                          style: const TextStyle(
                                            fontFamily: 'Calibri Light',
                                            fontSize: 12,
                                            color: Color(0xFF64748B),
                                            fontWeight: FontWeight.w600,
                                          ),
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
                                      color: s['study_type'] == 'Full-Time'
                                          ? const Color(0xFFEEF2FF)
                                          : const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      s['study_type'] == 'Full-Time'
                                          ? 'ពេញម៉ោង'
                                          : 'ក្រៅម៉ោង',
                                      style: TextStyle(
                                        fontFamily: 'Khmer OS Battambang',
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: s['study_type'] == 'Full-Time'
                                            ? const Color(0xFF4F46E5)
                                            : const Color(0xFFD97706),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(
                                height: 18,
                                color: Color(0xFFF1F5F9),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'ថ្នាក់: ${s['class_name'] ?? 'ទូទៅ'}',
                                      style: const TextStyle(
                                        fontFamily: 'Khmer OS Battambang',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'ទូរស័ព្ទ: ${s['parent_phone'] ?? '-'}',
                                    style: const TextStyle(
                                      fontFamily: 'Calibri Light',
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  _actionBtn(
                                    Icons.visibility_outlined,
                                    const Color(0xFF4F46E5),
                                    () => _openDetails(s),
                                  ),
                                  const SizedBox(width: 8),
                                  _actionBtn(
                                    Icons.edit_outlined,
                                    const Color(0xFFF59E0B),
                                    () => _openModal(s),
                                  ),
                                  const SizedBox(width: 8),
                                  _actionBtn(
                                    Icons.delete_outline_rounded,
                                    const Color(0xFFEF4444),
                                    () => _deleteStudent(
                                      s['id'],
                                      s['name_kh'] ?? '',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: constraints.maxWidth < 880
                                    ? 880
                                    : constraints.maxWidth,
                                child: Column(
                                  children: [
                                    Container(
                                      color: const Color(0xFFF8FAFC),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 16,
                                      ),
                                      child: Row(
                                        children: [
                                          _headerCol('អត្តលេខ/រូបភាព', 2),
                                          _headerCol('ឈ្មោះសិស្ស', 2),
                                          _headerCol('ភេទ', 1),
                                          _headerCol('ថ្នាក់/ប្រភេទ', 2),
                                          _headerCol('ទំនាក់ទំនង', 2),
                                          _headerCol(
                                            'សកម្មភាព',
                                            2,
                                            align: TextAlign.right,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(
                                      height: 1,
                                      color: Color(0xFFE2E8F0),
                                    ),
                                    Expanded(
                                      child: ListView.separated(
                                        itemCount: filtered.length,
                                        // ignore: unnecessary_underscores
                                        separatorBuilder: (_, __) =>
                                            const Divider(
                                              height: 1,
                                              color: Color(0xFFF1F5F9),
                                            ),
                                        itemBuilder: (ctx, i) {
                                          final s = filtered[i];
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
                                                      AppAvatar(
                                                        photoUrl:
                                                            s['photo_url'],
                                                        radius: 20,
                                                        fallbackText:
                                                            s['name_kh'] ?? '',
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Text(
                                                        s['student_code'] ??
                                                            '-',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Color(
                                                            0xFF475569,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        s['name_kh'] ?? '-',
                                                        style: const TextStyle(
                                                          fontFamily:
                                                              'Khmer OS Battambang',
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14,
                                                          color: Color(
                                                            0xFF1E293B,
                                                          ),
                                                        ),
                                                      ),
                                                      Text(
                                                        s['name_en'] ?? '',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Color(
                                                            0xFF64748B,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFF1F5F9,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      s['gender'] == 'Male'
                                                          ? 'ប្រុស'
                                                          : 'ស្រី',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: const TextStyle(
                                                        fontFamily:
                                                            'Khmer OS Battambang',
                                                        fontSize: 12,
                                                        color: Color(
                                                          0xFF475569,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        s['class_name'] ??
                                                            'ទូទៅ',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Color(
                                                            0xFF3B82F6,
                                                          ),
                                                          fontFamily:
                                                              'Khmer OS Battambang',
                                                        ),
                                                      ),
                                                      Text(
                                                        '${s['study_type']}',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Color(
                                                            0xFF64748B,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    '${s['parent_phone'] ?? '-'}',
                                                    style: const TextStyle(
                                                      color: Color(0xFF475569),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    alignment:
                                                        Alignment.centerRight,
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.end,
                                                      children: [
                                                        _actionBtn(
                                                          Icons
                                                              .visibility_outlined,
                                                          const Color(
                                                            0xFF4F46E5,
                                                          ),
                                                          () => _openDetails(s),
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        _actionBtn(
                                                          Icons.edit_outlined,
                                                          const Color(
                                                            0xFFF59E0B,
                                                          ),
                                                          () => _openModal(s),
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        _actionBtn(
                                                          Icons
                                                              .delete_outline_rounded,
                                                          const Color(
                                                            0xFFEF4444,
                                                          ),
                                                          () => _deleteStudent(
                                                            s['id'],
                                                            s['name_kh'],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
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
                          },
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBtn(String label, String value) {
    final isSelected = _filterType == value;
    return InkWell(
      onTap: () => setState(() => _filterType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Khmer OS Battambang',
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
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
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  void _openModal([Map<String, dynamic>? student]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StudentModal(student: student, onSaved: _fetchStudents),
    );
  }
}
