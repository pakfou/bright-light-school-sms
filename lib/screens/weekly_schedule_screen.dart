// lib/screens/weekly_schedule_screen.dart
import 'package:flutter/material.dart';

class WeeklyScheduleScreen extends StatefulWidget {
  const WeeklyScheduleScreen({super.key});

  @override
  State<WeeklyScheduleScreen> createState() => _WeeklyScheduleScreenState();
}

class _WeeklyScheduleScreenState extends State<WeeklyScheduleScreen> {
  int _activeTab = 0; // 0: By Class, 1: By Teacher, 2: Annual Academic Calendar
  String _selectedClass = 'ថ្នាក់ទី ១A';
  String _selectedTeacher = 'លោកគ្រូ ហាក់ ប៉ាក់ហ៊្វូរ';

  // Sample schedule database
  final Map<String, List<Map<String, String>>> _classSchedules = {
    'ថ្នាក់ទី ១A': [
      {'day': 'ចន្ទ (Mon)', 'time': '07:30 - 09:00', 'subject': 'ភាសាខ្មែរ (អាន & សរសេរ)', 'teacher': 'ចាន់ សុវណ្ណារ៉ា', 'room': 'បន្ទប់ ១០១'},
      {'day': 'ចន្ទ (Mon)', 'time': '09:15 - 10:45', 'subject': 'គណិតវិទ្យាមូលដ្ឋាន', 'teacher': 'ហាក់ ប៉ាក់ហ៊្វូរ', 'room': 'បន្ទប់ ១០១'},
      {'day': 'អង្គារ (Tue)', 'time': '07:30 - 09:00', 'subject': 'ភាសាអង់គ្លេសកុមារ Phonics', 'teacher': 'សន ចរិយា', 'room': 'បន្ទប់ ១០១'},
      {'day': 'អង្គារ (Tue)', 'time': '09:15 - 10:45', 'subject': 'វិទ្យាសាស្ត្រ និងសង្គម', 'teacher': 'ចាន់ សុវណ្ណារ៉ា', 'room': 'បន្ទប់ ១០១'},
      {'day': 'ពុធ (Wed)', 'time': '07:30 - 09:00', 'subject': 'គណិតវិទ្យា (លំហាត់អនុវត្ត)', 'teacher': 'ហាក់ ប៉ាក់ហ៊្វូរ', 'room': 'បន្ទប់ ១០១'},
      {'day': 'ពុធ (Wed)', 'time': '09:15 - 10:45', 'subject': 'គំនូរ និងសិល្បៈច្នៃប្រឌិត', 'teacher': 'សន ចរិយា', 'room': 'បន្ទប់ ១០១'},
      {'day': 'ព្រហស្បតិ៍ (Thu)', 'time': '07:30 - 09:00', 'subject': 'ភាសាខ្មែរ (អក្សរផ្ចង់)', 'teacher': 'ចាន់ សុវណ្ណារ៉ា', 'room': 'បន្ទប់ ១០១'},
      {'day': 'ព្រហស្បតិ៍ (Thu)', 'time': '09:15 - 10:45', 'subject': 'កុំព្យូទ័រមូលដ្ឋាន (Lab)', 'teacher': 'ហាក់ ប៉ាក់ហ៊្វូរ', 'room': 'Lab A'},
      {'day': 'សុក្រ (Fri)', 'time': '07:30 - 09:00', 'subject': 'អប់រំកាយ និងកីឡា', 'teacher': 'ចាន់ សុវណ្ណារ៉ា', 'room': 'តារាងបាល់ទាត់'},
      {'day': 'សុក្រ (Fri)', 'time': '09:15 - 10:45', 'subject': 'ភាសាអង់គ្លេស Conversation', 'teacher': 'សន ចរិយា', 'room': 'បន្ទប់ ១០១'},
      {'day': 'សៅរ៍ (Sat)', 'time': '08:00 - 10:00', 'subject': 'សកម្មភាពអានសៀវភៅ & ក្លឹបសិក្សា', 'teacher': 'ចាន់ សុវណ្ណារ៉ា', 'room': 'បណ្ណាល័យ'},
    ],
    'ថ្នាក់ទី ២B': [
      {'day': 'ចន្ទ (Mon)', 'time': '13:30 - 15:00', 'subject': 'គណិតវិទ្យាថ្នាក់ទី ២', 'teacher': 'ហាក់ ប៉ាក់ហ៊្វូរ', 'room': 'បន្ទប់ ១០២'},
      {'day': 'ចន្ទ (Mon)', 'time': '15:15 - 16:45', 'subject': 'ភាសាខ្មែរ (វេយ្យាករណ៍)', 'teacher': 'ចាន់ សុវណ្ណារ៉ា', 'room': 'បន្ទប់ ១០២'},
      {'day': 'អង្គារ (Tue)', 'time': '13:30 - 15:00', 'subject': 'ភាសាអង់គ្លេស Level 2', 'teacher': 'សន ចរិយា', 'room': 'បន្ទប់ ១០២'},
      {'day': 'ពុធ (Wed)', 'time': '13:30 - 15:00', 'subject': 'វិទ្យាសាស្ត្រអនុវត្ត', 'teacher': 'ហាក់ ប៉ាក់ហ៊្វូរ', 'room': 'បន្ទប់ ១០២'},
      {'day': 'ព្រហស្បតិ៍ (Thu)', 'time': '13:30 - 15:00', 'subject': 'ភាសាខ្មែរ (តែងសេចក្តី)', 'teacher': 'ចាន់ សុវណ្ណារ៉ា', 'room': 'បន្ទប់ ១០២'},
      {'day': 'សុក្រ (Fri)', 'time': '13:30 - 15:00', 'subject': 'អង់គ្លេស Listening & Speaking', 'teacher': 'សន ចរិយា', 'room': 'បន្ទប់ ១០២'},
    ],
    'English Level 1': [
      {'day': 'ចន្ទ - សុក្រ (Mon-Fri)', 'time': '17:30 - 18:30', 'subject': 'General English Starter', 'teacher': 'សន ចរិយា', 'room': 'Lab 2'},
      {'day': 'ចន្ទ - សុក្រ (Mon-Fri)', 'time': '18:30 - 19:30', 'subject': 'English Grammar & Vocabulary', 'teacher': 'សន ចរិយា', 'room': 'Lab 2'},
    ],
    'Computer Basics': [
      {'day': 'ចន្ទ - ពុធ - សុក្រ', 'time': '17:30 - 19:00', 'subject': 'MS Windows, Word, Excel & Internet', 'teacher': 'ហាក់ ប៉ាក់ហ៊្វូរ', 'room': 'Lab A'},
    ],
    'Chinese Foundation': [
      {'day': 'ចន្ទ - សុក្រ (Mon-Fri)', 'time': '17:30 - 19:00', 'subject': 'មេរៀនចិន Pinyin & សន្ទនា', 'teacher': 'ចាន់ សុវណ្ណារ៉ា', 'room': 'បន្ទប់ ២០១'},
    ],
  };

  final Map<String, List<Map<String, String>>> _teacherSchedules = {
    'លោកគ្រូ ហាក់ ប៉ាក់ហ៊្វូរ': [
      {'day': 'ចន្ទ (Mon)', 'time': '09:15 - 10:45', 'class': 'ថ្នាក់ទី ១A', 'subject': 'គណិតវិទ្យាមូលដ្ឋាន', 'room': 'បន្ទប់ ១០១'},
      {'day': 'ចន្ទ (Mon)', 'time': '13:30 - 15:00', 'class': 'ថ្នាក់ទី ២B', 'subject': 'គណិតវិទ្យាថ្នាក់ទី ២', 'room': 'បន្ទប់ ១០២'},
      {'day': 'ចន្ទ (Mon)', 'time': '17:30 - 19:00', 'class': 'Computer Basics', 'subject': 'MS Office & Internet', 'room': 'Lab A'},
      {'day': 'ពុធ (Wed)', 'time': '07:30 - 09:00', 'class': 'ថ្នាក់ទី ១A', 'subject': 'គណិតវិទ្យា (លំហាត់អនុវត្ត)', 'room': 'បន្ទប់ ១០១'},
      {'day': 'ពុធ (Wed)', 'time': '13:30 - 15:00', 'class': 'ថ្នាក់ទី ២B', 'subject': 'វិទ្យាសាស្ត្រអនុវត្ត', 'room': 'បន្ទប់ ១០២'},
      {'day': 'ពុធ (Wed)', 'time': '17:30 - 19:00', 'class': 'Computer Basics', 'subject': 'Computer Practical Lab', 'room': 'Lab A'},
      {'day': 'ព្រហស្បតិ៍ (Thu)', 'time': '09:15 - 10:45', 'class': 'ថ្នាក់ទី ១A', 'subject': 'កុំព្យូទ័រមូលដ្ឋាន (Lab)', 'room': 'Lab A'},
      {'day': 'សុក្រ (Fri)', 'time': '17:30 - 19:00', 'class': 'Computer Basics', 'subject': 'Exam & Final Project', 'room': 'Lab A'},
    ],
    'អ្នកគ្រូ សន ចរិយា': [
      {'day': 'ចន្ទ (Mon)', 'time': '17:30 - 19:30', 'class': 'English Level 1', 'subject': 'English Starter & Grammar', 'room': 'Lab 2'},
      {'day': 'អង្គារ (Tue)', 'time': '07:30 - 09:00', 'class': 'ថ្នាក់ទី ១A', 'subject': 'English Phonics', 'room': 'បន្ទប់ ១០១'},
      {'day': 'អង្គារ (Tue)', 'time': '13:30 - 15:00', 'class': 'ថ្នាក់ទី ២B', 'subject': 'English Level 2', 'room': 'បន្ទប់ ១០២'},
      {'day': 'ពុធ (Wed)', 'time': '09:15 - 10:45', 'class': 'ថ្នាក់ទី ១A', 'subject': 'គំនូរ និងសិល្បៈច្នៃប្រឌិត', 'room': 'បន្ទប់ ១០១'},
      {'day': 'ព្រហស្បតិ៍ (Thu)', 'time': '17:30 - 19:30', 'class': 'English Level 1', 'subject': 'Listening & Speaking Club', 'room': 'Lab 2'},
      {'day': 'សុក្រ (Fri)', 'time': '09:15 - 10:45', 'class': 'ថ្នាក់ទី ១A', 'subject': 'English Conversation', 'room': 'បន្ទប់ ១០១'},
      {'day': 'សុក្រ (Fri)', 'time': '13:30 - 15:00', 'class': 'ថ្នាក់ទី ២B', 'subject': 'Listening & Speaking', 'room': 'បន្ទប់ ១០២'},
    ],
    'លោកគ្រូ ចាន់ សុវណ្ណារ៉ា': [
      {'day': 'ចន្ទ (Mon)', 'time': '07:30 - 09:00', 'class': 'ថ្នាក់ទី ១A', 'subject': 'ភាសាខ្មែរ (អាន & សរសេរ)', 'room': 'បន្ទប់ ១០១'},
      {'day': 'ចន្ទ (Mon)', 'time': '15:15 - 16:45', 'class': 'ថ្នាក់ទី ២B', 'subject': 'ភាសាខ្មែរ (វេយ្យាករណ៍)', 'room': 'បន្ទប់ ១០២'},
      {'day': 'អង្គារ (Tue)', 'time': '09:15 - 10:45', 'class': 'ថ្នាក់ទី ១A', 'subject': 'វិទ្យាសាស្ត្រ និងសង្គម', 'room': 'បន្ទប់ ១០១'},
      {'day': 'ព្រហស្បតិ៍ (Thu)', 'time': '07:30 - 09:00', 'class': 'ថ្នាក់ទី ១A', 'subject': 'ភាសាខ្មែរ (អក្សរផ្ចង់)', 'room': 'បន្ទប់ ១០១'},
      {'day': 'ព្រហស្បតិ៍ (Thu)', 'time': '13:30 - 15:00', 'class': 'ថ្នាក់ទី ២B', 'subject': 'ភាសាខ្មែរ (តែងសេចក្តី)', 'room': 'បន្ទប់ ១០២'},
      {'day': 'សុក្រ (Fri)', 'time': '07:30 - 09:00', 'class': 'ថ្នាក់ទី ១A', 'subject': 'អប់រំកាយ និងកីឡា', 'room': 'តារាងបាល់ទាត់'},
      {'day': 'សៅរ៍ (Sat)', 'time': '08:00 - 10:00', 'class': 'ថ្នាក់ទី ១A', 'subject': 'សកម្មភាពអានសៀវភៅ & ក្លឹបសិក្សា', 'room': 'បណ្ណាល័យ'},
    ],
  };

  // Annual Academic Calendar Events 2026-2027
  final List<Map<String, dynamic>> _academicCalendarEvents = [
    {
      'date': '០១ តុលា ២០២៦',
      'title': 'បើកបវេសនកាលឆ្នាំសិក្សា ២០២៦-២០២៧',
      'type': 'MILESTONE',
      'description': 'ចាប់ផ្តើមឆមាសទី ១ សិស្សទាំងអស់ចូលរៀនផ្លូវការ និងទទួលសៀវភៅសិក្សាគោល។',
      'badgeColor': const Color(0xFF2563EB),
    },
    {
      'date': '១០ - ១២ តុលា ២០២៦',
      'title': 'ពិធីបុណ្យភ្ជុំបិណ្ឌ (Pchum Ben Festival)',
      'type': 'HOLIDAY',
      'description': 'ឈប់សម្រាកបុណ្យប្រពៃណីជាតិ និងសាសនា។',
      'badgeColor': const Color(0xFFE11D48),
    },
    {
      'date': '២៦ - ២៨ វិច្ឆិកា ២០២៦',
      'title': 'ពិធីបុណ្យអុំទូក បណ្តែតប្រទីប និងសំពះព្រះខែ',
      'type': 'HOLIDAY',
      'description': 'ឈប់សម្រាកបុណ្យជាតិប្រចាំឆ្នាំ។',
      'badgeColor': const Color(0xFFE11D48),
    },
    {
      'date': '១៥ - ២០ ធ្នូ ២០២៦',
      'title': 'ការប្រឡងឆមាសពាក់កណ្តាលទី ១ (Mid-Term Exam)',
      'type': 'EXAM',
      'description': 'ប្រឡងវាស់ស្ទង់សមត្ថភាពសិស្សគ្រប់កម្រិតថ្នាក់ និងចេញប័ណ្ណសរសើរប្រចាំត្រីមាស។',
      'badgeColor': const Color(0xFFD97706),
    },
    {
      'date': '១០ - ១៥ កុម្ភៈ ២០២៧',
      'title': 'ការប្រឡងបញ្ចប់ឆមាសទី ១ (End Semester 1 Exam)',
      'type': 'EXAM',
      'description': 'ប្រឡងបញ្ចប់ឆមាសទី ១ និងបូកសរុបពិន្ទុចំណាត់ថ្នាក់សិស្សប្រចាំឆមាស។',
      'badgeColor': const Color(0xFFD97706),
    },
    {
      'date': '១៦ - ២៨ កុម្ភៈ ២០២៧',
      'title': 'វិស្សមកាលតូច (Semester Break)',
      'type': 'BREAK',
      'description': 'ឈប់សម្រាកបញ្ចប់ឆមាសទី ១ រយៈពេល ២ សប្តាហ៍ មុនបើកឆមាសទី ២។',
      'badgeColor': const Color(0xFF0D9488),
    },
    {
      'date': '០២ មីនា ២០២៧',
      'title': 'ចាប់ផ្តើមឆមាសទី ២ (Semester 2 Start)',
      'type': 'MILESTONE',
      'description': 'ចូលរៀនឆមាសទី ២ ពេញលេញ និងពង្រឹងជំនាញភាសាបន្ថែម។',
      'badgeColor': const Color(0xFF2563EB),
    },
    {
      'date': '១៣ - ១៧ មេសា ២០២៧',
      'title': 'ពិធីបុណ្យចូលឆ្នាំថ្មីប្រពៃណីជាតិខ្មែរ',
      'type': 'HOLIDAY',
      'description': 'ឈប់សម្រាកបុណ្យចូលឆ្នាំខ្មែរ។',
      'badgeColor': const Color(0xFFE11D48),
    },
    {
      'date': '០១ - ០៨ កក្កដា ២០២៧',
      'title': 'ការប្រឡងបញ្ចប់ឆ្នាំសិក្សា (Final Annual Exams)',
      'type': 'EXAM',
      'description': 'ការប្រឡងធំប្រចាំឆ្នាំ សម្រាប់កំណត់ការឡើងថ្នាក់ និងចំណាត់ថ្នាក់កិត្តិយស។',
      'badgeColor': const Color(0xFFD97706),
    },
    {
      'date': '១៥ កក្កដា ២០២៧',
      'title': 'ពិធីចែករង្វាន់ជយលាភី & បិទឆ្នាំសិក្សា (Graduation)',
      'type': 'CELEBRATION',
      'description': 'ពិធីជួបជុំធំអាណាព្យាបាល ចែកវិញ្ញាបនបត្រ ប័ណ្ណសរសើរ និងរង្វាន់លើកទឹកចិត្ត។',
      'badgeColor': const Color(0xFF16A34A),
    },
  ];

  void _showAddScheduleDialog() {
    final dayCtrl = TextEditingController(text: 'ចន្ទ (Mon)');
    final timeCtrl = TextEditingController(text: '08:00 - 09:30');
    final subjectCtrl = TextEditingController();
    final teacherCtrl = TextEditingController(text: _selectedTeacher);
    final roomCtrl = TextEditingController(text: 'បន្ទប់ ១០១');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('បន្ថែមម៉ោងបង្រៀនថ្មី', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dayCtrl,
                decoration: const InputDecoration(labelText: 'ថ្ងៃសិក្សា', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeCtrl,
                decoration: const InputDecoration(labelText: 'ម៉ោងសិក្សា', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: subjectCtrl,
                decoration: const InputDecoration(labelText: 'មុខវិជ្ជា', border: OutlineInputBorder(), hintText: 'ឧ. គណិតវិទ្យា'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: teacherCtrl,
                decoration: const InputDecoration(labelText: 'គ្រូបង្រៀនទទួលបន្ទុក', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: roomCtrl,
                decoration: const InputDecoration(labelText: 'បន្ទប់សិក្សា / Lab', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('បោះបង់')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            onPressed: () {
              if (subjectCtrl.text.isNotEmpty) {
                setState(() {
                  _classSchedules[_selectedClass]?.add({
                    'day': dayCtrl.text,
                    'time': timeCtrl.text,
                    'subject': subjectCtrl.text,
                    'teacher': teacherCtrl.text,
                    'room': roomCtrl.text,
                  });
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('បានបន្ថែមម៉ោងបង្រៀនចូលក្នុងកាលវិភាគជោគជ័យ!')),
                );
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar with Tab Navigation
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
                        'កាលវិភាគ និងកម្មវិធីសិក្សាប្រចាំឆ្នាំ (Schedules & Curriculum)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'គ្រប់គ្រងកាលវិភាគប្រចាំសប្តាហ៍តាមថ្នាក់ តាមគ្រូ និងប្រតិទិនសិក្សាប្រចាំឆ្នាំ ២០២៦-២០២៧',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                // 3 Segmented Tabs
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                      value: 0,
                      icon: Icon(Icons.class_outlined, size: 16),
                      label: Text('កាលវិភាគតាមថ្នាក់'),
                    ),
                    ButtonSegment(
                      value: 1,
                      icon: Icon(Icons.person_outline, size: 16),
                      label: Text('កាលវិភាគតាមគ្រូ'),
                    ),
                    ButtonSegment(
                      value: 2,
                      icon: Icon(Icons.event_note, size: 16),
                      label: Text('កម្មវិធីសិក្សាប្រចាំឆ្នាំ'),
                    ),
                  ],
                  selected: {_activeTab},
                  onSelectionChanged: (val) => setState(() => _activeTab = val.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Main Tab Body
          Expanded(
            child: _activeTab == 0
                ? _buildClassScheduleView()
                : _activeTab == 1
                    ? _buildTeacherScheduleView()
                    : _buildAnnualCalendarView(),
          ),
        ],
      ),
    );
  }

  // VIEW 1: កាលវិភាគតាមថ្នាក់នីមួយៗ
  Widget _buildClassScheduleView() {
    final list = _classSchedules[_selectedClass] ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('ជ្រើសរើសថ្នាក់រៀន៖ ', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedClass,
                    underline: const SizedBox(),
                    items: _classSchedules.keys.map((cls) {
                      return DropdownMenuItem(value: cls, child: Text(cls, style: const TextStyle(fontWeight: FontWeight.w600)));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedClass = v);
                    },
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                icon: const Icon(Icons.add, color: Colors.white, size: 16),
                label: const Text('បន្ថែមម៉ោងបង្រៀន', style: TextStyle(color: Colors.white)),
                onPressed: _showAddScheduleDialog,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('មិនទាន់មានទិន្នន័យកាលវិភាគសម្រាប់ថ្នាក់នេះនៅឡើយទេ'))
                : SingleChildScrollView(
                    child: Table(
                      border: TableBorder.all(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(8)),
                      columnWidths: const {
                        0: FlexColumnWidth(1.2),
                        1: FlexColumnWidth(1.2),
                        2: FlexColumnWidth(2.0),
                        3: FlexColumnWidth(1.5),
                        4: FlexColumnWidth(1.0),
                        5: FixedColumnWidth(80),
                      },
                      children: [
                        TableRow(
                          decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                          children: const [
                            Padding(padding: EdgeInsets.all(12), child: Text('ថ្ងៃសិក្សា', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(12), child: Text('ម៉ោងសិក្សា', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(12), child: Text('មុខវិជ្ជា', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(12), child: Text('គ្រូបង្រៀនទទួលបន្ទុក', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(12), child: Text('បន្ទប់ / Lab', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(12), child: Text('សកម្មភាព', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                          ],
                        ),
                        ...list.map((item) {
                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(item['day']!, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A))),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(item['time']!, style: const TextStyle(fontWeight: FontWeight.w500)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    const Icon(Icons.menu_book, size: 16, color: Color(0xFF2563EB)),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(item['subject']!, style: const TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(item['teacher']!),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Chip(
                                  label: Text(item['room']!, style: const TextStyle(fontSize: 11)),
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6),
                                child: IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                  onPressed: () {
                                    setState(() => list.remove(item));
                                  },
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // VIEW 2: គ្រប់គ្រងកាលវិភាគតាមគ្រូបង្រៀនម្នាក់ៗ
  Widget _buildTeacherScheduleView() {
    final list = _teacherSchedules[_selectedTeacher] ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('ជ្រើសរើសគ្រូបង្រៀន៖ ', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedTeacher,
                    underline: const SizedBox(),
                    items: _teacherSchedules.keys.map((t) {
                      return DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedTeacher = v);
                    },
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timelapse, size: 16, color: Color(0xFF1D4ED8)),
                    const SizedBox(width: 6),
                    Text(
                      'បន្ទុកបង្រៀនសរុប៖ ${list.length * 2} ម៉ោង/សប្តាហ៍',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1D4ED8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('មិនទាន់មានទិន្នន័យកាលវិភាគសម្រាប់គ្រូរូបនេះនៅឡើយទេ'))
                : ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final item = list[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 140,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item['day']!,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 130,
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(item['time']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['subject']!,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                                  ),
                                  Text(
                                    'ថ្នាក់៖ ${item['class']} | ទីតាំង៖ ${item['room']}',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Chip(
                              label: Text(item['class']!),
                              backgroundColor: const Color(0xFFEFF6FF),
                              labelStyle: const TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // VIEW 3: គ្រប់គ្រងកម្មវិធីសម្រាប់សិស្សប្រចាំឆ្នាំសិក្សា
  Widget _buildAnnualCalendarView() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ប្រតិទិនសិក្សា & កម្មវិធីសិស្សប្រចាំឆ្នាំ ២០២៦-២០២៧',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'កាលវិភាគឆមាសទី ១, ឆមាសទី ២, ការប្រឡងប្រចាំខែ, ថ្ងៃឈប់សម្រាកបុណ្យជាតិ និងពិធីចែករង្វាន់ធំ',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.download, size: 16),
                label: const Text('ទាញយក PDF ប្រតិទិន'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('បានទាញយកប្រតិទិនសិក្សាប្រចាំឆ្នាំជា PDF រួចរាល់!')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: _academicCalendarEvents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final ev = _academicCalendarEvents[i];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 140,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: (ev['badgeColor'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          ev['date'],
                          style: TextStyle(
                            color: ev['badgeColor'],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  ev['title'],
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(width: 10),
                                Chip(
                                  label: Text(
                                    ev['type'],
                                    style: TextStyle(color: ev['badgeColor'], fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                  backgroundColor: (ev['badgeColor'] as Color).withOpacity(0.1),
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              ev['description'],
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
