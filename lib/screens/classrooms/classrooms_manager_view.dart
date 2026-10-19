import 'package:school_management_app/services/api_service.dart';
import 'package:school_management_app/utils/csv_exporter.dart';
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
  static String baseUrl = ApiService.baseUrl;
  List<dynamic> _levels = [];
  List<dynamic> _classes = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      ]);
      final lRes = results[0];
      final cRes = results[1];
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
                const SizedBox(height: 32),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'ឈ្មោះថ្នាក់ (ឧ. ថ្នាក់ទី១ ក)...',
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
                      value: effectiveLevel,
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
                const SizedBox(height: 20),
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
                        value: shift,
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
                          if (nameCtrl.text.isEmpty) return;
                          try {
                            await http.post(
                              Uri.parse('$baseUrl/classrooms'),
                              headers: {'Content-Type': 'application/json'},
                              body: jsonEncode({
                                'class_name': nameCtrl.text.trim(),
                                'grade_level_id': selLevel,
                                'room_number': roomCtrl.text.trim(),
                                'shift': shift,
                              }),
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            _loadAll();
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

  // ignore: unused_element
  void _editClassroomDialog(Map<String, dynamic> c) {
    final nameCtrl = TextEditingController(text: c['class_name'] ?? '');
    final roomCtrl = TextEditingController(text: c['room_number'] ?? 'Room-01');
    int? selLevel = c['grade_level_id'];
    String shift = c['shift'] ?? 'Morning';

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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.edit_location_alt_rounded,
                        color: Color(0xFF10B981),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'កែប្រែថ្នាក់រៀន',
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
                    labelText: 'ឈ្មោះថ្នាក់រៀន *',
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
                DropdownButtonFormField<int>(
                  // ignore: deprecated_member_use
                  value: _levels.any((l) => l['id'] == selLevel) ? selLevel : null,
                  decoration: InputDecoration(
                    labelText: 'កម្រិតសិក្សា',
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
                  items: () {
                    final seen = <int>{};
                    final list = <DropdownMenuItem<int>>[];
                    for (final l in _levels) {
                      final id = l['id'] is int ? l['id'] as int : int.tryParse(l['id']?.toString() ?? '');
                      if (id != null && seen.add(id)) {
                        list.add(DropdownMenuItem(
                          value: id,
                          child: Text(
                            '${l['name']} (${l['study_type']})',
                            style: const TextStyle(
                              fontFamily: 'Khmer OS Battambang',
                              fontSize: 13,
                            ),
                          ),
                        ));
                      }
                    }
                    return list;
                  }(),
                  onChanged: (v) => setM(() => selLevel = v),
                ),
                const SizedBox(height: 20),
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
                        value: shift,
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
                          if (nameCtrl.text.isEmpty) return;
                          await http.put(
                            Uri.parse('$baseUrl/classrooms/${c['id']}'),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({
                              'class_name': nameCtrl.text.trim(),
                              'grade_level_id': selLevel,
                              'room_number': roomCtrl.text.trim(),
                              'shift': shift,
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

  Future<void> _deleteLevel(int id, String name) async {
    final ok = await _confirmDelete(name);
    if (ok == true) {
      await http.delete(Uri.parse('$baseUrl/grade-levels/$id'));
      _loadAll();
    }
  }

  Future<void> _deleteClass(int id, String name) async {
    final ok = await _confirmDelete(name);
    if (ok == true) {
      await http.delete(Uri.parse('$baseUrl/classrooms/$id'));
      _loadAll();
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
                  Tab(text: 'បញ្ជីថ្នាក់រៀន (Classrooms)'),
                  Tab(text: 'កម្រិតសិក្សា (Grade Levels)'),
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
                      children: [_buildClassroomsTab(), _buildLevelsTab()],
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
                  _headerCol('ថ្នាក់រៀន', 2),
                  _headerCol('កម្រិតសិក្សា', 2),
                  _headerCol('វេន/លេខបន្ទប់', 2),
                  _headerCol('ចំនួនសិស្ស', 1),
                  _headerCol('សកម្មភាព', 1, align: TextAlign.right),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Expanded(
              child: _classes.isEmpty
                  ? const Center(
                      child: Text(
                        'មិនទាន់មានថ្នាក់រៀនទេ',
                        style: TextStyle(
                          fontFamily: 'Khmer OS Battambang',
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _classes.length,
                      // ignore: unnecessary_underscores
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (ctx, i) {
                        final c = _classes[i];
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
                                    Text(
                                      c['class_name'],
                                      style: const TextStyle(
                                        fontFamily: 'Khmer OS Battambang',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color(0xFF1E293B),
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
                                flex: 1,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
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
          // ignore: deprecated_member_use
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
