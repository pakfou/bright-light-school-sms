import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/classroom_model.dart';
import '../../models/student_model.dart';
import 'package:google_fonts/google_fonts.dart';

class GradesManagerView extends StatefulWidget {
  const GradesManagerView({super.key});

  @override
  State<GradesManagerView> createState() => _GradesManagerViewState();
}

class _GradesManagerViewState extends State<GradesManagerView> {
  List<ClassroomModel> _classrooms = [];
  List<StudentModel> _students = [];
  List<dynamic> _grades = [];
  ClassroomModel? _selectedClassroom;
  bool _isLoading = false;

  final _examTitleCtrl = TextEditingController();
  final _scoreCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClassrooms();
  }

  Future<void> _loadClassrooms() async {
    setState(() => _isLoading = true);
    final classes = await ApiService.getClassrooms();
    setState(() {
      _classrooms = classes;
      _isLoading = false;
    });
  }

  Future<void> _loadStudentsAndGrades(ClassroomModel classroom) async {
    setState(() {
      _selectedClassroom = classroom;
      _isLoading = true;
    });

    final students = await ApiService.getStudents(classroomId: classroom.id);
    final grades = await ApiService.getGrades(classroom.id);

    setState(() {
      _students = students;
      _grades = grades;
      _isLoading = false;
    });
  }

  Future<void> _addGrade(StudentModel student) async {
    if (_examTitleCtrl.text.isEmpty || _scoreCtrl.text.isEmpty) return;

    final score = double.tryParse(_scoreCtrl.text) ?? 0;
    String gradeLetter = 'F';
    if (score >= 90) {
      gradeLetter = 'A';
    } else if (score >= 80) {
      gradeLetter = 'B';
    } else if (score >= 70) {
      gradeLetter = 'C';
    } else if (score >= 60) {
      gradeLetter = 'D';
    } else if (score >= 50) {
      gradeLetter = 'E';
    }

    setState(() => _isLoading = true);
    final success = await ApiService.addGrade({
      'student_id': student.id,
      'classroom_id': _selectedClassroom!.id,
      'exam_title': _examTitleCtrl.text,
      'score': score,
      'grade_letter': gradeLetter,
    });

    if (success) {
      _scoreCtrl.clear();
      _examTitleCtrl.clear();
      await _loadStudentsAndGrades(_selectedClassroom!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('បានបញ្ចូលពិន្ទុជោគជ័យ (Grade added)')),
        );
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('មានបញ្ហា (Error)')));
      }
    }
  }

  void _showGradeModal(StudentModel student) {
    _scoreCtrl.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 20,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'បញ្ចូលពិន្ទុសម្រាប់: ${student.nameKhmer} (${student.fullName})',
              style: GoogleFonts.notoSansKhmer(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _examTitleCtrl,
              decoration: const InputDecoration(
                labelText: 'ឈ្មោះការប្រឡង (Exam Title)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _scoreCtrl,
              decoration: const InputDecoration(
                labelText: 'ពិន្ទុ (Score 0-100)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _addGrade(student);
                },
                child: const Text('រក្សាទុក (Save)'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'គ្រប់គ្រងពិន្ទុ (Grades Management)',
            style: GoogleFonts.notoSansKhmer(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<ClassroomModel>(
                  decoration: const InputDecoration(
                    labelText: 'ជ្រើសរើសថ្នាក់រៀន (Select Classroom)',
                    border: OutlineInputBorder(),
                  ),
                  items: _classrooms.map((c) {
                    return DropdownMenuItem(value: c, child: Text(c.className));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) _loadStudentsAndGrades(val);
                  },
                ),
              ),
              const SizedBox(width: 16),
              if (_isLoading) const CircularProgressIndicator(),
            ],
          ),
          const SizedBox(height: 24),
          if (_selectedClassroom != null) ...[
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Students List
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            // ignore: deprecated_member_use
                            color: const Color(0xFF94A3B8).withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _students.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final student = _students[i];
                          return Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFEEF2FF),
                                child: Text(
                                  student.studentCode.substring(student.studentCode.length - 2),
                                  style: GoogleFonts.outfit(color: const Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                              title: Text(student.nameKhmer, style: GoogleFonts.notoSansKhmer(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                              subtitle: Text(student.fullName, style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12)),
                              trailing: IconButton(
                                icon: const Icon(Icons.add_task, color: Color(0xFF4F46E5)),
                                onPressed: () => _showGradeModal(student),
                                tooltip: 'បញ្ចូលពិន្ទុ',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Grades List
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            // ignore: deprecated_member_use
                            color: const Color(0xFF94A3B8).withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _grades.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final g = _grades[i];
                          return Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor: g['grade_letter'] == 'F' ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                                child: Text(
                                  g['grade_letter'],
                                  style: GoogleFonts.outfit(
                                    color: g['grade_letter'] == 'F' ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                '${g['name_kh']} - ${g['exam_title']}',
                                style: GoogleFonts.notoSansKhmer(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                              ),
                              subtitle: Text(
                                'Score: ${g['score']} | Date: ${g['created_at'].toString().split('T')[0]}',
                                style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 13),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else
            const Expanded(
              child: Center(child: Text('សូមជ្រើសរើសថ្នាក់រៀនជាមុនសិន')),
            ),
        ],
      ),
    );
  }
}
