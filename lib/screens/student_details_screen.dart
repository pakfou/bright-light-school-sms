// lib/screens/student_details_screen.dart
import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../widgets/id_card_creator.dart';

class StudentDetailsScreen extends StatefulWidget {
  const StudentDetailsScreen({super.key});

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  String _searchQuery = '';
  final String _selectedClassFilter = 'All';
  String _selectedProgramFilter = 'All';

  void _openStudentHistoryModal(Student student) {
    final store = AppDataStore.instance;
    final classroom = store.classrooms.firstWhere(
      (c) => c.id == student.classroomId,
      orElse: () => Classroom(
        id: '',
        gradeLevel: 'ថ្នាក់ទូទៅ',
        roomName: 'បន្ទប់ ១០១',
        programType: student.programType,
        shift: ShiftType.morning,
      ),
    );

    showDialog(
      context: context,
      builder: (ctx) => DefaultTabController(
        length: 3,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 720,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.88,
              maxWidth: 720,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // Modal Top Banner & Profile Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: student.gender == 'M' ? const Color(0xFF2563EB) : const Color(0xFFEC4899),
                        child: Text(
                          student.khmerName.isNotEmpty ? student.khmerName.substring(0, 1) : 'S',
                          style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  student.khmerName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade700,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    student.studentCode,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${student.latinName} • ថ្នាក់រៀន៖ ${classroom.gradeLevel} (${classroom.roomName})',
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),

                // Navigation Tabs
                Container(
                  color: const Color(0xFFF8FAFC),
                  child: const TabBar(
                    labelColor: Color(0xFF2563EB),
                    unselectedLabelColor: Color(0xFF64748B),
                    indicatorColor: Color(0xFF2563EB),
                    tabs: [
                      Tab(icon: Icon(Icons.person_outline, size: 18), text: "ព័ត៌មានទូទៅ & អាណាព្យាបាល"),
                      Tab(icon: Icon(Icons.history_edu, size: 18), text: "ប្រវត្តិសិក្សា & ពិន្ទុ"),
                      Tab(icon: Icon(Icons.fact_check_outlined, size: 18), text: "ប្រវត្តិនៃការស្រង់វត្តមាន"),
                    ],
                  ),
                ),

                // TabBar View Content
                Expanded(
                  child: TabBarView(
                    children: [
                      // TAB 1: ព័ត៌មានទូទៅ & អាណាព្យាបាល
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoSection(
                              title: "ព័ត៌មានផ្ទាល់ខ្លួនរបស់សិស្ស",
                              items: [
                                _infoTile("អត្តលេខសិស្ស", student.studentCode, Icons.badge_outlined),
                                _infoTile("ភេទ", student.gender == 'M' ? 'ប្រុស (Male)' : 'ស្រី (Female)', Icons.transgender_outlined),
                                _infoTile("ថ្ងៃខែឆ្នាំកំណើត", "${student.dob.day}/${student.dob.month}/${student.dob.year}", Icons.cake_outlined),
                                _infoTile("កម្មវិធីសិក្សា", student.programType == ProgramType.fullTime ? 'សិស្សពេញម៉ោង' : 'សិស្សក្រៅម៉ោង', Icons.school_outlined),
                                _infoTile("កាលបរិច្ឆេទចូលរៀន", "${student.enrollmentDate.day}/${student.enrollmentDate.month}/${student.enrollmentDate.year}", Icons.calendar_today_outlined),
                                _infoTile("សាលារៀនពីមុន", student.previousSchool, Icons.apartment_outlined),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildInfoSection(
                              title: "ព័ត៌មានអាណាព្យាបាល និងទំនាក់ទំនង",
                              items: [
                                _infoTile("ឈ្មោះអាណាព្យាបាល", student.parentName, Icons.family_restroom_outlined),
                                _infoTile("លេខទូរស័ព្ទទំនាក់ទំនង", student.parentPhone, Icons.phone_outlined),
                                _infoTile("អាសយដ្ឋានបច្ចុប្បន្ន", student.address, Icons.home_outlined),
                                _infoTile("ស្ថានភាពសុខភាព / ចំណាំ", student.healthNotes, Icons.medical_services_outlined),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // TAB 2: ប្រវត្តិការសិក្សា និងពិន្ទុ
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _metricBadge("មធ្យមភាគប្រចាំខែ", "${student.averageGrade}", const Color(0xFF2563EB)),
                                const SizedBox(width: 12),
                                _metricBadge("ចំណាត់ថ្នាក់ក្នុងថ្នាក់", "លេខ ${student.rankInClass}", const Color(0xFF16A34A)),
                                const SizedBox(width: 12),
                                _metricBadge("និទ្ទេសរួម", student.gradeLetter, const Color(0xFFD97706)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text("លទ្ធផលប្រឡងប្រចាំខែវិច្ឆិកា ២០២៦", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 12),
                            Table(
                              border: TableBorder.all(color: const Color(0xFFE2E8F0)),
                              children: [
                                TableRow(
                                  decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
                                  children: [
                                    _th("មុខវិជ្ជា"),
                                    _th("ពិន្ទុផ្ទះ (50%)"),
                                    _th("ប្រឡង (50%)"),
                                    _th("សរុប"),
                                    _th("និទ្ទេស"),
                                  ],
                                ),
                                _tableRow("ភាសាខ្មែរ", "46", "48", "94.0", "A"),
                                _tableRow("គណិតវិទ្យា", "45", "45", "90.0", "A"),
                                _tableRow("ភាសាអង់គ្លេស", "48", "47", "95.0", "A"),
                                _tableRow("កុំព្យូទ័រ (ICT)", "44", "46", "90.0", "A"),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // TAB 3: ប្រវត្តិនៃការស្រង់វត្តមាន
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _metricBadge("អត្រាវត្តមានសរុប", "${student.attendanceRate}%", const Color(0xFF0D9488)),
                                const SizedBox(width: 12),
                                _metricBadge("មកទាន់ពេល", "២២ ថ្ងៃ", const Color(0xFF16A34A)),
                                const SizedBox(width: 12),
                                _metricBadge("មានច្បាប់", "១ ថ្ងៃ", const Color(0xFF2563EB)),
                                const SizedBox(width: 12),
                                _metricBadge("អវត្តមាន", "០ ថ្ងៃ", const Color(0xFFDC2626)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text("កំណត់ត្រាវត្តមាន ៥ ថ្ងៃចុងក្រោយ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 12),
                            ...List.generate(5, (i) {
                              final d = DateTime.now().subtract(Duration(days: i));
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 18),
                                        const SizedBox(width: 10),
                                        Text("${d.day}/${d.month}/${d.year}"),
                                      ],
                                    ),
                                    const Text("ស្កេនតាម QR Code (០៧:២៥ ព្រឹក)", style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
                                      child: const Text("វត្តមាន (PRESENT)", style: TextStyle(color: Color(0xFF166534), fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Modal Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.badge_outlined, size: 16),
                        label: const Text("បោះពុម្ពប័ណ្ណសិស្ស (ID Card)"),
                        onPressed: () {
                          Navigator.pop(ctx);
                          showDialog(
                            context: context,
                            builder: (_) => IdCardCreatorModal(
                              studentCode: student.studentCode,
                              khmerName: student.khmerName,
                              latinName: student.latinName,
                              gradeLevel: classroom.gradeLevel,
                              programType: student.programType == ProgramType.fullTime ? 'ពេញម៉ោង' : 'ក្រៅម៉ោង',
                            ),
                          );
                        },
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("យល់ព្រម / បិទ", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection({required String title, required List<Widget> items}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E3A8A))),
          const SizedBox(height: 12),
          Wrap(
            spacing: 20,
            runSpacing: 12,
            children: items,
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value, IconData icon) {
    return SizedBox(
      width: 300,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F172A))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricBadge(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _th(String text) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
    );
  }

  TableRow _tableRow(String subj, String hw, String test, String total, String grade) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(10), child: Text(subj, style: const TextStyle(fontWeight: FontWeight.w500))),
        Padding(padding: const EdgeInsets.all(10), child: Text(hw, textAlign: TextAlign.center)),
        Padding(padding: const EdgeInsets.all(10), child: Text(test, textAlign: TextAlign.center)),
        Padding(padding: const EdgeInsets.all(10), child: Text(total, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
        Padding(padding: const EdgeInsets.all(10), child: Text(grade, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB)))),
      ],
    );
  }

  void _openAddStudentModal([Student? editStudent]) {
    final khNameCtrl = TextEditingController(text: editStudent?.khmerName ?? '');
    final enNameCtrl = TextEditingController(text: editStudent?.latinName ?? '');
    final parentCtrl = TextEditingController(text: editStudent?.parentName ?? '');
    final phoneCtrl = TextEditingController(text: editStudent?.parentPhone ?? '');
    final addressCtrl = TextEditingController(text: editStudent?.address ?? '');
    String gender = editStudent?.gender ?? 'M';
    ProgramType progType = editStudent?.programType ?? ProgramType.fullTime;
    String classId = editStudent?.classroomId ?? (AppDataStore.instance.classrooms.isNotEmpty ? AppDataStore.instance.classrooms.first.id : 'c1');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            editStudent == null ? 'ចុះឈ្មោះសិស្សថ្មី (Student Registration)' : 'កែប្រែព័ត៌មានសិស្ស',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: khNameCtrl, decoration: const InputDecoration(labelText: 'ឈ្មោះខ្មែរ (Khmer Name)')),
                  const SizedBox(height: 10),
                  TextField(controller: enNameCtrl, decoration: const InputDecoration(labelText: 'ឈ្មោះឡាតាំង (Latin Name)')),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: gender,
                          decoration: const InputDecoration(labelText: 'ភេទ'),
                          items: const [
                            DropdownMenuItem(value: 'M', child: Text('ប្រុស (Male)')),
                            DropdownMenuItem(value: 'F', child: Text('ស្រី (Female)')),
                          ],
                          onChanged: (val) => setDialogState(() => gender = val!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<ProgramType>(
                          initialValue: progType,
                          decoration: const InputDecoration(labelText: 'ប្រភេទសិក្សា'),
                          items: const [
                            DropdownMenuItem(value: ProgramType.fullTime, child: Text('សិស្សពេញម៉ោង')),
                            DropdownMenuItem(value: ProgramType.partTime, child: Text('សិស្សក្រៅម៉ោង')),
                          ],
                          onChanged: (val) => setDialogState(() => progType = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: classId,
                    decoration: const InputDecoration(labelText: 'ចាត់ចូលបន្ទប់ថ្នាក់'),
                    items: AppDataStore.instance.classrooms.map((c) {
                      return DropdownMenuItem(value: c.id, child: Text('${c.gradeLevel} - ${c.roomName}'));
                    }).toList(),
                    onChanged: (val) => setDialogState(() => classId = val!),
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: parentCtrl, decoration: const InputDecoration(labelText: 'ឈ្មោះអាណាព្យាបាល')),
                  const SizedBox(height: 10),
                  TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'លេខទូរស័ព្ទអាណាព្យាបាល')),
                  const SizedBox(height: 10),
                  TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'អាសយដ្ឋានបច្ចុប្បន្ន')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('បោះបង់')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
              onPressed: () {
                if (khNameCtrl.text.isNotEmpty) {
                  if (editStudent == null) {
                    final newCode = 'BL-2026-${(AppDataStore.instance.students.length + 1).toString().padLeft(3, '0')}';
                    AppDataStore.instance.addStudent(Student(
                      id: 's_${DateTime.now().millisecondsSinceEpoch}',
                      studentCode: newCode,
                      khmerName: khNameCtrl.text,
                      latinName: enNameCtrl.text,
                      gender: gender,
                      dob: DateTime(2016, 1, 1),
                      parentName: parentCtrl.text.isNotEmpty ? parentCtrl.text : 'អាណាព្យាបាល',
                      parentPhone: phoneCtrl.text,
                      address: addressCtrl.text.isNotEmpty ? addressCtrl.text : 'ក្រុងប៉ោយប៉ែត',
                      programType: progType,
                      classroomId: classId,
                    ));
                  } else {
                    editStudent.khmerName = khNameCtrl.text;
                    editStudent.latinName = enNameCtrl.text;
                    editStudent.gender = gender;
                    editStudent.parentName = parentCtrl.text;
                    editStudent.parentPhone = phoneCtrl.text;
                    editStudent.address = addressCtrl.text;
                    editStudent.programType = progType;
                    editStudent.classroomId = classId;
                    AppDataStore.instance.updateStudent(editStudent);
                  }
                  Navigator.pop(ctx);
                }
              },
              child: Text(editStudent == null ? 'ចុះឈ្មោះ' : 'រក្សាទុកការកែប្រែ', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppDataStore.instance;
    final filtered = store.students.where((s) {
      final matchesSearch = s.khmerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.studentCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.latinName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesClass = _selectedClassFilter == 'All' || s.classroomId == _selectedClassFilter;
      final matchesProgram = _selectedProgramFilter == 'All' ||
          (_selectedProgramFilter == 'FullTime' && s.programType == ProgramType.fullTime) ||
          (_selectedProgramFilter == 'PartTime' && s.programType == ProgramType.partTime);
      return matchesSearch && matchesClass && matchesProgram;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Stats Counter
          Row(
            children: [
              _metricSmall("សិស្សសរុប", "${store.students.length} នាក់", Icons.school, const Color(0xFF2563EB)),
              const SizedBox(width: 12),
              _metricSmall("ពេញម៉ោង", "${store.students.where((s) => s.programType == ProgramType.fullTime).length}", Icons.wb_sunny, const Color(0xFF0D9488)),
              const SizedBox(width: 12),
              _metricSmall("ក្រៅម៉ោង", "${store.students.where((s) => s.programType == ProgramType.partTime).length}", Icons.nightlight_round, const Color(0xFFD97706)),
              const SizedBox(width: 12),
              _metricSmall("សិស្សស្រី", "${store.students.where((s) => s.gender == 'F').length}", Icons.female, const Color(0xFFEC4899)),
            ],
          ),
          const SizedBox(height: 20),

          // Search & Filter Toolbar
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'ស្វែងរកតាមឈ្មោះខ្មែរ ឡាតាំង ឬលេខកូដសិស្ស...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _selectedProgramFilter,
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('កម្មវិធីទាំងអស់')),
                  DropdownMenuItem(value: 'FullTime', child: Text('ពេញម៉ោង')),
                  DropdownMenuItem(value: 'PartTime', child: Text('ក្រៅម៉ោង')),
                ],
                onChanged: (val) => setState(() => _selectedProgramFilter = val!),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.person_add, color: Colors.white, size: 18),
                label: const Text('ចុះឈ្មោះសិស្សថ្មី', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () => _openAddStudentModal(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main Responsive Data Table
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                      columns: const [
                        DataColumn(label: Text('ល.រ', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('រូបថត & កូដសិស្ស', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('ឈ្មោះខ្មែរ (ឡាតាំង)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('ភេទ', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('ថ្នាក់រៀន', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('អាណាព្យាបាល & ទូរស័ព្ទ', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('មធ្យមភាគ', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('វត្តមាន', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('សកម្មភាព (Actions)', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: filtered.asMap().entries.map((entry) {
                        final idx = entry.key + 1;
                        final s = entry.value;
                        final classroom = store.classrooms.firstWhere(
                          (c) => c.id == s.classroomId,
                          orElse: () => Classroom(id: '', gradeLevel: 'N/A', roomName: '', programType: ProgramType.fullTime, shift: ShiftType.morning),
                        );

                        return DataRow(
                          cells: [
                            DataCell(Text('$idx')),
                            DataCell(
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: s.gender == 'M' ? const Color(0xFFDBEAFE) : const Color(0xFFFCE7F3),
                                    child: Text(
                                      s.khmerName.isNotEmpty ? s.khmerName.substring(0, 1) : 'S',
                                      style: TextStyle(color: s.gender == 'M' ? const Color(0xFF1E40AF) : const Color(0xFFBE185D), fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(s.studentCode, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            DataCell(
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.khmerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(s.latinName, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                            DataCell(Text(s.gender == 'M' ? 'ប្រុស' : 'ស្រី')),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                                child: Text('${classroom.gradeLevel} (${classroom.roomName})', style: const TextStyle(fontSize: 12)),
                              ),
                            ),
                            DataCell(
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.parentName, style: const TextStyle(fontSize: 12)),
                                  Text(s.parentPhone, style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            DataCell(Text('${s.averageGrade} (Rank #${s.rankInClass})', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)))),
                            DataCell(Text('${s.attendanceRate}%', style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold))),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'មើលប្រវត្តិរូប និងកំណត់ត្រា',
                                    icon: const Icon(Icons.remove_red_eye_outlined, color: Color(0xFF2563EB), size: 18),
                                    onPressed: () => _openStudentHistoryModal(s),
                                  ),
                                  IconButton(
                                    tooltip: 'ប័ណ្ណសម្គាល់ខ្លួន (ID Card)',
                                    icon: const Icon(Icons.badge_outlined, color: Color(0xFF0D9488), size: 18),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => IdCardCreatorModal(
                                          studentCode: s.studentCode,
                                          khmerName: s.khmerName,
                                          latinName: s.latinName,
                                          gradeLevel: classroom.gradeLevel,
                                          programType: s.programType == ProgramType.fullTime ? 'ពេញម៉ោង' : 'ក្រៅម៉ោង',
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    tooltip: 'កែប្រែព័ត៌មាន',
                                    icon: const Icon(Icons.edit_outlined, color: Color(0xFFD97706), size: 18),
                                    onPressed: () => _openAddStudentModal(s),
                                  ),
                                  IconButton(
                                    tooltip: 'លុប',
                                    icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 18),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (c) => AlertDialog(
                                          title: const Text('បញ្ជាក់ការលុប'),
                                          content: Text('តើអ្នកពិតជាចង់លុបទិន្នន័យសិស្ស ${s.khmerName} មែនទេ?'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(c), child: const Text('បោះបង់')),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                              onPressed: () {
                                                store.deleteStudent(s.id);
                                                Navigator.pop(c);
                                              },
                                              child: const Text('លុប', style: TextStyle(color: Colors.white)),
                                            )
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricSmall(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            )
          ],
        ),
      ),
    );
  }
}
