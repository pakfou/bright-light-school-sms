import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:school_management_app/services/api_service.dart';

class AttendanceScannerView extends StatefulWidget {
  const AttendanceScannerView({super.key});

  @override
  State<AttendanceScannerView> createState() => _AttendanceScannerViewState();
}

class _AttendanceScannerViewState extends State<AttendanceScannerView>
    with SingleTickerProviderStateMixin {
  static String baseUrl = ApiService.baseUrl;

  final TextEditingController _codeCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool get _isScannerSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  MobileScannerController? _scannerController;

  void _resetScannerController() {
    if (!_isScannerSupported) return;
    try {
      _scannerController?.dispose();
    } catch (_) {}
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.front,
    );
  }

  void _toggleCamera() async {
    if (!_isScannerSupported) return;
    if (_isCameraActive) {
      try {
        await _scannerController?.stop();
      } catch (_) {}
      if (mounted) setState(() => _isCameraActive = false);
    } else {
      _resetScannerController();
      if (mounted) setState(() => _isCameraActive = true);
    }
  }

  late AnimationController _scanAnimController;
  late Animation<double> _scanAnimation;

  int? _selectedClassroomId;
  String _selectedShift = 'Morning';
  List<dynamic> _classrooms = [];
  List<dynamic> _quickStudents = [];

  // Scanned Person state
  Map<String, dynamic>? _lastScannedPerson;
  String _scanResult = '';
  bool _isSuccess = true;
  bool _isLoading = false;
  bool _isCameraActive = false;

  String? _lastScannedCode;
  DateTime? _lastScannedTime;

  // History & Class Roster states
  final List<Map<String, dynamic>> _recentScans = [];
  bool _isRecentScansLoading = false;
  List<dynamic> _classroomStudents = [];
  bool _isLoadingClassStudents = false;
  int _historyTabIndex = 0; // 0: ប្រវត្តិស្កេនថ្មីៗ, 1: បញ្ជីវត្តមានក្នុងថ្នាក់

  @override
  void initState() {
    super.initState();
    if (_isScannerSupported) {
      _resetScannerController();
      _isCameraActive = true;
    } else {
      _isCameraActive = false;
    }

    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanAnimController, curve: Curves.easeInOut),
    );

    _fetchInitialData();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _focusNode.dispose();
    if (_isScannerSupported) {
      _scannerController?.dispose();
    }
    _scanAnimController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    await _fetchClassrooms();
    await Future.wait([_fetchQuickStudents(), _fetchRecentScans()]);
    if (_selectedClassroomId != null) {
      _fetchClassroomStudents(_selectedClassroomId!);
    }
  }

  Future<void> _fetchClassrooms() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/classrooms'));
      if (res.statusCode == 200) {
        final d = jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true));
        if (mounted) {
          setState(() {
            _classrooms = d['data'] ?? [];
            if (_classrooms.isNotEmpty && _selectedClassroomId == null) {
              final first = _classrooms[0];
              _selectedClassroomId = first['id'] is int
                  ? first['id']
                  : int.tryParse(first['id'].toString());
            }
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchQuickStudents() async {
    try {
      final sRes = await http.get(Uri.parse('$baseUrl/students'));
      if (sRes.statusCode == 200) {
        final sd = jsonDecode(
          utf8.decode(sRes.bodyBytes, allowMalformed: true),
        );
        if (mounted) {
          setState(() {
            _quickStudents = sd['data'] ?? [];
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchRecentScans() async {
    if (mounted) setState(() => _isRecentScansLoading = true);
    try {
      final list = await ApiService.getRecentAttendance();
      if (mounted) {
        setState(() {
          _recentScans.clear();
          for (final item in list) {
            final code =
                (item['code'] ??
                        item['student_code'] ??
                        item['teacher_code'] ??
                        '')
                    .toString();
            final nameKh = (item['name_kh'] ?? '').toString();
            final nameEn = (item['name_en'] ?? '').toString();
            final className = (item['class_name'] ?? 'ទូទៅ').toString();
            final status = (item['status'] ?? 'Present').toString();
            final shift = (item['shift'] ?? 'Morning').toString();
            final type = (item['type'] ?? 'Student').toString();
            final photoUrl = item['photo_url']?.toString();
            final timeStr = (item['time'] ?? '').toString();

            _recentScans.add({
              'code': code,
              'name_kh': nameKh,
              'name_en': nameEn,
              'class_name': className,
              'status': status,
              'shift': shift,
              'type': type,
              'photo_url': photoUrl,
              'time_str': timeStr.isNotEmpty ? timeStr : 'ថ្មីៗនេះ',
              'message': 'វត្តមាន៖ $nameKh ($code) ជោគជ័យ',
              'success': status.toLowerCase() != 'absent',
            });
          }

          // If no person card is shown yet, show the latest scan as preview
          if (_lastScannedPerson == null && _recentScans.isNotEmpty) {
            _lastScannedPerson = Map<String, dynamic>.from(_recentScans.first);
            _isSuccess = true;
            _scanResult =
                'ទិន្នន័យស្កេនចុងក្រោយ៖ ${_lastScannedPerson!['name_kh']} (${_lastScannedPerson!['code']})';
          }
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isRecentScansLoading = false);
    }
  }

  Future<void> _fetchClassroomStudents(int classroomId) async {
    if (mounted) setState(() => _isLoadingClassStudents = true);
    try {
      final list = await ApiService.getClassroomAttendance(classroomId);
      if (mounted) {
        setState(() {
          _classroomStudents = list;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingClassStudents = false);
    }
  }

  Future<void> _processScan(String code, {bool bypassLock = false}) async {
    final cleanCode = code.trim();
    if (cleanCode.isEmpty) return;

    // Prevent rapid multiple scans of the same code within 2 seconds
    if (!bypassLock &&
        _lastScannedCode == cleanCode &&
        _lastScannedTime != null) {
      if (DateTime.now().difference(_lastScannedTime!).inSeconds < 2) {
        return;
      }
    }
    _lastScannedCode = cleanCode;
    _lastScannedTime = DateTime.now();

    setState(() {
      _isLoading = true;
      _scanResult = 'កំពុងដំណើរការទាញទិន្នន័យ...';
    });

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/attendance/scan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code': cleanCode,
          'classroom_id': _selectedClassroomId,
          'shift': _selectedShift,
        }),
      );
      final d = jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true));
      final success = d['success'] == true;
      final message = d['message'] ?? d['error'] ?? 'កំហុសមិនស្គាល់';
      final personData = d['person'];

      final now = DateTime.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      Map<String, dynamic> personMap;
      if (personData != null && personData is Map) {
        personMap = {
          'code': personData['code'] ?? cleanCode,
          'name_kh': personData['name_kh'] ?? '',
          'name_en': personData['name_en'] ?? '',
          'class_name': personData['class_name'] ?? 'ទូទៅ',
          'type': personData['type'] ?? 'Student',
          'photo_url': personData['photo_url'],
          'status': 'Present',
          'shift': _selectedShift,
          'time_str': timeStr,
          'message': message,
          'success': success,
        };
      } else {
        // Fallback: match from _quickStudents
        dynamic matched;
        for (final s in _quickStudents) {
          if ((s['student_code'] ?? '').toString() == cleanCode) {
            matched = s;
            break;
          }
        }
        personMap = {
          'code': cleanCode,
          'name_kh': matched != null
              ? (matched['name_kh'] ?? '')
              : 'សិស្ស/គ្រូ',
          'name_en': matched != null ? (matched['name_en'] ?? '') : '',
          'class_name': matched != null
              ? (matched['class_name'] ?? 'ទូទៅ')
              : 'ទូទៅ',
          'type': 'Student',
          'photo_url': matched?['photo_url'],
          'status': success ? 'Present' : 'Failed',
          'shift': _selectedShift,
          'time_str': timeStr,
          'message': message,
          'success': success,
        };
      }

      setState(() {
        _isSuccess = success;
        _scanResult = message;
        _lastScannedPerson = personMap;

        // Prepend to recent scans list
        _recentScans.removeWhere((s) => s['code'] == cleanCode);
        _recentScans.insert(0, personMap);
        if (_recentScans.length > 50) _recentScans.removeLast();

        if (success) {
          _codeCtrl.clear();
        }
      });

      // Update class students roster if open
      if (_selectedClassroomId != null) {
        _fetchClassroomStudents(_selectedClassroomId!);
      }
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _scanResult = 'មិនអាចភ្ជាប់ទៅកាន់ Server បានទេ ($e)';
      });
    } finally {
      setState(() => _isLoading = false);
      _focusNode.requestFocus();
    }
  }

  // Helper to build photo avatar with Base64, Network, or Initials fallback
  Widget _buildAvatar(
    String? photoUrl,
    String name, {
    double size = 48,
    bool isOnline = false,
  }) {
    Widget avatarContent;
    final trimmed = photoUrl?.trim() ?? '';

    if (trimmed.startsWith('data:image')) {
      try {
        final comma = trimmed.indexOf(',');
        final base64Str = comma != -1 ? trimmed.substring(comma + 1) : trimmed;
        avatarContent = Image.memory(
          base64Decode(base64Str),
          fit: BoxFit.cover,
          width: size,
          height: size,
          // ignore: unnecessary_underscores
          errorBuilder: (_, __, ___) => _buildFallbackInitial(name, size),
        );
      } catch (_) {
        avatarContent = _buildFallbackInitial(name, size);
      }
    } else if (trimmed.startsWith('http')) {
      avatarContent = Image.network(
        trimmed,
        fit: BoxFit.cover,
        width: size,
        height: size,
        // ignore: unnecessary_underscores
        errorBuilder: (_, __, ___) => _buildFallbackInitial(name, size),
      );
    } else {
      avatarContent = _buildFallbackInitial(name, size);
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(size / 2),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: avatarContent,
          ),
        ),
        if (isOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFallbackInitial(String name, double size) {
    final initial = name.trim().isNotEmpty ? name.trim()[0] : 'U';
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.42,
          fontWeight: FontWeight.bold,
          fontFamily: 'Khmer OS Battambang',
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildScannedPersonCard() {
    if (_lastScannedPerson == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(22),
          ),
          border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 10),
                ],
              ),
              child: const Icon(
                Icons.fingerprint_rounded,
                color: Color(0xFF6366F1),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'រង់ចាំការស្កេនវត្តមាន...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Khmer OS Battambang',
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'សូមប្រើកាំភ្លើង USB, កាមេរ៉ា ឬចុចប៊ូតុងតេស្តខាងលើ',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Khmer OS Battambang',
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final p = _lastScannedPerson!;
    final nameKh = p['name_kh']?.toString() ?? 'សិស្ស/គ្រូ';
    final nameEn = p['name_en']?.toString() ?? '';
    final code = p['code']?.toString() ?? '';
    final className = p['class_name']?.toString() ?? 'ទូទៅ';
    final shift = p['shift']?.toString() ?? _selectedShift;
    final timeStr = p['time_str']?.toString() ?? '';
    final photoUrl = p['photo_url']?.toString();
    final isStudent = (p['type']?.toString().toLowerCase()) != 'teacher';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _isSuccess ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
        border: Border(
          top: BorderSide(
            color: _isSuccess
                ? const Color(0xFF86EFAC)
                : const Color(0xFFFCA5A5),
            width: 1.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(photoUrl, nameKh, size: 54, isOnline: _isSuccess),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isStudent
                                ? const Color(0xFFEEF2FF)
                                : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isStudent
                                  ? const Color(0xFFC7D2FE)
                                  : const Color(0xFFFDE68A),
                            ),
                          ),
                          child: Text(
                            isStudent ? 'សិស្ស' : 'គ្រូបង្រៀន',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontFamily: 'Khmer OS Battambang',
                              fontWeight: FontWeight.bold,
                              color: isStudent
                                  ? const Color(0xFF4338CA)
                                  : const Color(0xFFB45309),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _isSuccess
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isSuccess
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded,
                                size: 12,
                                color: _isSuccess
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFDC2626),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isSuccess
                                    ? 'មានវត្តមាន (Present)'
                                    : 'មិនជោគជ័យ',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontFamily: 'Khmer OS Battambang',
                                  fontWeight: FontWeight.bold,
                                  color: _isSuccess
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nameKh,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Khmer OS Battambang',
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (nameEn.isNotEmpty)
                      Text(
                        nameEn,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontFamily: 'Calibri Light',
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isSuccess
                    ? const Color(0xFFBBF7D0)
                    : const Color(0xFFFECACA),
              ),
            ),
            child: Row(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.badge_rounded,
                      size: 14,
                      color: Color(0xFF4F46E5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      code,
                      style: const TextStyle(
                        fontFamily: 'Calibri Light',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFF1E293B),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.meeting_room_rounded,
                        size: 14,
                        color: Color(0xFF8B5CF6),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          className,
                          style: const TextStyle(
                            fontFamily: 'Khmer OS Battambang',
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color: Color(0xFF475569),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 13,
                      color: Color(0xFF059669),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeStr.isNotEmpty ? timeStr : shift,
                      style: const TextStyle(
                        fontFamily: 'Khmer OS Battambang',
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_scanResult.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _isSuccess
                      ? Icons.info_outline_rounded
                      : Icons.warning_amber_rounded,
                  size: 14,
                  color: _isSuccess
                      ? const Color(0xFF059669)
                      : const Color(0xFFDC2626),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _scanResult,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Khmer OS Battambang',
                      fontWeight: FontWeight.w500,
                      color: _isSuccess
                          ? const Color(0xFF047857)
                          : const Color(0xFFB91C1C),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControlPanel({bool isMobile = false}) {
    final inputsColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'កំណត់ព័ត៌មានថ្នាក់',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'Khmer OS Battambang',
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        Builder(
          builder: (_) {
            final classroomItems = <DropdownMenuItem<int>>[];
            final seenClassIds = <int>{};
            for (final c in _classrooms) {
              final id = c['id'] is int
                  ? c['id'] as int
                  : int.tryParse(c['id'].toString());
              if (id != null && seenClassIds.add(id)) {
                classroomItems.add(
                  DropdownMenuItem(
                    value: id,
                    child: Text(
                      '${c['class_name']} (${c['shift'] ?? 'ព្រឹក'})',
                      style: const TextStyle(
                        fontFamily: 'Khmer OS Battambang',
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }
            }
            final effectiveClassId =
                (classroomItems.any(
                  (i) => i.value == _selectedClassroomId,
                ))
                ? _selectedClassroomId
                : (classroomItems.isNotEmpty
                      ? classroomItems.first.value
                      : null);

            return DropdownButtonFormField<int>(
              // ignore: deprecated_member_use
              value: effectiveClassId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'ជ្រើសរើសថ្នាក់រៀន',
                labelStyle: const TextStyle(
                  fontFamily: 'Khmer OS Battambang',
                  color: Color(0xFF64748B),
                  fontSize: 13,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                prefixIcon: const Icon(
                  Icons.meeting_room_rounded,
                  color: Color(0xFF8B5CF6),
                  size: 20,
                ),
              ),
              items: classroomItems,
              onChanged: (val) {
                setState(() => _selectedClassroomId = val);
                if (val != null) {
          // ignore: deprecated_member_use
                  _fetchClassroomStudents(val);
                }
                _focusNode.requestFocus();
              },
            );
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: ['Morning', 'Afternoon'].contains(_selectedShift)
              ? _selectedShift
              : 'Morning',
          decoration: InputDecoration(
            labelText: 'វេនសិក្សា (Shift)',
            labelStyle: const TextStyle(
              fontFamily: 'Khmer OS Battambang',
              color: Color(0xFF64748B),
              fontSize: 13,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            prefixIcon: const Icon(
              Icons.wb_sunny_rounded,
              color: Color(0xFFF59E0B),
              size: 20,
            ),
          ),
          items: const [
            DropdownMenuItem(
              value: 'Morning',
              child: Text(
                'ព្រឹក (Morning)',
                style: TextStyle(
                  fontFamily: 'Khmer OS Battambang',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            DropdownMenuItem(
              value: 'Afternoon',
              child: Text(
                'រសៀល (Afternoon)',
                style: TextStyle(
                  fontFamily: 'Khmer OS Battambang',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
          onChanged: (val) {
            setState(() => _selectedShift = val!);
            _focusNode.requestFocus();
          },
        ),

        const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Divider(color: Color(0xFFE2E8F0)),
        ),

        const Text(
          'ស្កេនដោយកាំភ្លើង USB / វាយបញ្ចូល',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'Khmer OS Battambang',
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _codeCtrl,
          focusNode: _focusNode,
          style: const TextStyle(
            fontFamily: 'Calibri Light',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
          decoration: InputDecoration(
            hintText: 'បញ្ចូល ID ឬ Scan...',
            hintStyle: const TextStyle(
              fontFamily: 'Khmer OS Battambang',
              fontSize: 13,
              color: Color(0xFF94A3B8),
              letterSpacing: 0,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            prefixIcon: const Icon(
              Icons.qr_code_2,
              color: Color(0xFF3B82F6),
              size: 20,
            ),
            suffixIcon: InkWell(
              onTap: () => _processScan(_codeCtrl.text),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
              ),
            ),
          ),
          onSubmitted: (code) => _processScan(code),
        ),
        const SizedBox(height: 12),

        // Quick Demo Tests
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  size: 14,
                  color: Color(0xFF64748B),
                ),
                SizedBox(width: 6),
                Text(
                  'តេស្តស្កេនរហ័ស (Quick Demo Tests):',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Khmer OS Battambang',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children:
                  (_quickStudents.isNotEmpty
                          ? _quickStudents.take(6).toList()
                          : [
                              {
                                'student_code': 'BLS-720655',
                                'name_kh': 'ស្រ៊ុន គឹមស៊ីង',
                              },
                              {
                                'student_code': 'BLS-083222',
                                'name_kh': 'ផល្លា អ៊ីណ្ឌូ',
                              },
                              {
                                'student_code': 'BLS-183133',
                                'name_kh': 'ឈាវ ម៉ីលិញ',
                              },
                            ])
                      .map<Widget>((s) {
                        final code =
                            s['student_code']?.toString() ?? '';
                        final name = s['name_kh']?.toString() ?? '';
                        return ActionChip(
                          avatar: const Icon(
                            Icons.flash_on_rounded,
                            size: 13,
                            color: Color(0xFF4F46E5),
                          ),
                          label: Text(
                            '$code • $name',
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'Khmer OS Battambang',
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4F46E5),
                            ),
                          ),
                          backgroundColor: const Color(0xFFEEF2FF),
                          side: const BorderSide(
                            color: Color(0xFFC7D2FE),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onPressed: () {
                            _codeCtrl.text = code;
                            _processScan(code, bypassLock: true);
                          },
                        );
                      })
                      .toList(),
            ),
          ],
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ម៉ាស៊ីនស្កេនវត្តមាន',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontFamily: 'Khmer OS Muol Light',
                        ),
                      ),
                      Text(
                        'Live Attendance Scanner',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11.5,
                          fontFamily: 'Calibri Light',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Inputs Section: Scrollable on Desktop, normal padding on Mobile
          if (isMobile)
            Padding(
              padding: const EdgeInsets.all(18),
              child: inputsColumn,
            )
          else
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: inputsColumn,
              ),
            ),

          // Scanned Person Profile Card or Standby Footer
          _buildScannedPersonCard(),
        ],
      ),
    );
  }

  Widget _buildScannerBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Camera Viewport
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_isScannerSupported &&
                      _isCameraActive &&
                      _scannerController != null)
                    MobileScanner(
                      key: ValueKey(_scannerController),
                      controller: _scannerController!,
                      errorBuilder: (context, error) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.videocam_off_rounded,
                                  color: Colors.white54,
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'មិនអាចភ្ជាប់កាមេរ៉ាបានទេ ឬគ្មានសិទ្ធិអនុញ្ញាត\nសូមប្រើប្រអប់វាយបញ្ចូល ID ឬកាំភ្លើងស្កេន USB ខាងឆ្វេង',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontFamily: 'Khmer OS Battambang',
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      onDetect: (capture) {
                        final List<Barcode> barcodes = capture.barcodes;
                        if (barcodes.isNotEmpty &&
                            barcodes.first.rawValue != null) {
                          _processScan(barcodes.first.rawValue!);
                        }
                      },
                    )
                  else if (!_isScannerSupported)
                    _buildHardwareScannerViewport()
                  else
                    const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.videocam_off_rounded,
                          color: Colors.white24,
                          size: 64,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'កាមេរ៉ាត្រូវបានបិទ',
                          style: TextStyle(
                            color: Colors.white54,
                            fontFamily: 'Khmer OS Battambang',
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),

                  // Scanning Overlay
                  if (_isScannerSupported && _isCameraActive)
                    AnimatedBuilder(
                      animation: _scanAnimation,
                      builder: (ctx, child) {
                        return CustomPaint(
                          painter: ScannerOverlayPainter(
                            animationValue: _scanAnimation.value,
                          ),
                        );
                      },
                    ),

                  // Camera Toggle Button
                  if (_isScannerSupported)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Material(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _toggleCamera,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              _isCameraActive
                                  ? Icons.flip_camera_ios_rounded
                                  : Icons.videocam_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Recent Scans History & Classroom Roster Tabs
        Expanded(flex: 5, child: _buildHistoryAndRosterPanel()),
      ],
    );
  }

  Widget _buildHistoryAndRosterPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Tab Bar and Refresh Button
          Row(
            children: [
              // Tab Switcher
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildTabButton(
                      index: 0,
                      icon: Icons.history_rounded,
                      title: 'ប្រវត្តិស្កេនថ្មីៗ',
                      badgeCount: _recentScans.length,
                    ),
                    const SizedBox(width: 4),
                    _buildTabButton(
                      index: 1,
                      icon: Icons.people_outline_rounded,
                      title: 'សិស្សក្នុងថ្នាក់',
                      badgeCount: _classroomStudents.length,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Refresh Button
              InkWell(
                onTap: () {
                  _fetchRecentScans();
                  if (_selectedClassroomId != null) {
                    _fetchClassroomStudents(_selectedClassroomId!);
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isRecentScansLoading || _isLoadingClassStudents)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF4F46E5),
                          ),
                        )
                      else
                        const Icon(
                          Icons.refresh_rounded,
                          size: 16,
                          color: Color(0xFF4F46E5),
                        ),
                      const SizedBox(width: 6),
                      const Text(
                        'ទាញទិន្នន័យ',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Khmer OS Battambang',
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Tab Content
          Expanded(
            child: _historyTabIndex == 0
                ? _buildRecentScansList()
                : _buildClassRosterList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required IconData icon,
    required String title,
    required int badgeCount,
  }) {
    final isSelected = _historyTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _historyTabIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? const Color(0xFF4F46E5)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Khmer OS Battambang',
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF64748B),
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF4F46E5)
                      : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'Calibri Light',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentScansList() {
    if (_isRecentScansLoading && _recentScans.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recentScans.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.history_toggle_off_rounded,
              color: Color(0xFFCBD5E1),
              size: 40,
            ),
            const SizedBox(height: 8),
            const Text(
              'មិនទាន់មានទិន្នន័យស្កេននៅឡើយទេ',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontFamily: 'Khmer OS Battambang',
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _fetchRecentScans,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text(
                'ទាញយកទិន្នន័យពី Server',
                style: TextStyle(fontFamily: 'Khmer OS Battambang'),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _recentScans.length,
      // ignore: unnecessary_underscores
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final scan = _recentScans[i];
        final isSuccess = scan['success'] == true;
        final nameKh = scan['name_kh']?.toString() ?? 'សិស្ស';
        final code = scan['code']?.toString() ?? '';
        final className = scan['class_name']?.toString() ?? 'ទូទៅ';
        final timeStr = scan['time_str']?.toString() ?? '';
        final photoUrl = scan['photo_url']?.toString();

        return InkWell(
          onTap: () {
            setState(() {
              _lastScannedPerson = Map<String, dynamic>.from(scan);
              _isSuccess = isSuccess;
              _scanResult = 'មើលព័ត៌មាន៖ $nameKh ($code)';
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _lastScannedPerson?['code'] == code
                    ? const Color(0xFF818CF8)
                    : const Color(0xFFF1F5F9),
                width: _lastScannedPerson?['code'] == code ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                _buildAvatar(photoUrl, nameKh, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              nameKh,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Khmer OS Battambang',
                                fontSize: 13,
                                color: Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              code,
                              style: const TextStyle(
                                fontSize: 10,
                                fontFamily: 'Calibri Light',
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'ថ្នាក់៖ $className • វេន៖ ${scan['shift'] ?? 'ព្រឹក'}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'Khmer OS Battambang',
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSuccess
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isSuccess ? 'មានវត្តមាន' : 'អវត្តមាន',
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'Khmer OS Battambang',
                          fontWeight: FontWeight.bold,
                          color: isSuccess
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Calibri Light',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClassRosterList() {
    if (_isLoadingClassStudents && _classroomStudents.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_classroomStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.school_outlined,
              color: Color(0xFFCBD5E1),
              size: 40,
            ),
            const SizedBox(height: 8),
            const Text(
              'គ្មានសិស្សនៅក្នុងថ្នាក់ដែលបានជ្រើសរើសទេ',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontFamily: 'Khmer OS Battambang',
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () {
                if (_selectedClassroomId != null) {
                  _fetchClassroomStudents(_selectedClassroomId!);
                }
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text(
                'ផ្ទុកបញ្ជីសិស្សឡើងវិញ',
                style: TextStyle(fontFamily: 'Khmer OS Battambang'),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _classroomStudents.length,
      // ignore: unnecessary_underscores
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final s = _classroomStudents[i];
        final nameKh = s['name_kh']?.toString() ?? '';
        final code = s['student_code']?.toString() ?? '';
        final photoUrl = s['photo_url']?.toString();
        final status = s['status']?.toString() ?? 'Not Scanned';
        final isPresent = status.toLowerCase() == 'present';
        final timeStr = s['time']?.toString() ?? '';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPresent
                  ? const Color(0xFFBBF7D0)
                  : const Color(0xFFF1F5F9),
            ),
          ),
          child: Row(
            children: [
              _buildAvatar(photoUrl, nameKh, size: 40, isOnline: isPresent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            nameKh,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Khmer OS Battambang',
                              fontSize: 13,
                              color: Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          code,
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'Calibri Light',
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isPresent
                          ? 'បានស្កេនរួចរាល់ • ម៉ោង $timeStr'
                          : 'មិនទាន់ស្កេនវត្តមាន',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'Khmer OS Battambang',
                        color: isPresent
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF94A3B8),
                        fontWeight: isPresent
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              if (isPresent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: Color(0xFF16A34A),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'មានវត្តមាន',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'Khmer OS Battambang',
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: () => _processScan(code, bypassLock: true),
                  icon: const Icon(Icons.check, size: 14),
                  label: const Text(
                    'កត់វត្តមាន',
                    style: TextStyle(
                      fontFamily: 'Khmer OS Battambang',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minimumSize: const Size(0, 32),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHardwareScannerViewport() {
    return Container(
      color: const Color(0xFF0F172A),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _scanAnimation,
              builder: (ctx, child) {
                return CustomPaint(
                  painter: ScannerOverlayPainter(
                    animationValue: _scanAnimation.value,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                        blurRadius: 28,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 60,
                    color: Color(0xFF38BDF8),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'ម៉ាស៊ីនស្កេនកូដ (Barcode & QR Scanner)',
                  style: TextStyle(
                    fontFamily: 'Khmer OS Muol Light',
                    fontSize: 17,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF065F46),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF10B981)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF34D399),
                        size: 15,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'ប្រព័ន្ធស្កេន USB & វាយបញ្ចូលកូដ រួចរាល់ (Active)',
                        style: TextStyle(
                          fontFamily: 'Khmer OS Battambang',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'សូមប្រើកាំភ្លើងស្កេនបាកូដ USB ឬវាយបញ្ចូលអត្តលេខសិស្ស/គ្រូក្នុងប្រអប់ខាងឆ្វេង',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Khmer OS Battambang',
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Container(
      color: const Color(0xFFF8FAFC),
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: isMobile
          ? SingleChildScrollView(
              child: Column(
                children: [
                  _buildControlPanel(isMobile: true),
                  const SizedBox(height: 24),
                  SizedBox(height: 600, child: _buildScannerBox()),
                ],
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 4, child: _buildControlPanel(isMobile: false)),
                const SizedBox(width: 32),
                Expanded(flex: 6, child: _buildScannerBox()),
              ],
            ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final double animationValue;
  ScannerOverlayPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw scanning bounding box
    final boxWidth = size.width * 0.6;
    final boxHeight = size.width * 0.6;
    final left = (size.width - boxWidth) / 2;
    final top = (size.height - boxHeight) / 2;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, boxWidth, boxHeight),
      const Radius.circular(24),
    );
    canvas.drawRRect(rrect, borderPaint);

    // Draw animated scan line
    final lineY = top + (boxHeight * animationValue);
    final linePaint = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Glow effect
    final glowPaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.4)
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawLine(
      Offset(left + 20, lineY),
      Offset(left + boxWidth - 20, lineY),
      glowPaint,
    );
    canvas.drawLine(
      Offset(left + 20, lineY),
      Offset(left + boxWidth - 20, lineY),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(ScannerOverlayPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}
