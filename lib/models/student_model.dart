class StudentModel {
  final int id;
  final String studentCode;
  final String nameKhmer;
  final String fullName;
  final String gender;
  final String phone;
  final String studyType;
  final String shift;
  final String dob;
  final String pob;
  final String parentName;
  final int classroomId;
  final String? photoUrl;

  StudentModel({
    required this.id,
    required this.studentCode,
    required this.nameKhmer,
    required this.fullName,
    required this.gender,
    required this.phone,
    required this.studyType,
    required this.shift,
    this.dob = '',
    this.pob = '',
    this.parentName = '',
    this.classroomId = 0,
    this.photoUrl,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      studentCode: json['student_code']?.toString() ?? '',
      nameKhmer: json['name_khmer'] ?? json['name_kh'] ?? '',
      fullName: json['full_name'] ?? json['name_en'] ?? '',
      gender: json['gender'] ?? '',
      phone: json['phone'] ?? json['parent_phone'] ?? '',
      studyType: json['study_type'] ?? '',
      shift: json['shift'] ?? '',
      dob: json['dob'] ?? json['date_of_birth'] ?? '',
      pob: json['pob'] ?? json['place_of_birth'] ?? '',
      parentName: json['parent_name'] ?? '',
      classroomId: int.tryParse(json['classroom_id']?.toString() ?? '0') ?? 0,
      photoUrl: json['photo_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_code': studentCode,
      'name_kh': nameKhmer,
      'name_en': fullName,
      'gender': gender,
      'parent_phone': phone,
      'study_type': studyType,
      'shift': shift,
      'dob': dob,
      'pob': pob,
      'parent_name': parentName,
      'classroom_id': classroomId,
      'photo_url': photoUrl,
    };
  }

  StudentModel copyWith({
    int? id,
    String? studentCode,
    String? nameKhmer,
    String? fullName,
    String? gender,
    String? phone,
    String? studyType,
    String? shift,
    String? dob,
    String? pob,
    String? parentName,
    int? classroomId,
    String? photoUrl,
  }) {
    return StudentModel(
      id: id ?? this.id,
      studentCode: studentCode ?? this.studentCode,
      nameKhmer: nameKhmer ?? this.nameKhmer,
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      studyType: studyType ?? this.studyType,
      shift: shift ?? this.shift,
      dob: dob ?? this.dob,
      pob: pob ?? this.pob,
      parentName: parentName ?? this.parentName,
      classroomId: classroomId ?? this.classroomId,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
