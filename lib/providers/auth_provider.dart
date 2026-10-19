import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/classroom_model.dart';
import '../services/api_service.dart';

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
      _errorMessage = 'មានបញ្ហាប្រព័ន្ធកំឡុងពេលចូលគណនី: $e';
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
