-- Migration: Seed 36 Classes and 360 Students for SkolaApp
-- Created: 2026-09-04

-- 1. Insert 36 Classes (10A..10L, 11A..11L, 12A..12L)
INSERT INTO public.classes (name, grade) VALUES
    ('10A', '10'), ('10B', '10'), ('10C', '10'), ('10D', '10'),
    ('10E', '10'), ('10F', '10'), ('10G', '10'), ('10H', '10'),
    ('10I', '10'), ('10J', '10'), ('10K', '10'), ('10L', '10'),
    ('11A', '11'), ('11B', '11'), ('11C', '11'), ('11D', '11'),
    ('11E', '11'), ('11F', '11'), ('11G', '11'), ('11H', '11'),
    ('11I', '11'), ('11J', '11'), ('11K', '11'), ('11L', '11'),
    ('12A', '12'), ('12B', '12'), ('12C', '12'), ('12D', '12'),
    ('12E', '12'), ('12F', '12'), ('12G', '12'), ('12H', '12'),
    ('12I', '12'), ('12J', '12'), ('12K', '12'), ('12L', '12')
ON CONFLICT (name) DO UPDATE SET grade = EXCLUDED.grade;

-- 2. Seed 10 Students per Class for all 36 Classes (360 Students Total)
DO $$
DECLARE
    v_class RECORD;
    v_first_names_male TEXT[] := ARRAY[
        'Aditya', 'Bagus', 'Candra', 'Dimas', 'Eko', 'Fajar', 'Gilang', 'Hendra', 'Irfan', 'Joko',
        'Kevin', 'Lukman', 'Mahendra', 'Naufal', 'Oki', 'Prasetyo', 'Rian', 'Surya', 'Teguh', 'Wahyu'
    ];
    v_first_names_female TEXT[] := ARRAY[
        'Anisa', 'Bella', 'Citra', 'Dewi', 'Elsa', 'Fitri', 'Gita', 'Hani', 'Intan', 'Jasmine',
        'Kartika', 'Laras', 'Mega', 'Nadia', 'Putri', 'Rani', 'Siti', 'Tiara', 'Utami', 'Wulan'
    ];
    v_last_names TEXT[] := ARRAY[
        'Pratama', 'Saputra', 'Wijaya', 'Kusuma', 'Santoso', 'Utomo', 'Hidayat', 'Wibowo', 'Nugroho', 'Setiawan',
        'Lestari', 'Anggraini', 'Permata', 'Rahmawati', 'Sari', 'Handayani', 'Puspa', 'Safitri', 'Astuti', 'Wulandari'
    ];
    v_name TEXT;
    v_gender TEXT;
    v_idx INT;
    v_code TEXT;
BEGIN
    FOR v_class IN SELECT id, name FROM public.classes WHERE name ~ '^(10|11|12)[A-L]$' ORDER BY name LOOP
        FOR v_idx IN 1..10 LOOP
            v_code := 'STD-' || v_class.name || '-' || LPAD(v_idx::TEXT, 2, '0');
            
            -- Alternate genders: Odd = male, Even = female
            IF v_idx % 2 = 1 THEN
                v_gender := 'male';
                v_name := v_first_names_male[((v_idx * 3 + ASCII(SUBSTRING(v_class.name, 1, 1))) % array_length(v_first_names_male, 1)) + 1] || ' ' ||
                          v_last_names[((v_idx * 7 + ASCII(SUBSTRING(v_class.name, 2, 1))) % array_length(v_last_names, 1)) + 1];
            ELSE
                v_gender := 'female';
                v_name := v_first_names_female[((v_idx * 5 + ASCII(SUBSTRING(v_class.name, 1, 1))) % array_length(v_first_names_female, 1)) + 1] || ' ' ||
                          v_last_names[((v_idx * 11 + ASCII(SUBSTRING(v_class.name, 2, 1))) % array_length(v_last_names, 1)) + 1];
            END IF;

            INSERT INTO public.students (student_code, name, gender, class_id)
            VALUES (v_code, v_name, v_gender, v_class.id)
            ON CONFLICT (student_code) DO UPDATE 
            SET name = EXCLUDED.name, gender = EXCLUDED.gender, class_id = EXCLUDED.class_id;
        END LOOP;
    END LOOP;
END $$;
