import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';

class ClassroomManagerView extends StatefulWidget {
  const ClassroomManagerView({super.key});

  @override
  State<ClassroomManagerView> createState() => _ClassroomManagerViewState();
}

class _ClassroomManagerViewState extends State<ClassroomManagerView> {
  List<dynamic> _classes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse('${ApiService.baseUrl}/classrooms'));
      final data = jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true));
      if (data['success'] == true) {
        setState(() => _classes = data['data']);
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  void _showAddEditModal({Map<String, dynamic>? item}) {
    final bool isEdit = item != null;
    final nameCtrl = TextEditingController(
      text: isEdit ? item['class_name'] : '',
    );
    final subjectCtrl = TextEditingController(
      text: isEdit ? item['subject'] : 'កុំព្យូទ័រ',
    );
    String level = isEdit ? item['level_type'] : 'Part-Time';
    String shift = isEdit ? item['shift'] : 'Morning';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            isEdit ? 'កែប្រែថ្នាក់រៀន' : 'បង្កើតថ្នាក់រៀនថ្មី',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ឈ្មោះថ្នាក់ (Class Name)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subjectCtrl,
                  decoration: const InputDecoration(
                    labelText: 'មុខវិជ្ជា (Subject)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  initialValue: level,
                  items: const [
                    DropdownMenuItem(
                      value: 'Full-Time',
                      child: Text('Full-Time (ពេញម៉ោង)'),
                    ),
                    DropdownMenuItem(
                      value: 'Part-Time',
                      child: Text('Part-Time (ក្រៅម៉ោង)'),
                    ),
                  ],
                  onChanged: (v) => setDialog(() => level = v!),
                  decoration: const InputDecoration(
                    labelText: 'កម្រិត (Level)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: shift,
                  items: const [
                    DropdownMenuItem(
                      value: 'Morning',
                      child: Text('Morning (ពេលព្រឹក)'),
                    ),
                    DropdownMenuItem(
                      value: 'Afternoon',
                      child: Text('Afternoon (ពេលរសៀល)'),
                    ),
                    DropdownMenuItem(
                      value: 'Weekend',
                      child: Text('Weekend (ចុងសប្តាហ៍)'),
                    ),
                  ],
                  onChanged: (v) => setDialog(() => shift = v!),
                  decoration: const InputDecoration(
                    labelText: 'វេន (Shift)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('បោះបង់'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final body = jsonEncode({
                  'class_name': nameCtrl.text,
                  'level_type': level,
                  'shift': shift,
                  'subject': subjectCtrl.text,
                });
                if (isEdit) {
                  await http.put(
                    Uri.parse('${ApiService.baseUrl}/classrooms/${item['id']}'),
                    headers: {'Content-Type': 'application/json'},
                    body: body,
                  );
                } else {
                  await http.post(
                    Uri.parse('${ApiService.baseUrl}/classrooms'),
                    headers: {'Content-Type': 'application/json'},
                    body: body,
                  );
                }
                // ignore: use_build_context_synchronously
                Navigator.pop(ctx);
                _loadClasses();
              },
              child: Text(isEdit ? 'រក្សាទុកការកែប្រែ' : 'បង្កើតថ្នាក់'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteClass(int id) async {
    await http.delete(Uri.parse('${ApiService.baseUrl}/classrooms/$id'));
    _loadClasses();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'គ្រប់គ្រងថ្នាក់រៀន',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'បញ្ជីថ្នាក់រៀនទាំងអស់នៅក្នុងសាលា',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.add, size: 20),
                label: const Text(
                  '+ បន្ថែមថ្នាក់',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _showAddEditModal(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    'ឈ្មោះថ្នាក់ (Class Name)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'កម្រិត (Level)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'វេន (Shift)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'សកម្មភាព (Actions)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    itemCount: _classes.length,
                    // ignore: unnecessary_underscores
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, i) {
                      final c = _classes[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Row(
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
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Text(
                                    c['class_name'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
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
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    c['level_type'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF475569),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                c['shift'] ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                      color: Color(0xFF2563EB),
                                    ),
                                    onPressed: () => _showAddEditModal(item: c),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                      color: Color(0xFFEF4444),
                                    ),
                                    onPressed: () => _deleteClass(c['id']),
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
    );
  }
}
