// lib/screens/attendance_scanner.dart
import 'package:flutter/material.dart';
import '../models/app_models.dart';

class AttendanceScanner extends StatefulWidget {
  const AttendanceScanner({super.key});

  @override
  State<AttendanceScanner> createState() => _AttendanceScannerState();
}

class _AttendanceScannerState extends State<AttendanceScanner> {
  String? _selectedClassId;
  final TextEditingController _qrInputController = TextEditingController();
  String? _lastScannedMessage;

  void _processQrCode(String code) {
    final store = AppDataStore.instance;
    final cleanCode = code.trim();

    final student = store.students.firstWhere(
      (s) => s.studentCode.toLowerCase() == cleanCode.toLowerCase(),
      orElse: () => Student(
        id: '',
        studentCode: '',
        khmerName: '',
        latinName: '',
        gender: '',
        dob: DateTime.now(),
        parentPhone: '',
        programType: ProgramType.fullTime,
        classroomId: '',
      ),
    );

    if (student.id.isEmpty) {
      setState(() => _lastScannedMessage = "❌ រកមិនឃើញទិន្នន័យសម្រាប់ QR: $cleanCode");
      return;
    }

    if (_selectedClassId != null && student.classroomId != _selectedClassId) {
      setState(() => _lastScannedMessage = "⚠️ សិស្ស ${student.khmerName} មិនស្ថិតក្នុងថ្នាក់ដែលបានជ្រើសរើសទេ!");
      return;
    }

    store.recordAttendance(student.id, student.classroomId, 'PRESENT');
    setState(() {
      _lastScannedMessage = "✅ វត្តមានទាន់ពេល៖ ${student.khmerName} (${student.studentCode})";
      _qrInputController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = AppDataStore.instance;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ផ្នែកខាងឆ្វេង៖ Scanner Controls
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ម៉ាស៊ីនស្កេនវត្តមាន QR Code (តាមថ្នាក់រៀន)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    initialValue: _selectedClassId,
                    decoration: const InputDecoration(
                      labelText: "ជ្រើសរើសថ្នាក់ដែលត្រូវស្រង់វត្តមាន",
                      border: OutlineInputBorder(),
                    ),
                    items: store.classrooms.map((c) {
                      return DropdownMenuItem(
                        value: c.id,
                        child: Text(
                          '${c.gradeLevel} - ${c.roomName} (${c.programType == ProgramType.fullTime ? "ពេញម៉ោង" : "ក្រៅម៉ោង"})',
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedClassId = val),
                  ),
                  const SizedBox(height: 24),

                  // UI Mock Camera Viewfinder
                  Container(
                    height: 240,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.qr_code_scanner, color: Colors.white38, size: 100),
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.greenAccent, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        const Positioned(
                          bottom: 16,
                          child: Text(
                            "ដាក់ QR Code ប័ណ្ណសិស្សចំប្រអប់កណ្តាល",
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ឧបករណ៍សម្រាប់បញ្ចូលកូដ Test ដោយដៃ ឬម៉ាស៊ីនបាញ់កូដ Barcode Gun
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _qrInputController,
                          decoration: const InputDecoration(
                            hintText: "វាយបញ្ចូល Student Code (ឧ. BL-2026-001) រួច Enter",
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: _processQrCode,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text('កត់ត្រា', style: TextStyle(color: Colors.white)),
                        onPressed: () => _processQrCode(_qrInputController.text),
                      ),
                    ],
                  ),

                  if (_lastScannedMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _lastScannedMessage!.startsWith('✅')
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _lastScannedMessage!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _lastScannedMessage!.startsWith('✅')
                              ? Colors.green.shade900
                              : Colors.red.shade900,
                        ),
                      ),
                    )
                  ]
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),

          // ផ្នែកខាងស្តាំ៖ តារាងវត្តមានសិស្សក្នុងថ្នាក់ដែលទើបស្កេនរួច
          Expanded(
            flex: 6,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'បញ្ជីវត្តមានថ្ងៃនេះ (Live Feed)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('កូដសិស្ស')),
                        DataColumn(label: Text('ឈ្មោះសិស្ស')),
                        DataColumn(label: Text('ម៉ោងស្កេន')),
                        DataColumn(label: Text('ស្ថានភាព')),
                      ],
                      rows: store.attendanceRecords.map((att) {
                        final student = store.students.firstWhere(
                          (s) => s.id == att.studentId,
                          orElse: () => Student(
                            id: '',
                            studentCode: '-',
                            khmerName: '-',
                            latinName: '-',
                            gender: '-',
                            dob: DateTime.now(),
                            parentPhone: '-',
                            programType: ProgramType.fullTime,
                            classroomId: '',
                          ),
                        );
                        return DataRow(cells: [
                          DataCell(Text(student.studentCode)),
                          DataCell(Text(student.khmerName)),
                          DataCell(Text(
                            '${att.timestamp.hour.toString().padLeft(2, '0')}:${att.timestamp.minute.toString().padLeft(2, '0')}',
                          )),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                att.status,
                                style: TextStyle(
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

