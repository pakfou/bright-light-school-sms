const mysql = require('mysql2/promise');

async function setupData() {
    console.log('--- STARTING COMPREHENSIVE SCHOOL DATA STANDARDIZATION ---');

    const pool = mysql.createPool({
        host: 'localhost',
        user: 'root',
        password: '',
        database: 'bls_school_db',
        charset: 'utf8mb4'
    });

    // 1. STANDARDIZE CLASSROOMS
    console.log('1. Standardizing Classrooms...');
    // Fix typo in classroom 13
    await pool.query(`
        UPDATE classrooms 
        SET class_name = 'បន្ទប់ការិយាល័យ & រដ្ឋបាល', room_number = 'Admin-01', capacity = 30
        WHERE id = 13
    `);
    await pool.query(`
        UPDATE classrooms 
        SET class_name = 'ថ្នាក់ទី១ (Class O1)', room_number = 'Room-101', capacity = 30
        WHERE id = 14
    `);
    await pool.query(`
        UPDATE classrooms 
        SET class_name = 'ថ្នាក់ទី២ (Class O2)', room_number = 'Room-102', capacity = 30
        WHERE id = 15
    `);

    // Ensure additional standard classrooms exist
    const [existingClassrooms] = await pool.query('SELECT class_name FROM classrooms');
    const existingClassNames = new Set(existingClassrooms.map(c => c.class_name));

    const extraClasses = [
        { name: 'ថ្នាក់ទី៣ (Grade 3)', level_type: 'Full-Time', shift: 'Morning', room: 'Room-201', cap: 30, subject: 'General', grade_level_id: 10 },
        { name: 'ថ្នាក់មត្តេយ្យ (Kindergarten)', level_type: 'Full-Time', shift: 'Morning', room: 'Room-K1', cap: 25, subject: 'Early Education', grade_level_id: 20 },
        { name: 'ថ្នាក់ភាសាអង់គ្លេស (English GEP)', level_type: 'Part-Time', shift: 'Afternoon', room: 'Room-202', cap: 25, subject: 'English', grade_level_id: 21 },
        { name: 'ថ្នាក់កុំព្យូទ័រ & IT', level_type: 'Part-Time', shift: 'Afternoon', room: 'Lab-01', cap: 25, subject: 'IT', grade_level_id: 25 }
    ];

    for (const ec of extraClasses) {
        if (!existingClassNames.has(ec.name)) {
            await pool.query(`
                INSERT INTO classrooms (class_name, level_type, shift, subject, grade_level_id, room_number, capacity)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            `, [ec.name, ec.level_type, ec.shift, ec.subject, ec.grade_level_id, ec.room, ec.cap]);
            console.log(`+ Added classroom: ${ec.name}`);
        }
    }

    const [allClassrooms] = await pool.query('SELECT id, class_name FROM classrooms');
    const classMap = {};
    for (const c of allClassrooms) classMap[c.class_name] = c.id;

    // 2. STANDARDIZE TEACHERS
    console.log('2. Standardizing Teachers...');
    // Update existing teacher 3
    await pool.query(`
        UPDATE teachers 
        SET name_kh = 'ហាក់​ ប៉ាក់ហ៊្វូរ', name_en = 'Hak Pakfou', specialized_subject = 'គ្រូបច្ចេកវិទ្យា & IT', base_salary = 350.00, role_title = 'គ្រូបង្រៀន & IT Admin', status = 'Active', phone = '012 889 911'
        WHERE id = 3
    `);

    const standardTeachers = [
        { code: 'TCH-1002', name_kh: 'សុខ ចាន់ដារ៉ា', name_en: 'Sok Chandara', gender: 'Male', dob: '1992-04-15', phone: '012 345 678', email: 'chandara.sok@bls.edu', role: 'គ្រូបង្រៀន', subject: 'គណិតវិទ្យា (Mathematics)', salary: 320.00, hire_date: '2022-09-01' },
        { code: 'TCH-1003', name_kh: 'គង់ ស្រីមុំ', name_en: 'Kong Sreymom', gender: 'Female', dob: '1995-08-20', phone: '098 765 432', email: 'sreymom.kong@bls.edu', role: 'គ្រូបង្រៀន', subject: 'ភាសាខ្មែរ (Khmer Literature)', salary: 300.00, hire_date: '2023-01-10' },
        { code: 'TCH-1004', name_kh: 'ម៉ៅ វណ្ណឌី', name_en: 'Mao Vandy', gender: 'Male', dob: '1990-11-05', phone: '088 123 4567', email: 'vandy.mao@bls.edu', role: 'គ្រូបង្រៀន', subject: 'ភាសាអង់គ្លេស (English Language)', salary: 320.00, hire_date: '2021-10-15' },
        { code: 'TCH-1005', name_kh: 'សេង សុភាព', name_en: 'Seng Sopheap', gender: 'Female', dob: '1994-02-28', phone: '077 998 877', email: 'sopheap.seng@bls.edu', role: 'គ្រូបង្រៀន', subject: 'វិទ្យាសាស្ត្រ (General Science)', salary: 310.00, hire_date: '2023-05-01' },
        { code: 'TCH-1006', name_kh: 'ចាន់ សុវណ្ណារ៉ា', name_en: 'Chan Sovannara', gender: 'Male', dob: '1996-07-12', phone: '096 443 322', email: 'sovannara.chan@bls.edu', role: 'គ្រូបង្រៀន', subject: 'សង្គមវិទ្យា & សីលធម៌', salary: 290.00, hire_date: '2024-02-01' }
    ];

    for (const t of standardTeachers) {
        const [existing] = await pool.query('SELECT id FROM teachers WHERE teacher_code = ?', [t.code]);
        if (existing.length === 0) {
            await pool.query(`
                INSERT INTO teachers (teacher_code, name_kh, name_en, gender, dob, phone, email, role_title, specialized_subject, base_salary, status, hire_date)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'Active', ?)
            `, [t.code, t.name_kh, t.name_en, t.gender, t.dob, t.phone, t.email, t.role, t.subject, t.salary, t.hire_date]);
            console.log(`+ Added teacher: ${t.name_kh} (${t.code})`);
        }
    }

    const [allTeachers] = await pool.query('SELECT id, teacher_code, name_kh FROM teachers');
    const teacherMap = {};
    for (const t of allTeachers) teacherMap[t.teacher_code] = t.id;

    // 3. STANDARDIZE STUDENTS
    console.log('3. Standardizing Students...');
    // Ensure existing students are distributed properly
    await pool.query('UPDATE students SET classroom_id = 13 WHERE id = 1809'); // ឈាវ ម៉ីលិញ -> បន្ទប់ការិយាល័យ & រដ្ឋបាល
    await pool.query('UPDATE students SET classroom_id = 14 WHERE id = 1810'); // ផល្លា អ៊ីណ្ឌូ -> ថ្នាក់ទី១ (Class O1)
    await pool.query('UPDATE students SET classroom_id = 15 WHERE id = 1812'); // ស្រ៊ុន គឹមស៊ីង -> ថ្នាក់ទី២ (Class O2)

    // Additional realistic students across classrooms
    const c13Id = 13;
    const c14Id = 14;
    const c15Id = 15;
    const c3Id = classMap['ថ្នាក់ទី៣ (Grade 3)'] || 14;
    const cKId = classMap['ថ្នាក់មត្តេយ្យ (Kindergarten)'] || 14;
    const cEngId = classMap['ថ្នាក់ភាសាអង់គ្លេស (English GEP)'] || 15;

    const standardStudents = [
        // Class O1 (id 14)
        { code: 'BLS-101001', name_kh: 'ឡុង វិបុល', name_en: 'Long Vibol', gender: 'Male', dob: '2017-03-12', parent: 'ឡុង វិចិត្រ', phone: '012 456 789', class_id: c14Id, shift: 'Morning' },
        { code: 'BLS-101002', name_kh: 'គង់ សុជាតា', name_en: 'Kong Socheata', gender: 'Female', dob: '2017-07-25', parent: 'គង់ សារ៉ាត', phone: '098 123 789', class_id: c14Id, shift: 'Morning' },
        { code: 'BLS-101003', name_kh: 'ចាន់ រដ្ឋា', name_en: 'Chan Ratha', gender: 'Male', dob: '2017-01-19', parent: 'ចាន់ សុខុម', phone: '088 234 567', class_id: c14Id, shift: 'Morning' },
        { code: 'BLS-101004', name_kh: 'អ៊ុក ចរិយា', name_en: 'Ouk Chariya', gender: 'Female', dob: '2017-09-08', parent: 'អ៊ុក វណ្ណា', phone: '097 555 432', class_id: c14Id, shift: 'Morning' },
        
        // Class O2 (id 15)
        { code: 'BLS-102001', name_kh: 'ហេង ពិសិដ្ឋ', name_en: 'Heng Piseth', gender: 'Male', dob: '2016-05-14', parent: 'ហេង សំបូរ', phone: '012 777 888', class_id: c15Id, shift: 'Both' },
        { code: 'BLS-102002', name_kh: 'កែវ រស្មី', name_en: 'Keo Reaksmey', gender: 'Female', dob: '2016-11-30', parent: 'កែវ បូរិន', phone: '015 666 999', class_id: c15Id, shift: 'Both' },
        { code: 'BLS-102003', name_kh: 'សុខ ម៉េងហួរ', name_en: 'Sok Menghour', gender: 'Male', dob: '2016-08-22', parent: 'សុខ គឹមហុង', phone: '096 111 222', class_id: c15Id, shift: 'Both' },
        { code: 'BLS-102004', name_kh: 'ទ្រី ស្រីលីន', name_en: 'Try Sreylin', gender: 'Female', dob: '2016-02-17', parent: 'ទ្រី វុទ្ធី', phone: '088 999 111', class_id: c15Id, shift: 'Both' },

        // Class 13 (Admin / Office Room)
        { code: 'BLS-100001', name_kh: 'លី សុវណ្ណ', name_en: 'Ly Sovann', gender: 'Male', dob: '2015-04-10', parent: 'លី សុផល', phone: '012 333 444', class_id: c13Id, shift: 'Morning' },
        { code: 'BLS-100002', name_kh: 'ឃុន ដាវីត', name_en: 'Khun David', gender: 'Male', dob: '2015-12-05', parent: 'ឃុន ចន្ថា', phone: '077 888 222', class_id: c13Id, shift: 'Morning' },

        // Kindergarten
        { code: 'BLS-104001', name_kh: 'ម៉េង ថាវី', name_en: 'Meng Thavy', gender: 'Female', dob: '2019-06-18', parent: 'ម៉េង សុខា', phone: '098 444 555', class_id: cKId, shift: 'Morning' },
        { code: 'BLS-104002', name_kh: 'នួន វឌ្ឍនៈ', name_en: 'Nuon Vattanak', gender: 'Male', dob: '2019-09-21', parent: 'នួន ចាន់នី', phone: '088 666 777', class_id: cKId, shift: 'Morning' }
    ];

    for (const s of standardStudents) {
        const [existing] = await pool.query('SELECT id FROM students WHERE student_code = ?', [s.code]);
        if (existing.length === 0) {
            await pool.query(`
                INSERT INTO students (student_code, name_kh, name_en, gender, dob, parent_name, parent_phone, study_type, shift, classroom_id, status)
                VALUES (?, ?, ?, ?, ?, ?, ?, 'Full-Time', ?, ?, 'Active')
            `, [s.code, s.name_kh, s.name_en, s.gender, s.dob, s.parent, s.phone, s.shift, s.class_id]);
            console.log(`+ Added student: ${s.name_kh} (${s.code})`);
        }
    }

    const [allStudents] = await pool.query('SELECT id, student_code, name_kh, classroom_id FROM students');
    console.log(`Total students now: ${allStudents.length}`);

    // 4. STANDARDIZE STUDENT GRADES
    console.log('4. Standardizing Student Grades...');
    // Synchronize classroom_id in student_grades with students table
    await pool.query(`
        UPDATE student_grades g 
        JOIN students s ON g.student_id = s.id 
        SET g.classroom_id = s.classroom_id
        WHERE g.classroom_id IS NULL OR g.classroom_id != s.classroom_id
    `);

    // Add grades for other students so report cards have complete scores
    const subjects = [
        'ភាសាខ្មែរ (Khmer Literature)',
        'គណិតវិទ្យា (Mathematics)',
        'វិទ្យាសាស្ត្រ (General Science)',
        'សង្គមវិទ្យា (Social Studies)',
        'ភាសាអង់គ្លេស (English Language)',
        'កុំព្យូទ័រ & IT (Computer Skills)'
    ];
    const months = ['មករា (January)', 'កុម្ភៈ (February)', 'មិនា (March)', 'កញ្ញា (September)', 'តុលា (October)'];

    for (const std of allStudents) {
        for (const month of ['កញ្ញា (September)', 'តុលា (October)']) {
            for (const sub of subjects) {
                const [hasGrade] = await pool.query(
                    'SELECT id FROM student_grades WHERE student_id = ? AND subject_name = ? AND month_name = ? LIMIT 1',
                    [std.id, sub, month]
                );
                if (hasGrade.length === 0) {
                    const score = (75 + Math.floor(Math.random() * 24)).toFixed(2);
                    const letter = score >= 90 ? 'A' : (score >= 80 ? 'B' : 'C');
                    const remarks = letter === 'A' 
                        ? 'សិស្សឆ្នើម ឆ្លាតវៃ ខិតខំប្រឹងប្រែង និងមានវិន័យល្អប្រសើរ។'
                        : 'សិស្សរៀនពូកែ មានការយកចិត្តទុកដាក់ និងគោរពបទបញ្ជាផ្ទៃក្នុង។';
                    await pool.query(`
                        INSERT INTO student_grades (student_id, classroom_id, subject_name, month_name, score, grade_letter, remarks, exam_title)
                        VALUES (?, ?, ?, ?, ?, ?, ?, 'ប្រឡងប្រចាំខែ')
                    `, [std.id, std.classroom_id, sub, month, score, letter, remarks]);
                }
            }
        }
    }
    console.log('✓ Student grades synchronized and populated across classrooms.');

    // 5. STANDARDIZE SCHEDULES
    console.log('5. Standardizing Schedules...');
    // Create complete schedules for Mon-Fri across classrooms 13, 14, 15
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    const timeSlots = [
        { start: '07:30', end: '09:00', shift: 'Morning' },
        { start: '09:15', end: '10:45', shift: 'Morning' },
        { start: '13:30', end: '15:00', shift: 'Afternoon' },
        { start: '15:15', end: '16:45', shift: 'Afternoon' }
    ];

    const teacherIds = allTeachers.map(t => t.id);
    const scheduleSubjects = ['ភាសាខ្មែរ', 'គណិតវិទ្យា', 'វិទ្យាសាស្ត្រ', 'ភាសាអង់គ្លេស', 'កុំព្យូទ័រ & IT', 'សង្គមវិទ្យា'];

    for (const cId of [13, 14, 15]) {
        for (let dIdx = 0; dIdx < days.length; dIdx++) {
            const day = days[dIdx];
            for (let sIdx = 0; sIdx < 2; sIdx++) { // 2 sessions per day
                const slot = timeSlots[sIdx];
                const sub = scheduleSubjects[(dIdx + sIdx + cId) % scheduleSubjects.length];
                const tId = teacherIds[(dIdx + sIdx) % teacherIds.length];

                const [hasSched] = await pool.query(
                    'SELECT id FROM schedules WHERE classroom_id = ? AND day_of_week = ? AND start_time = ? LIMIT 1',
                    [cId, day, slot.start]
                );
                if (hasSched.length === 0) {
                    await pool.query(`
                        INSERT INTO schedules (classroom_id, teacher_id, day_of_week, start_time, end_time, subject, subject_name, shift)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    `, [cId, tId, day, slot.start, slot.end, sub, sub, slot.shift]);
                }
            }
        }
    }
    console.log('✓ Weekly schedules populated across classrooms and teachers.');

    // 6. STANDARDIZE FINANCE (PAYMENTS & SALARIES)
    console.log('6. Standardizing Finance Records...');
    // Ensure payments exist for students
    for (const std of allStudents) {
        const [hasPay] = await pool.query('SELECT id FROM student_payments WHERE student_id = ? LIMIT 1', [std.id]);
        if (hasPay.length === 0) {
            const inv = `INV-${Math.floor(100000 + Math.random() * 900000)}`;
            const amt = [20.00, 25.00, 30.00, 35.00][Math.floor(Math.random() * 4)];
            const method = ['KHQR', 'Bank Transfer', 'Cash'][Math.floor(Math.random() * 3)];
            await pool.query(`
                INSERT INTO student_payments (student_id, amount, payment_date, status, invoice_no, payment_method, note, paid_date)
                VALUES (?, ?, '2026-10-14', 'Paid', ?, ?, 'ថ្លៃសិក្សាប្រចាំខែ តុលា', '2026-10-14')
            `, [std.id, amt, inv, method]);
        }
    }

    // Ensure salaries exist for teachers
    for (const tch of allTeachers) {
        const [hasSal] = await pool.query('SELECT id FROM teacher_salaries WHERE teacher_id = ? LIMIT 1', [tch.id]);
        if (hasSal.length === 0) {
            const slip = `SLIP-${Math.floor(100000 + Math.random() * 900000)}`;
            const base = 320.00;
            await pool.query(`
                INSERT INTO teacher_salaries (pay_slip_no, teacher_id, salary_month, base_salary, bonus, deductions, net_salary, paid_date)
                VALUES (?, ?, 'October 2026', ?, 20.00, 0.00, ?, '2026-10-14')
            `, [slip, tch.id, base, base + 20.00]);
        }
    }
    console.log('✓ Student tuition payments and teacher salaries standardized.');

    // 7. STANDARDIZE ATTENDANCE
    console.log('7. Standardizing Attendance for Recent Days and Today...');
    const todayStr = '2026-10-15';
    const dates = [
        '2026-10-10',
        '2026-10-11',
        '2026-10-12',
        '2026-10-13',
        '2026-10-14',
        '2026-10-15'
    ];

    for (const d of dates) {
        // Students attendance
        for (const std of allStudents) {
            const [hasAtt] = await pool.query(
                'SELECT id FROM attendance WHERE student_id = ? AND date = ? LIMIT 1',
                [std.id, d]
            );
            if (hasAtt.length === 0) {
                // 95% Present, 5% Permission
                const isPresent = Math.random() > 0.08;
                const status = isPresent ? 'Present' : 'Permission';
                const hour = 7 + Math.floor(Math.random() * 2);
                const min = Math.floor(Math.random() * 59);
                const timeStr = `${hour.toString().padStart(2, '0')}:${min.toString().padStart(2, '0')}:00`;
                await pool.query(`
                    INSERT INTO attendance (student_id, classroom_id, date, shift, status, created_at)
                    VALUES (?, ?, ?, 'Morning', ?, ?)
                `, [std.id, std.classroom_id, d, status, `${d} ${timeStr}`]);
            }
        }

        // Teachers attendance
        for (const tch of allTeachers) {
            const [hasAtt] = await pool.query(
                'SELECT id FROM attendance WHERE teacher_id = ? AND date = ? LIMIT 1',
                [tch.id, d]
            );
            if (hasAtt.length === 0) {
                await pool.query(`
                    INSERT INTO attendance (teacher_id, date, shift, status, created_at)
                    VALUES (?, ?, 'Morning', 'Present', ?)
                `, [tch.id, d, `${d} 07:15:00`]);
            }
        }
    }
    console.log('✓ Attendance records organized cleanly across recent days and today.');

    console.log('--- ALL SCHOOL DATA STANDARDIZED SUCCESSFULLY! ---');
    await pool.end();
}

setupData().catch(console.error);
