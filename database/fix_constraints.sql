USE bls_school_db;

-- ១. កំណត់ Charset UTF-8 ពេញលេញសម្រាប់ភាសាខ្មែរ
ALTER DATABASE bls_school_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ២. ដក និងភ្ជាប់ Foreign Key លើ attendance ឱ្យមាន ON DELETE CASCADE
ALTER TABLE attendance DROP FOREIGN KEY attendance_ibfk_1;
ALTER TABLE attendance DROP FOREIGN KEY attendance_ibfk_2;
ALTER TABLE attendance 
  ADD CONSTRAINT fk_att_student FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
  ADD CONSTRAINT fk_att_classroom FOREIGN KEY (classroom_id) REFERENCES classrooms(id) ON DELETE CASCADE;

-- ៣. កំណត់ ON DELETE CASCADE លើ student_grades
ALTER TABLE student_grades DROP FOREIGN KEY student_grades_ibfk_1;
ALTER TABLE student_grades DROP FOREIGN KEY student_grades_ibfk_2;
ALTER TABLE student_grades 
  ADD CONSTRAINT fk_grades_student FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
  ADD CONSTRAINT fk_grades_classroom FOREIGN KEY (classroom_id) REFERENCES classrooms(id) ON DELETE CASCADE;

-- ៤. កំណត់ ON DELETE CASCADE លើ student_payments
ALTER TABLE student_payments DROP FOREIGN KEY student_payments_ibfk_1;
ALTER TABLE student_payments 
  ADD CONSTRAINT fk_pay_student FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE;

-- ៥. កំណត់ឱ្យ classroom_id ក្លាយជា NULL ពេលលុបថ្នាក់រៀន
ALTER TABLE students DROP FOREIGN KEY students_ibfk_1;
ALTER TABLE students 
  ADD CONSTRAINT fk_students_classroom FOREIGN KEY (classroom_id) REFERENCES classrooms(id) ON DELETE SET NULL;
