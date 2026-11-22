// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../models/app_models.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _adminEmailController = TextEditingController(text: "admin@brightlife.edu.kh");
  final _adminPassController = TextEditingController(text: "admin123");
  final _teacherIdController = TextEditingController(text: "T-101");
  final _teacherPassController = TextEditingController(text: "123456");

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _loginAsAdmin() {
    AppDataStore.instance.currentUserRole = UserRole.admin;
    AppDataStore.instance.currentUserName = "អ្នកគ្រប់គ្រងប្រព័ន្ធ (Admin)";
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
  }

  void _loginAsTeacher() {
    final code = _teacherIdController.text.trim();
    final teacher = AppDataStore.instance.teachers.firstWhere(
      (t) => t.teacherCode == code,
      orElse: () => Teacher(
        id: 't-temp',
        teacherCode: code,
        fullName: 'លោកគ្រូ $code',
        phone: '',
        subjectSpecialty: '',
        baseSalary: 0,
      ),
    );
    AppDataStore.instance.currentUserRole = UserRole.teacher;
    AppDataStore.instance.currentUserName = teacher.fullName;
    AppDataStore.instance.loggedTeacherCode = code;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 440,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.school, size: 36, color: Color(0xFF1E3A8A)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'សាលាបឋមសិក្សា ប្រាយ ឡាយ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const Text(
                  'Bright Life School Management System',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: const Color(0xFF1E3A8A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF64748B),
                    tabs: const [
                      Tab(text: "Admin Portal"),
                      Tab(text: "Teacher Portal"),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 220,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Admin Form
                      Column(
                        children: [
                          TextField(
                            controller: _adminEmailController,
                            decoration: const InputDecoration(
                              labelText: "អ៊ីម៉ែល (Email)",
                              prefixIcon: Icon(Icons.email_outlined),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _adminPassController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: "ពាក្យសម្ងាត់",
                              prefixIcon: Icon(Icons.lock_outline),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A8A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _loginAsAdmin,
                              child: const Text(
                                "ចូលប្រព័ន្ធជា Admin",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Teacher Form
                      Column(
                        children: [
                          TextField(
                            controller: _teacherIdController,
                            decoration: const InputDecoration(
                              labelText: "លេខសម្គាល់គ្រូ (Teacher ID)",
                              prefixIcon: Icon(Icons.badge_outlined),
                              hintText: "ឧ. T-101",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _teacherPassController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: "ពាក្យសម្ងាត់",
                              prefixIcon: Icon(Icons.lock_outline),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D9488),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _loginAsTeacher,
                              child: const Text(
                                "ចូលប្រព័ន្ធ (Scan & View Only)",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
      ),
    );
  }
}

