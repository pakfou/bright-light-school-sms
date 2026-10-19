import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:school_management_app/services/api_service.dart';
import 'attendance_scanner_screen.dart';

class AttendanceView extends StatefulWidget {
  const AttendanceView({super.key});

  @override
  State<AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceView> {
  final TextEditingController _codeCtrl = TextEditingController();
  int? _selectedClassId;
  String _selectedClassName = '';
  String _shift = 'Morning';
  List<dynamic> _classes = [];
  String _statusMessage = '';
  bool _isSuccess = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchClassrooms();
  }

  Future<void> _fetchClassrooms() async {
    try {
      final res = await http.get(Uri.parse('${ApiService.baseUrl}/classrooms'));
      if (res.statusCode == 200) {
        final d = jsonDecode(utf8.decode(res.bodyBytes));
        setState(() {
          _classes = d['data'] ?? [];
          if (_classes.isNotEmpty) {
            _selectedClassId = _classes[0]['id'];
            _selectedClassName = _classes[0]['class_name'];
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _recordAttendance() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty || _selectedClassId == null) return;

    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/attendance/scan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code': code,
          'classroom_id': _selectedClassId,
          'shift': _shift,
        }),
      );
      final d = jsonDecode(utf8.decode(res.bodyBytes));
      setState(() {
        _isSuccess = d['success'] == true;
        _statusMessage = d['message'] ?? d['error'] ?? 'បរាជ័យ';
        if (_isSuccess) _codeCtrl.clear();
      });
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _statusMessage = 'កំហុសតភ្ជាប់ Server: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openCameraScanner() {
    if (_selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('សូមជ្រើសរើសថ្នាក់រៀនជាមុនសិន!')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AttendanceScannerScreen(
          classroomId: _selectedClassId!,
          classroomName: _selectedClassName,
          userId: 1, // Default user ID for now, should come from auth
          shift: _shift,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Container(
          width: 580,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: Colors.black.withOpacity(0.04),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 24,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        // ignore: deprecated_member_use
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'ប្រព័ន្ធស្កេនវត្តមាន',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'បែងចែកតាមថ្នាក់រៀន (Class-based Attendance)',
                      style: TextStyle(
                        fontSize: 13,
                        // ignore: deprecated_member_use
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),

              // BODY
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CLASS SELECTION
                    const Text(
                      'ជ្រើសរើសថ្នាក់រៀន',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedClassId,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.arrow_drop_down_rounded,
                            color: Color(0xFF64748B),
                          ),
                          hint: const Text('សូមជ្រើសរើសថ្នាក់រៀន'),
                          items: _classes.map<DropdownMenuItem<int>>((c) {
                            return DropdownMenuItem(
                              value: c['id'],
                              child: Text(
                                '${c['class_name']} (${c['shift'] ?? 'Morning'})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (v) {
                            setState(() {
                              _selectedClassId = v;
                              final cls = _classes.firstWhere(
                                (element) => element['id'] == v,
                              );
                              _selectedClassName = cls['class_name'];
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SHIFT SELECTION
                    const Text(
                      'វេនសិក្សា (Shift)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _shift = 'Morning'),
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _shift == 'Morning'
                                    ? const Color(0xFFEEF2FF)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _shift == 'Morning'
                                      ? const Color(0xFF4F46E5)
                                      : const Color(0xFFE2E8F0),
                                  width: _shift == 'Morning' ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.wb_sunny_rounded,
                                    size: 18,
                                    color: _shift == 'Morning'
                                        ? const Color(0xFF4F46E5)
                                        : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'វេនព្រឹក',
                                    style: TextStyle(
                                      color: _shift == 'Morning'
                                          ? const Color(0xFF4F46E5)
                                          : const Color(0xFF64748B),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _shift = 'Afternoon'),
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _shift == 'Afternoon'
                                    ? const Color(0xFFEEF2FF)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _shift == 'Afternoon'
                                      ? const Color(0xFF4F46E5)
                                      : const Color(0xFFE2E8F0),
                                  width: _shift == 'Afternoon' ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.wb_twighlight,
                                    size: 18,
                                    color: _shift == 'Afternoon'
                                        ? const Color(0xFF4F46E5)
                                        : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'វេនរសៀល',
                                    style: TextStyle(
                                      color: _shift == 'Afternoon'
                                          ? const Color(0xFF4F46E5)
                                          : const Color(0xFF64748B),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ACTIONS
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _codeCtrl,
                            autofocus: true,
                            onSubmitted: (_) => _recordAttendance(),
                            decoration: InputDecoration(
                              hintText: 'វាយលេខកូដសិស្ស/គ្រូ...',
                              hintStyle: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              prefixIcon: const Icon(
                                Icons.keyboard_alt_outlined,
                                color: Color(0xFF94A3B8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF4F46E5),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                            ),
                            onPressed: _isLoading ? null : _recordAttendance,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded, size: 20),
                            label: const Text(
                              'បញ្ចូល',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // CAMERA BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4F46E5),
                          side: const BorderSide(
                            color: Color(0xFF4F46E5),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _openCameraScanner,
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: const Text(
                          'បើកកាមេរ៉ាស្កេន QR Code',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),

                    // STATUS MESSAGE
                    if (_statusMessage.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isSuccess
                              ? const Color(0xFFF0FDF4)
                              : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isSuccess
                                ? const Color(0xFFBBF7D0)
                                : const Color(0xFFFECACA),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isSuccess
                                  ? Icons.check_circle_rounded
                                  : Icons.error_rounded,
                              color: _isSuccess
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFDC2626),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _statusMessage,
                                style: TextStyle(
                                  color: _isSuccess
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFFB91C1C),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
