import 'package:flutter/material.dart';
import '../models/classroom_model.dart';
// ignore: unused_import
import '../services/api_service.dart';

class ClassroomProvider extends ChangeNotifier {
  List<ClassroomModel> _classrooms = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ClassroomModel> get classrooms => _classrooms;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchClassrooms() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await ApiService.getClassrooms();
      _classrooms = data;
    } catch (e) {
      _errorMessage = 'បរាជ័យក្នុងការទាញយកទិន្នន័យថ្នាក់រៀន: $e';
      _classrooms = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
