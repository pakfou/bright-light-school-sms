// lib/screens/classrooms_manager.dart
import 'package:flutter/material.dart';
import '../models/app_models.dart';

class ClassroomsManager extends StatefulWidget {
  const ClassroomsManager({super.key});

  @override
  State<ClassroomsManager> createState() => _ClassroomsManagerState();
}

class _ClassroomsManagerState extends State<ClassroomsManager> {
  int _selectedTab = 0; // 0: Classrooms List, 1: Class Arrangement Table
  bool _countMergedRooms = true; // true: count as handover (97 students), false: count separate (109 students)
  bool _showInsights = true; // Toggle Insights & Anomalies banner

  void _openAddClassModal() {
    final gradeCtrl = TextEditingController();
    final roomCtrl = TextEditingController();
    ProgramType progType = ProgramType.fullTime;
    ShiftType shift = ShiftType.morning;
    String subjectFocus = "ភាសាអង់គ្លេស";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'បង្កើត និងបញ្ចូលកម្រិតថ្នាក់រៀនដោយដៃ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: gradeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ឈ្មោះកម្រិតថ្នាក់ (ឧ. ថ្នាក់ទី ១A / Level 1)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: roomCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ឈ្មោះបន្ទប់ (ឧ. បន្ទប់ ១០២ / Lab A)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ProgramType>(
                  value: progType,
                  decoration: const InputDecoration(labelText: 'ប្រភេទកម្មវិធីសិក្សា', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: ProgramType.fullTime, child: Text('សិស្សរៀនពេញម៉ោង')),
                    DropdownMenuItem(value: ProgramType.partTime, child: Text('សិស្សរៀនក្រៅម៉ោង')),
                  ],
                  onChanged: (val) => setDialogState(() => progType = val!),
                ),
                const SizedBox(height: 12),
                if (progType == ProgramType.fullTime)
                  DropdownButtonFormField<ShiftType>(
                    value: shift,
                    decoration: const InputDecoration(labelText: 'វេនសិក្សា (ពេញម៉ោង)', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: ShiftType.morning, child: Text('ពេលព្រឹក')),
                      DropdownMenuItem(value: ShiftType.afternoon, child: Text('ពេលរសៀល')),
                    ],
                    onChanged: (val) => setDialogState(() => shift = val!),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: subjectFocus,
                    decoration: const InputDecoration(labelText: 'មុខវិជ្ជាក្រៅម៉ោង', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'ភាសាអង់គ្លេស', child: Text('ភាសាអង់គ្លេស')),
                      DropdownMenuItem(value: 'ភាសាចិន', child: Text('ភាសាចិន')),
                      DropdownMenuItem(value: 'ថ្នាក់កុំព្យូទ័រ', child: Text('ថ្នាក់កុំព្យូទ័រ')),
                    ],
                    onChanged: (val) => setDialogState(() => subjectFocus = val!),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('បោះបង់'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
              onPressed: () {
                if (gradeCtrl.text.isNotEmpty && roomCtrl.text.isNotEmpty) {
                  AppDataStore.instance.addClassroom(Classroom(
                    id: 'c_${DateTime.now().millisecondsSinceEpoch}',
                    gradeLevel: gradeCtrl.text,
                    roomName: roomCtrl.text,
                    programType: progType,
                    shift: shift,
                    subjectFocus: progType == ProgramType.partTime ? subjectFocus : null,
                  ));
                  Navigator.pop(ctx);
                }
              },
              child: const Text('រក្សាទុក', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddArrangementRowModal([ClassArrangementRow? existingRow, int? editIndex]) {
    final store = AppDataStore.instance;
    final teacherCtrl = TextEditingController(text: existingRow?.teacherName ?? '');
    final oldLevelCtrl = TextEditingController(text: existingRow?.oldTermLevel ?? '');
    final oldStudentsCtrl = TextEditingController(text: existingRow?.oldStudentsCount ?? '');
    final newLevelCtrl = TextEditingController(text: existingRow?.newTermLevel ?? '');
    final roomCtrl = TextEditingController(text: existingRow?.room ?? 'O1');
    final newStudentsCtrl = TextEditingController(text: existingRow?.newStudentsCount ?? '');
    final othersCtrl = TextEditingController(text: existingRow?.others ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          editIndex == null ? 'បន្ថែមជួររៀបចំថ្នាក់រៀនថ្មី' : 'កែប្រែទិន្នន័យរៀបចំថ្នាក់រៀន',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: teacherCtrl,
                  decoration: const InputDecoration(labelText: "Teacher's name (ឈ្មោះគ្រូបង្រៀន)", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: oldLevelCtrl,
                        decoration: const InputDecoration(labelText: 'Old term level', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: oldStudentsCtrl,
                        decoration: const InputDecoration(labelText: 'Old Students', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: newLevelCtrl,
                        decoration: const InputDecoration(labelText: 'New term level', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: roomCtrl,
                        decoration: const InputDecoration(labelText: 'Room (ឧ. O1-O6)', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: newStudentsCtrl,
                        decoration: const InputDecoration(labelText: 'New Students', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: othersCtrl,
                        decoration: const InputDecoration(labelText: 'Others (ផ្សេងៗ)', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('បោះបង់')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
            onPressed: () {
              if (teacherCtrl.text.isNotEmpty && newLevelCtrl.text.isNotEmpty) {
                final row = ClassArrangementRow(
                  no: editIndex != null ? existingRow!.no : store.classArrangements.length + 1,
                  teacherName: teacherCtrl.text,
                  oldTermLevel: oldLevelCtrl.text.isEmpty ? '-' : oldLevelCtrl.text,
                  oldStudentsCount: oldStudentsCtrl.text.isEmpty ? '-' : oldStudentsCtrl.text,
                  newTermLevel: newLevelCtrl.text,
                  room: roomCtrl.text,
                  newStudentsCount: newStudentsCtrl.text,
                  others: othersCtrl.text,
                );

                if (editIndex == null) {
                  store.addClassArrangement(row);
                } else {
                  store.updateClassArrangement(editIndex, row);
                }
                Navigator.pop(ctx);
              }
            },
            child: const Text('រក្សាទុក', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppDataStore.instance,
      builder: (ctx, _) {
        final store = AppDataStore.instance;

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Tab Segmented Button
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
                            'គ្រប់គ្រងថ្នាក់រៀន និងតារាងរៀបចំថ្នាក់ (Classrooms & Arrangement)',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedTab == 0
                                ? 'គ្រប់គ្រងបញ្ជីកម្រិតថ្នាក់ បន្ទប់រៀន និងចំណុះសិស្សក្នុងថ្នាក់'
                                : 'English Class Arrangement Term 3 Year 4 (ការរៀបចំថ្នាក់ភាសាអង់គ្លេស ត្រីមាសទី ៣ ឆ្នាំទី ៤)',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(
                          value: 0,
                          icon: Icon(Icons.meeting_room_outlined, size: 16),
                          label: Text('បញ្ជីកម្រិតថ្នាក់'),
                        ),
                        ButtonSegment(
                          value: 1,
                          icon: Icon(Icons.table_chart_outlined, size: 16),
                          label: Text('តារាងរៀបចំថ្នាក់ (Term 3)'),
                        ),
                      ],
                      selected: {_selectedTab},
                      onSelectionChanged: (val) => setState(() => _selectedTab = val.first),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Active Tab Content
              Expanded(
                child: _selectedTab == 0 ? _buildClassroomsListView(store) : _buildArrangementTableView(store),
              ),
            ],
          ),
        );
      },
    );
  }

  // TAB 0: CLASSROOMS LIST VIEW
  Widget _buildClassroomsListView(AppDataStore store) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'បន្ទប់រៀន និងកម្រិតសិក្សាសរុប៖ ${store.classrooms.length} ថ្នាក់',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('បន្ថែមថ្នាក់រៀនដោយដៃ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: _openAddClassModal,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ListView.separated(
              itemCount: store.classrooms.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final c = store.classrooms[i];
                final isFullTime = c.programType == ProgramType.fullTime;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  leading: CircleAvatar(
                    backgroundColor: isFullTime ? const Color(0xFF1E3A8A) : const Color(0xFF0D9488),
                    child: Icon(
                      isFullTime ? Icons.wb_sunny_outlined : Icons.menu_book,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    '${c.gradeLevel} (${c.roomName})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  subtitle: Text(
                    isFullTime
                        ? 'ពេញម៉ោង (${c.shift == ShiftType.morning ? "ពេលព្រឹក" : "ពេលរសៀល"})'
                        : 'ក្រៅម៉ោង (ឯកទេស៖ ${c.subjectFocus ?? "ទូទៅ"})',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                  trailing: Chip(
                    label: Text('ចំណុះ ${c.capacity} នាក់', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    backgroundColor: const Color(0xFFF1F5F9),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // TAB 1: OFFICIAL CLASS ARRANGEMENT DOCUMENT VIEW (With Key Insights & Anomalies)
  Widget _buildArrangementTableView(AppDataStore store) {
    final oldStudentsTotal = 88;
    final newStudentsMerged = 97; // Handover (Ry Sreyneang -> Pen Rina)
    final newStudentsSeparate = 109; // Separate days
    final activeNewTotal = _countMergedRooms ? newStudentsMerged : newStudentsSeparate;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top Toolbar (Print, Add Row, Actions)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified, size: 16, color: Color(0xFF2563EB)),
                          SizedBox(width: 6),
                          Text('ឯកសាររៀបចំថ្នាក់ផ្លូវការ (Official Arrangement Doc)', style: TextStyle(color: Color(0xFF1D4ED8), fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD97706),
                        side: const BorderSide(color: Color(0xFFFBBF24)),
                      ),
                      icon: Icon(_showInsights ? Icons.visibility_off_outlined : Icons.lightbulb_outline, size: 16),
                      label: Text(_showInsights ? 'លាក់ផ្ទាំងវិភាគ' : 'បង្ហាញការវិភាគ (Insights)'),
                      onPressed: () => setState(() => _showInsights = !_showInsights),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('បន្ថែមជួរថ្មី'),
                      onPressed: () => _openAddArrangementRowModal(),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
                      icon: const Icon(Icons.print, color: Colors.white, size: 16),
                      label: const Text('បោះពុម្ពឯកសារ (Print Sheet)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('កំពុងបញ្ជូនឯកសារ English Class Arrangement ទៅកាន់ម៉ាស៊ីនបោះពុម្ព...')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),

            // 🌟 KEY INSIGHTS & ANOMALIES NOTIFICATION PANEL
            if (_showInsights) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 24),
                            SizedBox(width: 8),
                            Text(
                              'ចំណុចសំខាន់ៗ និងភាពមិនប្រក្រតីដែលគួរកត់សម្គាល់ (Key Insights & Anomalies)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF92400E)),
                            ),
                          ],
                        ),
                        // Calculation Mode Switcher
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFCD34D)),
                          ),
                          child: Row(
                            children: [
                              const Text('រាប់ជាថ្នាក់ប្តូរវេន (Handover): ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF78350F))),
                              Switch(
                                value: _countMergedRooms,
                                activeColor: const Color(0xFFD97706),
                                onChanged: (v) => setState(() => _countMergedRooms = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Point 1: Room O1 Collision & Handover
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.meeting_room, size: 16, color: Color(0xFFDC2626)),
                              SizedBox(width: 6),
                              Text(
                                '១. ការជាន់គ្នានៃបន្ទប់រៀន និងកម្រិតសិក្សា (ជួរទី ៣ និងទី ៧)៖',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFB45309)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '• គ្រូឈ្មោះ Ry Sreyneang (ល.រ ទី ៣) និងគ្រូឈ្មោះ Pen Rina (ល.រ ទី ៧) ត្រូវបានដាក់ឱ្យបង្រៀនកម្រិត EFL3B នៅ បន្ទប់ 01 និងមានចំនួនសិស្ស ១២ នាក់ ដូចគ្នាបេះបិទ។',
                            style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF1E293B)),
                          ),
                          const Text(
                            '• ការសន្និដ្ឋាន & ដោះស្រាយ៖ នេះជាការប្តូរវេនគ្រូបង្រៀន (ពី Ry Sreyneang មក Pen Rina ទើបមានសញ្ញាធីក ✓ នៅជួរទី ៧) ឬជាការបង្រៀនឆ្លាស់ថ្ងៃគ្នា (ចន្ទ-ពុធ-សុក្រ និង អង្គារ-ព្រហស្បតិ៍) ដើម្បីកុំឱ្យជាន់បន្ទប់ 01។',
                            style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF0F766E), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Point 2: Class Merging
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.merge_type, size: 16, color: Color(0xFF2563EB)),
                              SizedBox(width: 6),
                              Text(
                                '២. ការបង្រួមថ្នាក់រៀន (Class Merging)៖',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1D4ED8)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '• គ្រូ Phi Sreynuch៖ កាលពីវគ្គចាស់គាត់បង្រៀន ២ ថ្នាក់ផ្សេងគ្នា (EFL 3A និង EFL 5B) ប៉ុន្តែវគ្គថ្មីនេះត្រូវបានបង្រួមឱ្យបង្រៀនតែ ១ ថ្នាក់គត់គឺ EFL 5A ដែលមានសិស្សសរុប ២០ នាក់ (កើនពី ១៦ នាក់)។',
                            style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF1E293B)),
                          ),
                          const Text(
                            '• គ្រូ Sophann May៖ ចំនួនសិស្សកើនឡើងទ្វេដងពី ១០ នាក់ ដល់ ២២ នាក់ (ច្រើនជាងគេក្នុងតារាង) ដោយសារមានការបូកបញ្ចូលសិស្សពីថ្នាក់របស់គ្រូ Tous Sreymom ("Added Mom\'s class")។',
                            style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Point 3 & 4: Total calculation & Typo Corrections
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('៣. សរុបចំនួនសិស្សពេលល្ងាច៖', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF92400E))),
                                const SizedBox(height: 2),
                                Text(
                                  '• វគ្គចាស់៖ ៨៨ នាក់\n• វគ្គថ្មី (Merged Handover)៖ ៩៧ នាក់ (+៩ នាក់)\n• វគ្គថ្មី (Separate Days)៖ ១០៩ នាក់ (+២១ នាក់)',
                                  style: const TextStyle(fontSize: 11, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('៤. កែតម្រូវអក្ខរាវិរុទ្ធ (Fixed Typos)៖', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF92400E))),
                                const SizedBox(height: 2),
                                const Text(
                                  '• បានកែសម្រួលពី "Studdents" (វគ្គចាស់) និង "Studnents" (វគ្គថ្មី) មកជា "Students amount (ចំនួនសិស្ស)" ត្រឹមត្រូវតាមស្តង់ដារ។',
                                  style: TextStyle(fontSize: 11, height: 1.4, color: Color(0xFF15803D), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // KPI Stats Cards (Old Term vs New Term vs Rooms)
            Row(
              children: [
                _buildKpiCard('សិស្សវគ្គចាស់ (Old Term)', '$oldStudentsTotal នាក់', Icons.history, const Color(0xFF64748B)),
                _buildKpiCard(
                  _countMergedRooms ? 'សិស្សវគ្គថ្មី (Handover Mode)' : 'សិស្សវគ្គថ្មី (Separate Mode)',
                  '$activeNewTotal នាក់',
                  Icons.groups,
                  const Color(0xFF2563EB),
                  subtitle: _countMergedRooms ? 'កើនឡើង ៩ នាក់ (+10.2%)' : 'កើនឡើង ២១ នាក់ (+23.8%)',
                ),
                _buildKpiCard('បន្ទប់រៀនសរុប (Rooms)', '៦ បន្ទប់ (O1 - O6)', Icons.meeting_room, const Color(0xFFD97706)),
                _buildKpiCard('គ្រូបង្រៀនទទួលបន្ទុក', '${store.classArrangements.length} រូប', Icons.badge, const Color(0xFF0D9488)),
              ],
            ),
            const SizedBox(height: 20),

            // Document Header Area (Exact layout from the image)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo & Campus Name
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1E3A8A).withOpacity(0.08),
                        border: Border.all(color: const Color(0xFF1E3A8A), width: 1.5),
                      ),
                      child: const Center(
                        child: Icon(Icons.school, color: Color(0xFF1E3A8A), size: 32),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Bright Life School',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF0F172A)),
                    ),
                    const Text(
                      'Ochrov Campus',
                      style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                // Center Titles
                Expanded(
                  child: Column(
                    children: const [
                      Text(
                        'English Class Arrangement Term 3 Year 4',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Text(
                        '(ការរៀបចំថ្នាក់ភាសាអង់គ្លេស ត្រីមាសទី ៣ ឆ្នាំទី ៤)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Evening Classes (ថ្នាក់ពេលល្ងាច)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                // Spacer for visual balance
                const SizedBox(width: 78),
              ],
            ),
            const SizedBox(height: 20),

            // Arrangement Table (Exact structure with Typos Fixed & Room Conflict Handled)
            Table(
              border: TableBorder.all(
                color: const Color(0xFF0F172A),
                width: 1.0,
              ),
              columnWidths: const {
                0: FixedColumnWidth(46),   // Nº
                1: FlexColumnWidth(1.6),    // Teacher's name
                2: FlexColumnWidth(1.8),    // Old term level
                3: FixedColumnWidth(90),   // Students amount (Fixed Typo)
                4: FlexColumnWidth(1.6),    // New term level
                5: FixedColumnWidth(70),   // Room
                6: FixedColumnWidth(90),   // Students amount (Fixed Typo)
                7: FlexColumnWidth(1.8),    // Others
                8: FixedColumnWidth(60),   // Actions
              },
              children: [
                // Header Row (With Corrected Typos: Students amount)
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
                  children: const [
                    _TableHeaderCell('Nº'),
                    _TableHeaderCell("Teacher's name"),
                    _TableHeaderCell('Old term level'),
                    _TableHeaderCell('Students amount\n(កែពី Studdents)'),
                    _TableHeaderCell('New term level'),
                    _TableHeaderCell('Room'),
                    _TableHeaderCell('Students amount\n(កែពី Studnents)'),
                    _TableHeaderCell('Others'),
                    _TableHeaderCell('Action'),
                  ],
                ),
                // Data Rows
                ...store.classArrangements.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;

                  // Styling from the photo:
                  final isOthersHighlighted = item.others.contains("Mom's");
                  final isRoomConflict = item.room == 'O1';

                  return TableRow(
                    decoration: isRoomConflict ? BoxDecoration(color: const Color(0xFFFEF2F2).withOpacity(0.5)) : null,
                    children: [
                      // Nº
                      _TableCell('${item.no}', isCenter: true),
                      // Teacher's name
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.teacherName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            if (item.no == 3)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(4)),
                                child: const Text('⚠️ ជាន់បន្ទប់ O1 ជាមួយ ល.រ 7', style: TextStyle(fontSize: 9, color: Color(0xFFB45309), fontWeight: FontWeight.bold)),
                              ),
                            if (item.no == 7)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(4)),
                                child: const Text('✓ ប្តូរវេនពី Ry Sreyneang', style: TextStyle(fontSize: 9, color: Color(0xFF15803D), fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      ),
                      // Old term level
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.oldTermLevel, style: const TextStyle(fontSize: 12.5)),
                            if (item.no == 2)
                              const Text('🔗 បង្រួមពី ២ ថ្នាក់ (16នាក់)', style: TextStyle(fontSize: 9.5, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      // Old students amount
                      _TableCell(item.oldStudentsCount, isCenter: true),
                      // New term level (Highlighted pale green/yellow as in photo)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        color: const Color(0xFFDCFCE7).withValues(alpha: 0.6),
                        child: Text(
                          item.newTermLevel,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF065F46)),
                        ),
                      ),
                      // Room (Highlighted orange as in photo, with conflict indicator)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                        color: isRoomConflict
                            ? const Color(0xFFFCA5A5).withValues(alpha: 0.5)
                            : const Color(0xFFFED7AA).withValues(alpha: 0.6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.room,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isRoomConflict ? const Color(0xFFDC2626) : const Color(0xFF9A3412),
                              ),
                            ),
                            if (isRoomConflict) ...[
                              const SizedBox(width: 2),
                              const Icon(Icons.info_outline, size: 12, color: Color(0xFFDC2626)),
                            ],
                          ],
                        ),
                      ),
                      // New students amount (with checkmark for row 7)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.newStudentsCount,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            if (item.no == 7) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.check, size: 14, color: Color(0xFF16A34A)),
                            ],
                          ],
                        ),
                      ),
                      // Others (Highlighted yellow/orange if Added Mom's class)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        color: isOthersHighlighted ? const Color(0xFFFEF08A) : Colors.transparent,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.others,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isOthersHighlighted ? FontWeight.bold : FontWeight.normal,
                                color: isOthersHighlighted ? const Color(0xFF854D0E) : const Color(0xFF334155),
                              ),
                            ),
                            if (item.no == 4)
                              const Text('👥 ២២ នាក់ (ច្រើនជាងគេ)', style: TextStyle(fontSize: 9, color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      // Action buttons (Edit / Delete)
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: () => _openAddArrangementRowModal(item, idx),
                              child: const Icon(Icons.edit, size: 16, color: Color(0xFF2563EB)),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => store.deleteClassArrangement(idx),
                              child: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
            const SizedBox(height: 36),

            // Bottom Signature & Approval Section (Exact layout from the image)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: Seen and Approved (អ្នកពិនិត្យ និងអនុម័ត)
                Container(
                  width: 320,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Date: ${store.classArrangementApprovedDate}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Seen and Approved (អ្នកពិនិត្យ និងអនុម័ត):',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
                      ),
                      const SizedBox(height: 16),
                      // Signature Area
                      if (store.isClassArrangementApproved)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified, color: Color(0xFF16A34A), size: 18),
                              SizedBox(width: 8),
                              Text(
                                '[ បានអនុម័ត & ចុះហត្ថលេខារួច ]',
                                style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        const SizedBox(
                          width: 180,
                          child: Divider(color: Color(0xFF0F172A), thickness: 1.2),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '(មិនទាន់មានហត្ថលេខានៅឡើយទេ / Pending Signature)',
                          style: TextStyle(fontSize: 10, color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        store.classArrangementApprovedBy,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 8),
                      // Toggle Approval Button
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: store.isClassArrangementApproved ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                          side: BorderSide(color: store.isClassArrangementApproved ? const Color(0xFFDC2626) : const Color(0xFF16A34A)),
                        ),
                        icon: Icon(store.isClassArrangementApproved ? Icons.close : Icons.draw_outlined, size: 14),
                        label: Text(
                          store.isClassArrangementApproved ? 'ដកហូតការអនុម័ត' : 'ចុចអនុម័ត និងចុះហត្ថលេខា',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          store.toggleArrangementApproval();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                store.isClassArrangementApproved
                                    ? 'លោក/អ្នកស្រី SAM Sokunthea បានអនុម័ត និងចុះហត្ថលេខាលើឯកសារជោគជ័យ!'
                                    : 'បានដកហូតការអនុម័តលើឯកសារ!',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Right: Prepare by (អ្នករៀបចំ)
                Container(
                  width: 320,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Date: ${store.classArrangementPreparedDate}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Prepare by (អ្នករៀបចំ):',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
                      ),
                      const SizedBox(height: 12),
                      // Stylized Signature Badge matching photo signature
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.history_edu, color: Color(0xFF2563EB), size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Ven Leapheng (Signed)',
                              style: TextStyle(
                                fontFamily: 'cursive',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const SizedBox(
                        width: 180,
                        child: Divider(color: Color(0xFF0F172A), thickness: 1.2),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        store.classArrangementPreparedBy,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'ប្រធានផ្នែកភាសាអង់គ្លេស / Head of ESL',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  if (subtitle != null)
                    Text(subtitle, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String title;
  const _TableHeaderCell(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF0F172A)),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final bool isCenter;

  const _TableCell(this.text, {this.isCenter = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        text,
        textAlign: isCenter ? TextAlign.center : TextAlign.start,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }
}
