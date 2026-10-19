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

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
  };

  static Future<String?> uploadPhoto(Uint8List bytes, String filename) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
      request.files.add(
        http.MultipartFile.fromBytes('photo', bytes, filename: filename),
      );
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        var data = jsonDecode(
          utf8.decode(response.bodyBytes, allowMalformed: true),
        );
        if (data['success'] == true) return data['photoUrl'];
      }
    } catch (e) {
      debugPrint('Upload error: $e');
    }
    return null;
  }

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
        '1. ប្រសិនបើតេស្តលើកុំព្យូទ័រផ្ទាល់ សូមបើកតាម: http://localhost:5000/app\n'
        '2. ឬបើក Backend Server ដោយវាយ: cd backend; node server.js\n'
        '3. ឬកំណត់ Cloud API URL តាមរយៈប៊ូតុង Server ⚙️ ខាងក្រោម។',
      );
    }
    return jsonDecode(text);
  }

  // Generic helpers for legacy providers
  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl$endpoint'));
      final data = _safeJsonDecode(res);
      if (data is Map<String, dynamic>) return data;
      return {'success': false, 'error': 'Invalid response format'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(body),
      );
      final data = _safeJsonDecode(res);
      if (data is Map<String, dynamic>) return data;
      return {'success': false, 'error': 'Invalid response format'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
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
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: _headers,
        body: jsonEncode(payload),
      );
      final data = _safeJsonDecode(res);
      if (data is Map<String, dynamic>) return data;
      return {'success': false, 'error': 'Invalid response structure'};
    } catch (e) {
      return {'success': false, 'error': '$e'};
    }
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
    try {
      final res = await http.get(Uri.parse('$baseUrl/classrooms'));
      final data = jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true));
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((e) => ClassroomModel.fromJson(e))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching classrooms: $e');
    }
    return [];
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
    try {
      String url =
          '$baseUrl/students?_t=${DateTime.now().millisecondsSinceEpoch}';
      if (classroomId != null) url += '&classroom_id=$classroomId';

      final res = await http.get(
        Uri.parse(url),
        headers: {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'},
      );
      final data = jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true));
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((e) => StudentModel.fromJson(e))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching students: $e');
    }
    return [];
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
    try {
      String url =
          '$baseUrl/teachers?_t=${DateTime.now().millisecondsSinceEpoch}';
      final res = await http.get(
        Uri.parse(url),
        headers: {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'},
      );
      final data = jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true));
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((e) => TeacherModel.fromJson(e))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching teachers: $e');
    }
    return [];
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
    final t = DateTime.now().millisecondsSinceEpoch;
    try {
      final param = classroomId != null ? '&classroom_id=$classroomId' : '';
      final res = await http.get(Uri.parse('$baseUrl/attendance/recent?_t=$t$param'));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true));
        if (data['success'] == true && data['data'] is List && (data['data'] as List).isNotEmpty) {
          return data['data'];
        }
      }
    } catch (_) {}

    // Resilient fallback to recent-activity endpoint
    try {
      final res = await http.get(Uri.parse('$baseUrl/dashboard/recent-activity?_t=$t'));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true));
        final list = (data['data'] ?? data['activities'] ?? []) as List;
        return list;
      }
    } catch (_) {}

    return [];
  }

  static Future<List<dynamic>> getClassroomAttendance(int classroomId) async {
    final t = DateTime.now().millisecondsSinceEpoch;
    try {
      final res = await http.get(Uri.parse('$baseUrl/attendance/classroom/$classroomId?_t=$t'));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true));
        if (data['success'] == true && data['data'] is List && (data['data'] as List).isNotEmpty) {
          return data['data'];
        }
      }
    } catch (_) {}

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
}
