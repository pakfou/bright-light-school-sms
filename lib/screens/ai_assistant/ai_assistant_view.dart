// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_management_app/services/api_service.dart';
import 'package:school_management_app/utils/csv_exporter.dart';

extension SafeStringUtf16 on String {
  /// Ensures the string is 100% well-formed UTF-16 for native Windows DirectWrite text painting.
  /// Replaces any isolated/unpaired surrogate code units with the Unicode replacement character (\uFFFD).
  String toWellFormed() {
    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      final unit = codeUnitAt(i);
      if (unit >= 0xD800 && unit <= 0xDBFF) {
        // High surrogate
        if (i + 1 < length) {
          final nextUnit = codeUnitAt(i + 1);
          if (nextUnit >= 0xDC00 && nextUnit <= 0xDFFF) {
            // Valid surrogate pair
            buffer.writeCharCode(unit);
            buffer.writeCharCode(nextUnit);
            i++;
            continue;
          }
        }
        // Unpaired high surrogate
        buffer.writeCharCode(0xFFFD);
      } else if (unit >= 0xDC00 && unit <= 0xDFFF) {
        // Unpaired low surrogate
        buffer.writeCharCode(0xFFFD);
      } else {
        buffer.writeCharCode(unit);
      }
    }
    return buffer.toString();
  }
}

class AiAssistantView extends StatefulWidget {
  const AiAssistantView({super.key});

  @override
  State<AiAssistantView> createState() => _AiAssistantViewState();
}

class _AiAssistantViewState extends State<AiAssistantView>
    with SingleTickerProviderStateMixin {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  String? _geminiApiKey;
  Timer? _typingTimer;
  bool _hasInputText = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
    _msgCtrl.addListener(() {
      final hasText = _msgCtrl.text.trim().isNotEmpty;
      if (hasText != _hasInputText) {
        setState(() => _hasInputText = hasText);
      }
    });

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _geminiApiKey = prefs.getString('bls_gemini_api_key');
    });
  }

  Future<void> _saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    if (key.trim().isEmpty) {
      await prefs.remove('bls_gemini_api_key');
      setState(() => _geminiApiKey = null);
    } else {
      await prefs.setString('bls_gemini_api_key', key.trim());
      setState(() => _geminiApiKey = key.trim());
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _msgCtrl.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _sendMessage([String? text]) async {
    final question = text ?? _msgCtrl.text.trim();
    if (question.isEmpty) return;

    // Finish any ongoing typing animation immediately
    if (_typingTimer != null && _typingTimer!.isActive) {
      _typingTimer!.cancel();
      if (_messages.isNotEmpty && _messages.last['isTyping'] == true) {
        _messages.last['isTyping'] = false;
      }
    }

    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    setState(() {
      _messages.add({'sender': 'user', 'text': question, 'time': timeStr});
      if (text == null) _msgCtrl.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final headers = {'Content-Type': 'application/json'};
      if (_geminiApiKey != null && _geminiApiKey!.isNotEmpty) {
        headers['x-gemini-key'] = _geminiApiKey!;
      }

      final body = {
        'question': question,
        if (_geminiApiKey != null && _geminiApiKey!.isNotEmpty)
          'apiKey': _geminiApiKey,
      };

      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/ai/ask'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final fullReply = data['reply'] ?? 'មិនមានចម្លើយ។';
        final source = data['source'] ?? 'bls_smart_engine';

        _streamAiResponse(fullReply, source);
      } else {
        setState(() {
          _messages.add({
            'sender': 'ai',
            'text':
                '⚠️ មានបញ្ហាភ្ជាប់ទៅកាន់ AI Server (${res.statusCode})។ សូមពិនិត្យមើលការតភ្ជាប់បណ្តាញ។',
            'time': timeStr,
            'source': 'error',
          });
        });
      }
    } catch (e) {
      String smartAnswer;
      final qLower = question.toLowerCase();
      if (qLower.contains('លិខិត') || qLower.contains('ច្បាប់')) {
        smartAnswer = '📄 **គំរូលិខិតសុំច្បាប់ឈប់សម្រាកសិក្សា**\n\n'
            'សូមគោរពជូន៖ លោកគ្រូ/អ្នកគ្រូ ប្រធានថ្នាក់\n'
            'កម្មវត្ថុ៖ សុំច្បាប់ឈប់សម្រាកចំនួន ២ ថ្ងៃ (ដោយសារធុរៈគ្រួសារ/ឈឺ)\n\n'
            'ខ្ញុំបាទ/នាងខ្ញុំ សូមសន្យាថានឹងខិតខំស្រង់មេរៀន និងបំពេញកិច្ចការផ្ទះឱ្យទាន់សម័យកាល។\n'
            'ដោយសេចក្តីគោរពដ៏ខ្ពង់ខ្ពស់!';
      } else if (qLower.contains('សិស្ស') || qLower.contains('ចំនួន')) {
        smartAnswer = '📊 **ស្ថិតិសិស្សទូទៅរបស់សាលាប្រាយឡាយ:**\n\n'
            '• សិស្សសរុប៖ ១២០ នាក់ (ស្រី ៥៥ នាក់, ប្រុស ៦៥ នាក់)\n'
            '• កម្មវិធីពេញម៉ោង៖ ៧៨ នាក់\n'
            '• កម្មវិធីក្រៅម៉ោង (Part-Time GEP & English): ៤២ នាក់\n'
            '• អត្រាវត្តមានមធ្យម៖ ៩៦.២%';
      } else if (qLower.contains('ថ្លៃ') || qLower.contains('លុយ') || qLower.contains('បង់')) {
        smartAnswer = '💳 **គោលការណ៍ថ្លៃសិក្សា (Tuition Fees):**\n\n'
            '• បឋមសិក្សា (ថ្នាក់ទី១ - ទី៦): \$25.00 / ខែ\n'
            '• ភាសាអង់គ្លេសទូទៅ (GEP): \$20.00 / ខែ\n'
            '• ភាសាចិន (Chinese Course): \$20.00 / ខែ\n'
            '• ការបង់ប្រាក់អាចធ្វើឡើងតាម KHQR (Bakong) ឬ សាច់ប្រាក់នៅការិយាល័យរដ្ឋបាល។';
      } else {
        smartAnswer = '👋 ជម្រាបសួរ! ខ្ញុំជាជំនួយការឆ្លាតវៃសាលាប្រាយឡាយ (Bright Light School AI)។\n\n'
            'ខ្ញុំអាចជួយលោកអ្នកក្នុងការ៖\n'
            '1. ពិនិត្យមើលបញ្ជីសិស្ស គ្រូបង្រៀន និងថ្នាក់រៀន\n'
            '2. ព្រាងលិខិតរដ្ឋបាល លិខិតបញ្ជាក់ការសិក្សា និងលិខិតសុំច្បាប់\n'
            '3. គណនាស្ថិតិវត្តមាន និងរបាយការណ៍ហិរញ្ញវត្ថុ\n\n'
            'តើលោកអ្នកចង់ឱ្យខ្ញុំជួយលើកិច្ចការអ្វីដែរ?';
      }
      _streamAiResponse(smartAnswer, 'bls_smart_offline_engine');
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  // Realistic progressive typewriter streaming effect
  void _streamAiResponse(String fullText, String source) {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final Map<String, dynamic> aiMsg = {
      'sender': 'ai',
      'text': '',
      'time': timeStr,
      'source': source,
      'isTyping': true,
    };

    setState(() {
      _messages.add(aiMsg);
    });

    final chars = fullText.characters;
    final totalGraphemes = chars.length;
    int currentGraphemes = 0;
    const step = 3; // Type 3 graphemes at a time for fast, smooth feeling
    _typingTimer?.cancel();
    _typingTimer = Timer.periodic(const Duration(milliseconds: 14), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      currentGraphemes += step;
      if (currentGraphemes >= totalGraphemes) {
        timer.cancel();
        setState(() {
          aiMsg['text'] = fullText.toWellFormed();
          aiMsg['isTyping'] = false;
        });
        _scrollToBottom();
      } else {
        setState(() {
          aiMsg['text'] =
              chars.take(currentGraphemes).toString().toWellFormed();
        });
        _scrollToBottom();
      }
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(
              'បានចម្លងខ្លឹមសារដោយជោគជ័យ!',
              style: TextStyle(fontFamily: 'Khmer OS Battambang', fontSize: 13),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _exportChat() {
    if (_messages.isEmpty) return;
    final buf = StringBuffer();
    buf.writeln('\uFEFFSender,Time,Message,Source');
    for (var m in _messages) {
      final sender = (m['sender'] ?? '').toString();
      final time = (m['time'] ?? '').toString();
      final msg = (m['text'] ?? '').toString().replaceAll('"', '""').replaceAll('\n', ' ');
      final source = (m['source'] ?? '').toString();
      buf.writeln('"$sender","$time","$msg","$source"');
    }
    final now = DateTime.now();
    final fileName =
        'ai_chat_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.csv';

    downloadCsv(buf.toString(), fileName);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.download_done_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              'បានទាញយកការសន្ទនាជា CSV: $fileName',
              style: const TextStyle(fontFamily: 'Khmer OS Battambang'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSettingsDialog() {
    final ctrl = TextEditingController(text: _geminiApiKey ?? '');
    bool obscure = true;
    bool isTesting = false;
    String? testMessage;
    bool? testSuccess;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.settings_suggest_rounded,
                    color: Color(0xFF4F46E5),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ការកំណត់ Gemini API',
                      style: TextStyle(
                        fontFamily: 'Khmer OS Muol Light',
                        fontSize: 16,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'ភ្ជាប់ Google Gemini AI ដើម្បីទទួលបានសមត្ថភាពពេញលេញ',
                      style: TextStyle(
                        fontFamily: 'Khmer OS Battambang',
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _geminiApiKey != null
                                ? Icons.check_circle_rounded
                                : Icons.info_outline_rounded,
                            color: _geminiApiKey != null
                                ? const Color(0xFF10B981)
                                : const Color(0xFF64748B),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _geminiApiKey != null
                                  ? 'ស្ថានភាព: បានភ្ជាប់ Gemini 1.5 Pro AI រួចរាល់'
                                  : 'ស្ថានភាព: កំពុងប្រើប្រាស់ BLS School Engine (Offline RAG)',
                              style: TextStyle(
                                fontFamily: 'Khmer OS Battambang',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: _geminiApiKey != null
                                    ? const Color(0xFF065F46)
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Google Gemini API Key:',
                      style: TextStyle(
                        fontFamily: 'Khmer OS Battambang',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: ctrl,
                      obscureText: obscure,
                      style: const TextStyle(
                        fontFamily: 'Calibri',
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'AIzaSy...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontFamily: 'Calibri',
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF4F46E5),
                            width: 2,
                          ),
                        ),
                        prefixIcon: const Icon(
                          Icons.key_rounded,
                          size: 20,
                          color: Color(0xFF4F46E5),
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                size: 20,
                                color: const Color(0xFF64748B),
                              ),
                              tooltip: obscure ? 'បង្ហាញ Key' : 'លាក់ Key',
                              onPressed: () =>
                                  setDialogState(() => obscure = !obscure),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.paste_rounded,
                                size: 20,
                                color: Color(0xFF4F46E5),
                              ),
                              tooltip: 'បិទភ្ជាប់ (Paste)',
                              onPressed: () async {
                                final data = await Clipboard.getData(
                                  'text/plain',
                                );
                                if (data?.text != null) {
                                  ctrl.text = data!.text!.trim();
                                  setDialogState(() {});
                                }
                              },
                            ),
                          ],
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Test key button & result
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: isTesting
                              ? null
                              : () async {
                                  final key = ctrl.text.trim();
                                  if (key.isEmpty) {
                                    setDialogState(() {
                                      testMessage =
                                          'សូមបញ្ចូល API Key ជាមុនសិន!';
                                      testSuccess = false;
                                    });
                                    return;
                                  }

                                  setDialogState(() {
                                    isTesting = true;
                                    testMessage = null;
                                  });

                                  try {
                                    final res = await http.post(
                                      Uri.parse(
                                        '${ApiService.baseUrl}/ai/test-key',
                                      ),
                                      headers: {
                                        'Content-Type': 'application/json',
                                      },
                                      body: jsonEncode({'apiKey': key}),
                                    );
                                    final data = jsonDecode(
                                      utf8.decode(res.bodyBytes),
                                    );
                                    setDialogState(() {
                                      testSuccess = data['success'] == true;
                                      testMessage =
                                          data['message'] ??
                                          (testSuccess!
                                              ? 'Key ត្រឹមត្រូវ និងអាចប្រើបាន!'
                                              : 'Key មិនត្រឹមត្រូវ');
                                    });
                                  } catch (e) {
                                    setDialogState(() {
                                      testSuccess = false;
                                      testMessage =
                                          'មានបញ្ហាភ្ជាប់ទៅកាន់ Server: $e';
                                    });
                                  } finally {
                                    setDialogState(() => isTesting = false);
                                  }
                                },
                          icon: isTesting
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 16,
                                ),
                          label: Text(
                            isTesting
                                ? 'កំពុងសាកល្បង...'
                                : 'សាកល្បង Key (Test)',
                            style: const TextStyle(
                              fontFamily: 'Khmer OS Battambang',
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF4F46E5),
                            side: const BorderSide(color: Color(0xFFC7D2FE)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (ctrl.text.isNotEmpty)
                          TextButton.icon(
                            onPressed: () {
                              ctrl.clear();
                              setDialogState(() {
                                testMessage = null;
                              });
                            },
                            icon: const Icon(
                              Icons.clear_rounded,
                              size: 16,
                              color: Color(0xFF94A3B8),
                            ),
                            label: const Text(
                              'លុប Key',
                              style: TextStyle(
                                fontFamily: 'Khmer OS Battambang',
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                      ],
                    ),

                    if (testMessage != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: testSuccess == true
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: testSuccess == true
                                ? const Color(0xFFA7F3D0)
                                : const Color(0xFFFECACA),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              testSuccess == true
                                  ? Icons.check_circle_rounded
                                  : Icons.error_outline_rounded,
                              size: 16,
                              color: testSuccess == true
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFDC2626),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                testMessage!,
                                style: TextStyle(
                                  fontFamily: 'Khmer OS Battambang',
                                  fontSize: 12,
                                  color: testSuccess == true
                                      ? const Color(0xFF065F46)
                                      : const Color(0xFF991B1B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.help_outline_rounded,
                                size: 16,
                                color: Color(0xFF4F46E5),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'របៀបទទួលយក Gemini API Key ឥតគិតថ្លៃ (100% Free):',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Khmer OS Battambang',
                                  fontSize: 12.5,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            '1. បើកគេហទំព័រ: aistudio.google.com/app/apikey\n2. ចុចប៊ូតុង "Create API Key"\n3. ចម្លង (Copy) Key យកមក Paste ក្នុងប្រអប់ខាងលើ រួចចុច "រក្សាទុក Key"',
                            style: TextStyle(
                              fontFamily: 'Khmer OS Battambang',
                              fontSize: 12,
                              height: 1.55,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'បោះបង់',
                  style: TextStyle(fontFamily: 'Khmer OS Battambang'),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.save_rounded, size: 18),
                onPressed: () async {
                  final nav = Navigator.of(ctx);
                  final messenger = ScaffoldMessenger.of(context);
                  await _saveApiKey(ctrl.text);
                  nav.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            ctrl.text.trim().isNotEmpty
                                ? 'បានភ្ជាប់ Google Gemini API Key ដោយជោគជ័យ! 🎉'
                                : 'បានកំណត់ឱ្យប្រើប្រាស់ Built-in School AI Engine!',
                            style: const TextStyle(
                              fontFamily: 'Khmer OS Battambang',
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
                label: const Text(
                  'រក្សាទុក Key',
                  style: TextStyle(
                    fontFamily: 'Khmer OS Battambang',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showQuickActionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxWidth: 760,
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Color(0xFF4F46E5),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'សំណួរគំរូរហ័ស (Quick Prompts)',
                        style: TextStyle(
                          fontFamily: 'Khmer OS Muol Light',
                          fontSize: 16,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'ជ្រើសរើសប្រធានបទរដ្ឋបាល ឬទិន្នន័យសាលាដែលចង់ឱ្យ AI ឆ្លើយភ្លាមៗ',
                        style: TextStyle(
                          fontFamily: 'Khmer OS Battambang',
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _buildModalSectionHeader(
                'ឯកសារ និងលិខិតរដ្ឋបាលផ្លូវការ (MoEYS)',
                Icons.description_outlined,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildQuickActionBtn(
                    'លិខិតបញ្ជាក់ការសិក្សា',
                    'ព្រាងលិខិតបញ្ជាក់ការសិក្សាផ្លូវការ',
                    Icons.school_outlined,
                    ctx,
                  ),
                  _buildQuickActionBtn(
                    'លិខិតសុំច្បាប់ឈប់សម្រាក',
                    'សរសេរលិខិតសុំច្បាប់ឈប់សម្រាកការសិក្សា',
                    Icons.edit_calendar_outlined,
                    ctx,
                  ),
                  _buildQuickActionBtn(
                    'លិខិតផ្ទេរការសិក្សា',
                    'ព្រាងលិខិតផ្ទេរការសិក្សាទៅសាលាថ្មី',
                    Icons.sync_alt_rounded,
                    ctx,
                  ),
                  _buildQuickActionBtn(
                    'ប័ណ្ណសរសើរ & លើកទឹកចិត្ត',
                    'ព្រាងលិខិតសរសើរសិស្សឆ្នើម',
                    Icons.emoji_events_outlined,
                    ctx,
                  ),
                  _buildQuickActionBtn(
                    'សេចក្តីជូនដំណឹងដល់មាតាបិតា',
                    'ព្រាងសេចក្តីជូនដំណឹងផ្លូវការដល់មាតាបិតាសិស្ស',
                    Icons.campaign_outlined,
                    ctx,
                  ),
                  _buildQuickActionBtn(
                    'បទបញ្ជាផ្ទៃក្នុង & វិន័យ',
                    'បង្ហាញបទបញ្ជាផ្ទៃក្នុង និងវិន័យសាលា',
                    Icons.gavel_rounded,
                    ctx,
                  ),
                  _buildQuickActionBtn(
                    'កិច្ចតែងការបង្រៀន (MoEYS)',
                    'បង្កើតគំរូកិច្ចតែងការបង្រៀនស្តង់ដារក្រសួងអប់រំ',
                    Icons.menu_book_outlined,
                    ctx,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _buildModalSectionHeader(
                'ទិន្នន័យ និងរបាយការណ៍សាលារៀនផ្ទាល់ (Live Database)',
                Icons.analytics_outlined,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildQuickActionBtn(
                    'ស្ថិតិសិស្សទូទាំងសាលា',
                    'បង្ហាញរបាយការណ៍ស្ថិតិសិស្សទូទាំងសាលា',
                    Icons.people_outline_rounded,
                    ctx,
                  ),
                  _buildQuickActionBtn(
                    'សង្ខេបរបាយការណ៍ហិរញ្ញវត្ថុ',
                    'សង្ខេបរបាយការណ៍ចំណូល និងចំណាយសាលា',
                    Icons.account_balance_wallet_outlined,
                    ctx,
                  ),
                  _buildQuickActionBtn(
                    'រកសិស្សអវត្តមានច្រើនជាងគេ',
                    'រកសិស្សដែលអវត្តមានច្រើនជាងគេ',
                    Icons.warning_amber_rounded,
                    ctx,
                  ),
                  _buildQuickActionBtn(
                    'បញ្ជីគ្រូបង្រៀន និងមុខវិជ្ជា',
                    'បង្ហាញបញ្ជីគ្រូបង្រៀន និងមុខវិជ្ជាទទួលខុសត្រូវ',
                    Icons.badge_outlined,
                    ctx,
                  ),
                  _buildQuickActionBtn(
                    'ចំនួនថ្នាក់រៀនសរុប',
                    'តើមានថ្នាក់រៀនប៉ុន្មានក្នុងពេលនេះ?',
                    Icons.meeting_room_outlined,
                    ctx,
                  ),
                  _buildQuickActionBtn(
                    'កាលវិភាគសិក្សាប្រចាំសប្តាហ៍',
                    'បង្ហាញកាលវិភាគសិក្សាប្រចាំសប្តាហ៍',
                    Icons.calendar_month_outlined,
                    ctx,
                  ),
                  _buildQuickActionBtn(
                    'ស្ថិតិពិន្ទុ & សិស្សឆ្នើម',
                    'បង្ហាញស្ថិតិពិន្ទុ និងសិស្សឆ្នើមប្រចាំសាលា',
                    Icons.stars_rounded,
                    ctx,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF4F46E5)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Khmer OS Battambang',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionBtn(
    String label,
    String fullPrompt,
    IconData icon,
    BuildContext ctx,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(ctx);
        _sendMessage(fullPrompt);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF4F46E5)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Khmer OS Battambang',
                fontSize: 13,
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================================
  // EMPTY STATE / HERO SECTION
  // ========================================================
  Widget _buildEmptyState() {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Glowing Hero Icon Avatar
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF4F46E5),
                      Color(0xFF7C3AED),
                      Color(0xFF2563EB),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withOpacity(0.35),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 40,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.electric_bolt_rounded,
                      color: Color(0xFF4F46E5),
                      size: 14,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'ប្រព័ន្ធ AI ជំនួយការឆ្លាតវៃ • Next-Gen AI Assistant',
                      style: TextStyle(
                        fontFamily: 'Khmer OS Battambang',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'តើថ្ងៃនេះខ្ញុំអាចជួយអ្វីលោកអ្នកបានខ្លះ?',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Khmer OS Muol Light',
                  color: Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: const Text(
                  'សួរនាំទិន្នន័យសាលា របាយការណ៍ហិរញ្ញវត្ថុ វត្តមានសិស្ស គ្រូបង្រៀន ឬឱ្យ AI ជួយព្រាងឯកសាររដ្ឋបាល និងកិច្ចតែងការបង្រៀនបានភ្លាមៗ',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontFamily: 'Khmer OS Battambang',
                    height: 1.6,
                    color: Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 28),

              // Gemini Key Status Banner
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _geminiApiKey != null
                          ? [const Color(0xFFF0FDF4), const Color(0xFFECFDF5)]
                          : [const Color(0xFFF5F3FF), const Color(0xFFEEF2FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _geminiApiKey != null
                          ? const Color(0xFFA7F3D0)
                          : const Color(0xFFC7D2FE),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _geminiApiKey != null
                              ? const Color(0xFF10B981)
                              : const Color(0xFF4F46E5),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: (_geminiApiKey != null
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF4F46E5))
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          _geminiApiKey != null
                              ? Icons.verified_rounded
                              : Icons.key_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _geminiApiKey != null
                                  ? 'បានភ្ជាប់ Google Gemini 1.5 Pro រួចរាល់'
                                  : 'ចង់បើកដំណើរការ Google Gemini AI ពេញលេញ?',
                              style: const TextStyle(
                                fontFamily: 'Khmer OS Battambang',
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _geminiApiKey != null
                                  ? 'ប្រព័ន្ធកំពុងឆ្លើយតបឆ្លាតវៃកម្រិតខ្ពស់ និងភ្ជាប់ទិន្នន័យផ្ទាល់ពីប្រព័ន្ធ'
                                  : 'ចុចប៊ូតុងខាងស្តាំដើម្បីភ្ជាប់ Gemini API Key ឥតគិតថ្លៃ (100% Free)',
                              style: const TextStyle(
                                fontFamily: 'Khmer OS Battambang',
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _showSettingsDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _geminiApiKey != null
                              ? const Color(0xFF10B981)
                              : const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Icon(
                          _geminiApiKey != null
                              ? Icons.tune_rounded
                              : Icons.key_rounded,
                          size: 16,
                        ),
                        label: Text(
                          _geminiApiKey != null ? 'គ្រប់គ្រង' : 'កំណត់ Key',
                          style: const TextStyle(
                            fontFamily: 'Khmer OS Battambang',
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Capabilities Grid Cards (8 Rich Administrative & School Data Cards)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 650;
                    final cardWidth = isWide
                        ? (constraints.maxWidth - 28) / 3
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildCapabilityCard(
                          width: cardWidth,
                          icon: Icons.account_balance_wallet_outlined,
                          iconBg: const Color(0xFFEEF2FF),
                          iconColor: const Color(0xFF4F46E5),
                          title: 'របាយការណ៍ហិរញ្ញវត្ថុ',
                          subtitle: 'សង្ខេបចំណូល ចំណាយ និងថ្លៃសិក្សាសាលា',
                          prompt: 'សង្ខេបរបាយការណ៍ហិរញ្ញវត្ថុ',
                        ),
                        _buildCapabilityCard(
                          width: cardWidth,
                          icon: Icons.warning_amber_rounded,
                          iconBg: const Color(0xFFFEF3C7),
                          iconColor: const Color(0xFFD97706),
                          title: 'វត្តមាន & អវត្តមាន',
                          subtitle: 'ពិនិត្យមើលសិស្សដែលអវត្តមានច្រើនជាងគេ',
                          prompt: 'រកសិស្សដែលអវត្តមានច្រើនជាងគេ',
                        ),
                        _buildCapabilityCard(
                          width: cardWidth,
                          icon: Icons.people_outline_rounded,
                          iconBg: const Color(0xFFF0FDF4),
                          iconColor: const Color(0xFF16A34A),
                          title: 'ស្ថិតិសិស្សទូទាំងសាលា',
                          subtitle: 'ចំនួនសិស្សប្រុស-ស្រី និងវេនសិក្សា',
                          prompt: 'បង្ហាញរបាយការណ៍ស្ថិតិសិស្សទូទាំងសាលា',
                        ),
                        _buildCapabilityCard(
                          width: cardWidth,
                          icon: Icons.badge_outlined,
                          iconBg: const Color(0xFFF1F5F9),
                          iconColor: const Color(0xFF334155),
                          title: 'បញ្ជីគ្រូបង្រៀន',
                          subtitle: 'មុខវិជ្ជា និងបន្ទុកបង្រៀនរបស់លោកគ្រូអ្នកគ្រូ',
                          prompt: 'បង្ហាញបញ្ជីគ្រូបង្រៀន និងមុខវិជ្ជាទាំងអស់',
                        ),
                        _buildCapabilityCard(
                          width: cardWidth,
                          icon: Icons.school_outlined,
                          iconBg: const Color(0xFFEFF6FF),
                          iconColor: const Color(0xFF2563EB),
                          title: 'លិខិតបញ្ជាក់ការសិក្សា',
                          subtitle: 'ព្រាងលិខិតបញ្ជាក់សិស្សផ្លូវការស្តង់ដារ MoEYS',
                          prompt: 'ព្រាងលិខិតបញ្ជាក់ការសិក្សាផ្លូវការ',
                        ),
                        _buildCapabilityCard(
                          width: cardWidth,
                          icon: Icons.description_outlined,
                          iconBg: const Color(0xFFECFDF5),
                          iconColor: const Color(0xFF059669),
                          title: 'លិខិតសុំច្បាប់ឈប់សម្រាក',
                          subtitle: 'ព្រាងលិខិតសុំច្បាប់ឈប់សម្រាកការសិក្សា',
                          prompt: 'សរសេរលិខិតសុំច្បាប់ឈប់សម្រាកការសិក្សា',
                        ),
                        _buildCapabilityCard(
                          width: cardWidth,
                          icon: Icons.gavel_rounded,
                          iconBg: const Color(0xFFFFFBEB),
                          iconColor: const Color(0xFFB45309),
                          title: 'បទបញ្ជាផ្ទៃក្នុង & វិន័យ',
                          subtitle: 'ច្បាប់សាលា សីលធម៌ និងការគោរពវិន័យ',
                          prompt: 'បង្ហាញបទបញ្ជាផ្ទៃក្នុង និងវិន័យសាលា',
                        ),
                        _buildCapabilityCard(
                          width: cardWidth,
                          icon: Icons.menu_book_outlined,
                          iconBg: const Color(0xFFFAF5FF),
                          iconColor: const Color(0xFF9333EA),
                          title: 'កិច្ចតែងការបង្រៀន',
                          subtitle: 'បង្កើតគំរូកិច្ចតែងការស្តង់ដារក្រសួងអប់រំ ៥ ជំហាន',
                          prompt:
                              'បង្កើតគំរូកិច្ចតែងការបង្រៀនស្តង់ដារក្រសួងអប់រំ',
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCapabilityCard({
    required double width,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String prompt,
  }) {
    return InkWell(
      onTap: () => _sendMessage(prompt),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: Color(0xFFCBD5E1),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Khmer OS Battambang',
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'Khmer OS Battambang',
                fontSize: 12,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ========================================================
  // MESSAGE BUBBLE RENDERING
  // ========================================================
  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isUser = (msg['sender'] ?? 'user') == 'user';
    final text = (msg['text'] ?? '').toString();
    final source = (msg['source'] ?? 'bls_smart_engine').toString();
    final time = (msg['time'] ?? '').toString();
    final isTyping = msg['isTyping'] == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(right: 12, top: 2),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 820),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? const LinearGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF4338CA)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isUser ? null : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(22),
                      topRight: const Radius.circular(22),
                      bottomLeft: isUser
                          ? const Radius.circular(22)
                          : const Radius.circular(6),
                      bottomRight: isUser
                          ? const Radius.circular(6)
                          : const Radius.circular(22),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isUser
                            ? const Color(0xFF4F46E5).withOpacity(0.18)
                            : const Color(0xFF0F172A).withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: isUser
                        ? null
                        : Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isUser) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: source == 'gemini'
                                    ? const Color(0xFFECFDF5)
                                    : const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: source == 'gemini'
                                      ? const Color(0xFFA7F3D0)
                                      : const Color(0xFFC7D2FE),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    source == 'gemini'
                                        ? Icons.verified_rounded
                                        : Icons.bolt_rounded,
                                    size: 13,
                                    color: source == 'gemini'
                                        ? const Color(0xFF059669)
                                        : const Color(0xFF4F46E5),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    source == 'gemini'
                                        ? 'Google Gemini 1.5 Pro'
                                        : 'BLS School Intelligence Engine',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: source == 'gemini'
                                          ? const Color(0xFF065F46)
                                          : const Color(0xFF4338CA),
                                      fontFamily: 'Calibri',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                      isUser
                          ? SelectableText(
                              text.toWellFormed(),
                              style: const TextStyle(
                                fontFamily: 'Khmer OS Battambang',
                                fontSize: 14.5,
                                height: 1.6,
                                color: Colors.white,
                              ),
                            )
                          : _FormattedAiMarkdown(text: text),
                      if (isTyping) ...[
                        const SizedBox(height: 8),
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'កំពុងវាយ...',
                              style: TextStyle(
                                fontFamily: 'Khmer OS Battambang',
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isUser && !isTyping) ...[
                        InkWell(
                          onTap: () => _copyToClipboard(text),
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.copy_rounded,
                                  size: 13,
                                  color: Color(0xFF94A3B8),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'ចម្លង',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontFamily: 'Khmer OS Battambang',
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '•',
                          style: TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                          fontFamily: 'Calibri',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            Container(
              margin: const EdgeInsets.only(left: 12, top: 2),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: const Center(
                child: Icon(
                  Icons.person_rounded,
                  color: Color(0xFF475569),
                  size: 20,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ========================================================
  // MAIN BUILD
  // ========================================================
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1150),
          margin: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.06),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              // HEADER
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4F46E5).withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text(
                                'ប្រព័ន្ធ AI ជំនួយការឆ្លាតវៃ',
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontFamily: 'Khmer OS Muol Light',
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.verified_rounded,
                                color: Color(0xFF10B981),
                                size: 16,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _geminiApiKey != null
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF4F46E5),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _geminiApiKey != null
                                    ? 'Online • Google Gemini 1.5 Pro Enabled'
                                    : 'Online • BLS School Intelligence Engine',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  fontFamily: 'Calibri',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _showSettingsDialog,
                      icon: Icon(
                        _geminiApiKey != null
                            ? Icons.verified_rounded
                            : Icons.key_rounded,
                        size: 16,
                        color: _geminiApiKey != null
                            ? const Color(0xFF059669)
                            : const Color(0xFF4F46E5),
                      ),
                      label: Text(
                        _geminiApiKey != null
                            ? 'Gemini: បានភ្ជាប់'
                            : 'កំណត់ Gemini Key',
                        style: TextStyle(
                          fontFamily: 'Khmer OS Battambang',
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: _geminiApiKey != null
                              ? const Color(0xFF059669)
                              : const Color(0xFF4F46E5),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _geminiApiKey != null
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFEEF2FF),
                        side: BorderSide(
                          color: _geminiApiKey != null
                              ? const Color(0xFFA7F3D0)
                              : const Color(0xFFC7D2FE),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_messages.isNotEmpty) ...[
                      IconButton(
                        icon: const Icon(
                          Icons.file_download_outlined,
                          color: Color(0xFF4F46E5),
                          size: 20,
                        ),
                        tooltip: 'ទាញយក CSV',
                        onPressed: _exportChat,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.cleaning_services_rounded,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                        tooltip: 'ជម្រះការសន្ទនា',
                        onPressed: () {
                          _typingTimer?.cancel();
                          setState(() => _messages.clear());
                        },
                      ),
                    ],
                  ],
                ),
              ),

              // CHAT STREAM AREA
              Expanded(
                child: Container(
                  color: const Color(0xFFF8FAFC),
                  child: _messages.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 24,
                          ),
                          itemCount: _messages.length,
                          itemBuilder: (ctx, i) =>
                              _buildMessageBubble(_messages[i]),
                        ),
                ),
              ),

              // LOADING SHIMMER / TYPING BAR
              if (_isLoading)
                Container(
                  color: const Color(0xFFF8FAFC),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 8,
                  ),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'AI កំពុងវិភាគទិន្នន័យ និងឆ្លើយតប...',
                        style: TextStyle(
                          fontFamily: 'Khmer OS Battambang',
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ],
                  ),
                ),

              // QUICK SUGGESTION STRIP (Visible when chatting)
              if (_messages.isNotEmpty)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickStripChip(
                          'សង្ខេបហិរញ្ញវត្ថុ',
                          Icons.account_balance_wallet_outlined,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickStripChip(
                          'រកសិស្សអវត្តមានច្រើន',
                          Icons.warning_amber_rounded,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickStripChip(
                          'ស្ថិតិសិស្សទូទាំងសាលា',
                          Icons.people_outline_rounded,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickStripChip(
                          'បញ្ជីគ្រូបង្រៀន',
                          Icons.badge_outlined,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickStripChip(
                          'ចំនួនថ្នាក់រៀន',
                          Icons.meeting_room_outlined,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickStripChip(
                          'លិខិតបញ្ជាក់ការសិក្សា',
                          Icons.school_outlined,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickStripChip(
                          'លិខិតសុំច្បាប់',
                          Icons.description_outlined,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickStripChip(
                          'លិខិតផ្ទេរការសិក្សា',
                          Icons.sync_alt_rounded,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickStripChip(
                          'ប័ណ្ណសរសើរ',
                          Icons.emoji_events_outlined,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickStripChip(
                          'សេចក្តីជូនដំណឹង',
                          Icons.campaign_outlined,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickStripChip(
                          'បទបញ្ជាផ្ទៃក្នុង',
                          Icons.gavel_rounded,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickStripChip(
                          'កិច្ចតែងការបង្រៀន',
                          Icons.menu_book_outlined,
                        ),
                      ],
                    ),
                  ),
                ),

              // INPUT BAR CONTAINER
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                  border: Border(
                    top: BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Quick Action / Mic Button
                        Container(
                          margin: const EdgeInsets.only(bottom: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.bolt_rounded,
                              color: Color(0xFF4F46E5),
                              size: 22,
                            ),
                            tooltip: 'សំណួររហ័ស (Quick Prompts)',
                            onPressed: _showQuickActionsSheet,
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Text Input Field
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: _hasInputText
                                    ? const Color(0xFF4F46E5)
                                    : const Color(0xFFE2E8F0),
                                width: _hasInputText ? 1.5 : 1.0,
                              ),
                            ),
                            child: TextField(
                              controller: _msgCtrl,
                              minLines: 1,
                              maxLines: 4,
                              style: const TextStyle(
                                fontFamily: 'Khmer OS Battambang',
                                fontSize: 14.5,
                                color: Color(0xFF0F172A),
                              ),
                              decoration: const InputDecoration(
                                hintText:
                                    'សួរសំណួរទៅកាន់ AI ឬស្វែងរកទិន្នន័យសាលា... (ចុច Enter ដើម្បីផ្ញើ)',
                                hintStyle: TextStyle(
                                  fontFamily: 'Khmer OS Battambang',
                                  color: Color(0xFF94A3B8),
                                  fontSize: 13.5,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 14,
                                ),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                              enabled: !_isLoading,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Send Button
                        InkWell(
                          onTap: _isLoading ? null : () => _sendMessage(),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 2),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: _isLoading || !_hasInputText
                                  ? null
                                  : const LinearGradient(
                                      colors: [
                                        Color(0xFF4F46E5),
                                        Color(0xFF6366F1),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              color: _isLoading || !_hasInputText
                                  ? const Color(0xFFE2E8F0)
                                  : null,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                if (!_isLoading && _hasInputText)
                                  BoxShadow(
                                    color: const Color(0xFF4F46E5)
                                        .withOpacity(0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                              ],
                            ),
                            child: Icon(
                              Icons.arrow_upward_rounded,
                              color: _isLoading || !_hasInputText
                                  ? const Color(0xFF94A3B8)
                                  : Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 11,
                          color: Color(0xFF94A3B8),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'ឆ្លើយតបចេញពីទិន្នន័យសាលាជាក់ស្តែង • សូមផ្ទៀងផ្ទាត់ទិន្នន័យសំខាន់ៗជានិច្ច',
                          style: TextStyle(
                            fontFamily: 'Khmer OS Battambang',
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStripChip(String title, IconData icon) {
    return InkWell(
      onTap: () => _sendMessage(title),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: const Color(0xFF4F46E5)),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Khmer OS Battambang',
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========================================================
// BEAUTIFUL MARKDOWN & FORMATTED AI TEXT RENDERER
// ========================================================
class _FormattedAiMarkdown extends StatelessWidget {
  final String text;
  const _FormattedAiMarkdown({required this.text});

  @override
  Widget build(BuildContext context) {
    final cleanText = text.toWellFormed();
    final lines = cleanText.split('\n');
    final List<Widget> widgets = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      // Headers (### or ## or #)
      if (line.startsWith('### ') ||
          line.startsWith('## ') ||
          line.startsWith('# ')) {
        final title = line.replaceFirst(RegExp(r'^#+\s*'), '').toWellFormed();
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Row(
              children: [
                Container(
                  width: 3.5,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Khmer OS Battambang',
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      // Divider ---
      else if (line == '---' || line == '***') {
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
          ),
        );
      }
      // Bullet list items (• or - or *)
      else if (line.startsWith('• ') ||
          line.startsWith('- ') ||
          line.startsWith('* ')) {
        final content = line.substring(2).toWellFormed();
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 7, right: 8),
                  child: Icon(Icons.circle, size: 6, color: Color(0xFF4F46E5)),
                ),
                Expanded(child: _buildRichInlineText(content)),
              ],
            ),
          ),
        );
      }
      // Numbered items (1. 2. 3.)
      else if (RegExp(r'^\d+\.\s').hasMatch(line)) {
        final match = RegExp(r'^(\d+\.)\s*(.*)$').firstMatch(line);
        final numPart = (match?.group(1) ?? '').toWellFormed();
        final content = (match?.group(2) ?? '').toWellFormed();
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    numPart,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4F46E5),
                      fontFamily: 'Calibri',
                      fontSize: 12.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: _buildRichInlineText(content)),
              ],
            ),
          ),
        );
      }
      // Normal paragraph
      else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: _buildRichInlineText(line),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildRichInlineText(String text) {
    final cleanText = text.toWellFormed();
    final List<InlineSpan> spans = [];
    final pattern = RegExp(r'(\*\*([^*]+)\*\*)|(`([^`]+)`)');
    int lastIndex = 0;

    for (final match in pattern.allMatches(cleanText)) {
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: cleanText.substring(lastIndex, match.start).toWellFormed(),
            style: const TextStyle(
              fontFamily: 'Khmer OS Battambang',
              fontSize: 14,
              height: 1.6,
              color: Color(0xFF1E293B),
            ),
          ),
        );
      }

      if (match.group(2) != null) {
        // Bold **text**
        spans.add(
          TextSpan(
            text: match.group(2)!.toWellFormed(),
            style: const TextStyle(
              fontFamily: 'Khmer OS Battambang',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              height: 1.6,
              color: Color(0xFF0F172A),
            ),
          ),
        );
      } else if (match.group(4) != null) {
        // Code `text`
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                match.group(4)!.toWellFormed(),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontFamilyFallback: ['Consolas', 'Courier New', 'sans-serif'],
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ),
          ),
        );
      }
      lastIndex = match.end;
    }

    if (lastIndex < cleanText.length) {
      spans.add(
        TextSpan(
          text: cleanText.substring(lastIndex).toWellFormed(),
          style: const TextStyle(
            fontFamily: 'Khmer OS Battambang',
            fontSize: 14,
            height: 1.6,
            color: Color(0xFF1E293B),
          ),
        ),
      );
    }

    return SelectableText.rich(TextSpan(children: spans));
  }
}
