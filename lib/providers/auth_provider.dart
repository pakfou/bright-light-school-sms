import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/classroom_model.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  List<ClassroomModel> _assignedClasses = [];
  ClassroomModel? _selectedClass;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  List<ClassroomModel> get assignedClasses => _assignedClasses;
  ClassroomModel? get selectedClass => _selectedClass;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.role.toLowerCase() == 'admin';
  bool get isTeacher =>
      _currentUser?.role.toLowerCase() == 'teacher' ||
      _currentUser?.role.toLowerCase() == 'user';
  bool get canScanAttendance => _currentUser?.canScanAttendance ?? false;
  bool get canEnterGrades => _currentUser?.canEnterGrades ?? false;
  bool get canViewOverview => _currentUser?.canViewOverview ?? false;

  void selectClass(ClassroomModel classroom) {
    if (_assignedClasses.contains(classroom)) {
      _selectedClass = classroom;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Instant Demo Admin login fallback
  Future<bool> loginDemoAdmin() async {
    ApiConfig.isDemoMode = true;
    final demoAdmin = {
      'id': 1,
      'name': 'អ្នកគ្រប់គ្រងប្រព័ន្ធ (Admin Demo)',
      'email': 'admin@brightlight.edu.kh',
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
    };
    _currentUser = UserModel.fromJson(demoAdmin);
    _assignedClasses = ApiService.demoClassrooms;
    if (_assignedClasses.isNotEmpty) {
      _selectedClass = _assignedClasses.first;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(demoAdmin));
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  Future<bool> login(Map<String, dynamic> payload) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.login(payload);

      if (res['success'] == true && res['user'] != null) {
        final userMap = Map<String, dynamic>.from(res['user']);
        if (res['permissions'] != null && userMap['permissions'] == null) {
          userMap['permissions'] = res['permissions'];
        }
        _currentUser = UserModel.fromJson(userMap);

        if (res['assignedClasses'] != null) {
          _assignedClasses = (res['assignedClasses'] as List)
              .map((c) => ClassroomModel.fromJson(c))
              .toList();

          if (_assignedClasses.isNotEmpty) {
            _selectedClass = _assignedClasses.first;
          }
        }

        final prefs = await SharedPreferences.getInstance();
        final userDataToSave = Map<String, dynamic>.from(res['user']);
        userDataToSave.remove('photo_url');
        await prefs.setString('user_data', jsonEncode(userDataToSave));

        return true;
      } else {
        _errorMessage =
            res['error'] ?? 'បរាជ័យក្នុងការចូលប្រើប្រាស់។ សូមពិនិត្យម្តងទៀត!';
        return false;
      }
    } catch (e) {
      final email = (payload['email'] ?? '').toString().trim().toLowerCase();
      final pass = (payload['password'] ?? '').toString().trim();
      final role = (payload['role'] ?? '').toString();

      // Demo fallback when server is unreachable or offline
      if (role == 'Admin' &&
          (pass == '1202' ||
              pass == 'admin123' ||
              email == 'admin@brightlight.edu.kh' ||
              email.contains('admin'))) {
        ApiConfig.isDemoMode = true;
        final demoAdmin = {
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
        };
        _currentUser = UserModel.fromJson(demoAdmin);
        _assignedClasses = ApiService.demoClassrooms;
        if (_assignedClasses.isNotEmpty) {
          _selectedClass = _assignedClasses.first;
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(demoAdmin));
        return true;
      }

      final errStr = e.toString();
      if (errStr.contains('Connection refused') ||
          errStr.contains('Failed to connect') ||
          errStr.contains('ClientException') ||
          errStr.contains('SocketException')) {
        _errorMessage =
            '⚠️ មិនអាចតភ្ជាប់ទៅកាន់ Server បានទេ!\n\n'
            'មូលហេតុ៖ Cloud Backend (Render.com) កំពុង Spin Up ឬមិនទាន់ឆ្លើយតប។\n'
            'ដំណោះស្រាយ៖\n'
            '1. សូមរង់ចាំប្រហែល ៣០ វិនាទី រួចសាកល្បង Login ម្តងទៀត\n'
            '2. ឬចុចប៊ូតុង "⚡ ចូលមើលសាកល្បង Demo Admin" ខាងក្រោម ដើម្បីចូលប្រើភ្លាមៗ។';
      } else {
        _errorMessage = 'មានបញ្ហាប្រព័ន្ធកំឡុងពេលចូលគណនី: $e';
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _assignedClasses = [];
    _selectedClass = null;
    _errorMessage = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');

    notifyListeners();
  }
}
