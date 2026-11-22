# 🎓 Studies Pro - Bright Light School Management System

> **ប្រព័ន្ធគ្រប់គ្រងសាលារៀន ប្រាយ ឡាយ (Bright Light School Management System)**  
> ដំណោះស្រាយពេញលេញសម្រាប់គ្រប់គ្រងសាលារៀនទំនើប រួមមាន Frontend (Flutter Web) និង Backend (Node.js/Express + MySQL/TiDB Cloud)។

---

## 🇰🇭 ភាសាខ្មែរ (Khmer Overview)

**Studies Pro - Bright Light School Management System** គឺជាប្រព័ន្ធគ្រប់គ្រងសាលារៀនកម្រិតអាជីព ដែលត្រូវបានបង្កើតឡើងដើម្បីជួយសម្រួលដល់ដំណើរការរដ្ឋបាល ការគ្រប់គ្រងទិន្នន័យសិស្ស គ្រូបង្រៀន ពិន្ទុ វត្តមាន និងហិរញ្ញវត្ថុសាលា ឱ្យមានភាពរហ័ស សុក្រឹត និងទំនើប។

### 🌟 មុខងារចម្បងៗ (Key Features)
1. **ផ្ទាំងគ្រប់គ្រងទិន្នន័យ (Dashboard & Analytics):** ស្ថិតិសិស្សសរុប គ្រូបង្រៀន ចំណូល-ចំណាយ និងគំនូសតាងអត្រាវត្តមានប្រចាំខែ។
2. **គ្រប់គ្រងសិស្ស (Students Management):** ចុះឈ្មោះសិស្សថ្មី កែសម្រួលព័ត៌មាន ស្វែងរក នាំចេញទិន្នន័យជា CSV និងស្ទូឌីយោបង្កើតកាតសិស្ស (ID Card Studio) ជាមួយ QR Code។
3. **គ្រប់គ្រងគ្រូបង្រៀន (Teachers & HR):** កត់ត្រាព័ត៌មានគ្រូ កិច្ចសន្យា ប្រាក់បៀវត្សរ៍មូលដ្ឋាន និងការចេញប័ណ្ណបើកប្រាក់ខែ (Payslip)។
4. **គ្រប់គ្រងថ្នាក់រៀន និងកាលវិភាគ (Classrooms & Schedules):** បង្កើតកម្រិតថ្នាក់ បន្ទប់រៀន វេនសិក្សា (ព្រឹក/រសៀល/ពេញម៉ោង) និងតារាងកាលវិភាគប្រចាំសប្តាហ៍។
5. **ប្រព័ន្ធកត់ត្រាវត្តមាន (Attendance Scanner):** ស្កេន QR Code លើកាតសិស្ស ឬកត់ត្រាវត្តមានតាមបញ្ជីថ្នាក់រៀនដោយផ្ទាល់។
6. **ការបញ្ចូលពិន្ទុ និងចំណាត់ថ្នាក់ (Grading & Ranking):** បញ្ចូលពិន្ទុតាមមុខវិជ្ជា គណនាពិន្ទុសរុប មធ្យមភាគ និងចំណាត់ថ្នាក់ស្វ័យប្រវត្តិតាមកម្រិតថ្នាក់។
7. **ហិរញ្ញវត្ថុ និងការបង់ប្រាក់ (Student Payments & Payroll):** បង្កើតវិក្កយបត្រថ្លៃសិក្សា ស្កេនទូទាត់ប្រាក់តាមរយៈ KHQR (Bakong) និងការផ្ទៀងផ្ទាត់បង្កាន់ដៃបង់ប្រាក់។
8. **ការគាំទ្រ Offline/Demo Mode:** អាចដំណើរការបង្ហាញ និងតេស្តមុខងារទាំងអស់បានយ៉ាងរលូន ទោះបីជាគ្មានការភ្ជាប់អ៊ីនធឺណិត ឬ Backend ក៏ដោយ។

---

## 🇬🇧 English Overview

**Studies Pro - Bright Light School Management System** is an enterprise-grade school management platform featuring a high-performance **Flutter Web** application paired with a scalable **Node.js/Express** REST API and **MySQL/TiDB Cloud** relational database.

### 🛠️ Architecture & Tech Stack
- **Frontend:** Flutter Web (Dart SDK), Material 3 Design, Custom Khmer Typography (`Battambang`, `Khmer OS Muol Light`), Responsive Dashboard.
- **Backend:** Node.js, Express.js, MySQL2 (`mysql2/promise` with SSL connection pool), CORS, Multer.
- **Database:** MySQL / TiDB Cloud MySQL (`bls_school_db`).
- **Cloud Hosting:** Firebase Hosting ([https://bls-bmc.web.app](https://bls-bmc.web.app)) and Render.com.

---

## 🚀 របៀបដំឡើង និងដំណើរការ (Getting Started)

### ១. Backend (Node.js API)
```bash
# ចូលទៅកាន់ Folder backend
cd backend

# ដំឡើង dependencies
npm install

# បង្កើត database schema
node init_db.js

# ដំណើរការ Local API Server (Port 5000)
npm start
```

### ២. Frontend (Flutter Web)
```bash
# នៅក្នុង Root directory
flutter pub get

# ដំណើរការ Local Web Dev Server
flutter run -d chrome

# Build សម្រាប់ Production
flutter build web --release

# Deploy ទៅកាន់ Firebase Hosting
firebase deploy --only hosting
```

---

## 🔑 គណនីសម្រាប់តេស្ត (Demo Login Credentials)

| តួនាទី (Role) | គណនី / អ៊ីមែល (Account/Email) | ពាក្យសម្ងាត់ (Password) |
| :--- | :--- | :--- |
| **Admin** | `admin@brightlight.edu.kh` | `1202` |
| **Teacher** | `TCH-1001` | `1202` |

---

## 📄 License
រក្សាសិទ្ធិគ្រប់យ៉ាង © 2026 Bright Light Primary School. All rights reserved.
