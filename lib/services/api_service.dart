import 'dart:convert';
// ignore: unnecessary_import
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/classroom_model.dart';
import '../models/student_model.dart';
import '../models/teacher_model.dart';
import 'api_config.dart';

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;

  // ─── DEMO DATA FALLBACKS (When Server is Offline or Unreachable) ───
  static List<ClassroomModel> get demoClassrooms => [
    ClassroomModel(id: 25, className: 'O5 (Going Place 3)', levelType: 'Part-Time', shift: 'Evening', subject: 'English'),
    ClassroomModel(id: 24, className: 'O2 (EFL 5A)', levelType: 'Part-Time', shift: 'Evening', subject: 'English'),
    ClassroomModel(id: 23, className: 'O1 (EFL 3B)', levelType: 'Part-Time', shift: 'Evening', subject: 'English'),
    ClassroomModel(id: 13, className: 'បន្ទប់ការិយាល័យ & រដ្ឋបាល', levelType: 'Full-Time', shift: 'Morning', subject: 'General'),
    ClassroomModel(id: 1, className: 'ថ្នាក់ទី ១A', levelType: 'Full-Time', shift: 'Morning', subject: 'Primary'),
    ClassroomModel(id: 2, className: 'ថ្នាក់ទី ២A', levelType: 'Full-Time', shift: 'Morning', subject: 'Primary'),
  ];

  static List<StudentModel> get demoStudents => [
    StudentModel(id: 1, studentCode: 'BL-2026-001', nameKhmer: 'សុខ មករា', fullName: 'Sok Makara', gender: 'ប្រុស', phone: '012 345 678', studyType: 'Part-Time', shift: 'Evening', classroomId: 25),
    StudentModel(id: 2, studentCode: 'BL-2026-002', nameKhmer: 'ចាន់ ធារី', fullName: 'Chan Theary', gender: 'ស្រី', phone: '098 765 432', studyType: 'Part-Time', shift: 'Evening', classroomId: 25),
    StudentModel(id: 3, studentCode: 'BL-2026-003', nameKhmer: 'រ៉េត ពិសិដ្ឋ', fullName: 'Reth Piseth', gender: 'ប្រុស', phone: '088 112 233', studyType: 'Part-Time', shift: 'Evening', classroomId: 24),
    StudentModel(id: 4, studentCode: 'BL-2026-004', nameKhmer: 'វ៉ាន់ ស្រីម៉ៅ', fullName: 'Vann Sreymao', gender: 'ស្រី', phone: '097 554 433', studyType: 'Part-Time', shift: 'Evening', classroomId: 23),
    StudentModel(id: 5, studentCode: 'BL-2026-005', nameKhmer: 'គឹម សីហា', fullName: 'Kim Seyha', gender: 'ប្រុស', phone: '077 889 900', studyType: 'Full-Time', shift: 'Morning', classroomId: 1),
    StudentModel(id: 6, studentCode: 'BL-2026-006', nameKhmer: 'អ៊ុំ ម៉ាលី', fullName: 'Oum Maly', gender: 'ស្រី', phone: '011 223 344', studyType: 'Full-Time', shift: 'Morning', classroomId: 1),
    StudentModel(id: 7, studentCode: 'BL-2026-007', nameKhmer: 'ហេង វីរៈ', fullName: 'Heng Virak', gender: 'ប្រុស', phone: '015 667 788', studyType: 'Full-Time', shift: 'Morning', classroomId: 2),
  ];

  static List<TeacherModel> get demoTeachers => [
    TeacherModel(id: 1, userId: 1, teacherCode: 'T-1001', nameKhmer: 'វ៉ែន លាភហេង', fullName: 'VEN Leapheng', gender: 'Male', phone: '012 888 999', email: 'leapheng@brightlight.edu.kh', roleTitle: 'Academic Director', specializedSubject: 'Management'),
    TeacherModel(id: 2, userId: 2, teacherCode: 'T-1002', nameKhmer: 'ទូច ស្រីមុំ', fullName: 'Tous Sreymom', gender: 'Female', phone: '098 111 222', email: 'sreymom@brightlight.edu.kh', specializedSubject: 'Going Place 3'),
    TeacherModel(id: 3, userId: 3, teacherCode: 'T-1003', nameKhmer: 'ភី ស្រីនុច', fullName: 'Phi Sreynuch', gender: 'Female', phone: '088 333 444', email: 'sreynuch@brightlight.edu.kh', specializedSubject: 'EFL 5A'),
    TeacherModel(id: 4, userId: 4, teacherCode: 'T-1004', nameKhmer: 'រី ស្រីនាង', fullName: 'Ry Sreyneang', gender: 'Female', phone: '097 555 666', email: 'sreyneang@brightlight.edu.kh', specializedSubject: 'EFL 3B'),
    TeacherModel(id: 5, userId: 5, teacherCode: 'T-1005', nameKhmer: 'សុផាន់ ម៉ៃ', fullName: 'Sophann May', gender: 'Male', phone: '077 777 888', email: 'sophann@brightlight.edu.kh', specializedSubject: 'Four Corners 2B'),
    TeacherModel(id: 6, userId: 6, teacherCode: 'T-1006', nameKhmer: 'ប៉ែន រីណា', fullName: 'Pen Rina', gender: 'Female', phone: '096 999 888', email: 'rina@brightlight.edu.kh', specializedSubject: 'EFL 3B'),
  ];

  static Map<String, dynamic> get demoStats => {
    'success': true,
    'total_students': 125,
    'total_teachers': 18,
    'total_classrooms': 8,
    'present_today': 118,
    'absent_today': 7,
    'attendance_rate': 94.4,
    'total_revenue': 4850.0,
    'monthly_revenue': 4850.0,
    'unpaid_invoices': 5,
  };

  static Map<String, dynamic> get demoTrends => {
    'success': true,
    'data': [
      {'day': 'ចន្ទ', 'present': 120, 'absent': 5, 'rate': 96.0},
      {'day': 'អង្គារ', 'present': 118, 'absent': 7, 'rate': 94.4},
      {'day': 'ពុធ', 'present': 122, 'absent': 3, 'rate': 97.6},
      {'day': 'ព្រហស្បតិ៍', 'present': 117, 'absent': 8, 'rate': 93.6},
      {'day': 'សុក្រ', 'present': 119, 'absent': 6, 'rate': 95.2},
    ],
  };

  static Map<String, dynamic> get demoRecentActivity => {
    'success': true,
    'activities': [
      {'id': 1, 'code': 'BL-2026-001', 'name': 'សុខ មករា', 'type': 'student', 'status': 'Present', 'time': '07:25 AM', 'class': 'O5'},
      {'id': 2, 'code': 'BL-2026-002', 'name': 'ចាន់ ធារី', 'type': 'student', 'status': 'Present', 'time': '07:28 AM', 'class': 'O5'},
      {'id': 3, 'code': 'T-1001', 'name': 'វ៉ែន លាភហេង', 'type': 'teacher', 'status': 'Present', 'time': '07:15 AM', 'role': 'Director'},
      {'id': 4, 'code': 'BL-2026-003', 'name': 'រ៉េត ពិសិដ្ឋ', 'type': 'student', 'status': 'Late', 'time': '07:40 AM', 'class': 'O2'},
      {'id': 5, 'code': 'T-1002', 'name': 'ទូច ស្រីមុំ', 'type': 'teacher', 'status': 'Present', 'time': '07:20 AM', 'role': 'Teacher'},
    ],
  };

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };

  static dynamic _safeJsonDecode(http.Response res) {
    final text = utf8.decode(res.bodyBytes, allowMalformed: true).trim();
    if (text.startsWith('<!DOCTYPE') ||
        text.startsWith('<html') ||
        text.startsWith('<?xml') ||
        text.startsWith('<head')) {
      throw const FormatException(
        'Server ឆ្លើយតបជាទម្រង់ HTML Web Page ជំនួសឱ្យ JSON API data។\n'
        'មូលហេតុ៖ Backend Server មិនទាន់ដំណើរការ ឬ Web App កំពុងភ្ជាប់ទៅកាន់ Firebase Static Hosting ដោយគ្មាន Backend Proxy។\n\n'
        'ដំណោះស្រាយ៖\n'
        '1. ប្រសិនបើតេស្តលើកុំព្យូទ័រផ្ទាល់ សូមបើកតាម: https://bls-backend.onrender.com/app\n'
        '2. ឬបើក Backend Server ដោយវាយ: cd backend; node server.js\n'
        '3. ឬកំណត់ Cloud API URL តាមរយៈប៊ូតុង Server ⚙️ ខាងក្រោម។',
      );
    }
    return jsonDecode(text);
  }

  /// Centralized HTTP Request handler with Automatic Retry (2 attempts) & Cache-Busting
  static Future<Map<String, dynamic>> _requestWithRetry(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    int maxRetries = 2,
  }) async {
    int attempts = 0;
    while (attempts <= maxRetries) {
      attempts++;
      try {
        final headers = _headers;
        http.Response res;

        if (method == 'POST') {
          final uri = Uri.parse('$baseUrl$endpoint');
          res = await http
              .post(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
              .timeout(const Duration(seconds: 30));
        } else if (method == 'PUT') {
          final uri = Uri.parse('$baseUrl$endpoint');
          res = await http
              .put(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
              .timeout(const Duration(seconds: 30));
        } else if (method == 'DELETE') {
          final uri = Uri.parse('$baseUrl$endpoint');
          res = await http
              .delete(uri, headers: headers)
              .timeout(const Duration(seconds: 30));
        } else {
          // Automatic cache-busting timestamp for GET
          final sep = endpoint.contains('?') ? '&' : '?';
          final uri = Uri.parse('$baseUrl$endpoint${sep}_t=${DateTime.now().millisecondsSinceEpoch}');
          res = await http
              .get(uri, headers: const {'Accept': 'application/json'})
              .timeout(const Duration(seconds: 30));
        }

        final data = _safeJsonDecode(res);
        if (data is Map<String, dynamic>) {
          ApiConfig.isDemoMode = false;
          return data;
        }
        return {'success': false, 'error': 'Invalid response format'};
      } catch (e) {
        if (attempts > maxRetries) {
          debugPrint('$method $endpoint failed after $attempts attempts: $e');
          break;
        }
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    }

    // Fallback for GET in demo or offline mode
    if (method == 'GET') {
      if (endpoint.contains('/dashboard/stats')) return demoStats;
      if (endpoint.contains('/dashboard/attendance-trends')) return demoTrends;
      if (endpoint.contains('/dashboard/recent-activity') || endpoint.contains('/attendance/recent')) return demoRecentActivity;
      if (endpoint.contains('/classrooms')) return {'success': true, 'data': demoClassrooms.map((c) => c.toJson()).toList()};
      if (endpoint.contains('/students')) return {'success': true, 'data': demoStudents.map((s) => s.toJson()).toList()};
      if (endpoint.contains('/teachers')) return {'success': true, 'data': demoTeachers.map((t) => t.toJson()).toList()};
    }
    return {'success': false, 'error': 'មិនអាចភ្ជាប់ទៅកាន់ Server បានទេ'};
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    return _requestWithRetry('GET', endpoint);
  }

  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    return _requestWithRetry('POST', endpoint, body: body);
  }

  static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> body) async {
    return _requestWithRetry('PUT', endpoint, body: body);
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    return _requestWithRetry('DELETE', endpoint);
  }

  // Dashboard
  static Future<Map<String, dynamic>> getDashboardStats() async {
    return get('/dashboard/stats?_t=${DateTime.now().millisecondsSinceEpoch}');
  }

  static Future<Map<String, dynamic>> getDashboardTrends() async {
    return get('/dashboard/attendance-trends?_t=${DateTime.now().millisecondsSinceEpoch}');
  }

  static Future<Map<String, dynamic>> getRecentActivity() async {
    return get('/dashboard/recent-activity?_t=${DateTime.now().millisecondsSinceEpoch}');
  }

  // Auth
  static Future<Map<String, dynamic>> login(
    Map<String, dynamic> payload,
  ) async {
    final role = payload['role']?.toString() ?? 'Admin';
    final email = (payload['email'] ?? '').toString().trim().toLowerCase();
    final pass = (payload['password'] ?? '').toString().trim();
    final teacherCode = (payload['teacher_id_code'] ?? '').toString().trim();

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: _headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 8));
      final data = _safeJsonDecode(res);
      if (data is Map<String, dynamic> && data['success'] == true) {
        return data;
      }
    } catch (e) {
      debugPrint('Live login server failed: $e. Checking Demo Fallback...');
    }

    // 🌟 DEMO DATA FALLBACK WHEN SERVER IS OFFLINE
    if (role == 'Admin' &&
        (pass == '1202' ||
            email == 'admin@brightlight.edu.kh' ||
            email == 'admin@school.com' ||
            email.contains('admin'))) {
      ApiConfig.isDemoMode = true;
      return {
        'success': true,
        'role': 'Admin',
        'isDemo': true,
        'user': {
          'id': 1,
          'name': 'អ្នកគ្រប់គ្រងប្រព័ន្ធ (Admin)',
          'email': email.isNotEmpty ? email : 'admin@brightlight.edu.kh',
          'role': 'Admin',
          'permissions': {
            'overview': true,
            'students': true,
            'teachers': true,
            'classrooms': true,
            'attendance': true,
            'grades': true,
            'finance': true,
            'idcards': true,
            'schedule': true,
            'ai': true,
            'reports': true,
          },
        },
        'assignedClasses': demoClassrooms.map((c) => c.toJson()).toList(),
      };
    }

    // User / Teacher Fallback
    if (role != 'Admin' && teacherCode.isNotEmpty) {
      ApiConfig.isDemoMode = true;
      return {
        'success': true,
        'role': 'User',
        'isDemo': true,
        'user': {
          'id': 2,
          'name': 'លោកគ្រូ / អ្នកគ្រូ ($teacherCode)',
          'email': 'teacher@brightlight.edu.kh',
          'role': 'Teacher',
        },
        'assignedClasses': demoClassrooms.map((c) => c.toJson()).toList(),
      };
    }

    return {
      'success': false,
      'error': 'លេខសម្ងាត់ ឬគណនីមិនត្រឹមត្រូវ! (Admin: 1202)'
    };
  }

  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String role,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        }),
      );
      return jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true));
    } catch (e) {
      return {'success': false, 'error': 'Connection Error: $e'};
    }
  }

  // Classrooms
  static Future<List<ClassroomModel>> getClassrooms() async {
    if (ApiConfig.isDemoMode) return demoClassrooms;
    try {
      final res = await http.get(Uri.parse('$baseUrl/classrooms')).timeout(const Duration(seconds: 4));
      final data = jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true));
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((e) => ClassroomModel.fromJson(e))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching classrooms: $e. Using Demo fallback.');
      ApiConfig.isDemoMode = true;
    }
    return demoClassrooms;
  }

  static Future<bool> addClassroom(Map<String, dynamic> body) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/classrooms'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return jsonDecode(
            utf8.decode(res.bodyBytes, allowMalformed: true),
          )['success'] ==
          true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateClassroom(int id, Map<String, dynamic> body) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/classrooms/$id'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return jsonDecode(
            utf8.decode(res.bodyBytes, allowMalformed: true),
          )['success'] ==
          true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteClassroom(int id) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/classrooms/$id'),
        headers: _headers,
      );
      return jsonDecode(
            utf8.decode(res.bodyBytes, allowMalformed: true),
          )['success'] ==
          true;
    } catch (e) {
      return false;
    }
  }

  // Students
  static Future<List<StudentModel>> getStudents({int? classroomId}) async {
    if (ApiConfig.isDemoMode) {
      if (classroomId != null) {
        return demoStudents.where((s) => s.classroomId == classroomId).toList();
      }
      return demoStudents;
    }
    try {
      String url =
          '$baseUrl/students?_t=${DateTime.now().millisecondsSinceEpoch}';
      if (classroomId != null) url += '&classroom_id=$classroomId';

      final res = await http.get(
        Uri.parse(url),
        headers: {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'},
      ).timeout(const Duration(seconds: 4));
      final data = jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true));
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((e) => StudentModel.fromJson(e))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching students: $e. Using Demo fallback.');
      ApiConfig.isDemoMode = true;
    }
    if (classroomId != null) {
      return demoStudents.where((s) => s.classroomId == classroomId).toList();
    }
    return demoStudents;
  }

  static Future<bool> addStudent(Map<String, dynamic> body) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/students'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return jsonDecode(
            utf8.decode(res.bodyBytes, allowMalformed: true),
          )['success'] ==
          true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateStudent(int id, Map<String, dynamic> body) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/students/$id'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return jsonDecode(
            utf8.decode(res.bodyBytes, allowMalformed: true),
          )['success'] ==
          true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteStudent(int id) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/students/$id'),
        headers: _headers,
      );
      return jsonDecode(
            utf8.decode(res.bodyBytes, allowMalformed: true),
          )['success'] ==
          true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteAllStudents() async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/students'),
        headers: _headers,
      );
      return jsonDecode(
            utf8.decode(res.bodyBytes, allowMalformed: true),
          )['success'] ==
          true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> importStudentsBulk(
    List<Map<String, dynamic>> students,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/students/bulk'),
        headers: _headers,
        body: jsonEncode({'students': students}),
      );
      return jsonDecode(
            utf8.decode(res.bodyBytes, allowMalformed: true),
          )['success'] ==
          true;
    } catch (e) {
      return false;
    }
  }

  // Teachers
  static Future<List<TeacherModel>> getTeachers() async {
    if (ApiConfig.isDemoMode) return demoTeachers;
    try {
      String url =
          '$baseUrl/teachers?_t=${DateTime.now().millisecondsSinceEpoch}';
      final res = await http.get(
        Uri.parse(url),
        headers: {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'},
      ).timeout(const Duration(seconds: 4));
      final data = jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true));
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((e) => TeacherModel.fromJson(e))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching teachers: $e. Using Demo fallback.');
      ApiConfig.isDemoMode = true;
    }
    return demoTeachers;
  }

  static Future<bool> addTeacher(Map<String, dynamic> body) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/teachers'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return jsonDecode(
            utf8.decode(res.bodyBytes, allowMalformed: true),
          )['success'] ==
          true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateTeacher(int id, Map<String, dynamic> body) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/teachers/$id'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return jsonDecode(
            utf8.decode(res.bodyBytes, allowMalformed: true),
          )['success'] ==
          true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteTeacher(int id) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/teachers/$id'),
        headers: _headers,
      );
      return jsonDecode(
            utf8.decode(res.bodyBytes, allowMalformed: true),
          )['success'] ==
          true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteAllTeachers() async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/teachers'),
        headers: _headers,
      );
      return jsonDecode(
            utf8.decode(res.bodyBytes, allowMalformed: true),
          )['success'] ==
          true;
    } catch (e) {
      return false;
    }
  }

  // Attendance
  static Future<Map<String, dynamic>> scanAttendance(
    String code,
    int classroomId,
    int userId,
    String status,
    String shift,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/attendance/scan'),
        headers: _headers,
        body: jsonEncode({
          'student_code': code,
          'classroom_id': classroomId,
          'scanned_by': userId,
          'status': status,
          'shift': shift,
        }),
      );
      return jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true));
    } catch (e) {
      return {'success': false, 'message': 'Connection Error: $e'};
    }
  }

  static Future<List<dynamic>> getRecentAttendance({int? classroomId}) async {
    if (ApiConfig.isDemoMode) {
      return (demoRecentActivity['activities'] as List? ?? []);
    }
    final t = DateTime.now().millisecondsSinceEpoch;
    try {
      final param = classroomId != null ? '&classroom_id=$classroomId' : '';
      final res = await http.get(Uri.parse('$baseUrl/attendance/recent?_t=$t$param')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true));
        if (data['success'] == true && data['data'] is List && (data['data'] as List).isNotEmpty) {
          return data['data'];
        }
      }
    } catch (_) {
      ApiConfig.isDemoMode = true;
    }

    // Resilient fallback to recent-activity endpoint
    try {
      final res = await http.get(Uri.parse('$baseUrl/dashboard/recent-activity?_t=$t')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true));
        final list = (data['data'] ?? data['activities'] ?? []) as List;
        return list;
      }
    } catch (_) {
      ApiConfig.isDemoMode = true;
    }

    return (demoRecentActivity['activities'] as List? ?? []);
  }

  static Future<List<dynamic>> getClassroomAttendance(int classroomId) async {
    if (ApiConfig.isDemoMode) {
      final students = demoStudents.where((s) => s.classroomId == classroomId).toList();
      return students.map((s) => {
        'student_id': s.id,
        'student_code': s.studentCode,
        'name_khmer': s.nameKhmer,
        'full_name': s.fullName,
        'gender': s.gender,
        'status': 'Present',
        'scanned_at': '07:30 AM',
      }).toList();
    }
    final t = DateTime.now().millisecondsSinceEpoch;
    try {
      final res = await http.get(Uri.parse('$baseUrl/attendance/classroom/$classroomId?_t=$t')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true));
        if (data['success'] == true && data['data'] is List && (data['data'] as List).isNotEmpty) {
          return data['data'];
        }
      }
    } catch (_) {
      ApiConfig.isDemoMode = true;
    }

    // Resilient fallback: combine students for this class with today's recent activity
    try {
      final studentsRes = await http.get(Uri.parse('$baseUrl/students?_t=$t'));
      final recentRes = await http.get(Uri.parse('$baseUrl/dashboard/recent-activity?_t=$t'));
      if (studentsRes.statusCode == 200) {
        final sData = jsonDecode(utf8.decode(studentsRes.bodyBytes, allowMalformed: true));
        final List allStudents = sData['data'] ?? [];
        final classStudents = allStudents.where((s) {
          final cId = s['classroom_id'] is int ? s['classroom_id'] : int.tryParse(s['classroom_id'].toString());
          return cId == classroomId;
        }).toList();

        List recents = [];
        if (recentRes.statusCode == 200) {
          final rData = jsonDecode(utf8.decode(recentRes.bodyBytes, allowMalformed: true));
          recents = (rData['data'] ?? rData['activities'] ?? []) as List;
        }

        return classStudents.map((s) {
          final code = (s['student_code'] ?? '').toString();
          dynamic matchingScan;
          for (final r in recents) {
            if ((r['code'] ?? r['student_code'] ?? '').toString() == code) {
              matchingScan = r;
              break;
            }
          }
          return {
            'id': s['id'],
            'student_code': s['student_code'],
            'name_kh': s['name_kh'],
            'name_en': s['name_en'],
            'gender': s['gender'],
            'photo_url': s['photo_url'],
            'status': matchingScan != null ? (matchingScan['status'] ?? 'Present') : 'Not Scanned',
            'time': matchingScan != null ? (matchingScan['time'] ?? '') : null,
            'shift': matchingScan != null ? matchingScan['shift'] : s['shift'],
          };
        }).toList();
      }
    } catch (_) {}

    return [];
  }

  static Future<List<dynamic>> getAttendanceTrend() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/attendance/trend'));
      final data = jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true));
      return data['success'] == true ? data['data'] : [];
    } catch (e) {
      return [];
    }
  }

  // Grades
  static Future<List<dynamic>> getGrades(int classroomId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/grades/$classroomId'));
      final data = jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true));
      return data['success'] == true ? data['data'] : [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> addGrade(Map<String, dynamic> body) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/grades'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return jsonDecode(
            utf8.decode(res.bodyBytes, allowMalformed: true),
          )['success'] ==
          true;
    } catch (e) {
      return false;
    }
  }

  // Finance
  static Future<bool> payStudent(Map<String, dynamic> body) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/finance/student-payments'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return jsonDecode(
            utf8.decode(res.bodyBytes, allowMalformed: true),
          )['success'] ==
          true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> payTeacher(Map<String, dynamic> body) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/finance/teacher-salaries'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return jsonDecode(
            utf8.decode(res.bodyBytes, allowMalformed: true),
          )['success'] ==
          true;
    } catch (e) {
      return false;
    }
  }

  // AI Assistant
  static Future<String> askAi(String prompt) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/ai/ask'),
        headers: _headers,
        body: jsonEncode({'prompt': prompt}),
      );
      return jsonDecode(
            utf8.decode(res.bodyBytes, allowMalformed: true),
          )['reply'] ??
          'គ្មានការឆ្លើយតប';
    } catch (e) {
      return 'Connection Error: $e';
    }
  }

  // Payment Verification (Cashier / Accountant)
  static Future<Map<String, dynamic>> verifyPaymentSlip({
    required int invoiceId,
    required String action, // 'APPROVE' or 'REJECT'
    String? rejectionReason,
    int? verifiedBy,
  }) async {
    try {
      final payload = <String, dynamic>{'action': action};
      if (rejectionReason != null) payload['rejectionReason'] = rejectionReason;
      if (verifiedBy != null) payload['verifiedBy'] = verifiedBy;

      final res = await http.patch(
        Uri.parse('$baseUrl/payments/verify/$invoiceId'),
        headers: _headers,
        body: jsonEncode(payload),
      );
      return jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true));
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Upload Payment Slip (Multipart Form Data)
  static Future<Map<String, dynamic>> uploadPaymentSlip({
    required int invoiceId,
    required Uint8List bytes,
    String filename = 'slip.jpg',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/payments/upload-slip/$invoiceId');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        http.MultipartFile.fromBytes('slipImage', bytes, filename: filename),
      );
      final streamedResponse = await request.send();
      final res = await http.Response.fromStream(streamedResponse);
      return jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true));
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get Invoices for Cashier Dashboard (with counters, filters & pagination)
  static Future<Map<String, dynamic>> getCashierInvoices({
    String? status,
    String? month,
    dynamic classId,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null && status.isNotEmpty) 'status': status,
        if (month != null && month.isNotEmpty) 'month': month,
        if (classId != null) 'classId': classId.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };
      final uri = Uri.parse('$baseUrl/cashier/invoices').replace(queryParameters: queryParams);
      final res = await http.get(uri, headers: _headers);
      return jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true));
    } catch (e) {
      return {'success': false, 'error': e.toString(), 'data': []};
    }
  }

  // Direct Invoice PDF URL
  static String getInvoicePdfUrl(dynamic invoiceId) {
    return '$baseUrl/invoices/$invoiceId/download-pdf';
  }

  // Grade Ranking & Transcript APIs
  static Future<Map<String, dynamic>> calculateRanking({
    dynamic classroomId,
    String? monthName,
    bool saveToDb = true,
  }) async {
    try {
      final payload = <String, dynamic>{'save_to_db': saveToDb};
      if (classroomId != null) payload['classroom_id'] = classroomId;
      if (monthName != null) payload['month_name'] = monthName;

      final res = await http.post(
        Uri.parse('$baseUrl/grades/calculate-ranking'),
        headers: _headers,
        body: jsonEncode(payload),
      );
      return jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true));
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getMonthlyRanking({
    dynamic classroomId,
    String? monthName,
  }) async {
    try {
      final queryParams = <String, String>{
        if (classroomId != null) 'classroom_id': classroomId.toString(),
        if (monthName != null && monthName.isNotEmpty) 'month_name': monthName,
      };
      final uri = Uri.parse('$baseUrl/grades/monthly-ranking').replace(queryParameters: queryParams);
      final res = await http.get(uri, headers: _headers);
      return jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true));
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getStudentTranscript(
    dynamic studentId, {
    String? monthName,
  }) async {
    try {
      final queryParams = <String, String>{
        if (monthName != null && monthName.isNotEmpty) 'month_name': monthName,
      };
      final uri = Uri.parse('$baseUrl/grades/student-transcript/$studentId').replace(queryParameters: queryParams);
      final res = await http.get(uri, headers: _headers);
      return jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true));
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Admin Dashboard Metrics
  static Future<Map<String, dynamic>> getAdminDashboardMetrics() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/admin/dashboard-metrics'),
        headers: _headers,
      );
      return jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true));
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
