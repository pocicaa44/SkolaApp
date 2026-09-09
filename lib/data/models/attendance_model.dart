import 'package:flutter/material.dart';
import '../../app_theme.dart';

enum AttendanceStatus {
  present('present', 'Hadir', 'H', AppTheme.success, AppTheme.successSurface),
  permission('permission', 'Izin', 'I', AppTheme.info, AppTheme.infoSurface),
  sick('sick', 'Sakit', 'S', AppTheme.warning, AppTheme.warningSurface),
  absent('absent', 'Alpa', 'A', AppTheme.error, AppTheme.errorSurface);

  final String dbCode;
  final String label;
  final String shortCode;
  final Color color;
  final Color surfaceColor;

  const AttendanceStatus(
    this.dbCode,
    this.label,
    this.shortCode,
    this.color,
    this.surfaceColor,
  );

  static AttendanceStatus? fromDb(String? code) {
    if (code == null) return null;
    for (var s in AttendanceStatus.values) {
      if (s.dbCode == code.toLowerCase()) return s;
    }
    return null;
  }
}

class AttendanceModel {
  final String id;
  final String sessionId;
  final String studentId;
  final AttendanceStatus status;
  final String? notes;

  const AttendanceModel({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.status,
    this.notes,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as String? ?? '',
      sessionId: json['session_id'] as String? ?? '',
      studentId: json['student_id'] as String? ?? '',
      status:
          AttendanceStatus.fromDb(json['status'] as String?) ??
          AttendanceStatus.present,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'student_id': studentId,
    'status': status.dbCode,
    if (notes != null) 'notes': notes,
  };
}
