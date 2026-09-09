class ClassModel {
  final String id;
  final String name;
  final String grade;

  const ClassModel({required this.id, required this.name, this.grade = ''});

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      grade: (json['grade'] ?? json['grade_level'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'grade': grade};
}
