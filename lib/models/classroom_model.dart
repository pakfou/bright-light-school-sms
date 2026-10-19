class ClassroomModel {
  final int id;
  final String className;
  final String levelType;
  final String shift;
  final String subject;

  ClassroomModel({
    required this.id,
    required this.className,
    required this.levelType,
    required this.shift,
    required this.subject,
  });

  factory ClassroomModel.fromJson(Map<String, dynamic> json) {
    return ClassroomModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      className: json['class_name'] ?? '',
      levelType: json['level_type'] ?? '',
      shift: json['shift'] ?? '',
      subject: json['subject'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class_name': className,
      'level_type': levelType,
      'shift': shift,
      'subject': subject,
    };
  }

  ClassroomModel copyWith({
    int? id,
    String? className,
    String? levelType,
    String? shift,
    String? subject,
  }) {
    return ClassroomModel(
      id: id ?? this.id,
      className: className ?? this.className,
      levelType: levelType ?? this.levelType,
      shift: shift ?? this.shift,
      subject: subject ?? this.subject,
    );
  }
}
