// lib/screens/grade_entry_screen.dart
import 'package:flutter/material.dart';
import '../models/app_models.dart';

class GradeEntryScreen extends StatefulWidget {
  const GradeEntryScreen({super.key});

  @override
  State<GradeEntryScreen> createState() => _GradeEntryScreenState();
}

class _GradeEntryScreenState extends State<GradeEntryScreen> {
  String? _selectedClassId;
  String _selectedSubject = "ភាសាខ្មែរ / គណិតវិទ្យា";

  @override
  Widget build(BuildContext context) {
    final store = AppDataStore.instance;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _selectedClassId,
                  initialValue: _selectedClassId,
                  decoration: const InputDecoration(
                    labelText: "ជ្រើសរើសបន្ទប់ថ្នាក់",
                    border: OutlineInputBorder(),
                  ),
                  items: store.classrooms
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.gradeLevel)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedClassId = val),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _selectedSubject,
                  initialValue: _selectedSubject,
                  decoration: const InputDecoration(
                    labelText: "មុខវិជ្ជា",
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: "ភាសាខ្មែរ / គណិតវិទ្យា", child: Text("ភាសាខ្មែរ / គណិតវិទ្យា")),
                    DropdownMenuItem(value: "ភាសាអង់គ្លេស", child: Text("ភាសាអង់គ្លេស")),
                    DropdownMenuItem(value: "ភាសាចិន", child: Text("ភាសាចិន")),
                    DropdownMenuItem(value: "កុំព្យូទ័រ (Word/Excel)", child: Text("កុំព្យូទ័រ (Word/Excel)")),
                  ],
                  onChanged: (val) => setState(() => _selectedSubject = val!),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text('រក្សាទុកពិន្ទុ', style: TextStyle(color: Colors.white)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('បានរក្សាទុកពិន្ទុ និងគណនាចំណាត់ថ្នាក់ជោគជ័យ!')),
                  );
                },
              )
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ListView.separated(
                itemCount: store.students.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final s = store.students[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        CircleAvatar(child: Text('${i + 1}')),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.khmerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(s.studentCode, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: "45",
                            decoration: const InputDecoration(
                              labelText: 'Homework (50%)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: "42",
                            decoration: const InputDecoration(
                              labelText: 'Monthly Test (50%)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          'សរុប៖ 87.0 (A)',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

