class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? photoUrl;
  final String? code;
  final List<String> permissions;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.photoUrl,
    this.code,
    this.permissions = const ['overview', 'attendance', 'grades'],
  });

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get canScanAttendance => isAdmin || permissions.contains('attendance') || permissions.contains('*');
  bool get canEnterGrades => isAdmin || permissions.contains('grades') || permissions.contains('*');
  bool get canViewOverview => isAdmin || permissions.contains('overview') || permissions.contains('*');

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final roleStr = json['role'] ?? '';
    final isAdminRole = roleStr.toString().toLowerCase() == 'admin';
    List<String> perms = [];
    if (json['permissions'] is List) {
      perms = List<String>.from(json['permissions']);
    } else if (isAdminRole) {
      perms = ['*'];
    } else {
      perms = ['overview', 'attendance', 'grades'];
    }

    return UserModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: roleStr,
      photoUrl: json['photo_url'] ?? json['photoUrl'],
      code: json['code'] ?? json['teacher_code'],
      permissions: perms,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'photo_url': photoUrl,
      'code': code,
      'permissions': permissions,
    };
  }

  UserModel copyWith({
    int? id, 
    String? name, 
    String? email, 
    String? role,
    String? photoUrl,
    String? code,
    List<String>? permissions,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      code: code ?? this.code,
      permissions: permissions ?? this.permissions,
    );
  }
}
