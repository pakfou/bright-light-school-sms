import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:school_management_app/config/api_config.dart';
import 'package:school_management_app/services/html_print_service.dart';
import 'package:school_management_app/utils/csv_exporter.dart';
import 'package:http/http.dart' as http;
import 'package:school_management_app/services/api_service.dart';
import 'package:school_management_app/widgets/app_avatar.dart';
import 'package:school_management_app/screens/teachers/teacher_modal.dart';

class TeachersManagerView extends StatefulWidget {
  const TeachersManagerView({super.key});

  @override
  State<TeachersManagerView> createState() => _TeachersManagerViewState();
}

class _TeachersManagerViewState extends State<TeachersManagerView> {
  static String get baseUrl => ApiService.baseUrl;
  List<dynamic> _teachers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterType = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchTeachers();
    });
  }

  Future<void> _fetchTeachers() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final res = await http
          .get(Uri.parse('$baseUrl/teachers'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final d = jsonDecode(utf8.decode(res.bodyBytes));
        if (mounted) {
          setState(() {
            _teachers = d['data'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
    if (_teachers.isEmpty && mounted) {
      setState(() {
        _teachers = [
          {
            'id': 1,
            'teacher_code': 'TCH-1001',
            'name_kh': 'ហាក់ ប៉ាក់ហ៊្វូរ',
            'name_en': 'Hak Pakfou',
            'gender': 'ប្រុស',
            'phone': '012 345 678',
            'subject': 'ភាសាខ្មែរ (Khmer)',
            'role': 'Admin / Teacher',
            'status': 'Active',
            'monthly_salary': 450.0,
          },
          {
            'id': 2,
            'teacher_code': 'TCH-1002',
            'name_kh': 'សន ចរិយា',
            'name_en': 'Sorn Chariya',
            'gender': 'ស្រី',
            'phone': '098 765 432',
            'subject': 'គណិតវិទ្យា (Math)',
            'role': 'Teacher',
            'status': 'Active',
            'monthly_salary': 400.0,
          },
          {
            'id': 3,
            'teacher_code': 'TCH-1003',
            'name_kh': 'ទូច ស្រីមុំ (Tous Sreymom)',
            'name_en': 'Touch Sreymom',
            'gender': 'ស្រី',
            'phone': '088 123 456',
            'subject': 'ភាសាអង់គ្លេស (Going Place 3)',
            'role': 'Teacher',
            'status': 'Active',
            'monthly_salary': 420.0,
          },
          {
            'id': 4,
            'teacher_code': 'TCH-1004',
            'name_kh': 'ភី ស្រីនុច (Phi Sreynuch)',
            'name_en': 'Phi Sreynuch',
            'gender': 'ស្រី',
            'phone': '097 654 321',
            'subject': 'ភាសាអង់គ្លេស (EFL 5A)',
            'role': 'Teacher',
            'status': 'Active',
            'monthly_salary': 420.0,
          },
          {
            'id': 5,
            'teacher_code': 'TCH-1005',
            'name_kh': 'រី ស្រីនាង (Ry Sreyneang)',
            'name_en': 'Ry Sreyneang',
            'gender': 'ស្រី',
            'phone': '077 889 900',
            'subject': 'ភាសាអង់គ្លេស (EFL 3B)',
            'role': 'Teacher',
            'status': 'Active',
            'monthly_salary': 400.0,
          },
        ];
        _isLoading = false;
      });
    }
  }

  void _printTeachersNative() {
    HtmlPrintService.printTeacherReport(_teachers);
  }

  void _exportCSV() {
    final buf = StringBuffer();
    buf.writeln(
      '\uFEFFអត្តលេខ,ឈ្មោះខ្មែរ,ឈ្មោះឡាតាំង,ភេទ,ថ្ងៃខែឆ្នាំកំណើត,ទូរស័ព្ទ,មុខវិជ្ជាឯកទេស,ប្រាក់ខែគោល,ថ្ងៃចូលធ្វើការ,ស្ថានភាព',
    );
    for (var t in _teachers) {
      final dob = (t['dob'] ?? '').toString().split('T')[0];
      final hireDate = (t['hire_date'] ?? t['joined_date'] ?? '').toString().split('T')[0];
      buf.writeln(
        '${t['teacher_code']},"${t['name_kh']}","${t['name_en']}",${t['gender']},$dob,${t['phone'] ?? ''},"${t['specialized_subject'] ?? ''}",${t['base_salary'] ?? 0},$hireDate,${t['status'] ?? 'Active'}',
      );
    }
    downloadCsv(buf.toString(), 'teachers_data.csv');
  }

  Future<void> _deleteTeacher(int id, String name) async {
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
          'តើអ្នកពិតជាចង់លុបទិន្នន័យគ្រូបង្រៀន "$name" មែនទេ?\nសកម្មភាពនេះមិនអាចត្រឡប់វិញបានទេ។',
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
    if (ok == true) {
      if (ApiConfig.isDemoMode) {
        setState(() {
          _teachers.removeWhere((t) => t['id'] == id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('បានលុបជោគជ័យ! (Demo Mode)'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
        return;
      }
      try {
        final res = await http.delete(Uri.parse('$baseUrl/teachers/$id')).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          _fetchTeachers();
        } else {
          setState(() => _teachers.removeWhere((t) => t['id'] == id));
        }
      } catch (_) {
        ApiConfig.isDemoMode = true;
        setState(() => _teachers.removeWhere((t) => t['id'] == id));
      }
      if (mounted) {
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

  void _openDetails(Map<String, dynamic> t) {
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
                      'ព័ត៌មានលម្អិតគ្រូបង្រៀន',
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
                  photoUrl: t['photo_url'],
                  radius: 50,
                  fallbackText: t['name_kh'] ?? '',
                ),
                const SizedBox(height: 16),
                Text(
                  '${t['name_kh']} (${t['teacher_code']})',
                  style: const TextStyle(
                    fontFamily: 'Khmer OS Muol Light',
                    fontSize: 18,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  t['name_en'] ?? '-',
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
                        t['gender'] == 'Male' ? 'ប្រុស (Male)' : 'ស្រី (Female)',
                        Icons.person_outline,
                      ),
                      const Divider(height: 24, color: Color(0xFFE2E8F0)),
                      _row(
                        'ថ្ងៃខែឆ្នាំកំណើត',
                        _formatDate(t['dob']),
                        Icons.cake_outlined,
                      ),
                      const Divider(height: 24, color: Color(0xFFE2E8F0)),
                      _row(
                        'លេខទូរស័ព្ទ',
                        (t['phone'] != null && t['phone'].toString().trim().isNotEmpty)
                            ? t['phone'].toString().trim()
                            : '-',
                        Icons.phone_outlined,
                      ),
                      const Divider(height: 24, color: Color(0xFFE2E8F0)),
                      _row(
                        'មុខវិជ្ជាឯកទេស',
                        (t['specialized_subject'] != null &&
                                t['specialized_subject'].toString().trim().isNotEmpty)
                            ? t['specialized_subject'].toString().trim()
                            : '-',
                        Icons.book_outlined,
                      ),
                      const Divider(height: 24, color: Color(0xFFE2E8F0)),
                      _row(
                        'ថ្ងៃចូលបម្រើការ',
                        _formatDate(t['hire_date'] ?? t['joined_date']),
                        Icons.calendar_month_outlined,
                      ),
                      const Divider(height: 24, color: Color(0xFFE2E8F0)),
                      _row(
                        'ប្រាក់ខែគោល',
                        '\$${t['base_salary'] ?? 0}',
                        Icons.monetization_on_outlined,
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

  String _formatDate(dynamic d) {
    if (d == null) return '-';
    final s = d.toString().split('T')[0].trim();
    return (s.isEmpty || s == 'null') ? '-' : s;
  }

  Widget _row(String label, String value, IconData icon) {
    return Row(
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

  void _openModal([Map<String, dynamic>? teacher]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => TeacherModal(teacher: teacher, onSaved: _fetchTeachers),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _teachers.where((t) {
      final q = _searchQuery.toLowerCase();
      final matchSearch =
          (t['name_kh'] ?? '').toString().toLowerCase().contains(q) ||
          (t['teacher_code'] ?? '').toString().toLowerCase().contains(q) ||
          (t['name_en'] ?? '').toString().toLowerCase().contains(q);
      final matchType = _filterType == 'All' || t['status'] == _filterType;
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
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.co_present_rounded,
                                color: Color(0xFFEF4444),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'គ្រប់គ្រងគ្រូបង្រៀន',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Khmer OS Muol Light',
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  Text(
                                    'បញ្ជីឈ្មោះបុគ្គលិកអប់រំទូទៅ',
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
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(Icons.print_rounded, size: 18),
                                label: const Text(
                                  'Print',
                                  style: TextStyle(
                                    fontFamily: 'Khmer OS Battambang',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                onPressed: _printTeachersNative,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF1E293B),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(Icons.download_rounded, size: 18),
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
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF4444),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(Icons.person_add_rounded, size: 18),
                                label: const Text(
                                  'ថ្មី',
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
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.co_present_rounded,
                                color: Color(0xFFEF4444),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'គ្រប់គ្រងគ្រូបង្រៀន (Teachers Management)',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Khmer OS Muol Light',
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'បញ្ជីឈ្មោះ និងព័ត៌មានបុគ្គលិកអប់រំទូទៅ',
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
                              icon: const Icon(Icons.print_rounded, size: 20),
                              label: const Text(
                                'បោះពុម្ព (Print)',
                                style: TextStyle(
                                  fontFamily: 'Khmer OS Battambang',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: _printTeachersNative,
                            ),
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
                                backgroundColor: const Color(0xFFEF4444),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.person_add_rounded, size: 20),
                              label: const Text(
                                'ចុះឈ្មោះគ្រូថ្មី',
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
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          hintText: 'ស្វែងរកគ្រូបង្រៀន...',
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
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
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
                              _buildFilterBtn('សកម្ម', 'Active'),
                              _buildFilterBtn('ឈប់សម្រាក', 'On Leave'),
                              _buildFilterBtn('ព្យួរការងារ', 'Suspended'),
                              _buildFilterBtn('អសកម្ម', 'Inactive'),
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
                              onChanged: (v) => setState(() => _searchQuery = v),
                              decoration: InputDecoration(
                                hintText: 'ស្វែងរកគ្រូបង្រៀនតាមឈ្មោះ ឬកូដសម្គាល់...',
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
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
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
                                    _buildFilterBtn('សកម្ម (Active)', 'Active'),
                                    _buildFilterBtn('ឈប់សម្រាក (On Leave)', 'On Leave'),
                                    _buildFilterBtn('ព្យួរការងារ (Suspended)', 'Suspended'),
                                    _buildFilterBtn('អសកម្ម (Inactive)', 'Inactive'),
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
                              onChanged: (v) => setState(() => _searchQuery = v),
                              decoration: InputDecoration(
                                hintText: 'ស្វែងរកគ្រូបង្រៀនតាមឈ្មោះ ឬកូដសម្គាល់...',
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
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
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
                                _buildFilterBtn('សកម្ម (Active)', 'Active'),
                                _buildFilterBtn('ឈប់សម្រាក (On Leave)', 'On Leave'),
                                _buildFilterBtn('ព្យួរការងារ (Suspended)', 'Suspended'),
                                _buildFilterBtn('អសកម្ម (Inactive)', 'Inactive'),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
            const SizedBox(height: 16),
            // Data Table Section
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFEF4444),
                      ),
                    )
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              const Text(
                                'រកមិនឃើញទិន្នន័យគ្រូបង្រៀនទេ',
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
                                final t = filtered[i];
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
                                            photoUrl: t['photo_url'],
                                            radius: 22,
                                            fallbackText: t['name_kh'] ?? '',
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  t['name_kh'] ?? '-',
                                                  style: const TextStyle(
                                                    fontFamily: 'Khmer OS Muol Light',
                                                    fontSize: 14,
                                                    color: Color(0xFF1E293B),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${t['teacher_code'] ?? '-'} • ${t['name_en'] ?? ''}',
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
                                          _buildStatusBadge(t['status']),
                                        ],
                                      ),
                                      const Divider(height: 18, color: Color(0xFFF1F5F9)),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFEEF2FF),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    t['specialized_subject'] ?? 'ទូទៅ',
                                                    style: const TextStyle(
                                                      fontFamily: 'Khmer OS Battambang',
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF4F46E5),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  t['gender'] == 'Male' ? 'ប្រុស' : 'ស្រី',
                                                  style: const TextStyle(
                                                    fontFamily: 'Khmer OS Battambang',
                                                    fontSize: 12,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            'ប្រាក់ខែ: \$${t['base_salary'] ?? 0}',
                                            style: const TextStyle(
                                              fontFamily: 'Calibri Light',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'ទូរស័ព្ទ: ${t['phone'] ?? '-'}',
                                            style: const TextStyle(
                                              fontFamily: 'Calibri Light',
                                              fontSize: 12,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              _actionBtn(
                                                Icons.visibility_outlined,
                                                const Color(0xFF4F46E5),
                                                () => _openDetails(t),
                                              ),
                                              const SizedBox(width: 8),
                                              _actionBtn(
                                                Icons.edit_outlined,
                                                const Color(0xFFF59E0B),
                                                () => _openModal(t),
                                              ),
                                              const SizedBox(width: 8),
                                              _actionBtn(
                                                Icons.delete_outline_rounded,
                                                const Color(0xFFEF4444),
                                                () => _deleteTeacher(
                                                  t['id'],
                                                  t['name_kh'],
                                                ),
                                              ),
                                            ],
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
                                        width: constraints.maxWidth < 920 ? 920 : constraints.maxWidth,
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
                                                  _headerCol('ឈ្មោះគ្រូ', 2),
                                                  _headerCol('ភេទ', 1),
                                                  _headerCol('មុខវិជ្ជាឯកទេស', 2),
                                                  _headerCol('ទំនាក់ទំនង', 2),
                                                  _headerCol('ប្រាក់ខែ/ស្ថានភាព', 2),
                                                  _headerCol(
                                                    'សកម្មភាព',
                                                    2,
                                                    align: TextAlign.right,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Divider(height: 1, color: Color(0xFFE2E8F0)),
                                            Expanded(
                                              child: ListView.separated(
                                                itemCount: filtered.length,
                                                separatorBuilder: (_, index) => const Divider(
                                                  height: 1,
                                                  color: Color(0xFFF1F5F9),
                                                ),
                                                itemBuilder: (ctx, i) {
                                                  final t = filtered[i];
                                                  // ignore: unused_local_variable
                                                  final isActive = t['status'] != 'Suspended';
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
                                                                photoUrl: t['photo_url'],
                                                                radius: 20,
                                                                fallbackText:
                                                                    t['name_kh'] ?? '',
                                                              ),
                                                              const SizedBox(width: 12),
                                                              Text(
                                                                t['teacher_code'] ?? '-',
                                                                style: const TextStyle(
                                                                  fontWeight: FontWeight.bold,
                                                                  color: Color(0xFF475569),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        Expanded(
                                                          flex: 2,
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                t['name_kh'] ?? '-',
                                                                style: const TextStyle(
                                                                  fontFamily:
                                                                      'Khmer OS Battambang',
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 14,
                                                                  color: Color(0xFF1E293B),
                                                                ),
                                                              ),
                                                              Text(
                                                                t['name_en'] ?? '',
                                                                style: const TextStyle(
                                                                  fontSize: 12,
                                                                  color: Color(0xFF64748B),
                                                                ),
                                                              ),
                                                            ],
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
                                                              color: const Color(0xFFF1F5F9),
                                                              borderRadius:
                                                                  BorderRadius.circular(4),
                                                            ),
                                                            child: Text(
                                                              t['gender'] == 'Male'
                                                                  ? 'ប្រុស'
                                                                  : 'ស្រី',
                                                              textAlign: TextAlign.center,
                                                              style: const TextStyle(
                                                                fontFamily:
                                                                    'Khmer OS Battambang',
                                                                fontSize: 12,
                                                                color: Color(0xFF475569),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        Expanded(
                                                          flex: 2,
                                                          child: Text(
                                                            t['specialized_subject'] ?? 'ទូទៅ',
                                                            style: const TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              color: Color(0xFF3B82F6),
                                                              fontFamily: 'Khmer OS Battambang',
                                                            ),
                                                          ),
                                                        ),
                                                        Expanded(
                                                          flex: 2,
                                                          child: Text(
                                                            '${t['phone'] ?? '-'}',
                                                            style: const TextStyle(
                                                              color: Color(0xFF475569),
                                                            ),
                                                          ),
                                                        ),
                                                        Expanded(
                                                          flex: 2,
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                '\$${t['base_salary'] ?? 0}',
                                                                style: const TextStyle(
                                                                  fontWeight: FontWeight.bold,
                                                                  color: Color(0xFF1E293B),
                                                                ),
                                                              ),
                                                              const SizedBox(height: 4),
                                                              _buildStatusBadge(t['status']),
                                                            ],
                                                          ),
                                                        ),
                                                        Expanded(
                                                          flex: 2,
                                                          child: FittedBox(
                                                            fit: BoxFit.scaleDown,
                                                            alignment: Alignment.centerRight,
                                                            child: Row(
                                                              mainAxisSize: MainAxisSize.min,
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment.end,
                                                              children: [
                                                                _actionBtn(
                                                                  Icons.visibility_outlined,
                                                                  const Color(0xFF4F46E5),
                                                                  () => _openDetails(t),
                                                                ),
                                                                const SizedBox(width: 6),
                                                                _actionBtn(
                                                                  Icons.edit_outlined,
                                                                  const Color(0xFFF59E0B),
                                                                  () => _openModal(t),
                                                                ),
                                                                const SizedBox(width: 6),
                                                                _actionBtn(
                                                                  Icons.delete_outline_rounded,
                                                                  const Color(0xFFEF4444),
                                                                  () => _deleteTeacher(
                                                                    t['id'],
                                                                    t['name_kh'],
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
          color: isSelected ? const Color(0xFFEF4444) : Colors.transparent,
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

  // ignore: unused_element
  Widget _buildStatusBadge(dynamic status) {
    final s = (status ?? 'Active').toString();
    Color bgColor;
    Color textColor;
    Color dotColor;
    String label;

    switch (s) {
      case 'Active':
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF16A34A);
        dotColor = const Color(0xFF16A34A);
        label = 'សកម្ម';
        break;
      case 'On Leave':
        bgColor = const Color(0xFFFEF9C3);
        textColor = const Color(0xFFCA8A04);
        dotColor = const Color(0xFFEAB308);
        label = 'ឈប់សម្រាក';
        break;
      case 'Suspended':
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFDC2626);
        dotColor = const Color(0xFFEF4444);
        label = 'ផ្អាកការងារ';
        break;
      case 'Inactive':
      default:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF64748B);
        dotColor = const Color(0xFF94A3B8);
        label = 'អសកម្ម';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Khmer OS Battambang',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
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
}
