import 'package:school_management_app/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ReportsClosingScreen extends StatefulWidget {
  final int userId;
  const ReportsClosingScreen({super.key, required this.userId});

  @override
  State<ReportsClosingScreen> createState() => _ReportsClosingScreenState();
}

class _ReportsClosingScreenState extends State<ReportsClosingScreen> {
  String _closingType = 'Monthly'; // Daily, Weekly, Monthly, Yearly
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  // ignore: prefer_final_fields
  DateTime _endDate = DateTime.now();

  Map<String, dynamic>? _summary;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    setState(() => _isLoading = true);
    final sDate = _startDate.toISOString();
    final eDate = _endDate.toISOString();
    try {
      final res = await http.get(
        Uri.parse(
          // ignore: prefer_interpolation_to_compose_strings
          ApiService.baseUrl +
              '/reports/financial-summary?type=$_closingType&start_date=$sDate&end_date=$eDate',
        ),
      );
      final data = jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true));
      if (data['success'] == true) {
        setState(() => _summary = data['summary']);
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _executeClosing() async {
    if (_summary == null) return;
    final res = await http.post(
      // ignore: prefer_interpolation_to_compose_strings
      Uri.parse(ApiService.baseUrl + '/reports/close-period'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'closing_type': _closingType,
        'start_date': _startDate.toISOString(),
        'end_date': _endDate.toISOString(),
        'total_income': _summary!['total_income'],
        'total_expense': _summary!['total_expense'],
        'net_profit': _summary!['net_profit'],
        'closed_by': widget.userId,
        'notes': 'បានបិទបញ្ជីត្រឹមត្រូវតាមប្រព័ន្ធស្វ័យប្រវត្ត',
      }),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? 'បានបិទបញ្ជីជោគជ័យ!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'របាយការណ៍សាលា និងការបិទបញ្ជី (School Reports & Closings)',
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selector Tabs
            Row(
              children: [
                _periodBtn('Daily', 'ប្រចាំថ្ងៃ'),
                const SizedBox(width: 8),
                _periodBtn('Weekly', 'ប្រចាំសប្តាហ៍'),
                const SizedBox(width: 8),
                _periodBtn('Monthly', 'ប្រចាំខែ'),
                const SizedBox(width: 8),
                _periodBtn('Yearly', 'ប្រចាំឆ្នាំ'),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  icon: const Icon(Icons.lock_clock),
                  label: Text('អនុម័តបិទបញ្ជី ($_closingType)'),
                  onPressed: _executeClosing,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Summary Cards
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_summary != null)
              Expanded(
                child: ListView(
                  children: [
                    Row(
                      children: [
                        _statCard(
                          'ចំណូលសរុប (សិស្សបង់ថ្លៃ)',
                          '\$${_summary!['total_income']}',
                          Colors.green,
                        ),
                        const SizedBox(width: 16),
                        _statCard(
                          'ចំណាយសរុប (ប្រាក់ខែគ្រូ)',
                          '\$${_summary!['total_expense']}',
                          Colors.redAccent,
                        ),
                        const SizedBox(width: 16),
                        _statCard(
                          'ប្រាក់ចំណេញសុទ្ធ',
                          '\$${_summary!['net_profit']}',
                          const Color(0xFF2563EB),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'ស្ថិតិវត្តមានក្នុងកំឡុងពេលនេះ (Attendance Analysis)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.people, color: Colors.blue),
                        title: const Text('វត្តមានសិស្សានុសិស្ស'),
                        subtitle: Text(
                          'ទិន្នន័យបានកត់ត្រាចូល Database រួចរាល់: ${_summary!['student_attendance']}',
                        ),
                      ),
                    ),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.badge, color: Colors.teal),
                        title: const Text(
                          'វត្តមានគ្រូបង្រៀន (Staff Check-ins)',
                        ),
                        subtitle: Text(
                          'ទិន្នន័យវត្តមាន និងម៉ោងបង្រៀន: ${_summary!['teacher_attendance']}',
                        ),
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

  Widget _periodBtn(String type, String label) {
    final bool active = _closingType == type;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: active ? const Color(0xFF0F172A) : Colors.white,
        foregroundColor: active ? Colors.white : Colors.black87,
      ),
      onPressed: () {
        setState(() {
          _closingType = type;
          if (type == 'Daily')
            // ignore: curly_braces_in_flow_control_structures
            _startDate = DateTime.now().subtract(const Duration(days: 1));
          if (type == 'Weekly')
            // ignore: curly_braces_in_flow_control_structures
            _startDate = DateTime.now().subtract(const Duration(days: 7));
          if (type == 'Monthly')
            // ignore: curly_braces_in_flow_control_structures
            _startDate = DateTime.now().subtract(const Duration(days: 30));
          if (type == 'Yearly')
            // ignore: curly_braces_in_flow_control_structures
            _startDate = DateTime.now().subtract(const Duration(days: 365));
        });
        _fetchSummary();
      },
      child: Text(label),
    );
  }

  Widget _statCard(String title, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              val,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on DateTime {
  String toISOString() => toIso8601String().substring(0, 10);
}
