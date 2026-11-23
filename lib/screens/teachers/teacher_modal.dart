import 'package:school_management_app/config/api_config.dart';
import 'package:school_management_app/services/api_service.dart';
// ignore_for_file: avoid_web_libraries_in_flutter
// ignore: unused_import
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

class TeacherModal extends StatefulWidget {
  final Map<String, dynamic>? teacher;
  final VoidCallback onSaved;

  const TeacherModal({super.key, this.teacher, required this.onSaved});

  @override
  State<TeacherModal> createState() => _TeacherModalState();
}

class _TeacherModalState extends State<TeacherModal> {
  // ignore: unused_field
  static String get baseUrl => ApiService.baseUrl;

  // ignore: unused_field
  final _formKey = GlobalKey<FormState>();

  // ignore: unused_field
  late TextEditingController _codeCtrl;
  // ignore: unused_field
  late TextEditingController _nameKhCtrl;
  // ignore: unused_field
  late TextEditingController _nameEnCtrl;
  // ignore: unused_field
  late TextEditingController _phoneCtrl;
  // ignore: unused_field
  late TextEditingController _emailCtrl;
  // ignore: unused_field
  late TextEditingController _subjectCtrl;
  // ignore: unused_field
  late TextEditingController _salaryCtrl;
  // ignore: unused_field
  late TextEditingController _photoUrlCtrl;
  // ignore: unused_field
  late TextEditingController _roleTitleCtrl;

  // ignore: unused_field
  String _gender = 'Male';
  // ignore: unused_field
  String _status = 'Active';
  DateTime? _dob;
  DateTime? _hireDate;
  // ignore: unused_field, prefer_final_fields
  bool _isLoading = false;
  // ignore: unused_field
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    final t = widget.teacher;
    final rCode =
        'TCH-${1000 + (DateTime.now().millisecondsSinceEpoch % 9000)}';

    _codeCtrl = TextEditingController(text: t?['teacher_code'] ?? rCode);
    _nameKhCtrl = TextEditingController(text: t?['name_kh'] ?? '');
    _nameEnCtrl = TextEditingController(text: t?['name_en'] ?? '');
    _phoneCtrl = TextEditingController(text: t?['phone'] ?? '');
    _emailCtrl = TextEditingController(text: t?['email'] ?? '');
    _roleTitleCtrl = TextEditingController(
      text: t?['role_title'] ?? 'គ្រូបង្រៀន',
    );
    _subjectCtrl = TextEditingController(
      text: t?['specialized_subject'] ?? 'វិទ្យាសាស្ត្រកុំព្យូទ័រ',
    );
    _salaryCtrl = TextEditingController(
      text: t?['base_salary']?.toString() ?? '350.00',
    );
    _photoUrlCtrl = TextEditingController(text: t?['photo_url'] ?? '');

    _gender = t?['gender'] ?? 'Male';
    _status = t?['status'] ?? 'Active';
    if (t?['dob'] != null) _dob = DateTime.tryParse(t!['dob'].toString());
    final hireVal = t?['hire_date'] ?? t?['joined_date'];
    if (hireVal != null) {
      _hireDate = DateTime.tryParse(hireVal.toString());
    }
  }

  // ignore: unused_element
  Future<void> _selectDate(BuildContext context, bool isDob) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDob
          ? (_dob ?? DateTime(1995, 1, 1))
          : (_hireDate ?? DateTime.now()),
      firstDate: DateTime(1960),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        // ignore: curly_braces_in_flow_control_structures
        if (isDob)
          // ignore: curly_braces_in_flow_control_structures
          _dob = picked;
        // ignore: curly_braces_in_flow_control_structures
        else
          // ignore: curly_braces_in_flow_control_structures
          _hireDate = picked;
      });
    }
  }

  Future<void> _pickImageFromComputer() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 350,
        maxHeight: 350,
        imageQuality: 75,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        final ext = file.name.split('.').last.toLowerCase();
        final mimeType = ext == 'png' ? 'png' : 'jpeg';
        final base64String = 'data:image/$mimeType;base64,${base64Encode(bytes)}';

        setState(() {
          _imageBytes = bytes;
          _photoUrlCtrl.text = base64String;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _saveTeacher() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final payload = {
      'teacher_code': _codeCtrl.text.trim(),
      'name_kh': _nameKhCtrl.text.trim(),
      'name_en': _nameEnCtrl.text.trim(),
      'gender': _gender,
      'dob': _dob?.toIso8601String(),
      'phone': _phoneCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'role_title': _roleTitleCtrl.text.trim(),
      'specialized_subject': _subjectCtrl.text.trim(),
      'base_salary': double.tryParse(_salaryCtrl.text.trim()) ?? 0.0,
      'status': _status,
      'hire_date': _hireDate?.toIso8601String(),
      'photo_url': _photoUrlCtrl.text.trim().isEmpty
          ? null
          : _photoUrlCtrl.text.trim(),
    };

    try {
      final teacherId = widget.teacher != null ? (widget.teacher!['id'] ?? widget.teacher!['teacher_code']) : null;
      final url = widget.teacher != null
          ? '$baseUrl/teachers/$teacherId'
          : '$baseUrl/teachers';
      final method = widget.teacher != null ? http.put : http.post;

      final res = await method(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 30));
      final data = jsonDecode(utf8.decode(res.bodyBytes));

      if ((res.statusCode == 200 || res.statusCode == 201) &&
          data['success'] == true) {
        if (!mounted) return;
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  data['message'] ?? 'បានរក្សាទុកជោគជ័យ!',
                  style: const TextStyle(
                    fontFamily: 'Khmer OS Battambang',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        if (!mounted) return;
        final errMsg = data['message'] ?? data['error'] ?? 'បរាជ័យក្នុងការរក្សាទុក!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'កំហុសពី Server: $errMsg',
              style: const TextStyle(fontFamily: 'Khmer OS Battambang'),
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'បរាជ័យក្នុងការតភ្ជាប់ Server: $e',
            style: const TextStyle(fontFamily: 'Khmer OS Battambang'),
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = _photoUrlCtrl.text.trim();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: MediaQuery.of(context).size.width > 760
            ? 720
            : MediaQuery.of(context).size.width * 0.95,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 720,
        ),
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_pin_rounded,
                      color: Color(0xFF4F46E5),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ចុះឈ្មោះគ្រូបង្រៀនថ្មី (Teacher Registration)',
                          style: GoogleFonts.notoSansKhmer(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'សាលាប្រាយឡាយ • ព័ត៌មានលម្អិត ១៦ ចំណុច',
                          style: GoogleFonts.notoSansKhmer(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF94A3B8),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Scrollable Body
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Section: Photo Upload & Avatar Preview
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: _pickImageFromComputer,
                              borderRadius: BorderRadius.circular(42),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 84,
                                    height: 84,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF4F46E5),
                                        width: 2.5,
                                      ),
                                      color: const Color(0xFFEEF2FF),
                                    ),
                                    child: ClipOval(
                                      child: _imageBytes != null
                                          ? Image.memory(
                                              _imageBytes!,
                                              fit: BoxFit.cover,
                                            )
                                          : (photoUrl.startsWith('data:image')
                                                ? Image.memory(
                                                    base64Decode(
                                                      photoUrl.split(',').last,
                                                    ),
                                                    fit: BoxFit.cover,
                                                  )
                                                : (photoUrl.isNotEmpty
                                                      ? Image.network(
                                                          photoUrl,
                                                          fit: BoxFit.cover,
                                                          // ignore: unnecessary_underscores
                                                          errorBuilder:
                                                              (
                                                                _,
                                                                // ignore: unnecessary_underscores
                                                                __,
                                                                // ignore: unnecessary_underscores
                                                                ___,
                                                              ) => const Icon(
                                                                Icons.person,
                                                                size: 48,
                                                                color: Color(
                                                                  0xFF4F46E5,
                                                                ),
                                                              ),
                                                        )
                                                      : const Icon(
                                                          Icons.person,
                                                          size: 48,
                                                          color: Color(
                                                            0xFF4F46E5,
                                                          ),
                                                        ))),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF4F46E5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'រូបថតគ្រូបង្រៀន (Teacher Photo):',
                                    style: GoogleFonts.notoSansKhmer(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF334155),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _photoUrlCtrl,
                                    style: GoogleFonts.notoSansKhmer(),
                                    onChanged: (_) => setState(() {}),
                                    decoration: _inputStyle(
                                      'តំណភ្ជាប់រូបភាព (Photo URL - ជម្រើស)',
                                      Icons.link_rounded,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Row 1: Code & Khmer Name
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _codeCtrl,
                              label: 'អត្តលេខគ្រូ (Teacher Code)',
                              icon: Icons.tag,
                              readOnly: true,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildTextField(
                              controller: _nameKhCtrl,
                              label: 'ឈ្មោះខ្មែរ *',
                              icon: Icons.person_outline,
                              validator: (v) =>
                                  v!.trim().isEmpty ? 'សូមបញ្ចូលឈ្មោះ' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Row 2: English Name & Gender
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _nameEnCtrl,
                              label: 'ឈ្មោះឡាតាំង (English)',
                              icon: Icons.translate,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: (_gender == 'Female') ? 'Female' : 'Male',
                              decoration: _inputStyle(
                                'ភេទ (Gender)',
                                Icons.transgender,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Male',
                                  child: Text('ប្រុស (Male)'),
                                ),
                                DropdownMenuItem(
                                  value: 'Female',
                                  child: Text('ស្រី (Female)'),
                                ),
                              ],
                              onChanged: (v) => setState(() => _gender = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Row 3: Phone & Email
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _phoneCtrl,
                              label: 'លេខទូរស័ព្ទ',
                              icon: Icons.phone_android_rounded,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildTextField(
                              controller: _emailCtrl,
                              label: 'អ៊ីមែល (Email)',
                              icon: Icons.email_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Row 4: Subject & Base Salary
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _subjectCtrl,
                              label: 'មុខវិជ្ជាឯកទេស',
                              icon: Icons.book_outlined,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildTextField(
                              controller: _salaryCtrl,
                              label: 'ប្រាក់ខែគោល (\$)',
                              icon: Icons.attach_money_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Row 5: DOB & Hire Date
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, true),
                              child: InputDecorator(
                                decoration: _inputStyle(
                                  'ថ្ងៃខែឆ្នាំកំណើត (DOB)',
                                  Icons.cake_outlined,
                                ),
                                child: Text(
                                  _dob == null
                                      ? 'ជ្រើសរើសថ្ងៃ...'
                                      : DateFormat('dd/MM/yyyy').format(_dob!),
                                  style: GoogleFonts.notoSansKhmer(
                                    color: _dob == null
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, false),
                              child: InputDecorator(
                                decoration: _inputStyle(
                                  'ថ្ងៃចូលបម្រើការ (Hire Date)',
                                  Icons.calendar_month_outlined,
                                ),
                                child: Text(
                                  _hireDate == null
                                      ? 'ជ្រើសរើសថ្ងៃ...'
                                      : DateFormat(
                                          'dd/MM/yyyy',
                                        ).format(_hireDate!),
                                  style: GoogleFonts.notoSansKhmer(
                                    color: _hireDate == null
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Row 6: ស្ថានភាពសកម្មភាព (Status / Activity) & តួនាទី (Role Title)
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: ['Active', 'On Leave', 'Suspended', 'Inactive'].contains(_status)
                                  ? _status
                                  : 'Active',
                              decoration: _inputStyle(
                                'ស្ថានភាពសកម្មភាព (Status)',
                                Icons.verified_user_outlined,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Active',
                                  child: Row(
                                    children: [
                                      Icon(Icons.circle, color: Color(0xFF16A34A), size: 12),
                                      SizedBox(width: 8),
                                      Text('សកម្ម (Active)'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'On Leave',
                                  child: Row(
                                    children: [
                                      Icon(Icons.circle, color: Color(0xFFEAB308), size: 12),
                                      SizedBox(width: 8),
                                      Text('ឈប់សម្រាក (On Leave)'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Suspended',
                                  child: Row(
                                    children: [
                                      Icon(Icons.circle, color: Color(0xFFEF4444), size: 12),
                                      SizedBox(width: 8),
                                      Text('ផ្អាកបណ្តោះអាសន្ន (Suspended)'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Inactive',
                                  child: Row(
                                    children: [
                                      Icon(Icons.circle, color: Color(0xFF64748B), size: 12),
                                      SizedBox(width: 8),
                                      Text('អសកម្ម (Inactive)'),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _status = v);
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildTextField(
                              controller: _roleTitleCtrl,
                              label: 'តួនាទី / មុខតំណែង (Role Title)',
                              icon: Icons.badge_outlined,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // Actions (បិទ & រក្សាទុក)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'បិទ',
                      style: GoogleFonts.notoSansKhmer(
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5), // Indigo Accent
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _isLoading ? null : _saveTeacher,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      'រក្សាទុក',
                      style: GoogleFonts.notoSansKhmer(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF4F46E5), size: 18),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool readOnly = false,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      validator: validator,
      onChanged: onChanged,
      style: GoogleFonts.notoSansKhmer(),
      decoration: _inputStyle(
        label,
        icon ?? Icons.edit,
      ).copyWith(fillColor: readOnly ? const Color(0xFFF1F5F9) : Colors.white),
    );
  }
}
