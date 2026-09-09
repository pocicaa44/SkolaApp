import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/teacher_model.dart';
import '../models/subject_model.dart';

class ProfileRepository {
  final SupabaseClient _supabase;

  ProfileRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  Future<TeacherModel?> getTeacherByProfileId(
    String profileId, {
    String email = '',
  }) async {
    final res = await _supabase
        .from('teachers')
        .select('id, profile_id, teacher_code, name, status, subject_ids')
        .eq('profile_id', profileId)
        .maybeSingle();

    if (res == null) return null;
    return TeacherModel.fromJson(res, email: email);
  }

  Future<void> updateProfile({
    required String profileId,
    required String name,
    required List<String> subjectIds,
  }) async {
    // 1. Update user metadata (full_name)
    await _supabase.auth.updateUser(UserAttributes(data: {'full_name': name}));

    // 2. Check if teacher record exists
    final teacherCheck = await _supabase
        .from('teachers')
        .select('id')
        .eq('profile_id', profileId)
        .maybeSingle();

    if (teacherCheck != null) {
      await _supabase
          .from('teachers')
          .update({'name': name, 'subject_ids': subjectIds})
          .eq('profile_id', profileId);
    } else {
      // Auto-generate teacher code if not exists
      final codeNum = DateTime.now().millisecondsSinceEpoch
          .toString()
          .substring(7);
      await _supabase.from('teachers').insert({
        'profile_id': profileId,
        'teacher_code': 'GUR-$codeNum',
        'name': name,
        'subject_ids': subjectIds,
        'status': 'ACTIVE',
      });
    }
  }

  Future<List<SubjectModel>> getSubjectsForTeacher(
    List<String> subjectIds,
  ) async {
    if (subjectIds.isEmpty) return [];
    final res = await _supabase
        .from('subjects')
        .select('id, name, code')
        .inFilter('id', subjectIds);

    return (res as List).map((j) => SubjectModel.fromJson(j)).toList();
  }
}
