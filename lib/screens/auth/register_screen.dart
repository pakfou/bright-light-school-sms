import 'package:school_management_app/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:ui';
import '../../utils/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _selectedRole = 'Teacher'; // Admin or Teacher
  bool _isLoading = false;
  bool _obscurePass = true;

  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final res = await http
          .post(
            // ignore: prefer_interpolation_to_compose_strings
            Uri.parse(ApiService.baseUrl + '/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': _nameCtrl.text.trim(),
              'email': _emailCtrl.text.trim(),
              'password': _passCtrl.text.trim(),
              'role': _selectedRole,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true));
      if (body['success'] == true) {
        _showToast(body['message'] ?? 'បង្កើតគណនីបានជោគជ័យ!', isError: false);
        if (!mounted) return;
        Navigator.pop(context); // Go back to login
      } else {
        _showToast(body['error'] ?? 'បរាជ័យក្នុងការចុះឈ្មោះ', isError: true);
      }
    } catch (e) {
      _showToast('កំហុសតភ្ជាប់ Server: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showToast(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppTheme.danger : AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
        elevation: 6,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.slate900,
      body: Stack(
        children: [
          // Background Gradient Orbs
          Positioned(
            top: -120,
            right: -120,
            child: _buildGradientOrb(AppTheme.primary, 380),
          ),
          Positioned(
            bottom: -150,
            left: -120,
            child: _buildGradientOrb(AppTheme.info, 420),
          ),

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
              child: Container(color: Colors.transparent),
            ),
          ),

          // Professional Back Button (Top Left)
          Positioned(
            top: 28,
            left: 28,
            child: Material(
              // ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),

          // Main Registration Card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: FadeTransition(
                opacity: _fadeIn,
                child: Container(
                  width: 440,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    // ignore: deprecated_member_use
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 50,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 28,
                            horizontal: 24,
                          ),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.primary, AppTheme.primaryDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  // ignore: deprecated_member_use
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  // ignore: deprecated_member_use
                                  border: Border.all(
                                    // ignore: deprecated_member_use
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.person_add_rounded,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'បង្កើតគណនីថ្មី',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'សូមបំពេញព័ត៌មានខាងក្រោមដើម្បីចុះឈ្មោះ',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  // ignore: deprecated_member_use
                                  color: Colors.white.withOpacity(0.75),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Form Section
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ជ្រើសរើសប្រភេទគណនី (ROLE)',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.slate500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Role Selector Tabs
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.slate100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(
                                            () => _selectedRole = 'Admin',
                                          ),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _selectedRole == 'Admin'
                                                  ? Colors.white
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              boxShadow:
                                                  _selectedRole == 'Admin'
                                                  ? [
                                                      // ignore: deprecated_member_use
                                                      BoxShadow(
                                                        color: Colors.black
                                                            // ignore: deprecated_member_use
                                                            .withOpacity(0.04),
                                                        blurRadius: 6,
                                                        offset: const Offset(
                                                          0,
                                                          2,
                                                        ),
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              'Admin',
                                              style: TextStyle(
                                                fontWeight:
                                                    _selectedRole == 'Admin'
                                                    ? FontWeight.bold
                                                    : FontWeight.w600,
                                                color: _selectedRole == 'Admin'
                                                    ? AppTheme.primary
                                                    : AppTheme.slate500,
                                                fontSize: 13.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(
                                            () => _selectedRole = 'Teacher',
                                          ),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _selectedRole == 'Teacher'
                                                  ? Colors.white
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              boxShadow:
                                                  _selectedRole == 'Teacher'
                                                  ? [
                                                      // ignore: deprecated_member_use
                                                      BoxShadow(
                                                        color: Colors.black
                                                            // ignore: deprecated_member_use
                                                            .withOpacity(0.04),
                                                        blurRadius: 6,
                                                        offset: const Offset(
                                                          0,
                                                          2,
                                                        ),
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              'Teacher / User',
                                              style: TextStyle(
                                                fontWeight:
                                                    _selectedRole == 'Teacher'
                                                    ? FontWeight.bold
                                                    : FontWeight.w600,
                                                color:
                                                    _selectedRole == 'Teacher'
                                                    ? AppTheme.primary
                                                    : AppTheme.slate500,
                                                fontSize: 13.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 22),

                                // Name Field
                                const Text(
                                  'ឈ្មោះពេញ (FULL NAME)',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.slate500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _nameCtrl,
                                  validator: (value) => value!.isEmpty
                                      ? 'សូមបញ្ចូលឈ្មោះពេញ'
                                      : null,
                                  decoration: _inputDecoration(
                                    hint: 'នាមខ្លួន និងនាមត្រកូល',
                                    icon: Icons.person_outline_rounded,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Email Field
                                const Text(
                                  'អ៊ីមែល (EMAIL)',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.slate500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty)
                                      // ignore: curly_braces_in_flow_control_structures
                                      return 'សូមបញ្ចូលអ៊ីមែល';
                                    if (!value.contains('@'))
                                      // ignore: curly_braces_in_flow_control_structures
                                      return 'ទម្រង់អ៊ីមែលមិនត្រឹមត្រូវទេ';
                                    return null;
                                  },
                                  decoration: _inputDecoration(
                                    hint: 'example@brightlight.edu.kh',
                                    icon: Icons.alternate_email_rounded,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Password Field
                                const Text(
                                  'ពាក្យសម្ងាត់ (PASSWORD)',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.slate500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _passCtrl,
                                  obscureText: _obscurePass,
                                  validator: (value) {
                                    if (value == null || value.isEmpty)
                                      // ignore: curly_braces_in_flow_control_structures
                                      return 'សូមបញ្ចូលពាក្យសម្ងាត់';
                                    if (value.length < 6)
                                      // ignore: curly_braces_in_flow_control_structures
                                      return 'ពាក្យសម្ងាត់ត្រូវមានយ៉ាងហោចណាស់ ៦ ខ្ទង់';
                                    return null;
                                  },
                                  decoration:
                                      _inputDecoration(
                                        hint: '••••••••',
                                        icon: Icons.lock_outline_rounded,
                                      ).copyWith(
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePass
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: AppTheme.slate400,
                                            size: 20,
                                          ),
                                          onPressed: () => setState(
                                            () => _obscurePass = !_obscurePass,
                                          ),
                                          splashRadius: 20,
                                        ),
                                      ),
                                ),
                                const SizedBox(height: 28),

                                // Register Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _register,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : const Text(
                                            'បង្កើតគណនី (Register)',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
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
    );
  }

  Widget _buildGradientOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // ignore: deprecated_member_use
        color: color.withOpacity(0.35),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppTheme.slate400, fontSize: 13.5),
      prefixIcon: Icon(icon, color: AppTheme.slate400, size: 20),
      filled: true,
      fillColor: AppTheme.slate50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.slate200, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.danger, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.danger, width: 1.5),
      ),
    );
  }
}
