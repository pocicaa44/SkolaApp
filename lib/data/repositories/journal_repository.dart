import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/journal_model.dart';

class JournalRepository {
  final SupabaseClient _supabase;

  JournalRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  Future<JournalModel?> getJournalForSession({
    required String scheduleId,
    required DateTime date,
  }) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    try {
      final res = await _supabase
          .from('journals')
          .select('id, session_id, teaching_material, notes, created_at')
          .eq('schedule_id', scheduleId)
          .eq('date', dateStr)
          .maybeSingle();

      if (res == null) return null;
      return JournalModel.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveJournal({
    required String scheduleId,
    required String classId,
    required String subjectId,
    required DateTime date,
    required String teachingMaterial,
    String? notes,
  }) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final payload = <String, dynamic>{
      'schedule_id': scheduleId,
      'class_id': classId,
      'subject_id': subjectId,
      'date': dateStr,
      'teaching_material': teachingMaterial,
    };
    if (notes != null) {
      payload['notes'] = notes;
    }

    await _supabase
        .from('journals')
        .upsert(payload, onConflict: 'schedule_id,date');
  }
}
