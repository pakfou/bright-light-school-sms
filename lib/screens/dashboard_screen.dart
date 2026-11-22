// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import '../models/app_models.dart';
import 'attendance_scanner.dart';
import 'classrooms_manager.dart';
import 'student_details_screen.dart';
import 'teacher_details_screen.dart';
import 'id_card_studio_screen.dart';
import 'grade_entry_screen.dart';
import 'weekly_schedule_screen.dart';
import 'finance/student_payment_screen.dart';
import 'finance/teacher_salary_screen.dart';
import '../widgets/ai_assistant_widget.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _isAiOpen = false;

  @override
  Widget build(BuildContext context) {
    final store = AppDataStore.instance;
    final isAdmin = store.currentUserRole == UserRole.admin;

    // Menu Navigation Items
    final List<Map<String, dynamic>> menuItems = [
      {'title': 'ទិដ្ឋភាពទូទៅ (Dashboard)', 'icon': Icons.dashboard_outlined, 'adminOnly': false},
      {'title': 'ស្កេនវត្តមាន (QR Scanner)', 'icon': Icons.qr_code_scanner, 'adminOnly': false},
      {'title': 'គ្រប់គ្រងថ្នាក់រៀន (Classes)', 'icon': Icons.class_outlined, 'adminOnly': true},
      {'title': 'ព័ត៌មាន និងប្រវត្តិសិស្ស (Students)', 'icon': Icons.people_outline, 'adminOnly': true},
      {'title': 'ព័ត៌មាន និងប្រវត្តិរូបគ្រូ (Teachers)', 'icon': Icons.badge_outlined, 'adminOnly': true},
      {'title': 'ស្ទូឌីយោកាតសម្គាល់ (ID Cards)', 'icon': Icons.credit_card, 'adminOnly': true},
      {'title': 'កាលវិភាគ & កម្មវិធីសិក្សា (Schedules)', 'icon': Icons.calendar_month_outlined, 'adminOnly': false},
      {'title': 'បញ្ចូលពិន្ទុ (Grade Entry)', 'icon': Icons.grading, 'adminOnly': true},
      {'title': 'ថ្លៃសិក្សាសិស្ស (Student Fees)', 'icon': Icons.payments_outlined, 'adminOnly': true},
      {'title': 'ប្រាក់បៀវត្សរ៍គ្រូ (Salaries)', 'icon': Icons.account_balance_wallet_outlined, 'adminOnly': true},
    ];

    // Filter Items ផ្អែកលើ Role
    final accessibleMenus = menuItems.where((m) => !(m['adminOnly'] as bool) || isAdmin).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Row(
            children: [
              // Sidebar Navigation
              Container(
                width: 260,
                color: const Color(0xFF0F172A),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.school, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BRIGHT LIFE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  'Primary SMS v2.0',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Color(0xFF1E293B), height: 1),
                    Expanded(
                      child: ListView.builder(
                        itemCount: accessibleMenus.length,
                        itemBuilder: (ctx, idx) {
                          final item = accessibleMenus[idx];
                          final isSelected = _selectedIndex == idx;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              tileColor: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                              leading: Icon(
                                item['icon'] as IconData,
                                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                                size: 20,
                              ),
                              title: Text(
                                item['title'] as String,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                              onTap: () => setState(() => _selectedIndex = idx),
                            ),
                          );
                        },
                      ),
                    ),
                    // User Badge & Logout
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: isAdmin ? Colors.amber[700] : Colors.teal,
                            radius: 18,
                            child: Text(
                              isAdmin ? 'AD' : 'TC',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  store.currentUserName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  isAdmin ? 'Administrator' : 'Teacher View',
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout, color: Color(0xFFEF4444), size: 18),
                            onPressed: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Main Active View Content
              Expanded(
                child: Column(
                  children: [
                    // Top App Header
                    Container(
                      height: 64,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            accessibleMenus[_selectedIndex]['title'] as String,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF2563EB),
                                  side: const BorderSide(color: Color(0xFF2563EB)),
                                ),
                                icon: const Icon(Icons.smart_toy_outlined, size: 18),
                                label: Text(_isAiOpen ? 'បិទ AI Assistant' : 'បើក AI Assistant'),
                                onPressed: () => setState(() => _isAiOpen = !_isAiOpen),
                              ),
                              const SizedBox(width: 12),
                              Chip(
                                label: Text(DateTime.now().toString().substring(0, 10)),
                                backgroundColor: const Color(0xFFF1F5F9),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Body Views
                    Expanded(
                      child: AnimatedBuilder(
                        animation: AppDataStore.instance,
                        builder: (ctx, _) {
                          return _buildViewContent(_selectedIndex, isAdmin);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Floating AI Assistant Window
          if (_isAiOpen)
            Positioned(
              right: 24,
              bottom: 24,
              child: AiAssistantWidget(onClose: () => setState(() => _isAiOpen = false)),
            ),
        ],
      ),
    );
  }

  Widget _buildViewContent(int index, bool isAdmin) {
    if (!isAdmin) {
      if (index == 0) return _buildDashboardOverview();
      if (index == 1) return const AttendanceScanner();
      if (index == 2) return const WeeklyScheduleScreen();
      return _buildDashboardOverview();
    }

    switch (index) {
      case 0:
        return _buildDashboardOverview();
      case 1:
        return const AttendanceScanner();
      case 2:
        return const ClassroomsManager();
      case 3:
        return const StudentDetailsScreen();
      case 4:
        return const TeacherDetailsScreen();
      case 5:
        return const IdCardStudioScreen();
      case 6:
        return const WeeklyScheduleScreen();
      case 7:
        return const GradeEntryScreen();
      case 8:
        return const StudentPaymentScreen();
      case 9:
        return const TeacherSalaryScreen();
      default:
        return _buildDashboardOverview();
    }
  }

  Widget _buildDashboardOverview() {
    final store = AppDataStore.instance;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat KPI Cards
          Row(
            children: [
              _buildKpiCard('សិស្សសរុប', '${store.students.length}', Icons.groups, const Color(0xFF2563EB)),
              _buildKpiCard('បន្ទប់ថ្នាក់រៀន', '${store.classrooms.length}', Icons.meeting_room, const Color(0xFF0D9488)),
              _buildKpiCard('គ្រូបង្រៀន', '${store.teachers.length}', Icons.badge, const Color(0xFFD97706)),
              _buildKpiCard('វត្តមានកត់ត្រាថ្ងៃនេះ', '${store.attendanceRecords.length}', Icons.how_to_reg, const Color(0xFF16A34A)),
            ],
          ),
          const SizedBox(height: 24),

          // Attendance Trend Chart (គ្រូទាំងអស់ & សិស្ស)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AttendanceTrendChart (វត្តមានបង្រៀនរបស់គ្រូទាំងអស់)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Chip(label: Text('ខែវិច្ឆិកា ២០២៦'), backgroundColor: Color(0xFFF1F5F9)),
                  ],
                ),
                const SizedBox(height: 20),
                ...store.teachers.map((teacher) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${teacher.fullName} (${teacher.subjectSpecialty})',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            const Text(
                              'អត្រាវត្តមាន 96%',
                              style: TextStyle(
                                color: Color(0xFF16A34A),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: const LinearProgressIndicator(
                            value: 0.96,
                            minHeight: 10,
                            backgroundColor: Color(0xFFF1F5F9),
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                          ),
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
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

