import 'package:flutter/material.dart';
import '../../services/api_service.dart';
// ignore: unused_import
import 'package:google_fonts/google_fonts.dart';

// UserModel សម្រាប់បង្ហាញទិន្នន័យក្នុងតារាង
class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'User',
    );
  }
}

class AdminUserManagerScreen extends StatefulWidget {
  const AdminUserManagerScreen({super.key});

  @override
  State<AdminUserManagerScreen> createState() => _AdminUserManagerScreenState();
}

class _AdminUserManagerScreenState extends State<AdminUserManagerScreen> {
  bool _isLoading = false;
  List<UserModel> _users = [];
  String _searchQuery = '';
  String _selectedRoleFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  // จำลองការទាញយកទិន្នន័យ (ជំនួសដោយ ApiService របស់អ្នក)
  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));

    // Mock Data សម្រាប់បង្ហាញ UI ឱ្យស្អាត
    _users = [
      UserModel(
        id: 1,
        name: 'Sok Dara',
        email: 'dara.sok@school.edu',
        role: 'Admin',
      ),
      UserModel(
        id: 2,
        name: 'Chan Mony',
        email: 'mony.chan@school.edu',
        role: 'User',
      ),
      UserModel(
        id: 3,
        name: 'Vichea Rith',
        email: 'vichea.rith@school.edu',
        role: 'User',
      ),
    ];

    setState(() => _isLoading = false);
  }

  void _showAddUserModal() {
    showDialog(
      context: context,
      builder: (ctx) => const _AddUserDialog(),
    ).then((_) => _fetchUsers()); // Refresh ក្រោយពេល Add រួច
  }

  void _showUserActionMenu(UserModel user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFEEF2FF),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Color(0xFF4F46E5),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  user.name,
                  style: const TextStyle(
                    fontFamily: 'Khmer OS Muol Light',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${user.email} • ${user.role}',
                  style: const TextStyle(fontFamily: 'Calibri Light'),
                ),
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                  user.role == 'Admin'
                      ? Icons.person_outline
                      : Icons.admin_panel_settings_outlined,
                  color: const Color(0xFF4F46E5),
                ),
                title: Text(
                  user.role == 'Admin'
                      ? 'ប្តូរសិទ្ធិទៅជា User'
                      : 'ដំឡើងសិទ្ធិជា Admin',
                  style: const TextStyle(fontFamily: 'Khmer OS Battambang'),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _toggleUserRole(user);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444),
                ),
                title: const Text(
                  'លុបគណនីអ្នកប្រើប្រាស់',
                  style: TextStyle(
                    fontFamily: 'Khmer OS Battambang',
                    color: Color(0xFFEF4444),
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteUser(user);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleUserRole(UserModel user) {
    final newRole = user.role == 'Admin' ? 'User' : 'Admin';
    setState(() {
      final index = _users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        _users[index] = UserModel(
          id: user.id,
          name: user.name,
          email: user.email,
          role: newRole,
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'បានប្តូរសិទ្ធិរបស់ ${user.name} ទៅជា $newRole ដោយជោគជ័យ',
          style: const TextStyle(fontFamily: 'Khmer OS Battambang'),
        ),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  void _confirmDeleteUser(UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'បញ្ជាក់ការលុបគណនី',
          style: TextStyle(fontFamily: 'Khmer OS Muol Light'),
        ),
        content: Text(
          'តើអ្នកពិតជាចង់លុបគណនី "${user.name}" មែនដែរឬទេ?',
          style: const TextStyle(fontFamily: 'Khmer OS Battambang'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'បោះបង់',
              style: TextStyle(fontFamily: 'Khmer OS Battambang'),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _users.removeWhere((u) => u.id == user.id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'បានលុបគណនី ${user.name} រួចរាល់',
                    style: const TextStyle(fontFamily: 'Khmer OS Battambang'),
                  ),
                  backgroundColor: const Color(0xFFEF4444),
                ),
              );
            },
            child: const Text(
              'យល់ព្រមលុប',
              style: TextStyle(fontFamily: 'Khmer OS Battambang'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ត្រងទិន្នន័យតាម Search និង Filter
    final filteredUsers = _users.where((user) {
      final matchesSearch =
          user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesRole =
          _selectedRoleFilter == 'All' || user.role == _selectedRoleFilter;
      return matchesSearch && matchesRole;
    }).toList();

    final isMobile = MediaQuery.of(context).size.width < 768;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 14.0 : 28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'គ្រប់គ្រងអ្នកប្រើប្រាស់',
                      style: TextStyle(
                        fontFamily: 'Khmer OS Muol Light',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'គ្រប់គ្រងសិទ្ធិ និងគណនីបុគ្គលិកទាំងអស់ក្នុងប្រព័ន្ធ',
                      style: TextStyle(
                        fontFamily: 'Khmer OS Battambang',
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showAddUserModal,
                        icon: const Icon(Icons.person_add_alt_1, size: 18),
                        label: const Text(
                          'បន្ថែមគណនីថ្មី',
                          style: TextStyle(
                            fontFamily: 'Khmer OS Battambang',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'គ្រប់គ្រងអ្នកប្រើប្រាស់ (User Management)',
                          style: TextStyle(
                            fontFamily: 'Khmer OS Muol Light',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'គ្រប់គ្រងសិទ្ធិ និងគណនីបុគ្គលិកទាំងអស់នៅក្នុងប្រព័ន្ធ',
                          style: TextStyle(
                            fontFamily: 'Khmer OS Battambang',
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddUserModal,
                      icon: const Icon(Icons.person_add_alt_1, size: 18),
                      label: const Text(
                        'បន្ថែមគណនីថ្មី',
                        style: TextStyle(
                          fontFamily: 'Khmer OS Battambang',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 18),

          // Search & Filter Toolbar
          isMobile
              ? Column(
                  children: [
                    TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'ស្វែងរកឈ្មោះ ឬ អុីមែល...',
                        hintStyle: const TextStyle(
                          fontFamily: 'Khmer OS Battambang',
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF94A3B8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonHideUnderline(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedRoleFilter,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                              value: 'All',
                              child: Text(
                                'គ្រប់ប្រភេទ (All)',
                                style: TextStyle(
                                  fontFamily: 'Khmer OS Battambang',
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Admin',
                              child: Text(
                                'Admin',
                                style: TextStyle(fontFamily: 'Calibri Light'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'User',
                              child: Text(
                                'User',
                                style: TextStyle(fontFamily: 'Calibri Light'),
                              ),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedRoleFilter = v!),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          hintText: 'ស្វែងរកឈ្មោះ ឬ អុីមែល...',
                          hintStyle: const TextStyle(
                            fontFamily: 'Khmer OS Battambang',
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF94A3B8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButtonHideUnderline(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedRoleFilter,
                          items: const [
                            DropdownMenuItem(
                              value: 'All',
                              child: Text(
                                'គ្រប់ប្រភេទ (All)',
                                style: TextStyle(
                                  fontFamily: 'Khmer OS Battambang',
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Admin',
                              child: Text(
                                'Admin',
                                style: TextStyle(fontFamily: 'Calibri Light'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'User',
                              child: Text(
                                'User',
                                style: TextStyle(fontFamily: 'Calibri Light'),
                              ),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedRoleFilter = v!),
                        ),
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 18),

          // Table Section
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x04000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4F46E5),
                      ),
                    )
                  : filteredUsers.isEmpty
                  ? const Center(
                      child: Text(
                        'រកមិនឃើញទិន្នន័យអ្នកប្រើប្រាស់',
                        style: TextStyle(
                          fontFamily: 'Khmer OS Battambang',
                          color: Color(0xFF64748B),
                        ),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ListView.separated(
                        itemCount: filteredUsers.length,
                        // ignore: unnecessary_underscores
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          final isAdmin = user.role == 'Admin';
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: isAdmin
                                  ? const Color(0xFFEEF2FF)
                                  : const Color(0xFFF1F5F9),
                              child: Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  color: isAdmin
                                      ? const Color(0xFF4F46E5)
                                      : const Color(0xFF64748B),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              user.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                                fontFamily: 'Khmer OS Battambang',
                              ),
                            ),
                            subtitle: Text(
                              user.email,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                                fontFamily: 'Calibri Light',
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isAdmin
                                        ? const Color(0xFFEEF2FF)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    user.role,
                                    style: TextStyle(
                                      color: isAdmin
                                          ? const Color(0xFF4F46E5)
                                          : const Color(0xFF475569),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Calibri Light',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  onPressed: () => _showUserActionMenu(user),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- PROFESSIONAL ADD USER DIALOG ---
class _AddUserDialog extends StatefulWidget {
  const _AddUserDialog();

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _role = 'User';
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    if (_nameCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('សូមបំពេញព័ត៌មានឲ្យគ្រប់គ្រាន់'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final res = await ApiService.register(
      _nameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _passCtrl.text.trim(),
      _role,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('បង្កើតគណនីបានជោគជ័យ!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['error'] ?? 'បរាជ័យ'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'បន្ថែមគណនីថ្មី',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'ឈ្មោះ (Name)',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailCtrl,
              decoration: InputDecoration(
                labelText: 'អុីមែល (Email)',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'ពាក្យសម្ងាត់ (Password)',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: (_role == 'User') ? 'User' : 'Admin',
              decoration: InputDecoration(
                labelText: 'ប្រភេទគណនី (Role)',
                prefixIcon: const Icon(Icons.admin_panel_settings_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                DropdownMenuItem(value: 'User', child: Text('User (Teacher)')),
              ],
              onChanged: (v) => setState(() => _role = v!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
          child: const Text('បោះបង់'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleRegister,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('បង្កើតគណនី'),
        ),
      ],
    );
  }
}
