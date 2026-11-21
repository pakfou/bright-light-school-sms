// lib/screens/id_card_studio_screen.dart
import 'package:flutter/material.dart';
import '../models/app_models.dart';

class IdCardStudioScreen extends StatefulWidget {
  const IdCardStudioScreen({super.key});

  @override
  State<IdCardStudioScreen> createState() => _IdCardStudioScreenState();
}

class _IdCardStudioScreenState extends State<IdCardStudioScreen> {
  bool _isStudent = true; // true = Student Card, false = Teacher Card
  String _selectedStudentId = 's1';
  String _selectedTeacherId = 't1';
  bool _showBack = false;

  @override
  Widget build(BuildContext context) {
    final store = AppDataStore.instance;
    final student = store.students.firstWhere(
      (s) => s.id == _selectedStudentId,
      orElse: () => store.students.first,
    );
    final teacher = store.teachers.firstWhere(
      (t) => t.id == _selectedTeacherId,
      orElse: () => store.teachers.first,
    );

    final classroom = store.classrooms.firstWhere(
      (c) => c.id == student.classroomId,
      orElse: () => Classroom(
        id: '',
        gradeLevel: 'ថ្នាក់ទី ១A',
        roomName: 'បន្ទប់ ១០១',
        programType: student.programType,
        shift: ShiftType.morning,
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar with Switcher
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ស្ទូឌីយោកាតសម្គាល់ (ID Card Studio)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isStudent
                            ? 'កាតសម្គាល់សិស្ស៖ ភ្ជាប់ QR Code ស្កេនវត្តមានសិស្ស ព័ត៌មានអាណាព្យាបាល និងកម្រិតថ្នាក់'
                            : 'កាតសម្គាល់គ្រូបង្រៀន៖ ភ្ជាប់ QR Code ស្កេនវត្តមានគ្រូ កូដគ្រូ ជំនាញឯកទេស និងត្រាសាលា',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                // Card Category Switcher
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      icon: Icon(Icons.school_outlined, size: 16),
                      label: Text('កាតសិស្ស (Student ID)'),
                    ),
                    ButtonSegment(
                      value: false,
                      icon: Icon(Icons.badge_outlined, size: 16),
                      label: Text('កាតគ្រូ (Teacher ID)'),
                    ),
                  ],
                  selected: {_isStudent},
                  onSelectionChanged: (val) => setState(() => _isStudent = val.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Main Studio Content Area
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Control Panel: Selector & Actions
                Container(
                  width: 320,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isStudent ? 'ជ្រើសរើសសិស្សដើម្បីបង្កើតកាត' : 'ជ្រើសរើសគ្រូដើម្បីបង្កើតកាត',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      if (_isStudent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedStudentId,
                            isExpanded: true,
                            underline: const SizedBox(),
                            items: store.students.map((s) {
                              return DropdownMenuItem(
                                value: s.id,
                                child: Text('${s.khmerName} (${s.studentCode})'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedStudentId = val);
                            },
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedTeacherId,
                            isExpanded: true,
                            underline: const SizedBox(),
                            items: store.teachers.map((t) {
                              return DropdownMenuItem(
                                value: t.id,
                                child: Text('${t.fullName} (${t.teacherCode})'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedTeacherId = val);
                            },
                          ),
                        ),
                      const SizedBox(height: 20),

                      // Card Flip Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('បង្ហាញផ្នែកខាងក្រោយ (Back)', style: TextStyle(fontWeight: FontWeight.w600)),
                          Switch(
                            value: _showBack,
                            onChanged: (v) => setState(() => _showBack = v),
                          ),
                        ],
                      ),
                      const Divider(height: 32),

                      // Information summary
                      Text(
                        _isStudent ? 'ព័ត៌មានលើកាតសិស្ស' : 'ព័ត៌មានលើកាតគ្រូ',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 10),
                      if (_isStudent) ...[
                        _buildInfoRow('កូដសិស្ស៖', student.studentCode),
                        _buildInfoRow('ឈ្មោះខ្មែរ៖', student.khmerName),
                        _buildInfoRow('ឈ្មោះឡាតាំង៖', student.latinName),
                        _buildInfoRow('ថ្នាក់រៀន៖', classroom.gradeLevel),
                        _buildInfoRow('អាណាព្យាបាល៖', student.parentPhone),
                        _buildInfoRow('QR Scan:', 'វត្តមាន & ពិនិត្យពិន្ទុ'),
                      ] else ...[
                        _buildInfoRow('កូដគ្រូ៖', teacher.teacherCode),
                        _buildInfoRow('ឈ្មោះគ្រូ៖', teacher.fullName),
                        _buildInfoRow('ឈ្មោះឡាតាំង៖', teacher.latinName),
                        _buildInfoRow('ជំនាញឯកទេស៖', teacher.subjectSpecialty),
                        _buildInfoRow('ទូរស័ព្ទ៖', teacher.phone),
                        _buildInfoRow('QR Scan:', 'វត្តមានបង្រៀន & Check-in'),
                      ],

                      const Spacer(),

                      // Print & Export Action Buttons
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                          icon: const Icon(Icons.print, color: Colors.white, size: 18),
                          label: const Text('បោះពុម្ពកាតនេះ (Print ID Card)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('កំពុងបញ្ជូនប័ណ្ណសម្គាល់ខ្លួន ${_isStudent ? student.khmerName : teacher.fullName} ទៅកាន់ម៉ាស៊ីនបោះពុម្ព...'),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('ទាញយកជារូបភាព PNG'),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('បានរក្សាទុកប័ណ្ណសម្គាល់ខ្លួនជា High-Resolution PNG!')),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // Right Live Card Preview Area
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _showBack
                                  ? (_isStudent ? 'ផ្នែកខាងក្រោយកាតសិស្ស (Student Card Back)' : 'ផ្នែកខាងក្រោយកាតគ្រូ (Teacher Card Back)')
                                  : (_isStudent ? 'ផ្នែកខាងមុខកាតសិស្ស (Student Card Front)' : 'ផ្នែកខាងមុខកាតគ្រូ (Teacher Card Front)'),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                            ),
                            const SizedBox(height: 20),

                            // Actual ID Card Container
                            _showBack
                                ? _buildCardBack()
                                : (_isStudent ? _buildStudentCardFront(student, classroom) : _buildTeacherCardFront(teacher)),
                            const SizedBox(height: 24),

                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.verified, size: 16, color: Color(0xFF16A34A)),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isStudent
                                        ? 'កាតសិស្សមាន QR ស្កេនវត្តមានស្វ័យប្រវត្ត (គ្មានរន្ធខ្សែ Lanyard)'
                                        : 'កាតគ្រូបង្រៀនមាន QR Check-in វត្តមានបង្រៀន (ផ្លូវការ)',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  // STUDENT CARD FRONT
  Widget _buildStudentCardFront(Student student, Classroom classroom) {
    return Container(
      width: 440,
      height: 270,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Watermark Logo
          Positioned(
            right: -20,
            bottom: -20,
            child: Opacity(
              opacity: 0.08,
              child: const Icon(Icons.school, size: 240, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.school, color: Color(0xFF1E3A8A), size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'សាលាបឋមសិក្សា ប្រាយ ឡាយ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          Text(
                            'BRIGHT LIFE PRIMARY SCHOOL',
                            style: TextStyle(color: Colors.white70, fontSize: 8.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('STUDENT', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                const Divider(color: Colors.white24, height: 16),

                // Card Body
                Expanded(
                  child: Row(
                    children: [
                      // Photo
                      Column(
                        children: [
                          Container(
                            width: 86,
                            height: 104,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                color: student.gender == 'F' ? const Color(0xFFFCE7F3) : const Color(0xFFE0F2FE),
                                child: Center(
                                  child: Icon(
                                    Icons.person,
                                    size: 56,
                                    color: student.gender == 'F' ? const Color(0xFFEC4899) : const Color(0xFF0284C7),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade700,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              student.studentCode,
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),

                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              student.khmerName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              student.latinName.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.amberAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildCardField('ភេទ / Gender:', student.gender == 'F' ? 'ស្រី / Female' : 'ប្រុស / Male'),
                            _buildCardField('ថ្នាក់ / Class:', classroom.gradeLevel),
                            _buildCardField('កម្មវិធី / Program:', student.programType == ProgramType.fullTime ? 'ពេញម៉ោង' : 'ក្រៅម៉ោង'),
                            _buildCardField('អាណាព្យាបាល:', student.parentPhone),
                          ],
                        ),
                      ),

                      // QR Code for Student Attendance
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.qr_code_2, size: 84, color: Colors.black87),
                            const SizedBox(height: 2),
                            const Text(
                              'QR ស្កេនវត្តមាន',
                              style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TEACHER CARD FRONT
  Widget _buildTeacherCardFront(Teacher teacher) {
    return Container(
      width: 440,
      height: 270,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Opacity(
              opacity: 0.08,
              child: const Icon(Icons.badge, size: 240, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.account_balance, color: Color(0xFF0D9488), size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'សាលាបឋមសិក្សា ប្រាយ ឡាយ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          Text(
                            'BRIGHT LIFE PRIMARY SCHOOL',
                            style: TextStyle(color: Colors.white70, fontSize: 8.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('TEACHER / FACULTY', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                const Divider(color: Colors.white24, height: 16),

                // Body
                Expanded(
                  child: Row(
                    children: [
                      // Photo
                      Column(
                        children: [
                          Container(
                            width: 86,
                            height: 104,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                color: const Color(0xFFCCFBF1),
                                child: const Center(
                                  child: Icon(Icons.person, size: 56, color: Color(0xFF0F766E)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF14B8A6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              teacher.teacherCode,
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),

                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              teacher.fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              teacher.latinName.toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF5EEAD4),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildCardField('តួនាទី / Role:', 'គ្រូបង្រៀន (Faculty)'),
                            _buildCardField('ជំនាញ / Subject:', teacher.subjectSpecialty),
                            _buildCardField('កម្រិតវប្បធម៌:', teacher.educationDegree),
                            _buildCardField('ទូរស័ព្ទ / Phone:', teacher.phone),
                          ],
                        ),
                      ),

                      // QR Code for Teacher Attendance Check-In
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.qr_code_2, size: 84, color: Colors.black87),
                            const SizedBox(height: 2),
                            const Text(
                              'QR ស្កេនវត្តមានគ្រូ',
                              style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // CARD BACK
  Widget _buildCardBack() {
    return Container(
      width: 440,
      height: 270,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'លក្ខខណ្ឌនៃការប្រើប្រាស់ប័ណ្ណ (TERMS & CONDITIONS)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF0F172A)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('DISCIPLINE • RESPECT • HONESTY', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
              )
            ],
          ),
          const Divider(height: 14),
          const Text('១. ប័ណ្ណនេះត្រូវតែពាក់ជាប់ខ្លួនពេលចូលក្នុងបរិវេណសាលា និងពេលស្កេនវត្តមាន។', style: TextStyle(fontSize: 10, height: 1.4)),
          const Text('២. មិនអនុញ្ញាតឱ្យផ្ទេរ ឬខ្ចីប័ណ្ណនេះទៅបុគ្គលដទៃប្រើប្រាស់ជំនួសឡើយ។', style: TextStyle(fontSize: 10, height: 1.4)),
          const Text('៣. ករណីបាត់បង់ ឬខូចខាត សូមរាយការណ៍មកការិយាល័យរដ្ឋបាលជាបន្ទាន់។', style: TextStyle(fontSize: 10, height: 1.4)),
          const Text('៤. ប័ណ្ណនេះជាសម្បត្តិផ្លូវការរបស់សាលាបឋមសិក្សា ប្រាយ ឡាយ។', style: TextStyle(fontSize: 10, height: 1.4)),
          const Spacer(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ការិយាល័យរដ្ឋបាល & ទំនាក់ទំនង៖', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                  Text('ទូរស័ព្ទ៖ 078 350 908 / 088 757 4732', style: TextStyle(fontSize: 9.5, color: Colors.blue.shade900, fontWeight: FontWeight.bold)),
                  const Text('ក្រុងប៉ោយប៉ែត ខេត្តបន្ទាយមានជ័យ, កម្ពុជា', style: TextStyle(fontSize: 9, color: Colors.grey)),
                ],
              ),
              Column(
                children: [
                  const Text('នាយកសាលា / Principal', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: const Text('[ ត្រា & ហត្ថលេខា ]', style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 3),
            color: const Color(0xFFF1F5F9),
            child: const Text(
              'បើបានរើស សូមប្រគល់ជូនសាលាវិញ / If found, please return to Bright Life School',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 8.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCardField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9.5)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
