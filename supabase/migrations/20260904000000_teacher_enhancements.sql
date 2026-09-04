-- Migration: Teacher Enhancements & Conflict Detection
-- Created: 2026-09-04

-- 1. Add status column to profiles if not exists
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'status') THEN
        ALTER TABLE public.profiles ADD COLUMN status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE', 'DELETED'));
    END IF;
END $$;

-- 2. Add status & subject_ids column to teachers if not exists
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'teachers' AND column_name = 'status') THEN
        ALTER TABLE public.teachers ADD COLUMN status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE', 'DELETED'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'teachers' AND column_name = 'subject_ids') THEN
        ALTER TABLE public.teachers ADD COLUMN subject_ids UUID[] DEFAULT '{}';
    END IF;
END $$;

-- 3. Function to check schedule conflicts for (class_id, day_of_week, period overlap)
CREATE OR REPLACE FUNCTION public.check_schedule_conflict(
    p_schedule_id UUID,
    p_class_id UUID,
    p_day_of_week INT,
    p_period_start INT,
    p_period_end INT
) RETURNS BOOLEAN AS $$
DECLARE
    v_conflict_count INT;
BEGIN
    SELECT COUNT(*)
    INTO v_conflict_count
    FROM public.schedules
    WHERE class_id = p_class_id
      AND day_of_week = p_day_of_week
      AND (p_schedule_id IS NULL OR id <> p_schedule_id)
      AND (
          (period_start <= p_period_end AND period_end >= p_period_start)
      );
      
    RETURN v_conflict_count > 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Seed Standard Master Subjects
INSERT INTO public.subjects (name, code) VALUES
    ('Bahasa Indonesia', 'BINDO'),
    ('Matematika', 'MTK'),
    ('Bahasa Inggris', 'BING'),
    ('Pendidikan Pancasila', 'PPKN'),
    ('Sejarah', 'SEJ'),
    ('Agama', 'AGAMA')
ON CONFLICT (code) DO UPDATE 
SET name = EXCLUDED.name;

