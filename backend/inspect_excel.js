const XLSX = require('xlsx');
const path = require('path');
const fs = require('fs');

const dir = 'd:\\Downloads\\Telegram Desktop';
const candidateFiles = [
  'តារាងព័ត៍មានសិស្សសាលា_BLS_2026.xlsx',
  'តារាងព័ត៍មានសិស្សសាលា_BLS_2026 (2).xlsx',
  'តារាងព័ត៍មានសិស្សBLS_Whole.xlsx',
  'តារាងព័ត៍មានសិស្ស.xlsx',
  'តារាងព័ត៍មានសិស្ស (2).xlsx',
  'តារាងព័ត៍មានសិស្ស (3).xlsx',
  'តារាងព័ត៍មានសិស្សBLS.xlsx',
  "Students' Name.xlsx"
];

for (const file of candidateFiles) {
  const fullPath = path.join(dir, file);
  if (!fs.existsSync(fullPath)) continue;
  try {
    const wb = XLSX.readFile(fullPath);
    console.log('\n=========================================');
    console.log('FILE:', file, 'Sheets:', wb.SheetNames);
    for (const sheetName of wb.SheetNames) {
      const sheet = wb.Sheets[sheetName];
      const data = XLSX.utils.sheet_to_json(sheet, { header: 1 });
      console.log(`-- Sheet [${sheetName}] Rows: ${data.length}`);
      // Find row with ឈឿន or ម៉ានីង or Chhoen or Maning
      for (let i = 0; i < data.length; i++) {
        const rowStr = JSON.stringify(data[i]);
        if (rowStr.includes('Maning') || rowStr.includes('ម៉ានីង') || rowStr.includes('Huy Long') || rowStr.includes('ហេង ហ៊ុយឡុង')) {
          console.log(`   FOUND MATCH at row ${i} in sheet ${sheetName}:`, JSON.stringify(data[i]));
          break;
        }
      }
    }
  } catch(e) {
    console.log('Error reading', file, e.message);
  }
}
