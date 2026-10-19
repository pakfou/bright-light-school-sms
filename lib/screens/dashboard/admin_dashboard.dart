import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_logo.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(context, auth),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, auth),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Admin Control Center',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: GridView.count(
                            crossAxisCount: 3,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.5,
                            children: [
                              _infoCard(
                                'Total Users',
                                '1,248',
                                Icons.people,
                                Colors.blue,
                              ),
                              _infoCard(
                                'Active Classes',
                                '32',
                                Icons.class_,
                                Colors.green,
                              ),
                              _infoCard(
                                'System Status',
                                'Optimal',
                                Icons.check_circle,
                                Colors.orange,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, AuthProvider auth) {
    return Container(
      width: 260,
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                AppLogo.widget(width: 32, height: 32, shape: BoxShape.circle),
                const SizedBox(width: 12),
                const Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _sidebarItem(Icons.dashboard, 'Dashboard', true),
          _sidebarItem(Icons.supervised_user_circle, 'Users Management', false),
          _sidebarItem(Icons.class_, 'Classrooms', false),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: () => auth.logout(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String title, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white70),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: () {},
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, AuthProvider auth) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Hello, ${auth.currentUser?.name} (${auth.currentUser?.role})',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 16),
          const CircleAvatar(
            backgroundColor: Color(0xFF4F46E5),
            child: Text('A', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      // ignore: deprecated_member_use
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          // ignore: deprecated_member_use
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            // ignore: deprecated_member_use
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
        ],
      ),
    );
  }
}
