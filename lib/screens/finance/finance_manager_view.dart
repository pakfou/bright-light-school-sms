import 'package:school_management_app/services/api_service.dart';
import 'package:school_management_app/services/html_print_service.dart';
import 'package:school_management_app/utils/csv_exporter.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FinanceManagerView extends StatefulWidget {
  const FinanceManagerView({super.key});

  @override
  State<FinanceManagerView> createState() => _FinanceManagerViewState();
}

class _FinanceManagerViewState extends State<FinanceManagerView>
    with SingleTickerProviderStateMixin {
  static String baseUrl = ApiService.baseUrl;
  late TabController _tabCtrl;
  List<dynamic> _payments = [];
  List<dynamic> _salaries = [];
  List<dynamic> _students = [];
  List<dynamic> _teachers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        http.get(Uri.parse('$baseUrl/payments/students')),
        http.get(Uri.parse('$baseUrl/payments/teacher-salaries')),
        http.get(Uri.parse('$baseUrl/students')),
        http.get(Uri.parse('$baseUrl/teachers')),
      ]);
      final pRes = results[0];
      final salRes = results[1];
      final sRes = results[2];
      final tRes = results[3];

      if (mounted) {
        setState(() {
          if (pRes.statusCode == 200) {
            try {
              final d = jsonDecode(utf8.decode(pRes.bodyBytes))['data'];
              if (d is List) _payments = d;
            } catch (_) {}
          }
          if (salRes.statusCode == 200) {
            try {
              final d = jsonDecode(utf8.decode(salRes.bodyBytes))['data'];
              if (d is List) _salaries = d;
            } catch (_) {}
          }
          if (sRes.statusCode == 200) {
            try {
              final d = jsonDecode(utf8.decode(sRes.bodyBytes))['data'];
              if (d is List) _students = d;
            } catch (_) {}
          }
          if (tRes.statusCode == 200) {
            try {
              final d = jsonDecode(utf8.decode(tRes.bodyBytes))['data'];
              if (d is List) _teachers = d;
            } catch (_) {}
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openPayStudentDialog() {
    int? sId = _students.isNotEmpty ? _students[0]['id'] : null;
    final amountCtrl = TextEditingController(text: '20.00');
    String method = 'KHQR';

    if (_students.isEmpty) {
      _showError('មិនមានទិន្នន័យសិស្សទេ! សូមបន្ថែមសិស្សជាមុនសិន។');
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
            width: 450,
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        color: Color(0xFF3B82F6),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'កត់ត្រាការបង់ថ្លៃសិក្សា',
                      style: TextStyle(
                        fontFamily: 'Khmer OS Muol Light',
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Builder(
                  builder: (_) {
                    final studentItems = <DropdownMenuItem<int>>[];
                    final seenStudentIds = <int>{};
                    for (final s in _students) {
                      final id = s['id'] is int
                          ? s['id'] as int
                          : int.tryParse(s['id'].toString());
                      if (id != null && seenStudentIds.add(id)) {
                        final gradeStr =
                            (s['class_name'] ??
                                    s['grade'] ??
                                    s['grade_level_name'] ??
                                    'ថ្នាក់ទី ១A')
                                .toString();
                        studentItems.add(
                          DropdownMenuItem<int>(
                            value: id,
                            child: Text(
                              '${s['name_kh']} (${s['student_code']}) • $gradeStr',
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
                    final effectiveStudentId =
                        (studentItems.any((i) => i.value == sId))
                        ? sId
                        : (studentItems.isNotEmpty
                              ? studentItems.first.value
                              : null);

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<int>(
                          // ignore: deprecated_member_use
                          value: effectiveStudentId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'ជ្រើសរើសសិស្ស',
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
                          items: studentItems,
                          onChanged: (v) => setM(() => sId = v),
                        ),
                        if (_students.isNotEmpty)
                          Builder(
                            builder: (_) {
                              final sel = _students.firstWhere(
                                (st) => st['id'] == (effectiveStudentId ?? sId),
                                orElse: () => _students.first,
                              );
                              final gradeStr =
                                  (sel['class_name'] ??
                                          sel['grade'] ??
                                          sel['grade_level_name'] ??
                                          'ថ្នាក់ទី ១A')
                                      .toString();
                              return Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFFDE68A),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.school_rounded,
                                      size: 20,
                                      color: Color(0xFFD97706),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'កម្រិតថ្នាក់៖ $gradeStr',
                                            style: const TextStyle(
                                              fontFamily: 'Khmer OS Battambang',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Color(0xFF92400E),
                                            ),
                                          ),
                                          Text(
                                            'អត្តលេខ៖ ${sel['student_code'] ?? '-'} • ភេទ៖ ${sel['gender'] ?? 'ស្រី'}',
                                            style: const TextStyle(
                                              fontFamily: 'Khmer OS Battambang',
                                              fontSize: 11,
                                              color: Color(0xFFB45309),
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
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'ចំនួនទឹកប្រាក់ (\$)',
                    labelStyle: const TextStyle(
                      fontFamily: 'Khmer OS Battambang',
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                    prefixIcon: const Icon(
                      Icons.attach_money,
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
                  value: method,
                  decoration: InputDecoration(
                    labelText: 'វិធីសាស្ត្របង់ប្រាក់',
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
                      value: 'Cash',
                      child: Text(
                        'សាច់ប្រាក់ (Cash)',
                        style: TextStyle(
                          fontFamily: 'Khmer OS Battambang',
                          fontSize: 13,
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'KHQR',
                      child: Text(
                        'វេលុយ (KHQR)',
                        style: TextStyle(
                          fontFamily: 'Khmer OS Battambang',
                          fontSize: 13,
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Bank Transfer',
                      child: Text(
                        'ផ្ទេរប្រាក់ (Bank Transfer)',
                        style: TextStyle(
                          fontFamily: 'Khmer OS Battambang',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) => setM(() => method = v!),
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
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          if (amountCtrl.text.isEmpty) return;
                          await http.post(
                            Uri.parse('$baseUrl/payments/students'),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({
                              'student_id': sId,
                              'amount': double.tryParse(amountCtrl.text) ?? 0,
                              'payment_method': method,
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

  void _openPayTeacherDialog() {
    int? tId = _teachers.isNotEmpty ? _teachers[0]['id'] : null;
    final amountCtrl = TextEditingController(text: '300.00');
    final monthCtrl = TextEditingController(text: 'August 2026');
    String method = 'Bank Transfer';

    if (_teachers.isEmpty) {
      _showError('មិនមានទិន្នន័យគ្រូទេ! សូមបន្ថែមគ្រូជាមុនសិន។');
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
            width: 450,
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: Color(0xFF10B981),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'បើកប្រាក់បៀវត្សរ៍គ្រូ',
                      style: TextStyle(
                        fontFamily: 'Khmer OS Muol Light',
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                DropdownButtonFormField<int>(
                  // ignore: deprecated_member_use
                  value: tId,
                  decoration: InputDecoration(
                    labelText: 'ជ្រើសរើសគ្រូបង្រៀន',
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
                  items: _teachers
                      .map<DropdownMenuItem<int>>(
                        (t) => DropdownMenuItem(
                          value: t['id'],
                          child: Text(
                            '${t['name_kh']} (${t['teacher_code']})',
                            style: const TextStyle(
                              fontFamily: 'Khmer OS Battambang',
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    setM(() => tId = v);
                    Map<String, dynamic>? selectedT;
                    for (final x in _teachers) {
                      if (x['id'] == v) {
                        selectedT = x;
                        break;
                      }
                    }
                    if (selectedT != null) {
                      setM(
                        () => amountCtrl.text = (selectedT!['base_salary'] ?? 0)
                            .toString(),
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'ចំនួនទឹកប្រាក់ (\$)',
                          labelStyle: const TextStyle(
                            fontFamily: 'Khmer OS Battambang',
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                          prefixIcon: const Icon(
                            Icons.attach_money,
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
                      child: TextField(
                        controller: monthCtrl,
                        decoration: InputDecoration(
                          labelText: 'សម្រាប់ខែ',
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
                  ],
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: method,
                  decoration: InputDecoration(
                    labelText: 'វិធីសាស្ត្របើកប្រាក់',
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
                      value: 'Cash',
                      child: Text(
                        'សាច់ប្រាក់ (Cash)',
                        style: TextStyle(
                          fontFamily: 'Khmer OS Battambang',
                          fontSize: 13,
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Bank Transfer',
                      child: Text(
                        'ផ្ទេរប្រាក់ (Bank Transfer)',
                        style: TextStyle(
                          fontFamily: 'Khmer OS Battambang',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) => setM(() => method = v!),
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
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          if (amountCtrl.text.isEmpty) return;
                          await http.post(
                            Uri.parse('$baseUrl/payments/teacher-salaries'),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({
                              'teacher_id': tId,
                              'amount': double.tryParse(amountCtrl.text) ?? 0,
                              'payment_method': method,
                              'for_month': monthCtrl.text,
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

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              msg,
              style: const TextStyle(fontFamily: 'Khmer OS Battambang'),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _deletePayment(int id) async {
    final ok = await _confirmDelete('ការបង់ប្រាក់');
    if (ok == true) {
      await http.delete(Uri.parse('$baseUrl/payments/students/$id'));
      _loadAll();
    }
  }

  Future<void> _deleteSalary(int id) async {
    final ok = await _confirmDelete('ប្រាក់បៀវត្សរ៍');
    if (ok == true) {
      await http.delete(Uri.parse('$baseUrl/payments/teacher-salaries/$id'));
      _loadAll();
    }
  }

  Future<bool?> _confirmDelete(String item) {
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
          'តើអ្នកពិតជាចង់លុបទិន្នន័យ "$item" នេះមែនទេ?\nសកម្មភាពនេះមិនអាចត្រឡប់វិញបានទេ។',
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

  void _exportCSV() {
    final isStudentTab = _tabCtrl.index == 0;
    final buf = StringBuffer();
    if (isStudentTab) {
      buf.writeln(
        '\uFEFFលេខវិក័យប័ត្រ,កាលបរិច្ឆេទ,ឈ្មោះសិស្ស,លេខកូដសិស្ស,កម្រិតថ្នាក់,វិធីសាស្ត្របង់,ទឹកប្រាក់ (\$)',
      );
      for (var p in _payments) {
        final d = '${p['paid_date'] ?? p['payment_date'] ?? ''}'.split('T')[0];
        final name = p['name_kh'] ?? p['student_name'] ?? p['name_en'] ?? '';
        final code = p['student_code'] ?? '';
        final grade =
            p['class_name'] ??
            p['grade'] ??
            p['grade_level_name'] ??
            'ថ្នាក់ទី ១A';
        final method = p['payment_method'] ?? 'KHQR';
        buf.writeln(
          '#${p['id']},"$d","$name","$code","$grade","$method",${p['amount'] ?? 0}',
        );
      }
      downloadCsv(
        buf.toString(),
        'student_payments_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
    } else {
      buf.writeln(
        '\uFEFFលេខវិក័យប័ត្រ,កាលបរិច្ឆេទ,ឈ្មោះគ្រូ,លេខកូដគ្រូ,សម្រាប់ខែ,វិធីសាស្ត្របើក,ទឹកប្រាក់ (\$)',
      );
      for (var s in _salaries) {
        final d = '${s['paid_date'] ?? s['payment_date'] ?? ''}'.split('T')[0];
        final name = s['name_kh'] ?? s['teacher_name'] ?? s['name_en'] ?? '';
        final code = s['teacher_code'] ?? '';
        final month = s['salary_month'] ?? s['for_month'] ?? '';
        final method = s['payment_method'] ?? 'Bank Transfer';
        buf.writeln(
          '#${s['id']},"$d","$name","$code","$month","$method",${s['amount'] ?? s['net_salary'] ?? s['base_salary'] ?? 0}',
        );
      }
      downloadCsv(
        buf.toString(),
        'teacher_salaries_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              isStudentTab
                  ? 'បានទាញយកទិន្នន័យបង់ប្រាក់សិស្សជា CSV ដោយជោគជ័យ'
                  : 'បានទាញយកទិន្នន័យប្រាក់បៀវត្សរ៍ជា CSV ដោយជោគជ័យ',
              style: const TextStyle(fontFamily: 'Khmer OS Battambang'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: LayoutBuilder(
        builder: (context, screenConstraints) {
          final isMobile = screenConstraints.maxWidth < 800;
          return Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 28),
            child: Column(
              children: [
                // Header Section
                Container(
                  padding: EdgeInsets.all(isMobile ? 14 : 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 980;
                      final titleWidget = Row(
                        mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(isMobile ? 10 : 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.account_balance,
                              color: const Color(0xFFF59E0B),
                              size: isMobile ? 24 : 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ហិរញ្ញវត្ថុ & ប្រាក់បៀវត្សរ៍',
                                  style: TextStyle(
                                    fontSize: isMobile ? 16 : 18,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Khmer OS Muol Light',
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'គ្រប់គ្រងចំណូលសិស្ស និងចំណាយប្រាក់បៀវត្សរ៍គ្រូបង្រៀន',
                                  style: TextStyle(
                                    color: const Color(0xFF64748B),
                                    fontSize: isMobile ? 11 : 13,
                                    fontFamily: 'Khmer OS Battambang',
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );

                  final buttonsWidget = Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF475569),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.file_download_outlined,
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
                        icon: const Icon(Icons.add_shopping_cart, size: 20),
                        label: const Text(
                          'កត់ត្រាការបង់ប្រាក់សិស្ស',
                          style: TextStyle(
                            fontFamily: 'Khmer OS Battambang',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: _openPayStudentDialog,
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.payments_outlined, size: 20),
                        label: const Text(
                          'បើកប្រាក់បៀវត្សរ៍គ្រូ',
                          style: TextStyle(
                            fontFamily: 'Khmer OS Battambang',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: _openPayTeacherDialog,
                      ),
                    ],
                  );

                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        titleWidget,
                        const SizedBox(height: 16),
                        buttonsWidget,
                      ],
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: titleWidget),
                      const SizedBox(width: 16),
                      buttonsWidget,
                    ],
                  );
                },
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
                controller: _tabCtrl,
                isScrollable: isMobile,
                tabAlignment: isMobile ? TabAlignment.start : null,
                indicatorColor: const Color(0xFFF59E0B),
                indicatorWeight: 3,
                labelColor: const Color(0xFFF59E0B),
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(
                  fontFamily: 'Khmer OS Battambang',
                  fontWeight: FontWeight.bold,
                ),
                tabs: const [
                  Tab(text: 'ប្រតិបត្តិការបង់ប្រាក់សិស្ស (Student Payments)'),
                  Tab(text: 'បញ្ជីបើកប្រាក់ខែគ្រូ (Teacher Salaries)'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Tab Views
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFF59E0B),
                      ),
                    )
                  : TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _buildStudentPaymentsTab(),
                        _buildTeacherSalariesTab(),
                      ],
                    ),
            ),
          ],
        ),
      );
    },
  ),
);
  }

  Widget _buildStudentPaymentsTab() {
    return Container(
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
                width: constraints.maxWidth < 1050 ? 1050 : constraints.maxWidth,
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
                          _headerCol('កាលបរិច្ឆេទ/វិក័យប័ត្រ', 2),
                          _headerCol('ឈ្មោះសិស្ស', 2),
                          _headerCol('កម្រិតថ្នាក់', 2),
                          _headerCol('វិធីសាស្ត្របង់', 2),
                          _headerCol('ទឹកប្រាក់', 1),
                          _headerCol('អ្នកទទួល', 1),
                          _headerCol('សកម្មភាព', 1, align: TextAlign.right),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    Expanded(
                      child: _payments.isEmpty
                          ? const Center(
                              child: Text(
                                'មិនទាន់មានប្រតិបត្តិការទេ',
                                style: TextStyle(
                                  fontFamily: 'Khmer OS Battambang',
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _payments.length,
                              // ignore: unnecessary_underscores
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                color: Color(0xFFF1F5F9),
                              ),
                              itemBuilder: (ctx, i) {
                                final p = _payments[i];
                                final rawDate =
                                    '${p['paid_date'] ?? p['payment_date'] ?? ''}'
                                        .split('T')[0];
                                final displayDate = rawDate.isNotEmpty
                                    ? rawDate
                                    : '-';
                                final studentName =
                                    p['name_kh'] ??
                                    p['student_name'] ??
                                    p['name_en'] ??
                                    '-';
                                final studentCode = p['student_code'] ?? '-';
                                final gradeStr =
                                    (p['class_name'] ??
                                            p['grade'] ??
                                            p['grade_level_name'] ??
                                            'ថ្នាក់ទី ១A')
                                        .toString();

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'វិក័យប័ត្រ: #${p['id']}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF475569),
                                              ),
                                            ),
                                            Text(
                                              displayDate,
                                              style: const TextStyle(
                                                fontFamily:
                                                    'Khmer OS Battambang',
                                                fontSize: 12,
                                                color: Color(0xFF64748B),
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
                                              studentName,
                                              style: const TextStyle(
                                                fontFamily:
                                                    'Khmer OS Battambang',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Color(0xFF1E293B),
                                              ),
                                            ),
                                            Text(
                                              'កូដ: $studentCode',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF64748B),
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
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF3C7),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: const Color(
                                                  0xFFFDE68A,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.school_rounded,
                                                  size: 14,
                                                  color: Color(0xFFD97706),
                                                ),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    gradeStr,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontFamily:
                                                          'Khmer OS Battambang',
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFFB45309),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEFF6FF),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${p['payment_method'] ?? 'KHQR'}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF3B82F6),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          '\$${p['amount']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color(0xFF16A34A),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          p['received_by'] ?? 'Admin',
                                          style: const TextStyle(
                                            fontFamily: 'Khmer OS Battambang',
                                            color: Color(0xFF475569),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerRight,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              _actionBtn(
                                                Icons.print_outlined,
                                                const Color(0xFF4F46E5),
                                                () {
                                                  HtmlPrintService.printPaymentReceipt(
                                                    receiptNo: '${p['id']}',
                                                    studentName:
                                                        studentName != '-'
                                                        ? studentName
                                                        : 'សិស្ស',
                                                    studentCode: studentCode,
                                                    grade:
                                                        (p['class_name'] ??
                                                                p['grade'] ??
                                                                p['grade_level_name'] ??
                                                                'ថ្នាក់ទី ១A')
                                                            .toString(),
                                                    amount: '${p['amount']}',
                                                    paymentMethod:
                                                        '${p['payment_method'] ?? 'KHQR'}',
                                                    date: displayDate,
                                                    receivedBy:
                                                        p['received_by'] ??
                                                        'បេឡាធិការ',
                                                    notes:
                                                        p['notes'] ?? p['note'],
                                                  );
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'កំពុងបើកផ្ទាំងបោះពុម្ពវិក័យប័ត្រ #${p['id']}...',
                                                        style: const TextStyle(
                                                          fontFamily:
                                                              'Khmer OS Battambang',
                                                        ),
                                                      ),
                                                      backgroundColor:
                                                          const Color(
                                                            0xFF4F46E5,
                                                          ),
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                      duration: const Duration(
                                                        seconds: 2,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                              const SizedBox(width: 6),
                                              _actionBtn(
                                                Icons.delete_outline_rounded,
                                                const Color(0xFFEF4444),
                                                () => _deletePayment(p['id']),
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
    );
  }

  Widget _buildTeacherSalariesTab() {
    return Container(
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
                width: constraints.maxWidth < 1000 ? 1000 : constraints.maxWidth,
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
                          _headerCol('កាលបរិច្ឆេទបើក', 2),
                          _headerCol('ឈ្មោះគ្រូបង្រៀន', 2),
                          _headerCol('សម្រាប់ខែ', 2),
                          _headerCol('វិធីសាស្ត្របើក', 2),
                          _headerCol('ទឹកប្រាក់', 1),
                          _headerCol('សកម្មភាព', 1, align: TextAlign.right),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    Expanded(
                      child: _salaries.isEmpty
                          ? const Center(
                              child: Text(
                                'មិនទាន់មានប្រតិបត្តិការទេ',
                                style: TextStyle(
                                  fontFamily: 'Khmer OS Battambang',
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _salaries.length,
                              // ignore: unnecessary_underscores
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                color: Color(0xFFF1F5F9),
                              ),
                              itemBuilder: (ctx, i) {
                                final s = _salaries[i];
                                final rawSalDate =
                                    '${s['paid_date'] ?? s['payment_date'] ?? ''}'
                                        .split('T')[0];
                                final displaySalDate = rawSalDate.isNotEmpty
                                    ? rawSalDate
                                    : '-';
                                final teacherName =
                                    s['name_kh'] ??
                                    s['teacher_name'] ??
                                    s['name_en'] ??
                                    '-';
                                final teacherCode = s['teacher_code'] ?? '-';
                                final forMonth =
                                    s['salary_month'] ?? s['for_month'] ?? '-';
                                final payMethod =
                                    s['payment_method'] ?? 'Bank Transfer';

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'វិក័យប័ត្រ: #${s['id']}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF475569),
                                              ),
                                            ),
                                            Text(
                                              displaySalDate,
                                              style: const TextStyle(
                                                fontFamily:
                                                    'Khmer OS Battambang',
                                                fontSize: 12,
                                                color: Color(0xFF64748B),
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
                                              teacherName,
                                              style: const TextStyle(
                                                fontFamily:
                                                    'Khmer OS Battambang',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Color(0xFF1E293B),
                                              ),
                                            ),
                                            Text(
                                              'កូដ: $teacherCode',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          forMonth,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF475569),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFECFDF5),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              payMethod,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF10B981),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          '\$${s['amount'] ?? s['net_salary'] ?? s['base_salary'] ?? '0.00'}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color(0xFFEF4444),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerRight,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              _actionBtn(
                                                Icons.print_outlined,
                                                const Color(0xFF4F46E5),
                                                () {
                                                  HtmlPrintService.printSalarySlip(
                                                    slipNo: '${s['id']}',
                                                    teacherName:
                                                        teacherName != '-'
                                                        ? teacherName
                                                        : 'គ្រូបង្រៀន',
                                                    teacherCode: teacherCode,
                                                    forMonth: forMonth != '-'
                                                        ? forMonth
                                                        : 'បច្ចុប្បន្ន',
                                                    amount:
                                                        '${s['amount'] ?? s['net_salary'] ?? s['base_salary'] ?? '0.00'}',
                                                    paymentMethod: payMethod,
                                                    date: displaySalDate,
                                                    notes: s['notes'],
                                                  );
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'កំពុងបើកផ្ទាំងបោះពុម្ពប័ណ្ណបើកប្រាក់បៀវត្សរ៍ #${s['id']}...',
                                                        style: const TextStyle(
                                                          fontFamily:
                                                              'Khmer OS Battambang',
                                                        ),
                                                      ),
                                                      backgroundColor:
                                                          const Color(
                                                            0xFF0D9488,
                                                          ),
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                      duration: const Duration(
                                                        seconds: 2,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                              const SizedBox(width: 6),
                                              _actionBtn(
                                                Icons.delete_outline_rounded,
                                                const Color(0xFFEF4444),
                                                () => _deleteSalary(s['id']),
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
        // ignore: deprecated_member_use
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
