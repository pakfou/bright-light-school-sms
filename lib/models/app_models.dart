// lib/models/app_models.dart
import 'package:flutter/material.dart';

enum UserRole { admin, teacher }
enum ProgramType { fullTime, partTime }
enum ShiftType { morning, afternoon, evening }

class Student {
  final String id;
  final String studentCode;
  String khmerName;
  String latinName;
  String gender;
  DateTime dob;
  String parentName;
  String parentPhone;
  String address;
  ProgramType programType;
  String classroomId;
  String status;
  String? photoUrl;
  DateTime enrollmentDate;
  double averageGrade;
  int rankInClass;
  String gradeLetter;
  double attendanceRate;
  String healthNotes;
  String previousSchool;

  Student({
    required this.id,
    required this.studentCode,
    required this.khmerName,
    required this.latinName,
    required this.gender,
    required this.dob,
    this.parentName = 'អាណាព្យាបាល',
    required this.parentPhone,
    this.address = 'ក្រុងប៉ោយប៉ែត ខេត្តបន្ទាយមានជ័យ',
    required this.programType,
    required this.classroomId,
    this.status = 'ACTIVE',
    this.photoUrl,
    DateTime? enrollmentDate,
    this.averageGrade = 88.5,
    this.rankInClass = 1,
    this.gradeLetter = 'A',
    this.attendanceRate = 97.5,
    this.healthNotes = 'សុខភាពល្អធម្មតា គ្មានប្រវត្តិប្រតិកម្មថ្នាំ',
    this.previousSchool = 'មត្តេយ្យសាលាប៉ោយប៉ែត',
  }) : enrollmentDate = enrollmentDate ?? DateTime(2026, 1, 10);
}

class Classroom {
  final String id;
  String gradeLevel;
  String roomName;
  ProgramType programType;
  ShiftType shift;
  String? subjectFocus; // អង់គ្លេស, ចិន, កុំព្យូទ័រ
  int capacity;

  Classroom({
    required this.id,
    required this.gradeLevel,
    required this.roomName,
    required this.programType,
    required this.shift,
    this.subjectFocus,
    this.capacity = 30,
  });
}

class ClassArrangementRow {
  final int no;
  String teacherName;
  String oldTermLevel;
  String oldStudentsCount;
  String newTermLevel;
  String room;
  String newStudentsCount;
  String others;

  ClassArrangementRow({
    required this.no,
    required this.teacherName,
    required this.oldTermLevel,
    required this.oldStudentsCount,
    required this.newTermLevel,
    required this.room,
    required this.newStudentsCount,
    this.others = '',
  });
}

class Teacher {
  final String id;
  final String teacherCode;
  String fullName;
  String latinName;
  String gender;
  String phone;
  String email;
  String subjectSpecialty;
  String educationDegree;
  String experienceYears;
  double baseSalary;
  DateTime joinDate;
  String status;
  String? photoUrl;
  String bioSummary;
  List<String> assignedClasses;
  double attendanceRate;

  Teacher({
    required this.id,
    required this.teacherCode,
    required this.fullName,
    this.latinName = '',
    this.gender = 'M',
    required this.phone,
    this.email = '',
    required this.subjectSpecialty,
    this.educationDegree = 'បរិញ្ញាបត្រអប់រំ (B.Ed)',
    this.experienceYears = '៥ ឆ្នាំ',
    required this.baseSalary,
    DateTime? joinDate,
    this.status = 'ACTIVE',
    this.photoUrl,
    this.bioSummary = 'មានបទពិសោធន៍បង្រៀនជាច្រើនឆ្នាំ ផ្តោតលើវិធីសាស្ត្របង្រៀនទំនើប និងយកចិត្តទុកដាក់ខ្ពស់ចំពោះការលូតលាស់របស់កុមារ។',
    List<String>? assignedClasses,
    this.attendanceRate = 98.0,
  })  : joinDate = joinDate ?? DateTime(2023, 10, 1),
        assignedClasses = assignedClasses ?? const ['ថ្នាក់ទី ១A', 'ថ្នាក់ទី ២B'];
}

class AttendanceRecord {
  final String studentId;
  final String classroomId;
  final DateTime timestamp;
  String status; // PRESENT, LATE, PERMISSION, ABSENT

  AttendanceRecord({
    required this.studentId,
    required this.classroomId,
    required this.timestamp,
    required this.status,
  });
}

// Global Mock Database Singleton សម្រាប់ State Management
class AppDataStore extends ChangeNotifier {
  static final AppDataStore instance = AppDataStore._internal();
  AppDataStore._internal();

  UserRole currentUserRole = UserRole.admin;
  String currentUserName = "ហាក់ ប៉ាក់ហ៊្វូរ (Admin)";
  String? loggedTeacherCode;

  // បញ្ជីថ្នាក់រៀន
  List<Classroom> classrooms = [
    Classroom(id: 'c1', gradeLevel: 'ថ្នាក់ទី ១A', roomName: 'បន្ទប់ ១០១', programType: ProgramType.fullTime, shift: ShiftType.morning),
    Classroom(id: 'c2', gradeLevel: 'ថ្នាក់ទី ២B', roomName: 'បន្ទប់ ១០២', programType: ProgramType.fullTime, shift: ShiftType.afternoon),
    Classroom(id: 'c3', gradeLevel: 'English Level 1', roomName: 'បន្ទប់ Lab 2', programType: ProgramType.partTime, shift: ShiftType.evening, subjectFocus: 'ភាសាអង់គ្លេស'),
    Classroom(id: 'c4', gradeLevel: 'Computer Basics', roomName: 'បន្ទប់កុំព្យូទ័រ A', programType: ProgramType.partTime, shift: ShiftType.evening, subjectFocus: 'ថ្នាក់កុំព្យូទ័រ'),
    Classroom(id: 'c5', gradeLevel: 'Chinese Foundation', roomName: 'បន្ទប់ ២០១', programType: ProgramType.partTime, shift: ShiftType.evening, subjectFocus: 'ភាសាចិន'),
  ];

  // បញ្ជីសិស្ស
  List<Student> students = [
    Student(
      id: 's1',
      studentCode: 'BL-2026-001',
      khmerName: 'ឈាវ ម៉ីលីញ',
      latinName: 'Chheav Meyling',
      gender: 'F',
      dob: DateTime(2016, 5, 12),
      parentName: 'ឈាវ សុផល (ឪពុក)',
      parentPhone: '012 345 678',
      address: 'ភូមិក្បាលស្ពាន សង្កាត់ប៉ោយប៉ែត ក្រុងប៉ោយប៉ែត',
      programType: ProgramType.fullTime,
      classroomId: 'c1',
      averageGrade: 94.5,
      rankInClass: 1,
      gradeLetter: 'A',
      attendanceRate: 98.8,
      healthNotes: 'សុខភាពមាំទាំ គ្មានជំងឺប្រចាំកាយ',
      previousSchool: 'មត្តេយ្យសាលាប៉ោយប៉ែត',
    ),
    Student(
      id: 's2',
      studentCode: 'BL-2026-002',
      khmerName: 'បៀវ ម៉េវហៃ',
      latinName: 'Biev Mevhay',
      gender: 'M',
      dob: DateTime(2016, 8, 20),
      parentName: 'បៀវ សេង (ឪពុក)',
      parentPhone: '097 888 999',
      address: 'ភូមិអូរជ្រៅ សង្កាត់អូរជ្រៅ ក្រុងប៉ោយប៉ែត',
      programType: ProgramType.fullTime,
      classroomId: 'c1',
      averageGrade: 88.0,
      rankInClass: 2,
      gradeLetter: 'B',
      attendanceRate: 96.5,
      healthNotes: 'ប្រតិកម្មនឹងធូលីតិចតួច',
      previousSchool: 'សាលាភាសាអង់គ្លេសស្មាតឃីដ',
    ),
    Student(
      id: 's3',
      studentCode: 'BL-2026-003',
      khmerName: 'ឡុង វិបុល',
      latinName: 'Long Vibol',
      gender: 'M',
      dob: DateTime(2015, 2, 14),
      parentName: 'ឡុង សុជាតិ (ម្តាយ)',
      parentPhone: '088 123 456',
      address: 'ភូមិព្រៃព្រិច សង្កាត់ប៉ោយប៉ែត',
      programType: ProgramType.partTime,
      classroomId: 'c4',
      averageGrade: 85.0,
      rankInClass: 3,
      gradeLetter: 'B',
      attendanceRate: 95.0,
      healthNotes: 'ធម្មតា',
      previousSchool: 'សាលាបឋមសិក្សាទួលពង្រ',
    ),
    Student(
      id: 's4',
      studentCode: 'BL-2026-004',
      khmerName: 'នួន វឌ្ឍនៈ',
      latinName: 'Nuon Vathana',
      gender: 'M',
      dob: DateTime(2015, 11, 05),
      parentName: 'នួន វិរៈ (ឪពុក)',
      parentPhone: '092 555 444',
      address: 'ភូមិផ្សារកណ្តាល សង្កាត់ផ្សារកណ្តាល',
      programType: ProgramType.partTime,
      classroomId: 'c3',
      averageGrade: 91.0,
      rankInClass: 1,
      gradeLetter: 'A',
      attendanceRate: 97.2,
      healthNotes: 'ធម្មតា',
      previousSchool: 'មត្តេយ្យសាលាសុភមង្គល',
    ),
  ];

  // បញ្ជីគ្រូបង្រៀន
  List<Teacher> teachers = [
    Teacher(
      id: 't1',
      teacherCode: 'T-101',
      fullName: 'ហាក់ ប៉ាក់ហ៊្វូរ',
      latinName: 'Hak Pakfou',
      gender: 'M',
      phone: '088 999 777',
      email: 'hakpakfou@brightlife.edu.kh',
      subjectSpecialty: 'វិទ្យាសាស្ត្រកុំព្យូទ័រ & គណិតវិទ្យា',
      educationDegree: 'បរិញ្ញាបត្រវិទ្យាសាស្ត្រកុំព្យូទ័រ (RUPP)',
      experienceYears: '៦ ឆ្នាំ',
      baseSalary: 450.0,
      joinDate: DateTime(2021, 9, 1),
      status: 'ACTIVE',
      bioSummary: 'ប្រធានដេប៉ាតឺម៉ង់បច្ចេកវិទ្យា និងគណិតវិទ្យា មានជំនាញខ្ពស់លើការបង្រៀនកុមារជាមួយប្រព័ន្ធឌីជីថល និងសរសេរកូដមូលដ្ឋាន។',
      assignedClasses: ['Computer Basics', 'ថ្នាក់ទី ១A (គណិត)'],
      attendanceRate: 99.1,
    ),
    Teacher(
      id: 't2',
      teacherCode: 'T-102',
      fullName: 'សន ចរិយា',
      latinName: 'Sorn Chariya',
      gender: 'F',
      phone: '077 333 222',
      email: 'sornchariya@brightlife.edu.kh',
      subjectSpecialty: 'ភាសាអង់គ្លេសកុមារ (ESL)',
      educationDegree: 'បរិញ្ញាបត្រអប់រំភាសាអង់គ្លេស (IFL)',
      experienceYears: '៤ ឆ្នាំ',
      baseSalary: 380.0,
      joinDate: DateTime(2022, 10, 15),
      status: 'ACTIVE',
      bioSummary: 'គ្រូបង្រៀនភាសាអង់គ្លេសកម្រិតបឋមសិក្សា មានវិញ្ញាបនបត្រ TESOL អន្តរជាតិ និងបច្ចេកទេសបង្រៀនតាមបែប Phonics & Gamification។',
      assignedClasses: ['English Level 1', 'ថ្នាក់ទី ២B'],
      attendanceRate: 97.8,
    ),
    Teacher(
      id: 't3',
      teacherCode: 'T-103',
      fullName: 'ចាន់ សុវណ្ណារ៉ា',
      latinName: 'Chan Sovannara',
      gender: 'M',
      phone: '012 444 888',
      email: 'sovannara@brightlife.edu.kh',
      subjectSpecialty: 'ភាសាខ្មែរ និងអក្សរសាស្ត្រ',
      educationDegree: 'គរុកោសល្យបឋមសិក្សា (PTTC)',
      experienceYears: '៨ ឆ្នាំ',
      baseSalary: 420.0,
      joinDate: DateTime(2020, 1, 5),
      status: 'ACTIVE',
      bioSummary: 'មានជំនាញជ្រៅជ្រះលើការបង្រៀនអក្សរផ្ចង់ វេយ្យាករណ៍ និងការអានស្ទាត់ជំនាញដល់សិស្សកម្រិតបឋមសិក្សា។',
      assignedClasses: ['ថ្នាក់ទី ១A', 'ថ្នាក់ទី ២B'],
      attendanceRate: 98.5,
    ),
  ];

  // បញ្ជីវត្តមាន
  List<AttendanceRecord> attendanceRecords = [];

  // ប្រាក់បង់សិស្ស & ប្រាក់ខែគ្រូ
  List<Map<String, dynamic>> studentInvoices = [
    {
      'id': 'INV-2026-001',
      'studentCode': 'BL-2026-001',
      'name': 'ឈាវ ម៉ីលីញ',
      'parentName': 'ឈាវ សុផល',
      'parentPhone': '012 345 678',
      'class': 'ថ្នាក់ទី ១A',
      'program': 'ពេញម៉ោង (Full-Time)',
      'month': 'វិច្ឆិកា ២០២៦',
      'amount': 45.0,
      'dueDate': '2026-11-05',
      'daysOverdue': 0,
      'status': 'PAID', // PAID, DUE_TODAY, OVERDUE
      'paidDate': '2026-11-03',
      'bankType': 'ABA KHQR',
      'accountNo': '000 888 999 (Bright Life School)',
    },
    {
      'id': 'INV-2026-002',
      'studentCode': 'BL-2026-002',
      'name': 'បៀវ ម៉េវហៃ',
      'parentName': 'បៀវ សេង',
      'parentPhone': '097 888 999',
      'class': 'ថ្នាក់ទី ១A',
      'program': 'ពេញម៉ោង (Full-Time)',
      'month': 'វិច្ឆិកា ២០២៦',
      'amount': 45.0,
      'dueDate': '2026-11-20', // Today
      'daysOverdue': 0,
      'status': 'DUE_TODAY',
      'paidDate': null,
      'bankType': 'ABA KHQR',
      'accountNo': '000 888 999 (Bright Life School)',
    },
    {
      'id': 'INV-2026-003',
      'studentCode': 'BL-2026-003',
      'name': 'ឡុង វិបុល',
      'parentName': 'ឡុង សុជាតិ',
      'parentPhone': '088 123 456',
      'class': 'Computer Basics',
      'program': 'ក្រៅម៉ោង (Part-Time)',
      'month': 'វិច្ឆិកា ២០២៦',
      'amount': 25.0,
      'dueDate': '2026-11-10', // 10 days ago
      'daysOverdue': 10,
      'status': 'OVERDUE',
      'paidDate': null,
      'bankType': 'ACLEDA KHQR',
      'accountNo': '012 345 678 90 (Bright Life School)',
    },
    {
      'id': 'INV-2026-004',
      'studentCode': 'BL-2026-004',
      'name': 'នួន វឌ្ឍនៈ',
      'parentName': 'នួន វិរៈ',
      'parentPhone': '092 555 444',
      'class': 'English Level 1',
      'program': 'ក្រៅម៉ោង (Part-Time)',
      'month': 'វិច្ឆិកា ២០២៦',
      'amount': 30.0,
      'dueDate': '2026-11-15',
      'daysOverdue': 5,
      'status': 'OVERDUE',
      'paidDate': null,
      'bankType': 'ABA KHQR',
      'accountNo': '000 888 999 (Bright Life School)',
    },
  ];

  List<Map<String, dynamic>> teacherSalaries = [
    {
      'id': 'SAL-2026-11-01',
      'teacherId': 't1',
      'teacherCode': 'T-101',
      'teacherName': 'ហាក់ ប៉ាក់ហ៊្វូរ',
      'latinName': 'Hak Pakfou',
      'subject': 'វិទ្យាសាស្ត្រកុំព្យូទ័រ & គណិតវិទ្យា',
      'month': 'វិច្ឆិកា ២០២៦',
      'daysTaught': 22, // ចំនួនថ្ងៃដែលបានបង្រៀនជាក់ស្តែង
      'totalWorkDays': 24, // ចំនួនថ្ងៃធ្វើការសរុបក្នុងខែ
      'attendanceRate': 99.1,
      'baseSalary': 450.0,
      'teachingAllowance': 50.0,
      'bonus': 30.0,
      'deductions': 0.0,
      'netSalary': 530.0,
      'status': 'READY_TO_PAY', // PAID, READY_TO_PAY, PENDING
      'paymentDate': null,
    },
    {
      'id': 'SAL-2026-11-02',
      'teacherId': 't2',
      'teacherCode': 'T-102',
      'teacherName': 'សន ចរិយា',
      'latinName': 'Sorn Chariya',
      'subject': 'ភាសាអង់គ្លេសកុមារ (ESL)',
      'month': 'វិច្ឆិកា ២០២៦',
      'daysTaught': 21,
      'totalWorkDays': 24,
      'attendanceRate': 97.8,
      'baseSalary': 380.0,
      'teachingAllowance': 40.0,
      'bonus': 20.0,
      'deductions': 0.0,
      'netSalary': 440.0,
      'status': 'PAID',
      'paymentDate': '2026-11-19',
    },
    {
      'id': 'SAL-2026-11-03',
      'teacherId': 't3',
      'teacherCode': 'T-103',
      'teacherName': 'ចាន់ សុវណ្ណារ៉ា',
      'latinName': 'Chan Sovannara',
      'subject': 'ភាសាខ្មែរ និងអក្សរសាស្ត្រ',
      'month': 'វិច្ឆិកា ២០២៦',
      'daysTaught': 23,
      'totalWorkDays': 24,
      'attendanceRate': 98.5,
      'baseSalary': 420.0,
      'teachingAllowance': 45.0,
      'bonus': 25.0,
      'deductions': 0.0,
      'netSalary': 490.0,
      'status': 'READY_TO_PAY',
      'paymentDate': null,
    },
  ];

  void markInvoiceAsPaid(String invoiceId) {
    final idx = studentInvoices.indexWhere((inv) => inv['id'] == invoiceId);
    if (idx != -1) {
      studentInvoices[idx]['status'] = 'PAID';
      studentInvoices[idx]['paidDate'] = DateTime.now().toString().substring(0, 10);
      notifyListeners();
    }
  }

  void markSalaryAsPaid(String salaryId) {
    final idx = teacherSalaries.indexWhere((sal) => sal['id'] == salaryId);
    if (idx != -1) {
      teacherSalaries[idx]['status'] = 'PAID';
      teacherSalaries[idx]['paymentDate'] = DateTime.now().toString().substring(0, 10);
      notifyListeners();
    }
  }

  void addClassroom(Classroom c) {
    classrooms.add(c);
    notifyListeners();
  }

  void addStudent(Student s) {
    students.add(s);
    notifyListeners();
  }

  void updateStudent(Student s) {
    final idx = students.indexWhere((item) => item.id == s.id);
    if (idx != -1) {
      students[idx] = s;
      notifyListeners();
    }
  }

  void deleteStudent(String id) {
    students.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  void addTeacher(Teacher t) {
    teachers.add(t);
    notifyListeners();
  }

  void updateTeacher(Teacher t) {
    final idx = teachers.indexWhere((item) => item.id == t.id);
    if (idx != -1) {
      teachers[idx] = t;
      notifyListeners();
    }
  }

  void deleteTeacher(String id) {
    teachers.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  void recordAttendance(String studentId, String classId, String status) {
    attendanceRecords.removeWhere((r) => r.studentId == studentId && r.classroomId == classId && r.timestamp.day == DateTime.now().day);
    attendanceRecords.add(AttendanceRecord(
      studentId: studentId,
      classroomId: classId,
      timestamp: DateTime.now(),
      status: status,
    ));
    notifyListeners();
  }

  // 📋 តារាងរៀបចំថ្នាក់រៀនភាសាអង់គ្លេស (English Class Arrangement Term 3 Year 4)
  bool isClassArrangementApproved = false;
  String classArrangementApprovedDate = '03 October 2025';
  String classArrangementApprovedBy = 'SAM Sokunthea';
  String classArrangementPreparedDate = '03 October 2025';
  String classArrangementPreparedBy = 'VEN Leapheng';

  List<ClassArrangementRow> classArrangements = [
    ClassArrangementRow(
      no: 1,
      teacherName: 'Tous Sreymom',
      oldTermLevel: 'Four Corners 1B',
      oldStudentsCount: '12',
      newTermLevel: 'Going Place 3',
      room: 'O6',
      newStudentsCount: '13',
      others: '',
    ),
    ClassArrangementRow(
      no: 2,
      teacherName: 'Phi Sreynuch',
      oldTermLevel: 'EFL 3A (8) / EFL 5B (8)',
      oldStudentsCount: '16',
      newTermLevel: 'EFL 5A',
      room: 'O2',
      newStudentsCount: '20',
      others: '',
    ),
    ClassArrangementRow(
      no: 3,
      teacherName: 'Ry Sreyneang',
      oldTermLevel: 'Going Place 2',
      oldStudentsCount: '13',
      newTermLevel: 'EFL 3B',
      room: 'O1',
      newStudentsCount: '12',
      others: '',
    ),
    ClassArrangementRow(
      no: 4,
      teacherName: 'Sophann May',
      oldTermLevel: 'Four Corners 2A',
      oldStudentsCount: '10',
      newTermLevel: 'Four Corners 2B',
      room: 'O5',
      newStudentsCount: '22',
      others: '',
    ),
    ClassArrangementRow(
      no: 5,
      teacherName: 'Eat Sochea',
      oldTermLevel: 'EFL 4B',
      oldStudentsCount: '20',
      newTermLevel: 'Going Place 1',
      room: 'O3',
      newStudentsCount: '13',
      others: "Added Mom's class",
    ),
    ClassArrangementRow(
      no: 6,
      teacherName: 'Ven Leapheng',
      oldTermLevel: 'Four Corners 4A',
      oldStudentsCount: '17',
      newTermLevel: 'Four Corners 4B',
      room: 'O4',
      newStudentsCount: '17',
      others: '',
    ),
    ClassArrangementRow(
      no: 7,
      teacherName: 'Pen Rina',
      oldTermLevel: '-',
      oldStudentsCount: '-',
      newTermLevel: 'EFL 3B',
      room: 'O1',
      newStudentsCount: '12',
      others: '',
    ),
  ];

  void addClassArrangement(ClassArrangementRow row) {
    classArrangements.add(row);
    notifyListeners();
  }

  void updateClassArrangement(int index, ClassArrangementRow row) {
    if (index >= 0 && index < classArrangements.length) {
      classArrangements[index] = row;
      notifyListeners();
    }
  }

  void deleteClassArrangement(int index) {
    if (index >= 0 && index < classArrangements.length) {
      classArrangements.removeAt(index);
      notifyListeners();
    }
  }

  void toggleArrangementApproval() {
    isClassArrangementApproved = !isClassArrangementApproved;
    notifyListeners();
  }
}
