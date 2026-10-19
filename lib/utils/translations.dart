import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('km'); // Default to Khmer

  Locale get locale => _locale;

  void toggleLanguage() {
    if (_locale.languageCode == 'km') {
      _locale = const Locale('en');
    } else {
      _locale = const Locale('km');
    }
    notifyListeners();
  }
}

class AppTranslations {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'Bright Light School OS',
      'login': 'Login',
      'register': 'Create Account',
      'email': 'Email',
      'password': 'Password',
      'role': 'Role',
      'full_name': 'Full Name',
      'no_account': 'Don\'t have an account? ',
      'dashboard': 'Dashboard Overview',
      'scanner': 'Dual Attendance Scanner',
      'management': 'Student & Teacher Mgt',
      'schedule': 'Weekly Schedule',
      'grades': 'Grade Entry',
      'finance': 'Finance (Tuition & Salary)',
      'assistant': 'AI School Assistant',
      'reports': 'Periodic Closing Reports',
      'classrooms': 'Classrooms Manager',
      'id_card': 'ID Card Studio',
      'logout': 'Logout',
      'welcome': 'Welcome to the system',
      'total_students': 'Total Students',
      'today_attendance': 'Today\'s Attendance',
      'active_teachers': 'Active Teachers',
      'total_revenue': 'Total Revenue',
      'last_7_days': 'Attendance last 7 days',
    },
    'km': {
      'app_title': 'ប្រព័ន្ធគ្រប់គ្រងសាលារៀន Bright Light',
      'login': 'ចូលគណនី (LOGIN)',
      'register': 'បង្កើតគណនីថ្មី (REGISTER)',
      'email': 'អ៊ីមែល (Email)',
      'password': 'ពាក្យសម្ងាត់ (Password)',
      'role': 'ប្រភេទអ្នកប្រើ (Role)',
      'full_name': 'ឈ្មោះពេញ (Full Name)',
      'no_account': 'មិនទាន់មានគណនី? ',
      'dashboard': 'ផ្ទាំងគ្រប់គ្រងទូទៅ',
      'scanner': 'ស្កេនវត្តមាន (សិស្ស/គ្រូ)',
      'management': 'គ្រប់គ្រងសិស្ស និង គ្រូ',
      'schedule': 'កាលវិភាគប្រចាំសប្តាហ៍',
      'grades': 'បញ្ចូលពិន្ទុ',
      'finance': 'ហិរញ្ញវត្ថុ (បង់ថ្លៃសិក្សា & ប្រាក់ខែ)',
      'assistant': 'ជំនួយការ AI សាលារៀន',
      'reports': 'របាយការណ៍បិទបញ្ជី',
      'classrooms': 'គ្រប់គ្រងថ្នាក់រៀន',
      'id_card': 'បង្កើតកាតសម្គាល់ខ្លួន',
      'logout': 'ចាកចេញ',
      'welcome': 'សូមស្វាគមន៍មកកាន់ប្រព័ន្ធ',
      'total_students': 'សិស្សសរុប',
      'today_attendance': 'វត្តមានថ្ងៃនេះ',
      'active_teachers': 'គ្រូកំពុងបង្រៀន',
      'total_revenue': 'ចំណូលសរុបខែនេះ',
      'last_7_days': 'ស្ថិតិវត្តមាន ៧ ថ្ងៃចុងក្រោយ',
    },
  };

  static String t(BuildContext context, String key) {
    // Quick fallback if provider is not used in context tree yet
    String lang = 'km';
    try {
      // ignore: depend_on_referenced_packages
      // Will be handled via provider later
    } catch (_) {}
    return _localizedValues[lang]?[key] ?? key;
  }

  static String translate(String lang, String key) {
    return _localizedValues[lang]?[key] ?? key;
  }
}
