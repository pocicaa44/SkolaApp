-- Migration: Initial School Schema for Skola App
-- Created: 2026-09-01

-- 1. Drop existing dummy profiles table if present
DROP TABLE IF EXISTS public.profiles CASCADE;

-- 2. Profiles Table
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE,
    email TEXT,
    role TEXT NOT NULL DEFAULT 'teacher' CHECK (role IN ('teacher')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. Teachers Table
CREATE TABLE public.teachers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID UNIQUE NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    teacher_code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 4. Classes Table
CREATE TABLE public.classes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    grade TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 5. Students Table
CREATE TABLE public.students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    gender TEXT NOT NULL CHECK (gender IN ('male', 'female')),
    class_id UUID NOT NULL REFERENCES public.classes(id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 6. Subjects Table
CREATE TABLE public.subjects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    code TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 7. Schedules Table
CREATE TABLE public.schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    teacher_id UUID NOT NULL REFERENCES public.teachers(id) ON DELETE CASCADE,
    class_id UUID NOT NULL REFERENCES public.classes(id) ON DELETE RESTRICT,
    subject_id UUID NOT NULL REFERENCES public.subjects(id) ON DELETE RESTRICT,
    day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_schedule_time CHECK (start_time < end_time)
);

-- 8. Attendance Table
CREATE TABLE public.attendance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    schedule_id UUID NOT NULL REFERENCES public.schedules(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
    attendance_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status TEXT NOT NULL CHECK (status IN ('present', 'sick', 'permission', 'absent', 'late')),
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_schedule_student_date UNIQUE (schedule_id, student_id, attendance_date)
);

-- 9. Indexes
CREATE INDEX idx_students_class_id ON public.students(class_id);
CREATE INDEX idx_schedules_teacher_id ON public.schedules(teacher_id);
CREATE INDEX idx_schedules_class_id ON public.schedules(class_id);
CREATE INDEX idx_schedules_subject_id ON public.schedules(subject_id);
CREATE INDEX idx_schedules_day_teacher ON public.schedules(teacher_id, day_of_week);
CREATE INDEX idx_attendance_schedule_date ON public.attendance(schedule_id, attendance_date);
CREATE INDEX idx_attendance_student_id ON public.attendance(student_id);

-- 10. Enable Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teachers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;

-- 11. RLS Policies

-- Profiles Policies
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT TO authenticated
    USING ((select auth.uid()) = id);

CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE TO authenticated
    USING ((select auth.uid()) = id)
    WITH CHECK ((select auth.uid()) = id);

CREATE POLICY "Users can insert own profile" ON public.profiles
    FOR INSERT TO authenticated
    WITH CHECK ((select auth.uid()) = id);

-- Teachers Policies
CREATE POLICY "Authenticated users can view teachers" ON public.teachers
    FOR SELECT TO authenticated
    USING (true);

CREATE POLICY "Teachers can insert/update own record" ON public.teachers
    FOR ALL TO authenticated
    USING (profile_id = (select auth.uid()))
    WITH CHECK (profile_id = (select auth.uid()));

-- Classes Policies
CREATE POLICY "Authenticated users can view classes" ON public.classes
    FOR SELECT TO authenticated
    USING (true);

-- Students Policies
CREATE POLICY "Authenticated users can view students" ON public.students
    FOR SELECT TO authenticated
    USING (true);

-- Subjects Policies
CREATE POLICY "Authenticated users can view subjects" ON public.subjects
    FOR SELECT TO authenticated
    USING (true);

-- Schedules Policies
CREATE POLICY "Teachers can view assigned schedules" ON public.schedules
    FOR SELECT TO authenticated
    USING (
        teacher_id IN (
            SELECT t.id FROM public.teachers t WHERE t.profile_id = (select auth.uid())
        )
    );

-- Attendance Policies
CREATE POLICY "Teachers can view assigned schedule attendance" ON public.attendance
    FOR SELECT TO authenticated
    USING (
        schedule_id IN (
            SELECT s.id FROM public.schedules s
            JOIN public.teachers t ON s.teacher_id = t.id
            WHERE t.profile_id = (select auth.uid())
        )
    );

CREATE POLICY "Teachers can manage assigned schedule attendance" ON public.attendance
    FOR ALL TO authenticated
    USING (
        schedule_id IN (
            SELECT s.id FROM public.schedules s
            JOIN public.teachers t ON s.teacher_id = t.id
            WHERE t.profile_id = (select auth.uid())
        )
    )
    WITH CHECK (
        schedule_id IN (
            SELECT s.id FROM public.schedules s
            JOIN public.teachers t ON s.teacher_id = t.id
            WHERE t.profile_id = (select auth.uid())
        )
    );
