-- ប្រសិនបើអ្នកមិនទាន់ចង់លុបទិន្នន័យចាស់ចោល អាចប្រើ Command ខាងក្រោមនេះ ដើម្បីថែម Column ថ្មីៗចូលទៅក្នុងតារាង students និង teachers៖

-- ជួសជុលតារាង students
ALTER TABLE students 
ADD COLUMN IF NOT EXISTS name_kh VARCHAR(100) AFTER student_code,
ADD COLUMN IF NOT EXISTS name_en VARCHAR(100) AFTER name_kh;

-- ជួសជុលតារាង teachers
ALTER TABLE teachers 
ADD COLUMN IF NOT EXISTS name_kh VARCHAR(100) AFTER teacher_code,
ADD COLUMN IF NOT EXISTS name_en VARCHAR(100) AFTER name_kh;
