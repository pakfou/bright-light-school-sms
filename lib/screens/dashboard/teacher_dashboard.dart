import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Welcome, ${auth.currentUser?.name} (Teacher)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Assigned Classes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: auth.assignedClasses.isEmpty
                  ? const Center(child: Text('No classes assigned.'))
                  : ListView.builder(
                      itemCount: auth.assignedClasses.length,
                      itemBuilder: (context, index) {
                        final classroom = auth.assignedClasses[index];
                        final isSelected =
                            auth.selectedClass?.id == classroom.id;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF4F46E5)
                                  : Colors.transparent,
                              width: 2,
                            ),
                            // ignore: deprecated_member_use
                            boxShadow: [
                              BoxShadow(
                                // ignore: deprecated_member_use
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFEEF2FF),
                              child: Icon(
                                Icons.class_,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                            title: Text(
                              classroom.className,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text('Subject: ${classroom.subject}'),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected
                                    ? const Color(0xFF4F46E5)
                                    : Colors.grey.shade100,
                                foregroundColor: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                              onPressed: () => auth.selectClass(classroom),
                              child: Text(
                                isSelected ? 'Selected' : 'Select Class',
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
