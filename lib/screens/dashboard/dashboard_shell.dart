import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:school_management_app/config/api_config.dart';
import 'package:school_management_app/providers/auth_provider.dart';
import 'package:school_management_app/utils/app_theme.dart';
import 'package:school_management_app/utils/app_logo.dart';

// Imports ទាំង ១២ ម៉ូឌុល
import 'package:school_management_app/screens/dashboard/overview_dashboard_view.dart';
import 'package:school_management_app/screens/attendance/attendance_scanner_view.dart';
import 'package:school_management_app/screens/attendance/attendance_trend_chart_view.dart';
import 'package:school_management_app/screens/students/students_manager_view.dart';
import 'package:school_management_app/screens/teachers/teachers_manager_view.dart';
import 'package:school_management_app/screens/classrooms/classrooms_manager_view.dart';
import 'package:school_management_app/screens/id_cards/id_card_creator_view.dart';
import 'package:school_management_app/screens/schedules/weekly_schedule_view.dart';
import 'package:school_management_app/screens/grades/grades_entry_view.dart';
import 'package:school_management_app/screens/finance/finance_manager_view.dart';
import 'package:school_management_app/screens/ai_assistant/ai_assistant_view.dart';
import 'package:school_management_app/screens/reports/reports_view.dart';
import 'package:school_management_app/screens/auth/login_screen.dart';

class _BLSModuleDef {
  final String id;
  final String titleKh;
  final String titleEn;
  final String categoryKh;
  final String categoryEn;
  final String description;
  final IconData icon;
  final bool adminOnly;
  final String? badge;
  final Color? badgeColor;
  final Widget Function(Function(int globalIndex) onNavigate, bool isAdmin) builder;

  const _BLSModuleDef({
    required this.id,
    required this.titleKh,
    required this.titleEn,
    required this.categoryKh,
    required this.categoryEn,
    required this.description,
    required this.icon,
    this.adminOnly = false,
    this.badge,
    this.badgeColor,
    required this.builder,
  });

  String get title => titleKh;
}

class DashboardShell extends StatefulWidget {
  final Map<String, dynamic>? currentUser;
  final bool isAdmin;

  const DashboardShell({super.key, this.currentUser, this.isAdmin = true});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _activeModuleIndex = 0;
  final Set<int> _loadedTabs = {0};

  bool _sidebarCollapsed = false;
  String _sidebarFilter = '';
  final TextEditingController _sidebarSearchCtrl = TextEditingController();
  Timer? _keepAliveTimer;

  late final List<_BLSModuleDef> _allModules;

  @override
  void initState() {
    super.initState();
    _startKeepAliveTimer();
    _allModules = [
      // ─── Category 1: ទូទៅ & វត្តមាន (Overview & Attendance) ───
      _BLSModuleDef(
        id: 'overview',
        titleKh: 'ទិដ្ឋភាពទូទៅ',
        titleEn: 'Dashboard Overview',
        categoryKh: 'ទូទៅ & វត្តមាន',
        categoryEn: 'OVERVIEW & ATTENDANCE',
        description: 'ស្ថិតិទូទៅ សិស្ស គ្រូ ថ្នាក់រៀន និងវត្តមានប្រចាំថ្ងៃ',
        icon: Icons.grid_view_rounded,
        adminOnly: false,
        builder: (onNav, isAdmin) =>
            OverviewDashboardView(onNavigate: onNav, isAdmin: isAdmin),
      ),
      _BLSModuleDef(
        id: 'scanner',
        titleKh: 'ស្កេនវត្តមាន',
        titleEn: 'Attendance Scanner',
        categoryKh: 'ទូទៅ & វត្តមាន',
        categoryEn: 'OVERVIEW & ATTENDANCE',
        description: 'ស្កេន QR Code កាតសិស្ស និងគ្រូកត់ត្រាវត្តមានរហ័ស',
        icon: Icons.qr_code_scanner_rounded,
        adminOnly: false,
        badge: 'LIVE',
        badgeColor: const Color(0xFF10B981),
        builder: (_, _) => const AttendanceScannerView(),
      ),
      _BLSModuleDef(
        id: 'trend',
        titleKh: 'ស្ថិតិវត្តមាន',
        titleEn: 'Attendance Analytics',
        categoryKh: 'ទូទៅ & វត្តមាន',
        categoryEn: 'OVERVIEW & ATTENDANCE',
        description: 'ក្រាហ្វិកវិភាគវត្តមាន អវត្តមាន និងនិន្នាការតាមខែ',
        icon: Icons.insights_rounded,
        adminOnly: true,
        builder: (_, _) => const AttendanceTrendChartView(),
      ),

      // ─── Category 2: រដ្ឋបាល & សមាជិក (Core Administration) ───
      _BLSModuleDef(
        id: 'students',
        titleKh: 'គ្រប់គ្រងសិស្ស',
        titleEn: 'Student Directory',
        categoryKh: 'រដ្ឋបាល & សមាជិក',
        categoryEn: 'CORE ADMINISTRATION',
        description: 'បញ្ជីឈ្មោះសិស្ស ចុះឈ្មោះ និងព័ត៌មានលម្អិតសិស្ស',
        icon: Icons.school_rounded,
        adminOnly: true,
        builder: (_, _) => const StudentsManagerView(),
      ),
      _BLSModuleDef(
        id: 'teachers',
        titleKh: 'គ្រប់គ្រងគ្រូបង្រៀន',
        titleEn: 'Faculty & Teachers',
        categoryKh: 'រដ្ឋបាល & សមាជិក',
        categoryEn: 'CORE ADMINISTRATION',
        description: 'បញ្ជីឈ្មោះគ្រូបង្រៀន កម្រិត និងកាលវិភាគបង្រៀន',
        icon: Icons.badge_rounded,
        adminOnly: true,
        builder: (_, _) => const TeachersManagerView(),
      ),
      _BLSModuleDef(
        id: 'classrooms',
        titleKh: 'គ្រប់គ្រងថ្នាក់រៀន',
        titleEn: 'Classroom Manager',
        categoryKh: 'រដ្ឋបាល & សមាជិក',
        categoryEn: 'CORE ADMINISTRATION',
        description: 'គ្រប់គ្រងបន្ទប់រៀន ថ្នាក់ពេញម៉ោង និងក្រៅម៉ោង',
        icon: Icons.meeting_room_rounded,
        adminOnly: true,
        builder: (_, _) => const ClassroomsManagerView(),
      ),
      // ─── Category 3: ស្ទូឌីយោ & ការសិក្សា (Studio & Grades) ───
      _BLSModuleDef(
        id: 'id_cards',
        titleKh: 'ស្ទូឌីយោកាតសម្គាល់',
        titleEn: 'ID Card Studio',
        categoryKh: 'ស្ទូឌីយោ & ការសិក្សា',
        categoryEn: 'STUDIO & ACADEMICS',
        description: 'រចនា បោះពុម្ពកាតសិស្ស និងគ្រូ ISO CR-80 PVC & A4 Sheet',
        icon: Icons.credit_card_rounded,
        adminOnly: true,
        badge: 'PRO',
        badgeColor: const Color(0xFF4F46E5),
        builder: (_, _) => const IdCardCreatorView(),
      ),
      _BLSModuleDef(
        id: 'schedules',
        titleKh: 'កាលវិភាគប្រចាំសប្តាហ៍',
        titleEn: 'Weekly Timetable',
        categoryKh: 'រដ្ឋបាល & សមាជិក',
        categoryEn: 'CORE ADMINISTRATION',
        description: 'កាលវិភាគម៉ោងបង្រៀនតាមថ្នាក់ និងតាមគ្រូប្រចាំសប្តាហ៍',
        icon: Icons.calendar_month_rounded,
        adminOnly: true,
        builder: (_, _) => const WeeklyScheduleView(),
      ),
      _BLSModuleDef(
        id: 'grades',
        titleKh: 'ពិន្ទុ និងការសិក្សា',
        titleEn: 'Grades & Exams',
        categoryKh: 'ស្ទូឌីយោ & ការសិក្សា',
        categoryEn: 'STUDIO & ACADEMICS',
        description: 'បញ្ចូលពិន្ទុប្រចាំខែ ចំណាត់ថ្នាក់ និងរបាយការណ៍សិក្សា',
        icon: Icons.auto_stories_rounded,
        adminOnly: false,
        builder: (_, _) => const GradesEntryView(),
      ),

      // ─── Category 4: ហិរញ្ញវត្ថុ & របាយការណ៍ (Finance & Audit) ───
      _BLSModuleDef(
        id: 'finance',
        titleKh: 'ហិរញ្ញវត្ថុ & បៀវត្សរ៍',
        titleEn: 'Finance & Payroll',
        categoryKh: 'ហិរញ្ញវត្ថុ & របាយការណ៍',
        categoryEn: 'FINANCE & AUDIT',
        description: 'ចំណូល ចំណាយ ថ្លៃសិក្សា និងបើកប្រាក់ខែបុគ្គលិក',
        icon: Icons.account_balance_wallet_rounded,
        adminOnly: true,
        builder: (_, _) => const FinanceManagerView(),
      ),

      // ─── Category 5: បច្ចេកវិទ្យាឆ្លាតវៃ (Smart AI) ───
      _BLSModuleDef(
        id: 'ai_assistant',
        titleKh: 'ជំនួយការ AI',
        titleEn: 'AI Smart Assistant',
        categoryKh: 'បច្ចេកវិទ្យាឆ្លាតវៃ',
        categoryEn: 'INTELLIGENCE',
        description: 'វិភាគទិន្នន័យ ឆ្លើយសំណួរ និងផ្តល់អនុសាសន៍ឆ្លាតវៃ',
        icon: Icons.smart_toy_rounded,
        adminOnly: true,
        badge: 'AI',
        badgeColor: const Color(0xFFF59E0B),
        builder: (_, _) => const AiAssistantView(),
      ),

      // ─── Category 4 continued: Reports ───
      _BLSModuleDef(
        id: 'reports',
        titleKh: 'របាយការណ៍បិទបញ្ជី',
        titleEn: 'Audit Reports',
        categoryKh: 'ហិរញ្ញវត្ថុ & របាយការណ៍',
        categoryEn: 'FINANCE & AUDIT',
        description: 'របាយការណ៍សង្ខេបប្រចាំខែ និងប្រចាំឆ្នាំផ្លូវការ',
        icon: Icons.assessment_rounded,
        adminOnly: true,
        builder: (_, _) => const ReportsView(),
      ),
    ];
  }

  void _startKeepAliveTimer() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(minutes: 10), (_) async {
      try {
        final uri = Uri.parse('${ApiConfig.baseUrl}/health?_t=${DateTime.now().millisecondsSinceEpoch}');
        await http.get(uri).timeout(const Duration(seconds: 15));
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _keepAliveTimer?.cancel();
    _sidebarSearchCtrl.dispose();
    super.dispose();
  }

  List<_BLSModuleDef> get _availableModules {
    if (widget.isAdmin) {
      return _allModules;
    }
    // Teachers have permissions for: Overview, Scanner, Grades
    return _allModules.where((m) => !m.adminOnly).toList();
  }

  void _handleOverviewNavigate(int rawTargetIndex) {
    if (rawTargetIndex < 0 || rawTargetIndex >= _allModules.length) return;
    final target = _allModules[rawTargetIndex];

    if (target.adminOnly && !widget.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'មុខងារនេះសម្រាប់តែ Admin ប៉ុណ្ណោះ! គណនីគ្រូបង្រៀនមានសិទ្ធិតែ៖ ទិដ្ឋភាពទូទៅ, ស្កេនវត្តមាន និងបញ្ចូលពិន្ទុ។',
                  style: TextStyle(fontFamily: 'Khmer OS Battambang', fontSize: 12.5),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final newIndex = _availableModules.indexWhere((m) => m.id == target.id);
    if (newIndex != -1) {
      _selectModule(newIndex);
    }
  }

  void _selectModule(int idx) {
    if (idx >= 0 && idx < _availableModules.length) {
      setState(() {
        _loadedTabs.add(idx);
        _activeModuleIndex = idx;
      });
    }
  }

  void _selectModuleById(String id) {
    final idx = _availableModules.indexWhere((m) => m.id == id);
    if (idx != -1) {
      _selectModule(idx);
    }
  }

  Widget _buildView(int index) {
    if (index < 0 || index >= _availableModules.length) {
      return const SizedBox.shrink();
    }
    return _availableModules[index].builder(
      _handleOverviewNavigate,
      widget.isAdmin,
    );
  }

  // ─── Spotlight Command Palette (Ctrl + K) ───
  void _showCommandPalette() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (dialogCtx) {
        String query = '';
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final filtered = _availableModules.where((m) {
              if (query.trim().isEmpty) return true;
              final q = query.toLowerCase().trim();
              return m.titleKh.toLowerCase().contains(q) ||
                  m.titleEn.toLowerCase().contains(q) ||
                  m.categoryKh.toLowerCase().contains(q) ||
                  m.categoryEn.toLowerCase().contains(q) ||
                  m.description.toLowerCase().contains(q) ||
                  m.id.toLowerCase().contains(q);
            }).toList();

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Container(
                width: 620,
                constraints: const BoxConstraints(maxHeight: 520),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 36,
                      offset: const Offset(0, 16),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search Input Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF4F46E5),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              autofocus: true,
                              decoration: const InputDecoration(
                                hintText: 'ស្វែងរកមុខងាររហ័ស... (Quick Jump / Search)',
                                hintStyle: TextStyle(
                                  fontFamily: 'Khmer OS Battambang',
                                  fontSize: 14,
                                  color: Color(0xFF94A3B8),
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: const TextStyle(
                                fontFamily: 'Khmer OS Battambang',
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                              onChanged: (val) {
                                setDialogState(() => query = val);
                              },
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: const Text(
                              'ESC',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Results List
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 48,
                                    color: const Color(0xFFCBD5E1),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'មិនមានមុខងារត្រូវនឹង "$query"',
                                    style: AppTheme.khmerBody(
                                      color: const Color(0xFF64748B),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              itemCount: filtered.length,
                              itemBuilder: (c, idx) {
                                final mod = filtered[idx];
                                final isSelected =
                                    _availableModules[_activeModuleIndex].id == mod.id;

                                return Container(
                                  margin: const EdgeInsets.symmetric(vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFEEF2FF)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: isSelected
                                        ? Border.all(color: const Color(0xFFC7D2FE))
                                        : null,
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 4,
                                    ),
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF4F46E5)
                                            : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        mod.icon,
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF475569),
                                        size: 20,
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Text(
                                          mod.titleKh,
                                          style: AppTheme.khmerBody(
                                            color: const Color(0xFF0F172A),
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          mod.titleEn,
                                          style: AppTheme.englishCaption(
                                            color: const Color(0xFF64748B),
                                            fontSize: 11,
                                          ),
                                        ),
                                        if (mod.badge != null) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: (mod.badgeColor ?? const Color(0xFF4F46E5))
                                                  .withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              mod.badge!,
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w800,
                                                color: mod.badgeColor ?? const Color(0xFF4F46E5),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    subtitle: Text(
                                      mod.description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTheme.khmerBody(
                                        color: const Color(0xFF64748B),
                                        fontSize: 11.5,
                                      ),
                                    ),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 13,
                                      color: Color(0xFF94A3B8),
                                    ),
                                    onTap: () {
                                      Navigator.of(dialogCtx).pop();
                                      final targetIdx =
                                          _availableModules.indexWhere((m) => m.id == mod.id);
                                      if (targetIdx != -1) {
                                        _selectModule(targetIdx);
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                    ),

                    // Footer Shortcuts hint
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                        border: Border(
                          top: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.keyboard_command_key_rounded,
                                size: 14,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'ជ្រើសរើសដើម្បីបើកភ្លាមៗ • Instant Module Navigation',
                                style: AppTheme.englishCaption(
                                  color: const Color(0xFF64748B),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Bright Light School OS',
                            style: AppTheme.englishCaption(
                              color: const Color(0xFF94A3B8),
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── Logout Confirmation Dialog ───
  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFDC2626),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'ចាកចេញពីប្រព័ន្ធ',
              style: AppTheme.khmerHeading(
                fontSize: 17,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: Text(
          'តើលោកអ្នកពិតជាចង់ចាកចេញពីគណនីគ្រប់គ្រងសាលាប្រាយឡាយមែនទេ?',
          style: AppTheme.khmerBody(
            fontSize: 13.5,
            color: const Color(0xFF475569),
          ),
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'បោះបង់ (Cancel)',
              style: AppTheme.englishHeading(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'ចាកចេញ (Logout)',
              style: AppTheme.englishHeading(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  // ─── Modern Categorized Sidebar ───
  Widget _buildSidebarContent(String userName, bool isMobile) {
    final modules = _availableModules;
    final isCollapsed = !isMobile && _sidebarCollapsed;

    // Filter modules if search text is typed
    final filteredModules = modules.where((m) {
      if (_sidebarFilter.trim().isEmpty) return true;
      final q = _sidebarFilter.toLowerCase().trim();
      return m.titleKh.toLowerCase().contains(q) ||
          m.titleEn.toLowerCase().contains(q) ||
          m.categoryKh.toLowerCase().contains(q) ||
          m.categoryEn.toLowerCase().contains(q);
    }).toList();

    // Group filtered modules by category
    final Map<String, List<_BLSModuleDef>> groupedModules = {};
    for (final m in filteredModules) {
      groupedModules.putIfAbsent(m.categoryKh, () => []).add(m);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOutCubic,
      width: isCollapsed ? 76 : 272,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(
          right: BorderSide(color: Color(0xFF1E293B), width: 1),
        ),
      ),
      child: SizedBox(
        width: isCollapsed ? 76 : 272,
        child: Column(
          children: [
          // ─── Institution Brand Header ───
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 12 : 18,
              vertical: 20,
            ),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF1E293B)),
              ),
            ),
            child: Row(
              mainAxisAlignment:
                  isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: AppLogo.widget(
                    width: isCollapsed ? 34 : 38,
                    height: isCollapsed ? 34 : 38,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'សាលាប្រាយឡាយ',
                          style: AppTheme.khmerHeading(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Bright Light School',
                          style: AppTheme.englishCaption(
                            color: const Color(0xFF94A3B8),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isMobile)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  else
                    IconButton(
                      tooltip: 'បង្រួញម៉ឺនុយ (Collapse Sidebar)',
                      icon: const Icon(
                        Icons.first_page_rounded,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
                      onPressed: () => setState(() => _sidebarCollapsed = true),
                    ),
                ],
              ],
            ),
          ),

          // ─── Expanded Mode: Role Badge & Quick Filter ───
          if (!isCollapsed) ...[
            // Permission Pill
            Container(
              margin: const EdgeInsets.fromLTRB(14, 12, 14, 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: widget.isAdmin
                    ? const Color(0xFF1E293B)
                    : const Color(0xFF064E3B).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: widget.isAdmin
                      ? const Color(0xFF334155)
                      : const Color(0xFF059669).withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.isAdmin
                        ? Icons.security_rounded
                        : Icons.verified_user_rounded,
                    color: widget.isAdmin
                        ? const Color(0xFF818CF8)
                        : const Color(0xFF34D399),
                    size: 15,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.isAdmin
                          ? 'គ្រប់គ្រងពេញលេញ (Admin Access)'
                          : 'សិទ្ធិគ្រូបង្រៀន (Faculty Access)',
                      style: AppTheme.khmerBody(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: widget.isAdmin
                          ? const Color(0xFF818CF8)
                          : const Color(0xFF34D399),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),

            // Sidebar Filter Field
            Container(
              margin: const EdgeInsets.fromLTRB(14, 4, 14, 8),
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: TextField(
                controller: _sidebarSearchCtrl,
                decoration: InputDecoration(
                  hintText: 'ស្វែងរកម៉ឺនុយ... (Filter)',
                  hintStyle: const TextStyle(
                    fontFamily: 'Khmer OS Battambang',
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                  suffixIcon: _sidebarFilter.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 14, color: Colors.white70),
                          onPressed: () {
                            _sidebarSearchCtrl.clear();
                            setState(() => _sidebarFilter = '');
                          },
                        )
                      : null,
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                style: const TextStyle(
                  fontFamily: 'Khmer OS Battambang',
                  fontSize: 12,
                  color: Colors.white,
                ),
                onChanged: (val) => setState(() => _sidebarFilter = val),
              ),
            ),
          ] else ...[
            // Collapsed Mode: Expand Toggle Button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: IconButton(
                tooltip: 'ពង្រីកម៉ឺនុយ (Expand Sidebar)',
                icon: const Icon(
                  Icons.last_page_rounded,
                  color: Color(0xFF818CF8),
                  size: 22,
                ),
                onPressed: () => setState(() => _sidebarCollapsed = false),
              ),
            ),
          ],

          // ─── Module List (Categorized) ───
          Expanded(
            child: ListView(
              key: ValueKey(isCollapsed),
              padding: EdgeInsets.symmetric(
                horizontal: isCollapsed ? 8 : 10,
                vertical: 6,
              ),
              children: isCollapsed
                  // Collapsed View: Just icons with rich tooltips
                  ? modules.map((m) {
                      final originalIndex = _availableModules.indexOf(m);
                      final isSelected = _activeModuleIndex == originalIndex;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Tooltip(
                          message: '${m.titleKh} (${m.titleEn})',
                          preferBelow: false,
                          child: InkWell(
                            onTap: () {
                              _selectModule(originalIndex);
                              if (isMobile) Navigator.of(context).pop();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF4F46E5)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF4F46E5).withValues(alpha: 0.4),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    m.icon,
                                    size: 20,
                                    color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                                  ),
                                  if (m.badge != null)
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: m.badgeColor ?? const Color(0xFF4F46E5),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList()
                  // Expanded View: Categorized Sections
                  : groupedModules.entries.map((entry) {
                      final categoryKh = entry.key;
                      final categoryItems = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 14, 10, 6),
                            child: Row(
                              children: [
                                Text(
                                  categoryKh,
                                  style: AppTheme.khmerBody(
                                    color: const Color(0xFF64748B),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...categoryItems.map((mod) {
                            final originalIndex = _availableModules.indexOf(mod);
                            final isSelected = _activeModuleIndex == originalIndex;

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? const LinearGradient(
                                        colors: [Color(0xFF4F46E5), Color(0xFF4338CA)],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      )
                                    : null,
                                color: isSelected ? null : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  hoverColor: const Color(0xFF1E293B),
                                  onTap: () {
                                    _selectModule(originalIndex);
                                    if (isMobile) Navigator.of(context).pop();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Colors.white.withValues(alpha: 0.15)
                                                : const Color(0xFF1E293B),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            mod.icon,
                                            size: 18,
                                            color: isSelected
                                                ? Colors.white
                                                : const Color(0xFF94A3B8),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                mod.titleKh,
                                                style: AppTheme.khmerBody(
                                                  color: isSelected
                                                      ? Colors.white
                                                      : const Color(0xFFE2E8F0),
                                                  fontSize: 12.5,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                mod.titleEn,
                                                style: AppTheme.englishCaption(
                                                  color: isSelected
                                                      ? const Color(0xFFC7D2FE)
                                                      : const Color(0xFF64748B),
                                                  fontSize: 10,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (mod.badge != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Colors.white.withValues(alpha: 0.2)
                                                  : (mod.badgeColor ?? const Color(0xFF4F46E5))
                                                      .withValues(alpha: 0.18),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              mod.badge!,
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                color: isSelected
                                                    ? Colors.white
                                                    : (mod.badgeColor ?? const Color(0xFF818CF8)),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    }).toList(),
            ),
          ),

          // ─── Sidebar Footer: User Profile & Logout ───
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 8 : 14,
              vertical: 12,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF090D16),
              border: Border(
                top: BorderSide(color: Color(0xFF1E293B)),
              ),
            ),
            child: isCollapsed
                ? Center(
                    child: IconButton(
                      tooltip: 'ចាកចេញ (Logout)',
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFF87171),
                        size: 20,
                      ),
                      onPressed: _confirmLogout,
                    ),
                  )
                : Row(
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: widget.isAdmin
                            ? const Color(0xFF4F46E5)
                            : const Color(0xFF10B981),
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              userName,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.khmerBody(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              widget.isAdmin
                                  ? 'ប្រព័ន្ធអេតមីន • Administrator'
                                  : (widget.currentUser?['code'] != null
                                      ? 'ID: ${widget.currentUser!['code']} • គ្រូបង្រៀន'
                                      : 'គ្រូបង្រៀន • Teacher'),
                              style: AppTheme.englishCaption(
                                color: widget.isAdmin
                                    ? const Color(0xFF93C5FD)
                                    : const Color(0xFFA7F3D0),
                                fontSize: 9.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'ចាកចេញ (Logout)',
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Color(0xFFF87171),
                          size: 18,
                        ),
                        onPressed: _confirmLogout,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    ),
  );
  }

  // ─── Modern Desktop TopBar ───
  Widget _buildDesktopTopBar(String userName, _BLSModuleDef currentModule) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final showFullBreadcrumb = availableWidth > 1200;
        final showSearchFull = availableWidth > 1050;
        final showActionButtons = availableWidth > 1250;
        final showTermStatus = availableWidth > 920;

        return Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
          ),
          child: Row(
            children: [
              // Breadcrumb Navigation
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        currentModule.icon,
                        size: 18,
                        color: const Color(0xFF4F46E5),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (showFullBreadcrumb)
                            Row(
                              children: [
                                Text(
                                  'Bright Light School',
                                  style: AppTheme.englishCaption(
                                    color: const Color(0xFF64748B),
                                    fontSize: 10.5,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 14,
                                  color: Color(0xFF94A3B8),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    currentModule.categoryKh,
                                    style: AppTheme.khmerBody(
                                      color: const Color(0xFF64748B),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  currentModule.titleKh,
                                  style: AppTheme.khmerHeading(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (availableWidth > 820) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF94A3B8),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    currentModule.titleEn,
                                    style: AppTheme.englishHeading(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF64748B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Spotlight Command Bar Trigger
              if (showSearchFull)
                InkWell(
                  onTap: _showCommandPalette,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ស្វែងរកមុខងារ...',
                          style: AppTheme.khmerBody(
                            fontSize: 11.5,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFC7D2FE)),
                          ),
                          child: const Text(
                            'Ctrl+K',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4F46E5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                IconButton(
                  tooltip: 'ស្វែងរកមុខងាររហ័ស (Ctrl+K)',
                  icon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                  onPressed: _showCommandPalette,
                ),

              if (showActionButtons) ...[
                const SizedBox(width: 8),
                // Quick Action: Attendance Scanner Shortcut
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    backgroundColor: const Color(0xFFF8FAFC),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 16,
                    color: Color(0xFF059669),
                  ),
                  label: Text(
                    'ស្កេន QR',
                    style: AppTheme.khmerBody(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF065F46),
                    ),
                  ),
                  onPressed: () => _selectModuleById('scanner'),
                ),

                if (widget.isAdmin) ...[
                  const SizedBox(width: 8),
                  // Quick Action: ID Card Studio Shortcut
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      backgroundColor: const Color(0xFFF8FAFC),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(
                      Icons.credit_card_rounded,
                      size: 16,
                      color: Color(0xFF4F46E5),
                    ),
                    label: Text(
                      'ស្ទូឌីយោកាត',
                      style: AppTheme.khmerBody(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4338CA),
                      ),
                    ),
                    onPressed: () => _selectModuleById('id_cards'),
                  ),
                ],
              ],

              if (showTermStatus) ...[
                const SizedBox(width: 10),
                // Academic Term Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'ឆមាសទី ១ • ២០២៥-២០២៦',
                        style: AppTheme.khmerBody(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF065F46),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(width: 10),

              // User Profile Pill Dropdown
              PopupMenuButton<String>(
                tooltip: 'ព័ត៌មានគណនី (Account Options)',
                offset: const Offset(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                onSelected: (val) {
                  if (val == 'logout') {
                    _confirmLogout();
                  } else if (val == 'command') {
                    _showCommandPalette();
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: AppTheme.khmerBody(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          widget.isAdmin
                              ? 'Admin Full Privileges'
                              : 'Teacher / Faculty User',
                          style: AppTheme.englishCaption(
                            fontSize: 10.5,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const Divider(height: 16),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'command',
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, size: 18, color: Color(0xFF4F46E5)),
                        const SizedBox(width: 10),
                        Text(
                          'ស្វែងរកមុខងារ (Ctrl+K)',
                          style: AppTheme.khmerBody(fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFDC2626)),
                        const SizedBox(width: 10),
                        Text(
                          'ចាកចេញពីប្រព័ន្ធ (Logout)',
                          style: AppTheme.khmerBody(
                            fontSize: 12.5,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: widget.isAdmin
                            ? const Color(0xFF4F46E5)
                            : const Color(0xFF10B981),
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      if (availableWidth > 680) ...[
                        const SizedBox(width: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 110),
                          child: Text(
                            userName,
                            style: AppTheme.khmerBody(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Guard against transient or uninitialized canvas constraints (e.g. Size(1.6, 1.6) during web hot restart)
    if (size.width < 100 || size.height < 100) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF818CF8),
            ),
          ),
        ),
      );
    }

    final modules = _availableModules;
    final safeIndex = _activeModuleIndex.clamp(0, modules.length - 1);
    final currentModule = modules[safeIndex];

    final userName =
        widget.currentUser?['name'] ??
        (widget.isAdmin ? 'Admin BLS' : 'គ្រូបង្រៀន');
    final isMobile = size.width < 960;

    final contentStack = IndexedStack(
      index: safeIndex,
      children: List.generate(modules.length, (i) {
        if (_loadedTabs.contains(i)) {
          return _buildView(i);
        }
        return const SizedBox.shrink();
      }),
    );

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if ((HardwareKeyboard.instance.isControlPressed ||
                  HardwareKeyboard.instance.isMetaPressed) &&
              event.logicalKey == LogicalKeyboardKey.keyK) {
            _showCommandPalette();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF8FAFC),
        drawer: isMobile
            ? Drawer(child: _buildSidebarContent(userName, true))
            : null,
        appBar: isMobile
            ? AppBar(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                elevation: 0,
                titleSpacing: 0,
                leading: IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Colors.white),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(currentModule.icon, size: 18, color: const Color(0xFF818CF8)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        currentModule.titleKh,
                        style: AppTheme.khmerHeading(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    tooltip: 'ស្វែងរកមុខងាររហ័ស',
                    icon: const Icon(Icons.search_rounded, color: Colors.white70, size: 20),
                    onPressed: _showCommandPalette,
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.isAdmin
                          ? const Color(0xFF4F46E5)
                          : const Color(0xFF059669),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      widget.isAdmin
                          ? 'ADMIN'
                          : (widget.currentUser?['code'] ?? 'TEACHER'),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              )
            : null,
        body: isMobile
            ? contentStack
            : Row(
                children: [
                  _buildSidebarContent(userName, false),
                  Expanded(
                    child: Column(
                      children: [
                        _buildDesktopTopBar(userName, currentModule),
                        Expanded(child: contentStack),
                      ],
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: isMobile
            ? Builder(
                builder: (context) {
                  int bottomNavIndex = 0;
                  if (widget.isAdmin) {
                    if (safeIndex == 0) {
                      bottomNavIndex = 0; // Overview
                    } else if (safeIndex == 1) {
                      bottomNavIndex = 1; // Scanner
                    } else if (safeIndex == 3) {
                      bottomNavIndex = 2; // Students
                    } else if (safeIndex == 8) {
                      bottomNavIndex = 3; // Grades
                    } else {
                      bottomNavIndex = 4; // Menu Drawer
                    }
                  } else {
                    bottomNavIndex = safeIndex.clamp(0, 2);
                  }

                  return Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F172A),
                      border: Border(top: BorderSide(color: Color(0xFF1E293B))),
                    ),
                    child: NavigationBarTheme(
                      data: NavigationBarThemeData(
                        indicatorColor: const Color(0xFF4F46E5),
                        labelTextStyle: WidgetStateProperty.resolveWith(
                          (states) => TextStyle(
                            fontFamily: 'Khmer OS Battambang',
                            fontSize: 10,
                            fontWeight: states.contains(WidgetState.selected)
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: states.contains(WidgetState.selected)
                                ? Colors.white
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      child: NavigationBar(
                        height: 65,
                        backgroundColor: const Color(0xFF0F172A),
                        selectedIndex: bottomNavIndex,
                        onDestinationSelected: (idx) {
                          if (widget.isAdmin) {
                            if (idx == 0) {
                              _selectModule(0);
                            } else if (idx == 1) {
                              _selectModule(1);
                            } else if (idx == 2) {
                              _selectModule(3);
                            } else if (idx == 3) {
                              _selectModule(8);
                            } else if (idx == 4) {
                              _scaffoldKey.currentState?.openDrawer();
                            }
                          } else {
                            if (idx >= 0 && idx < modules.length) {
                              _selectModule(idx);
                            }
                          }
                        },
                        destinations: widget.isAdmin
                            ? const [
                                NavigationDestination(
                                  icon: Icon(Icons.grid_view_rounded, color: Color(0xFF94A3B8)),
                                  selectedIcon: Icon(Icons.grid_view_rounded, color: Colors.white),
                                  label: 'ទំព័រដើម',
                                ),
                                NavigationDestination(
                                  icon: Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF94A3B8)),
                                  selectedIcon: Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
                                  label: 'ស្កេនវត្តមាន',
                                ),
                                NavigationDestination(
                                  icon: Icon(Icons.school_rounded, color: Color(0xFF94A3B8)),
                                  selectedIcon: Icon(Icons.school_rounded, color: Colors.white),
                                  label: 'សិស្ស',
                                ),
                                NavigationDestination(
                                  icon: Icon(Icons.auto_stories_rounded, color: Color(0xFF94A3B8)),
                                  selectedIcon: Icon(Icons.auto_stories_rounded, color: Colors.white),
                                  label: 'ពិន្ទុ',
                                ),
                                NavigationDestination(
                                  icon: Icon(Icons.apps_rounded, color: Color(0xFF94A3B8)),
                                  selectedIcon: Icon(Icons.apps_rounded, color: Colors.white),
                                  label: 'ម៉ឺនុយទាំងអស់',
                                ),
                              ]
                            : const [
                                NavigationDestination(
                                  icon: Icon(Icons.grid_view_rounded, color: Color(0xFF94A3B8)),
                                  selectedIcon: Icon(Icons.grid_view_rounded, color: Colors.white),
                                  label: 'ទំព័រដើម',
                                ),
                                NavigationDestination(
                                  icon: Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF94A3B8)),
                                  selectedIcon: Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
                                  label: 'ស្កេនវត្តមាន',
                                ),
                                NavigationDestination(
                                  icon: Icon(Icons.auto_stories_rounded, color: Color(0xFF94A3B8)),
                                  selectedIcon: Icon(Icons.auto_stories_rounded, color: Colors.white),
                                  label: 'បញ្ចូលពិន្ទុ',
                                ),
                              ],
                      ),
                    ),
                  );
                },
              )
            : null,
      ),
    );
  }
}
