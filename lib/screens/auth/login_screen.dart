import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_management_app/providers/auth_provider.dart';
import 'package:school_management_app/screens/dashboard/dashboard_shell.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:school_management_app/services/api_config.dart';
// ignore: unused_import
import 'package:school_management_app/services/api_service.dart';
import 'package:school_management_app/utils/app_theme.dart';
import 'package:school_management_app/utils/app_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _selectedRole = 'Admin'; // 'Admin' ឬ 'User'
  final TextEditingController _adminEmailCtrl = TextEditingController(
    text: 'admin@brightlight.edu.kh',
  );
  final TextEditingController _adminPassCtrl = TextEditingController(
    text: '1202',
  );
  final TextEditingController _teacherIdCtrl = TextEditingController(
    text: 'TCH-1001',
  );

  bool _obscurePassword = true;

  @override
  void dispose() {
    _adminEmailCtrl.dispose();
    _adminPassCtrl.dispose();
    _teacherIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final auth = context.read<AuthProvider>();
    auth.clearError();

    if (_selectedRole == 'User') {
      final code = _teacherIdCtrl.text.trim();
      if (code.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('សូមបញ្ចូលលេខសម្គាល់ ID គ្រូបង្រៀន!'),
            backgroundColor: Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    } else {
      if (_adminEmailCtrl.text.trim().isEmpty ||
          _adminPassCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('សូមបញ្ចូលអ៊ីម៉ែល និងលេខសម្ងាត់ Admin!'),
            backgroundColor: Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    final payload = _selectedRole == 'Admin'
        ? {
            'role': 'Admin',
            'email': _adminEmailCtrl.text.trim(),
            'password': _adminPassCtrl.text.trim(),
          }
        : {'role': 'User', 'teacher_id_code': _teacherIdCtrl.text.trim()};

    final success = await auth.login(payload).timeout(
      const Duration(seconds: 8),
      onTimeout: () => false,
    );

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardShell(
            currentUser: auth.currentUser!.toJson(),
            isAdmin: auth.isAdmin,
          ),
        ),
      );
    } else if (mounted) {
      // Automatic Demo Fallback for Admin when backend is unreachable or returns error
      final pass = _adminPassCtrl.text.trim();
      final email = _adminEmailCtrl.text.trim().toLowerCase();
      if (_selectedRole == 'Admin' &&
          (pass == '1202' ||
              pass == 'admin123' ||
              email == 'admin@brightlight.edu.kh' ||
              email.contains('admin'))) {
        await _enterDemoMode();
      }
    }
  }

  /// Instant Demo Admin fallback entry
  Future<void> _enterDemoMode() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.loginDemoAdmin();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 បានចូលប្រព័ន្ធជោគជ័យក្នុងមុខងារ Admin Demo (Offline/Direct Access)!'),
          backgroundColor: Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardShell(
            currentUser: auth.currentUser!.toJson(),
            isAdmin: auth.isAdmin,
          ),
        ),
      );
    }
  }

  void _showServerConfigDialog() {
    final controller = TextEditingController(text: ApiConfig.baseUrl);
    String? testStatus;
    Color testStatusColor = const Color(0xFF64748B);
    bool testing = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.dns_rounded,
                    color: Color(0xFF2563EB),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'កំណត់ Server API (Endpoint)',
                    style: AppTheme.khmerHeading(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'បញ្ចូលអាសយដ្ឋាន Backend Server (សម្រាប់ Firebase Hosting, Cloud Run, ឬ Local)៖',
                    style: AppTheme.khmerBody(
                      fontSize: 12.5,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    style: AppTheme.khmerBody(
                      fontSize: 13,
                      color: const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.link_rounded,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
                      hintText: 'https://bright-light-school-sms.onrender.com/api',
                      labelText: 'API Base URL',
                      labelStyle: AppTheme.khmerBody(fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.cloud_done_rounded, size: 14, color: Color(0xFF2563EB)),
                        label: Text(
                          'Render Cloud (bright-light-school-sms.onrender.com)',
                          style: AppTheme.khmerBody(fontSize: 10.5, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          setDialogState(() {
                            controller.text = 'https://bright-light-school-sms.onrender.com/api';
                          });
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.laptop_rounded, size: 14, color: Color(0xFF059669)),
                        label: Text(
                          'Local (127.0.0.1:5000)',
                          style: AppTheme.khmerBody(fontSize: 10.5),
                        ),
                        onPressed: () {
                          setDialogState(() {
                            if (kIsWeb && Uri.base.scheme == 'https') {
                              testStatus = '⚠️ Web Hosting HTTPS មិនអាចភ្ជាប់ទៅកាន់ HTTP Localhost បានទេ (Browser Mixed Content Security Block)។';
                              testStatusColor = const Color(0xFFD97706);
                            }
                            controller.text = 'http://127.0.0.1:5000/api';
                          });
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.shield_rounded, size: 14, color: Color(0xFFD97706)),
                        label: Text(
                          'Cloudflare Tunnel',
                          style: AppTheme.khmerBody(fontSize: 10.5),
                        ),
                        onPressed: () {
                          setDialogState(() {
                            controller.text =
                                'https://cakes-intro-prepare-sisters.trycloudflare.com/api';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (testStatus != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: testStatusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: testStatusColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        testStatus!,
                        style: AppTheme.khmerBody(
                          fontSize: 12,
                          color: testStatusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: testing
                    ? null
                    : () async {
                        setDialogState(() {
                          testing = true;
                          testStatus = 'កំពុងតេស្តការតភ្ជាប់...';
                          testStatusColor = const Color(0xFF64748B);
                        });

                        final target = controller.text.trim();
                        final healthUrl = target.endsWith('/api')
                            ? target.replaceAll('/api', '/health')
                            : '$target/health';

                        try {
                          final res = await http
                              .get(Uri.parse(healthUrl))
                              .timeout(const Duration(seconds: 5));
                          if (res.statusCode == 200) {
                            final body = jsonDecode(res.body);
                            setDialogState(() {
                              testing = false;
                              testStatus =
                                  '✅ ភ្ជាប់ជោគជ័យ! (Database: ${body['database'] ?? 'OK'})';
                              testStatusColor = const Color(0xFF059669);
                            });
                          } else {
                            setDialogState(() {
                              testing = false;
                              testStatus = '⚠️ ឆ្លើយតបកូដ ${res.statusCode}';
                              testStatusColor = const Color(0xFFD97706);
                            });
                          }
                        } catch (e) {
                          setDialogState(() {
                            testing = false;
                            testStatus = '❌ មិនអាចភ្ជាប់បានទេ: $e';
                            testStatusColor = const Color(0xFFDC2626);
                          });
                        }
                      },
                icon: testing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_find_rounded, size: 18),
                label: Text(
                  'តេស្ត (Test)',
                  style: AppTheme.khmerBody(fontSize: 12),
                ),
              ),
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('បោះបង់', style: AppTheme.khmerBody(fontSize: 12)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final newUrl = controller.text.trim();
                  await ApiConfig.setCustomBaseUrl(newUrl);
                  if (context.mounted) {
                    setState(() {});
                    Navigator.pop(ctx);
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('បានរក្សាទុក Server: $newUrl'),
                        backgroundColor: const Color(0xFF059669),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: Text(
                  'រក្សាទុក (Save)',
                  style: AppTheme.khmerBody(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ignore: unused_element
  Widget _buildPermissionTag(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTheme.khmerBody(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. School Campus Building & Courtyard Background Image (Bundled Asset)
        Image.asset(
          'assets/images/login_bg.jpg',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, _, _) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),

        // 2. High-end Rich Dark Gradient with Cinematic Vignette
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF0F172A).withValues(alpha: 0.58),
                const Color(0xFF1E1B4B).withValues(alpha: 0.45),
                const Color(0xFF0F172A).withValues(alpha: 0.82),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _selectedRole == 'Admin';
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Stack(
        children: [
          // Background Layer
          Positioned.fill(child: _buildBackground()),

          // Foreground Centered Login Portal Card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: Container(
                width: 490,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.97),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header Banner with Logo & Institution Title
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 28,
                        horizontal: 24,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF1E1B4B),
                            Color(0xFF282566),
                            Color(0xFF1E3A8A),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: AppLogo.widget(
                              width: 78,
                              height: 78,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'សាលាប្រាយឡាយ',
                            textAlign: TextAlign.center,
                            style: AppTheme.khmerHeading(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'BRIGHT LIGHT SCHOOL • MANAGEMENT SYSTEM',
                            textAlign: TextAlign.center,
                            style: AppTheme.englishHeading(
                              color: const Color(0xFF93C5FD),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Form Body
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 28,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              'ចូលប្រព័ន្ធគ្រប់គ្រងសាលា',
                              style: AppTheme.khmerHeading(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Role Selector Tab (Admin vs Teacher)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      setState(() => _selectedRole = 'Admin');
                                      context.read<AuthProvider>().clearError();
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isAdmin
                                            ? const Color(0xFF1D4ED8)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: isAdmin
                                            ? [
                                                BoxShadow(
                                                  color: const Color(
                                                    0xFF1D4ED8,
                                                  ).withValues(alpha: 0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons
                                                    .admin_panel_settings_rounded,
                                                size: 18,
                                                color: isAdmin
                                                    ? Colors.white
                                                    : const Color(0xFF64748B),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'អេតមីន (Admin)',
                                                style: AppTheme.khmerBody(
                                                  color: isAdmin
                                                      ? Colors.white
                                                      : const Color(0xFF475569),
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      setState(() => _selectedRole = 'User');
                                      context.read<AuthProvider>().clearError();
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: !isAdmin
                                            ? const Color(0xFF1D4ED8)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: !isAdmin
                                            ? [
                                                BoxShadow(
                                                  color: const Color(
                                                    0xFF1D4ED8,
                                                  ).withValues(alpha: 0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.badge_rounded,
                                                size: 18,
                                                color: !isAdmin
                                                    ? Colors.white
                                                    : const Color(0xFF64748B),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'អ្នកប្រើប្រាស់ (Users / គ្រូ)',
                                                style: AppTheme.khmerBody(
                                                  color: !isAdmin
                                                      ? Colors.white
                                                      : const Color(0xFF475569),
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Error Alert Banner
                          if (auth.errorMessage != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFFECACA),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: Color(0xFFDC2626),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      auth.errorMessage!,
                                      style: AppTheme.khmerBody(
                                        color: const Color(0xFFB91C1C),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          if (isAdmin) ...[
                            // ADMIN: EMAIL & PASSWORD
                            Text(
                              'អ៊ីម៉ែលគណនីអេតមីន (Admin Email)',
                              style: AppTheme.khmerBody(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _adminEmailCtrl,
                              style: AppTheme.khmerBody(
                                fontSize: 13.5,
                                color: const Color(0xFF0F172A),
                              ),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                  color: Color(0xFF64748B),
                                  size: 20,
                                ),
                                hintText: 'admin@brightlight.edu.kh',
                                hintStyle: AppTheme.khmerBody(
                                  fontSize: 13,
                                  color: const Color(0xFF94A3B8),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFCBD5E1),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFCBD5E1),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF2563EB),
                                    width: 1.5,
                                  ),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'ពាក្យសម្ងាត់ (Password: 1202)',
                              style: AppTheme.khmerBody(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _adminPassCtrl,
                              obscureText: _obscurePassword,
                              style: AppTheme.khmerBody(
                                fontSize: 13.5,
                                color: const Color(0xFF0F172A),
                              ),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  color: Color(0xFF64748B),
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: const Color(0xFF64748B),
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFCBD5E1),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFCBD5E1),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF2563EB),
                                    width: 1.5,
                                  ),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ] else ...[
                            // USER / TEACHER: CODE / ID
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'លេខសម្គាល់ ID គ្រូបង្រៀន (Teacher ID)',
                                  style: AppTheme.khmerBody(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF334155),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'សម្រាប់ Users / គ្រូ',
                                    style: AppTheme.khmerBody(
                                      fontSize: 10,
                                      color: const Color(0xFF2563EB),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _teacherIdCtrl,
                              style: AppTheme.khmerBody(
                                fontSize: 13.5,
                                color: const Color(0xFF0F172A),
                              ),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.badge_outlined,
                                  color: Color(0xFF64748B),
                                  size: 20,
                                ),
                                hintText: 'ឧ. TCH-1001 ឬ 1001',
                                hintStyle: AppTheme.khmerBody(
                                  fontSize: 13,
                                  color: const Color(0xFF94A3B8),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFCBD5E1),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFCBD5E1),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF2563EB),
                                    width: 1.5,
                                  ),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Quick selection chips
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'គំរូ ID គ្រូ:',
                                  style: AppTheme.khmerBody(
                                    fontSize: 11,
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                ...['TCH-1001', 'TCH-1002', 'TCH-1003'].map(
                                  (idCode) => InkWell(
                                    onTap: () {
                                      setState(() {
                                        _teacherIdCtrl.text = idCode;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(0xFFCBD5E1),
                                        ),
                                      ),
                                      child: Text(
                                        idCode,
                                        style: AppTheme.khmerBody(
                                          fontSize: 10.5,
                                          color: const Color(0xFF1E293B),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Permissions Notice Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFBBF7D0),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.verified_user_rounded,
                                        color: Color(0xFF16A34A),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'សិទ្ធិប្រើប្រាស់គណនីគ្រូ (Permissions)',
                                        style: AppTheme.khmerBody(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF166534),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _buildPermissionTag(
                                        Icons.grid_view_rounded,
                                        'ទិដ្ឋភាពទូទៅ (មើល)',
                                        const Color(0xFF2563EB),
                                      ),
                                      _buildPermissionTag(
                                        Icons.qr_code_scanner_rounded,
                                        'ស្កេនវត្តមាន',
                                        const Color(0xFF059669),
                                      ),
                                      _buildPermissionTag(
                                        Icons.grade_rounded,
                                        'បញ្ចូលពិន្ទុ',
                                        const Color(0xFFD97706),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '* Users / គ្រូបង្រៀន មានសិទ្ធិប្រើប្រាស់តែ ៣ មុខងារខាងលើប៉ុណ្ណោះ។',
                                    style: AppTheme.khmerBody(
                                      fontSize: 10.5,
                                      color: const Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),

                          // Submit Action Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1D4ED8),
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor: const Color(0x661D4ED8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: auth.isLoading ? null : _handleLogin,
                              child: auth.isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.login_rounded,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'ចូលប្រព័ន្ធ / Sign In',
                                          style: AppTheme.khmerBody(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Demo Fallback Action Button
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFF10B981),
                                  width: 1.5,
                                ),
                                backgroundColor: const Color(0xFFF0FDF4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: auth.isLoading ? null : _enterDemoMode,
                              icon: const Icon(
                                Icons.offline_bolt_rounded,
                                size: 18,
                                color: Color(0xFF059669),
                              ),
                              label: Text(
                                '⚡ ចូលមើលសាកល្បង Demo Admin (គ្មាន Server)',
                                style: AppTheme.khmerBody(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF065F46),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Footer Note
                          Center(
                            child: Text(
                              'ប្រព័ន្ធគ្រប់គ្រងសាលាប្រាយឡាយ • Bright Light School © 2026',
                              textAlign: TextAlign.center,
                              style: AppTheme.khmerBody(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Server Connection Pill
                          Center(
                            child: InkWell(
                              onTap: _showServerConfigDialog,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
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
                                    const SizedBox(width: 7),
                                    Text(
                                      'Server: ${ApiConfig.baseUrl}',
                                      style: AppTheme.khmerBody(
                                        fontSize: 10.5,
                                        color: const Color(0xFF475569),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    const Icon(
                                      Icons.settings_outlined,
                                      size: 13,
                                      color: Color(0xFF64748B),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
