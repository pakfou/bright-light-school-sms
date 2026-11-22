// lib/screens/teacher_details_screen.dart
import 'package:flutter/material.dart';
import '../models/app_models.dart';

class TeacherDetailsScreen extends StatefulWidget {
  const TeacherDetailsScreen({super.key});

  @override
  State<TeacherDetailsScreen> createState() => _TeacherDetailsScreenState();
}

class _TeacherDetailsScreenState extends State<TeacherDetailsScreen> {
  String _searchQuery = '';
  final String _selectedSubjectFilter = 'All';

  void _openTeacherBioModal(Teacher teacher) {
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
                        backgroundColor: teacher.gender == 'M' ? const Color(0xFF0D9488) : const Color(0xFFEC4899),
                        child: Text(
                          teacher.fullName.isNotEmpty ? teacher.fullName.substring(0, 1) : 'T',
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
                                  teacher.fullName,
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
                                    color: const Color(0xFF0D9488),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    teacher.teacherCode,
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
                              '${teacher.latinName.isNotEmpty ? teacher.latinName : teacher.fullName} • ឯកទេស៖ ${teacher.subjectSpecialty}',
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
                    labelColor: Color(0xFF0D9488),
                    unselectedLabelColor: Color(0xFF64748B),
                    indicatorColor: Color(0xFF0D9488),
                    tabs: [
                      Tab(icon: Icon(Icons.account_box_outlined, size: 18), text: "ប្រវត្តិរូបសង្ខេប & ការអប់រំ"),
                      Tab(icon: Icon(Icons.class_outlined, size: 18), text: "បន្ទុកបង្រៀន & ថ្នាក់រៀន"),
                      Tab(icon: Icon(Icons.payments_outlined, size: 18), text: "ប្រាក់បៀវត្សរ៍ & កិច្ចសន្យា"),
                    ],
                  ),
                ),

                // TabBar View Content
                Expanded(
                  child: TabBarView(
                    children: [
                      // TAB 1: ប្រវត្តិរូបសង្ខេប & ការអប់រំ
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoSection(
                              title: "ប្រវត្តិរូបសង្ខេប (Professional Summary)",
                              items: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    teacher.bioSummary,
                                    style: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF334155)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildInfoSection(
                              title: "ព័ត៌មានផ្ទាល់ខ្លួន និងទំនាក់ទំនង",
                              items: [
                                _infoTile("កូដគ្រូបង្រៀន", teacher.teacherCode, Icons.badge_outlined),
                                _infoTile("ភេទ", teacher.gender == 'M' ? 'ប្រុស (Male)' : 'ស្រី (Female)', Icons.transgender_outlined),
                                _infoTile("លេខទូរស័ព្ទ", teacher.phone, Icons.phone_outlined),
                                _infoTile("អ៊ីម៉ែល (Email)", teacher.email.isNotEmpty ? teacher.email : 'contact@brightlife.edu.kh', Icons.email_outlined),
                                _infoTile("កម្រិតសញ្ញាបត្រ", teacher.educationDegree, Icons.school_outlined),
                                _infoTile("បទពិសោធន៍បង្រៀន", teacher.experienceYears, Icons.work_history_outlined),
                                _infoTile("កាលបរិច្ឆេទចូលបម្រើការងារ", "${teacher.joinDate.day}/${teacher.joinDate.month}/${teacher.joinDate.year}", Icons.calendar_today_outlined),
                                _infoTile("ស្ថានភាពការងារ", teacher.status == 'ACTIVE' ? 'សកម្ម (Active Staff)' : 'សម្រាក', Icons.check_circle_outline),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // TAB 2: បន្ទុកបង្រៀន & ថ្នាក់រៀន
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _metricBadge("អត្រាវត្តមានបង្រៀន", "${teacher.attendanceRate}%", const Color(0xFF0D9488)),
                                const SizedBox(width: 12),
                                _metricBadge("ថ្នាក់ទទួលខុសត្រូវ", "${teacher.assignedClasses.length} ថ្នាក់", const Color(0xFF2563EB)),
                                const SizedBox(width: 12),
                                _metricBadge("ម៉ោងបង្រៀនសរុប", "២៤ ម៉ោង/សប្តាហ៍", const Color(0xFFD97706)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text("បញ្ជីបន្ទប់ថ្នាក់ និងមុខវិជ្ជាបង្រៀន", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 12),
                            ...teacher.assignedClasses.map((cls) => Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                                          const Icon(Icons.meeting_room_outlined, color: Color(0xFF0D9488), size: 20),
                                          const SizedBox(width: 12),
                                          Text(cls, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        ],
                                      ),
                                      Chip(
                                        label: Text('ឯកទេស៖ ${teacher.subjectSpecialty}'),
                                        backgroundColor: const Color(0xFFE6FFFA),
                                        labelStyle: const TextStyle(color: Color(0xFF0D9488), fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),

                      // TAB 3: ប្រាក់បៀវត្សរ៍ & កិច្ចសន្យា
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _metricBadge("ប្រាក់បៀវត្សរ៍មូលដ្ឋាន", "\$${teacher.baseSalary}", const Color(0xFF1E3A8A)),
                                const SizedBox(width: 12),
                                _metricBadge("ស្ថានភាពបើកប្រាក់ខែ", "បានទូទាត់ (PAID)", const Color(0xFF16A34A)),
                                const SizedBox(width: 12),
                                _metricBadge("ប្រភេទកិច្ចសន្យា", "ពេញសិទ្ធិ (Full-Time)", const Color(0xFF0D9488)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text("ប្រវត្តិបើកប្រាក់បៀវត្សរ៍ ៣ ខែចុងក្រោយ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 12),
                            Table(
                              border: TableBorder.all(color: const Color(0xFFE2E8F0)),
                              children: [
                                TableRow(
                                  decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
                                  children: [
                                    _th("ខែបើកប្រាក់"),
                                    _th("ប្រាក់ខែមូលដ្ឋាន"),
                                    _th("ប្រាក់ឧបត្ថម្ភ"),
                                    _th("សរុបជាក់ស្តែង"),
                                    _th("ស្ថានភាព"),
                                  ],
                                ),
                                _tableRow("ខែតុលា ២០២៦", "\$${teacher.baseSalary}", "\$20.00", "\$${teacher.baseSalary + 20}", "PAID"),
                                _tableRow("ខែកញ្ញា ២០២៦", "\$${teacher.baseSalary}", "\$20.00", "\$${teacher.baseSalary + 20}", "PAID"),
                                _tableRow("ខែសីហា ២០២៦", "\$${teacher.baseSalary}", "\$15.00", "\$${teacher.baseSalary + 15}", "PAID"),
                              ],
                            ),
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
                        icon: const Icon(Icons.receipt_long_outlined, size: 16),
                        label: const Text("បោះពុម្ពប័ណ្ណបើកប្រាក់ខែ (Salary Payslip)"),
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('ចេញ Slip ប្រាក់បៀវត្សរ៍ជូន ${teacher.fullName} រួចរាល់!')),
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
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0D9488))),
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
            Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
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

  TableRow _tableRow(String month, String base, String bonus, String total, String status) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(10), child: Text(month, style: const TextStyle(fontWeight: FontWeight.w500))),
        Padding(padding: const EdgeInsets.all(10), child: Text(base, textAlign: TextAlign.center)),
        Padding(padding: const EdgeInsets.all(10), child: Text(bonus, textAlign: TextAlign.center)),
        Padding(padding: const EdgeInsets.all(10), child: Text(total, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)))),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
            child: Text(status, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green.shade900)),
          ),
        ),
      ],
    );
  }

  void _openAddTeacherModal([Teacher? editTeacher]) {
    final nameCtrl = TextEditingController(text: editTeacher?.fullName ?? '');
    final latinCtrl = TextEditingController(text: editTeacher?.latinName ?? '');
    final phoneCtrl = TextEditingController(text: editTeacher?.phone ?? '');
    final emailCtrl = TextEditingController(text: editTeacher?.email ?? '');
    final subjectCtrl = TextEditingController(text: editTeacher?.subjectSpecialty ?? '');
    final degreeCtrl = TextEditingController(text: editTeacher?.educationDegree ?? '');
    final salaryCtrl = TextEditingController(text: editTeacher?.baseSalary.toString() ?? '400');
    final bioCtrl = TextEditingController(text: editTeacher?.bioSummary ?? '');
    String gender = editTeacher?.gender ?? 'M';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            editTeacher == null ? 'បន្ថែមព័ត៌មានគ្រូបង្រៀនថ្មី' : 'កែប្រែព័ត៌មានគ្រូបង្រៀន',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ឈ្មោះខ្មែរ (Khmer Full Name)')),
                  const SizedBox(height: 10),
                  TextField(controller: latinCtrl, decoration: const InputDecoration(labelText: 'ឈ្មោះឡាតាំង (Latin Name)')),
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
                        child: TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'លេខទូរស័ព្ទ')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'អ៊ីម៉ែល (Email)')),
                  const SizedBox(height: 10),
                  TextField(controller: subjectCtrl, decoration: const InputDecoration(labelText: 'មុខវិជ្ជាឯកទេស (Specialized Subject)')),
                  const SizedBox(height: 10),
                  TextField(controller: degreeCtrl, decoration: const InputDecoration(labelText: 'កម្រិតសញ្ញាបត្រ (Degree)')),
                  const SizedBox(height: 10),
                  TextField(controller: salaryCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ប្រាក់បៀវត្សរ៍មូលដ្ឋាន (\$ USD)')),
                  const SizedBox(height: 10),
                  TextField(controller: bioCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'សង្ខេបប្រវត្តិរូប (Bio Summary)')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('បោះបង់')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
              onPressed: () {
                if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                  if (editTeacher == null) {
                    final newCode = 'T-${(AppDataStore.instance.teachers.length + 101)}';
                    AppDataStore.instance.addTeacher(Teacher(
                      id: 't_${DateTime.now().millisecondsSinceEpoch}',
                      teacherCode: newCode,
                      fullName: nameCtrl.text,
                      latinName: latinCtrl.text,
                      gender: gender,
                      phone: phoneCtrl.text,
                      email: emailCtrl.text,
                      subjectSpecialty: subjectCtrl.text.isNotEmpty ? subjectCtrl.text : 'ទូទៅ',
                      educationDegree: degreeCtrl.text.isNotEmpty ? degreeCtrl.text : 'បរិញ្ញាបត្រ',
                      baseSalary: double.tryParse(salaryCtrl.text) ?? 400.0,
                      bioSummary: bioCtrl.text.isNotEmpty ? bioCtrl.text : 'គ្រូបង្រៀនមានការប្តេជ្ញាចិត្តខ្ពស់',
                    ));
                  } else {
                    editTeacher.fullName = nameCtrl.text;
                    editTeacher.latinName = latinCtrl.text;
                    editTeacher.gender = gender;
                    editTeacher.phone = phoneCtrl.text;
                    editTeacher.email = emailCtrl.text;
                    editTeacher.subjectSpecialty = subjectCtrl.text;
                    editTeacher.educationDegree = degreeCtrl.text;
                    editTeacher.baseSalary = double.tryParse(salaryCtrl.text) ?? editTeacher.baseSalary;
                    editTeacher.bioSummary = bioCtrl.text;
                    AppDataStore.instance.updateTeacher(editTeacher);
                  }
                  Navigator.pop(ctx);
                }
              },
              child: Text(editTeacher == null ? 'រក្សាទុក' : 'កែប្រែ', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppDataStore.instance;
    final filtered = store.teachers.where((t) {
      final matchesSearch = t.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.teacherCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.subjectSpecialty.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesSubject = _selectedSubjectFilter == 'All' || t.subjectSpecialty == _selectedSubjectFilter;
      return matchesSearch && matchesSubject;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Stats Counter
          Row(
            children: [
              _metricSmall("គ្រូបង្រៀនសរុប", "${store.teachers.length} នាក់", Icons.badge, const Color(0xFF0D9488)),
              const SizedBox(width: 12),
              _metricSmall("គ្រូពេញសិទ្ធិ", "${store.teachers.where((t) => t.status == 'ACTIVE').length}", Icons.verified, const Color(0xFF2563EB)),
              const SizedBox(width: 12),
              _metricSmall("អត្រាវត្តមានមធ្យម", "98.4%", Icons.how_to_reg, const Color(0xFF16A34A)),
              const SizedBox(width: 12),
              _metricSmall("ប្រាក់ខែមធ្យម", "\$416.00", Icons.attach_money, const Color(0xFFD97706)),
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
                    hintText: 'ស្វែងរកតាមឈ្មោះ កូដគ្រូ ឬមុខវិជ្ជាឯកទេស...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.person_add, color: Colors.white, size: 18),
                label: const Text('បន្ថែមគ្រូបង្រៀនថ្មី', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () => _openAddTeacherModal(),
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
                        DataColumn(label: Text('រូបថត & កូដគ្រូ', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('ឈ្មោះគ្រូបង្រៀន', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('ភេទ', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('មុខវិជ្ជាឯកទេស', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('កម្រិតសញ្ញាបត្រ', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('ទូរស័ព្ទ & អ៊ីម៉ែល', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('ប្រាក់បៀវត្សរ៍', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('វត្តមាន', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('សកម្មភាព (Actions)', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: filtered.asMap().entries.map((entry) {
                        final idx = entry.key + 1;
                        final t = entry.value;

                        return DataRow(
                          cells: [
                            DataCell(Text('$idx')),
                            DataCell(
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: t.gender == 'M' ? const Color(0xFFCCFBF1) : const Color(0xFFFCE7F3),
                                    child: Text(
                                      t.fullName.isNotEmpty ? t.fullName.substring(0, 1) : 'T',
                                      style: TextStyle(
                                        color: t.gender == 'M' ? const Color(0xFF0F766E) : const Color(0xFFBE185D),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(t.teacherCode, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            DataCell(
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(t.latinName.isNotEmpty ? t.latinName : 'Teacher', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                            DataCell(Text(t.gender == 'M' ? 'ប្រុស' : 'ស្រី')),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                                child: Text(t.subjectSpecialty, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                            ),
                            DataCell(Text(t.educationDegree, style: const TextStyle(fontSize: 12))),
                            DataCell(
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.phone, style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
                                  Text(t.email.isNotEmpty ? t.email : '-', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                            DataCell(Text('\$${t.baseSalary}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)))),
                            DataCell(Text('${t.attendanceRate}%', style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold))),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'មើលប្រវត្តិរូបសង្ខេប (View Bio & Resume)',
                                    icon: const Icon(Icons.remove_red_eye_outlined, color: Color(0xFF0D9488), size: 18),
                                    onPressed: () => _openTeacherBioModal(t),
                                  ),
                                  IconButton(
                                    tooltip: 'ចេញប័ណ្ណបើកប្រាក់ខែ (Payslip)',
                                    icon: const Icon(Icons.receipt_long_outlined, color: Color(0xFF2563EB), size: 18),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('ចេញ Slip ប្រាក់បៀវត្សរ៍ជូន ${t.fullName}')),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    tooltip: 'កែប្រែព័ត៌មាន',
                                    icon: const Icon(Icons.edit_outlined, color: Color(0xFFD97706), size: 18),
                                    onPressed: () => _openAddTeacherModal(t),
                                  ),
                                  IconButton(
                                    tooltip: 'លុប',
                                    icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 18),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (c) => AlertDialog(
                                          title: const Text('បញ្ជាក់ការលុប'),
                                          content: Text('តើអ្នកពិតជាចង់លុបទិន្នន័យគ្រូបង្រៀន ${t.fullName} មែនទេ?'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(c), child: const Text('បោះបង់')),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                              onPressed: () {
                                                store.deleteTeacher(t.id);
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
