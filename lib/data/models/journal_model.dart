class JournalModel {
  final String? id;
  final String sessionId;
  final String teachingMaterial;
  final String? notes;
  final DateTime? createdAt;

  const JournalModel({
    this.id,
    required this.sessionId,
    required this.teachingMaterial,
    this.notes,
    this.createdAt,
  });

  factory JournalModel.fromJson(Map<String, dynamic> json) {
    return JournalModel(
      id: json['id'] as String?,
      sessionId: json['session_id'] as String? ?? '',
      teachingMaterial:
          json['teaching_material'] as String? ??
          (json['material'] as String? ?? ''),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'teaching_material': teachingMaterial,
    if (notes != null) 'notes': notes,
  };
}
