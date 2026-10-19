class TeacherModel {
  final int id;
  final int userId;
  final String teacherCode;
  final String nameKhmer;
  final String fullName;
  final String gender;
  final String dob;
  final String phone;
  final String email;
  final String roleTitle;
  final String specializedSubject;
  final double baseSalary;
  final String photoUrl;
  final String status;
  final String hireDate;

  TeacherModel({
    required this.id,
    required this.userId,
    required this.teacherCode,
    required this.nameKhmer,
    required this.fullName,
    required this.gender,
    this.dob = '',
    required this.phone,
    required this.email,
    this.roleTitle = 'Teacher',
    this.specializedSubject = '',
    this.baseSalary = 0.0,
    this.photoUrl = 'default.png',
    this.status = 'Active',
    this.hireDate = '',
  });

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    return TeacherModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: int.tryParse(json['user_id']?.toString() ?? json['id']?.toString() ?? '0') ?? 0,
      teacherCode: json['teacher_code']?.toString() ?? '',
      nameKhmer: json['name_kh'] ?? json['name'] ?? '',
      fullName: json['name_en'] ?? '',
      gender: json['gender'] ?? 'Male',
      dob: json['dob'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      roleTitle: json['role'] ?? json['role_title'] ?? 'Teacher',
      specializedSubject: json['subject'] ?? json['specialized_subject'] ?? '',
      baseSalary: (json['base_salary'] != null)
          ? double.tryParse(json['base_salary'].toString()) ?? 0.0
          : 0.0,
      photoUrl: json['photo_url'] ?? 'default.png',
      status: json['status'] ?? 'Active',
      hireDate: json['hire_date'] ?? json['joined_date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'teacher_code': teacherCode,
      'name_kh': nameKhmer,
      'name_en': fullName,
      'gender': gender,
      'dob': dob,
      'phone': phone,
      'email': email,
      'role_title': roleTitle,
      'specialized_subject': specializedSubject,
      'base_salary': baseSalary,
      'photo_url': photoUrl,
      'status': status,
      'hire_date': hireDate,
    };
  }

  TeacherModel copyWith({
    int? id,
    int? userId,
    String? teacherCode,
    String? nameKhmer,
    String? fullName,
    String? gender,
    String? dob,
    String? phone,
    String? email,
    String? roleTitle,
    String? specializedSubject,
    double? baseSalary,
    String? photoUrl,
    String? status,
    String? hireDate,
  }) {
    return TeacherModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      teacherCode: teacherCode ?? this.teacherCode,
      nameKhmer: nameKhmer ?? this.nameKhmer,
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      roleTitle: roleTitle ?? this.roleTitle,
      specializedSubject: specializedSubject ?? this.specializedSubject,
      baseSalary: baseSalary ?? this.baseSalary,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      hireDate: hireDate ?? this.hireDate,
    );
  }
}
