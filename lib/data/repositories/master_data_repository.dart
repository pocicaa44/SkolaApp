import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/cache/memory_cache_service.dart';
import '../../core/utils/period_helper.dart';
import '../models/class_model.dart';
import '../models/lesson_period_model.dart';
import '../models/subject_model.dart';

class MasterDataRepository {
  final SupabaseClient _supabase;
  final MemoryCacheService _cache;

  MasterDataRepository({SupabaseClient? supabase, MemoryCacheService? cache})
    : _supabase = supabase ?? Supabase.instance.client,
      _cache = cache ?? MemoryCacheService();

  Future<List<SubjectModel>> getSubjects({bool forceRefresh = false}) async {
    const cacheKey = 'master_subjects';
    if (!forceRefresh) {
      final cached = _cache.get<List<SubjectModel>>(cacheKey);
      if (cached != null) return cached;
    }

    final data = await _supabase
        .from('subjects')
        .select('id, name, code')
        .order('name');

    final subjects = (data as List)
        .map((json) => SubjectModel.fromJson(json))
        .toList();
    _cache.set(cacheKey, subjects, ttl: const Duration(minutes: 15));
    return subjects;
  }

  Future<List<ClassModel>> getClasses({bool forceRefresh = false}) async {
    const cacheKey = 'master_classes';
    if (!forceRefresh) {
      final cached = _cache.get<List<ClassModel>>(cacheKey);
      if (cached != null) return cached;
    }

    final data = await _supabase
        .from('classes')
        .select('id, name, grade')
        .order('name');

    final classes = (data as List)
        .map((json) => ClassModel.fromJson(json))
        .toList();
    _cache.set(cacheKey, classes, ttl: const Duration(minutes: 15));
    return classes;
  }

  Future<List<LessonPeriodModel>> getLessonPeriodConfigs({
    bool forceRefresh = false,
  }) async {
    const cacheKey = 'master_lesson_period_configs';
    if (!forceRefresh) {
      final cached = _cache.get<List<LessonPeriodModel>>(cacheKey);
      if (cached != null) return cached;
    }

    try {
      final data = await _supabase
          .from('lesson_period_configs')
          .select('day_of_week, period_duration_minutes');

      final configs = (data as List)
          .map((json) => LessonPeriodModel.fromJson(json))
          .toList();
      for (var c in configs) {
        PeriodHelper.periodDurations[c.dayOfWeek] = c.periodDurationMinutes;
      }
      _cache.set(cacheKey, configs, ttl: const Duration(minutes: 30));
      return configs;
    } catch (_) {
      return [];
    }
  }
}
