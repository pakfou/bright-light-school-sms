// lib/widgets/id_card_creator.dart
import 'package:flutter/material.dart';

class IdCardCreatorModal extends StatelessWidget {
  final String studentCode;
  final String khmerName;
  final String latinName;
  final String gradeLevel;
  final String programType;

  const IdCardCreatorModal({
    super.key,
    required this.studentCode,
    required this.khmerName,
    required this.latinName,
    required this.gradeLevel,
    required this.programType,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ប័ណ្ណសម្គាល់ខ្លួនសិស្ស (Official Student ID Card)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 20),
            // Student Card Container (Clean design, without lanyard slot hole)
            Container(
              width: 360,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'សាលាបឋមសិក្សា ប្រាយ ឡាយ',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Text(
                    'BRIGHT LIFE PRIMARY SCHOOL',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                  const Divider(color: Colors.white24, height: 20),
                  Row(
                    children: [
                      // QR Code Container
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.qr_code, size: 75, color: Colors.black87),
                            Text(
                              studentCode,
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              khmerName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              latinName,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'កម្រិត៖ $gradeLevel',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'ប្រភេទ៖ $programType',
                              style: const TextStyle(color: Colors.white70, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('បិទ'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                  icon: const Icon(Icons.print, color: Colors.white, size: 18),
                  label: const Text('បោះពុម្ពប័ណ្ណ (Print Card)', style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('កំពុងបញ្ជូនទៅកាន់ម៉ាស៊ីនបោះពុម្ពប័ណ្ណ...')),
                    );
                    Navigator.pop(context);
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

