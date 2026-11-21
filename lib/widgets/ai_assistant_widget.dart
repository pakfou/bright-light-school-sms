// lib/widgets/ai_assistant_widget.dart
import 'package:flutter/material.dart';
import '../models/app_models.dart';

class AiAssistantWidget extends StatefulWidget {
  final VoidCallback onClose;
  const AiAssistantWidget({super.key, required this.onClose});

  @override
  State<AiAssistantWidget> createState() => _AiAssistantWidgetState();
}

class _AiAssistantWidgetState extends State<AiAssistantWidget> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      'sender': 'AI',
      'text': 'សួស្តី! ខ្ញុំជា AI ជំនួយការរបស់សាលាបឋមសិក្សា ប្រាយ ឡាយ។ តើលោកគ្រូអ្នកគ្រូចង់ស្រង់ស្ថិតិសិស្ស វត្តមាន ឬកាលវិភាគថ្នាក់ណាដែរ?'
    }
  ];

  void _handleSend() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    final store = AppDataStore.instance;
    String reply = "ខ្ញុំបានស្វែងរកក្នុង Database ៖ ";

    if (query.contains("សិស្ស")) {
      reply += "បច្ចុប្បន្នសាលាមានសិស្សសរុប ${store.students.length} នាក់ (ពេញម៉ោង និងក្រៅម៉ោង)។";
    } else if (query.contains("វត្តមាន")) {
      reply += "ថ្ងៃនេះមានសិស្សបានស្កេន QR Code ចំនួន ${store.attendanceRecords.length} នាក់។";
    } else if (query.contains("ថ្នាក់")) {
      reply += "សាលាមានថ្នាក់រៀនសរុប ${store.classrooms.length} បន្ទប់ថ្នាក់។";
    } else {
      reply += "ទិន្នន័យត្រូវបានកត់ត្រាក្នុង MySQL រួចរាល់។ ខ្ញុំអាចជួយរៀបចំរបាយការណ៍បន្ថែមជូនបាន!";
    }

    setState(() {
      _messages.add({'sender': 'USER', 'text': query});
      _messages.add({'sender': 'AI', 'text': reply});
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 360,
        height: 480,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF1E3A8A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.smart_toy, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Bright Life AI Assistant',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (ctx, i) {
                  final isUser = _messages[i]['sender'] == 'USER';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isUser ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _messages[i]['text']!,
                        style: TextStyle(
                          color: isUser ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'សួរសំណួរទៅកាន់ AI...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF2563EB), size: 20),
                    onPressed: _handleSend,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

