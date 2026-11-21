const XLSX = require('xlsx');
const mysql = require('mysql2/promise');
const path = require('path');
const fs = require('fs');
require('dotenv').config({ path: path.join(__dirname, '.env') });

const khmerMonths = {
  'មករា': 1, 'កុម្ភៈ': 2, 'កុម្ភះ': 2, 'មីនា': 3, 'មេសា': 4,
  'ឧសភា': 5, 'មិថុនា': 6, 'កក្កដា': 7, 'សីហា': 8, 'កញ្ញា': 9,
  'តុលា': 10, 'វិច្ឆិកា': 11, 'ធ្នូ': 12
};

const khmerDigits = {
  '០': '0', '១': '1', '២': '2', '៣': '3', '៤': '4',
  '៥': '5', '៦': '6', '៧': '7', '៨': '8', '៩': '9'
};

function cleanKhmer(str) {
  if (!str) return '';
  return String(str).replace(/[\u200B-\u200D\uFEFF]/g, '').trim();
}

function cleanPhone(raw) {
  if (!raw) return '';
  return String(raw)
    .replace(/[\u200B-\u200D\uFEFF]/g, '')
    .replace(/[០-៩]/g, d => khmerDigits[d] || d)
    .replace(/\s+/g, ' ')
    .trim();
}

function parseDob(rawDob) {
  if (!rawDob) return null;
  if (typeof rawDob === 'number') {
    const date = new Date(Math.round((rawDob - 25569) * 86400 * 1000));
    const y = date.getUTCFullYear();
    const m = String(date.getUTCMonth() + 1).padStart(2, '0');
    const d = String(date.getUTCDate()).padStart(2, '0');
    return `${y}-${m}-${d}`;
  }

  let s = cleanKhmer(rawDob)
    .replace(/[០-៩]/g, d => khmerDigits[d] || d)
    .replace(/20219/g, '2019');

  // Format: ថ្ងៃទី ០១ ខែ កញ្ញា ឆ្នាំ ២០១៧ or ថ្ងៃទី ០៤ ទី កក្កដា ឆ្នាំ ២០១៤
  const matchKh = s.match(/ថ្ងៃទី\s*(\d+)\s*(?:ខែ|ទី)\s*([^\s\d]+)\s*ឆ្នាំ\s*(\d{4})/);
  if (matchKh) {
    const day = String(matchKh[1]).padStart(2, '0');
    const mName = matchKh[2].trim();
    const month = String(khmerMonths[mName] || 1).padStart(2, '0');
    const year = matchKh[3];
    return `${year}-${month}-${day}`;
  }

  // Format: DD-MM-YYYY or DD/MM/YYYY
  const matchDMY = s.match(/^(\d{1,2})[-/.](\d{1,2})[-/.](\d{4})$/);
  if (matchDMY) {
    return `${matchDMY[3]}-${String(matchDMY[2]).padStart(2, '0')}-${String(matchDMY[1]).padStart(2, '0')}`;
  }

  // Format: YYYY-MM-DD
  const matchYMD = s.match(/^(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})$/);
  if (matchYMD) {
    return `${matchYMD[1]}-${String(matchYMD[2]).padStart(2, '0')}-${String(matchYMD[3]).padStart(2, '0')}`;
  }

  return null;
}

async function runImport() {
  const filePath = 'd:\\Downloads\\Telegram Desktop\\តារាងព័ត៍មានសិស្សសាលា_BLS_2026 (2).xlsx';
  if (!fs.existsSync(filePath)) {
    console.error('File not found:', filePath);
    process.exit(1);
  }

  console.log('Reading Excel file:', filePath);
  const wb = XLSX.readFile(filePath);
  const sheet = wb.Sheets['Sheet1'];
  const rawRows = XLSX.utils.sheet_to_json(sheet, { header: 1 });

  const pool = mysql.createPool({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'bls_school_db',
    port: process.env.DB_PORT || 3306,
  });

  console.log('Connected to MySQL bls_school_db');

  // Ensure classrooms for Grade 4, 5, 6 exist
  const [existingClasses] = await pool.query('SELECT id, class_name FROM classrooms');
  const classMap = {};
  for (const c of existingClasses) {
    classMap[c.class_name] = c.id;
  }

  async function getOrCreateClass(name, gradeLevelId, room) {
    for (const key in classMap) {
      if (key.includes(name) || key.includes(room)) {
        return classMap[key];
      }
    }
    const [res] = await pool.query(
      'INSERT INTO classrooms (class_name, level_type, shift, subject, grade_level_id, room_number, capacity) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [name, 'Full-Time', 'Morning', 'General', gradeLevelId, room, 30]
    );
    classMap[name] = res.insertId;
    console.log(`Created new classroom [${name}] with ID: ${res.insertId}`);
    return res.insertId;
  }

  const kId = await getOrCreateClass('ថ្នាក់មត្តេយ្យ (Kindergarten)', 20, 'Room-K1');
  const g1Id = await getOrCreateClass('ថ្នាក់ទី១ (Class O1)', 20, 'Room-101');
  const g2Id = await getOrCreateClass('ថ្នាក់ទី២ (Class O2)', 27, 'Room-102');
  const g3Id = await getOrCreateClass('ថ្នាក់ទី៣ (Grade 3)', 10, 'Room-201');
  const g4Id = await getOrCreateClass('ថ្នាក់ទី៤ (Grade 4)', 11, 'Room-203');
  const g5Id = await getOrCreateClass('ថ្នាក់ទី៥ (Grade 5)', 12, 'Room-204');
  const g6Id = await getOrCreateClass('ថ្នាក់ទី៦ (Grade 6)', 13, 'Room-205');

  console.log('Classroom IDs:', { kId, g1Id, g2Id, g3Id, g4Id, g5Id, g6Id });

  // Load existing students to preserve IDs if already present
  const [existingStudents] = await pool.query('SELECT id, student_code, name_kh FROM students');
  const existingByName = new Map();
  const existingByCode = new Map();
  for (const s of existingStudents) {
    if (s.name_kh) existingByName.set(s.name_kh.trim(), s);
    if (s.student_code) existingByCode.set(s.student_code.trim(), s);
  }

  let insertedCount = 0;
  let updatedCount = 0;

  for (let i = 11; i < rawRows.length; i++) {
    const row = rawRows[i];
    if (!row) continue;
    const no = row[0];
    const nameKh = cleanKhmer(row[1]);
    const nameEn = cleanKhmer(row[2]);
    const genderKh = cleanKhmer(row[3]);
    const rawDob = row[4];
    const pob = cleanKhmer(row[5]);
    const fatherName = cleanKhmer(row[6]);
    const motherName = cleanKhmer(row[7]);
    const phone = cleanPhone(row[8]);

    if (!nameKh && !nameEn) continue;

    const gender = genderKh === 'ស្រី' ? 'Female' : 'Male';
    const dob = parseDob(rawDob);

    // Parent name
    let parentName = '';
    if (fatherName && motherName) {
      parentName = `${fatherName} / ${motherName}`;
    } else if (fatherName) {
      parentName = fatherName;
    } else if (motherName) {
      parentName = motherName;
    }
    if (parentName.length > 95) {
      parentName = parentName.substring(0, 95);
    }

    // Determine classroom based on birth year
    let classroomId = g1Id;
    if (dob) {
      const year = parseInt(dob.substring(0, 4), 10);
      if (year >= 2020) {
        classroomId = kId;
      } else if (year === 2019) {
        classroomId = g1Id;
      } else if (year === 2018) {
        classroomId = g2Id;
      } else if (year === 2017) {
        classroomId = g3Id;
      } else if (year === 2016) {
        classroomId = g4Id;
      } else if (year === 2015) {
        classroomId = g5Id;
      } else if (year <= 2014) {
        classroomId = g6Id;
      }
    }

    // Standard student code
    const stdCode = `BLS-${String(1000 + (parseInt(no, 10) || (i - 10))).padStart(4, '0')}`;

    // Check if student exists
    const match = existingByName.get(nameKh);
    if (match) {
      // Update existing student
      await pool.query(
        `UPDATE students 
         SET name_kh = ?, name_en = ?, gender = ?, dob = ?, pob = ?, parent_name = ?, parent_phone = ?, study_type = 'Full-Time', shift = 'Morning', classroom_id = COALESCE(classroom_id, ?), status = 'Active'
         WHERE id = ?`,
        [nameKh, nameEn || null, gender, dob, pob || null, parentName || null, phone || null, classroomId, match.id]
      );
      updatedCount++;
    } else {
      // Check code collision
      let finalCode = stdCode;
      if (existingByCode.has(finalCode)) {
        finalCode = `BLS-${Math.floor(2000 + Math.random() * 8000)}`;
      }

      await pool.query(
        `INSERT INTO students (student_code, name_kh, name_en, gender, dob, pob, parent_name, parent_phone, study_type, shift, part_time_course, classroom_id, status)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'Full-Time', 'Morning', 'None', ?, 'Active')`,
        [finalCode, nameKh, nameEn || null, gender, dob, pob || null, parentName || null, phone || null, classroomId]
      );
      existingByCode.set(finalCode, true);
      insertedCount++;
    }
  }

  const [totalCount] = await pool.query('SELECT COUNT(*) AS total FROM students');
  console.log('====================================');
  console.log(`IMPORT COMPLETED SUCCESSFULLY!`);
  console.log(`- Inserted new students: ${insertedCount}`);
  console.log(`- Updated existing students: ${updatedCount}`);
  console.log(`- Total students in database: ${totalCount[0].total}`);
  console.log('====================================');

  await pool.end();
}

runImport().catch(err => {
  console.error('Fatal import error:', err);
  process.exit(1);
});
