import 'subject_model.dart';

class TeacherModel {
  final String id;
  final String profileId;
  final String teacherCode;
  final String name;
  final String email;
  final String status; // ACTIVE, INACTIVE, DELETED
  final List<String> subjectIds;
  final List<SubjectModel> subjects;

  const TeacherModel({
    required this.id,
    required this.profileId,
    required this.teacherCode,
    required this.name,
    this.email = '',
    this.status = 'ACTIVE',
    this.subjectIds = const [],
    this.subjects = const [],
  });

  bool get isActive => status.toUpperCase() == 'ACTIVE';
  bool get isDeleted => status.toUpperCase() == 'DELETED';
  bool get isInactive => status.toUpperCase() == 'INACTIVE';

  factory TeacherModel.fromJson(
    Map<String, dynamic> json, {
    String email = '',
  }) {
    final rawSubjectIds = json['subject_ids'];
    final List<String> ids = [];
    if (rawSubjectIds is List) {
      for (var item in rawSubjectIds) {
        if (item != null) ids.add(item.toString());
      }
    }

    return TeacherModel(
      id: json['id'] as String? ?? '',
      profileId: json['profile_id'] as String? ?? '',
      teacherCode: json['teacher_code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: email,
      status: json['status'] as String? ?? 'ACTIVE',
      subjectIds: ids,
    );
  }

  TeacherModel copyWith({
    String? id,
    String? profileId,
    String? teacherCode,
    String? name,
    String? email,
    String? status,
    List<String>? subjectIds,
    List<SubjectModel>? subjects,
  }) {
    return TeacherModel(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      teacherCode: teacherCode ?? this.teacherCode,
      name: name ?? this.name,
      email: email ?? this.email,
      status: status ?? this.status,
      subjectIds: subjectIds ?? this.subjectIds,
      subjects: subjects ?? this.subjects,
    );
  }
}
