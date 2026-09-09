class StudentModel {
  final String id;
  final String studentCode;
  final String name;
  final String gender;
  final String classId;

  const StudentModel({
    required this.id,
    required this.studentCode,
    required this.name,
    this.gender = 'L',
    this.classId = '',
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] as String? ?? '',
      studentCode: json['student_code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      gender: json['gender'] as String? ?? 'L',
      classId: json['class_id'] as String? ?? '',
    );
  }
}
