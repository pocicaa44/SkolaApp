-- Migration: Allow Authenticated Users to View All Schedules for Cross-Teacher Conflict Prevention
-- File: supabase/migrations/20260908010000_allow_teachers_view_all_schedules.sql

-- 1. Drop policy lama yang membatasi SELECT hanya untuk guru yang bersangkutan
DROP POLICY IF EXISTS "Teachers can view assigned schedules" ON public.schedules;
DROP POLICY IF EXISTS "Authenticated users can view schedules" ON public.schedules;
DROP POLICY IF EXISTS "Teachers can view all schedules" ON public.schedules;

-- 2. Buat policy SELECT baru: Semua user terautentikasi dapat melihat seluruh jadwal
CREATE POLICY "Authenticated users can view schedules" ON public.schedules
    FOR SELECT TO authenticated
    USING (true);

-- 3. Pastikan policy INSERT hanya untuk jadwal milik guru yang bersangkutan
DROP POLICY IF EXISTS "Teachers can insert own schedules" ON public.schedules;
CREATE POLICY "Teachers can insert own schedules" ON public.schedules
    FOR INSERT TO authenticated
    WITH CHECK (
        teacher_id IN (
            SELECT t.id FROM public.teachers t WHERE t.profile_id = (select auth.uid())
        )
    );

-- 4. Pastikan policy UPDATE hanya untuk jadwal milik guru yang bersangkutan
DROP POLICY IF EXISTS "Teachers can update own schedules" ON public.schedules;
CREATE POLICY "Teachers can update own schedules" ON public.schedules
    FOR UPDATE TO authenticated
    USING (
        teacher_id IN (
            SELECT t.id FROM public.teachers t WHERE t.profile_id = (select auth.uid())
        )
    )
    WITH CHECK (
        teacher_id IN (
            SELECT t.id FROM public.teachers t WHERE t.profile_id = (select auth.uid())
        )
    );

-- 5. Pastikan policy DELETE hanya untuk jadwal milik guru yang bersangkutan
DROP POLICY IF EXISTS "Teachers can delete own schedules" ON public.schedules;
CREATE POLICY "Teachers can delete own schedules" ON public.schedules
    FOR DELETE TO authenticated
    USING (
        teacher_id IN (
            SELECT t.id FROM public.teachers t WHERE t.profile_id = (select auth.uid())
        )
    );
