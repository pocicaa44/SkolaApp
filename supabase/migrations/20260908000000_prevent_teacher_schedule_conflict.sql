-- Migration: Prevent Teacher and Class Schedule Overlap
-- File: supabase/migrations/20260908000000_prevent_teacher_schedule_conflict.sql

CREATE OR REPLACE FUNCTION public.check_schedule_conflict(
    p_schedule_id UUID,
    p_teacher_id UUID,
    p_class_id UUID,
    p_day_of_week INT,
    p_period_start INT,
    p_period_end INT
) RETURNS JSONB AS $$
DECLARE
    v_class_conflict RECORD;
    v_teacher_conflict RECORD;
BEGIN
    -- 1. Cek apakah ada jadwal guru lain/sama di KELAS ini pada JP & hari yang sama
    SELECT s.id, c.name AS class_name, sub.name AS subject_name, s.period_start, s.period_end
    INTO v_class_conflict
    FROM public.schedules s
    JOIN public.classes c ON c.id = s.class_id
    JOIN public.subjects sub ON sub.id = s.subject_id
    WHERE s.class_id = p_class_id
      AND s.day_of_week = p_day_of_week
      AND (p_schedule_id IS NULL OR s.id <> p_schedule_id)
      AND (s.period_start <= p_period_end AND s.period_end >= p_period_start)
    LIMIT 1;

    IF v_class_conflict IS NOT NULL THEN
        RETURN jsonb_build_object(
            'has_conflict', true,
            'conflict_type', 'class',
            'message', format('Kelas %s sudah memiliki jadwal %s pada JP %s-%s.', 
                              v_class_conflict.class_name, 
                              v_class_conflict.subject_name, 
                              v_class_conflict.period_start, 
                              v_class_conflict.period_end)
        );
    END IF;

    -- 2. Cek apakah GURU INI sudah memiliki jadwal di kelas manapun pada JP & hari yang sama
    IF p_teacher_id IS NOT NULL THEN
        SELECT s.id, c.name AS class_name, sub.name AS subject_name, s.period_start, s.period_end
        INTO v_teacher_conflict
        FROM public.schedules s
        JOIN public.classes c ON c.id = s.class_id
        JOIN public.subjects sub ON sub.id = s.subject_id
        WHERE s.teacher_id = p_teacher_id
          AND s.day_of_week = p_day_of_week
          AND (p_schedule_id IS NULL OR s.id <> p_schedule_id)
          AND (s.period_start <= p_period_end AND s.period_end >= p_period_start)
        LIMIT 1;

        IF v_teacher_conflict IS NOT NULL THEN
            RETURN jsonb_build_object(
                'has_conflict', true,
                'conflict_type', 'teacher',
                'message', format('Anda sudah memiliki jadwal mengajar %s di %s pada JP %s-%s.', 
                                  v_teacher_conflict.subject_name, 
                                  v_teacher_conflict.class_name, 
                                  v_teacher_conflict.period_start, 
                                  v_teacher_conflict.period_end)
            );
        END IF;
    END IF;

    -- Tidak ada konflik
    RETURN jsonb_build_object(
        'has_conflict', false,
        'conflict_type', null,
        'message', null
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
