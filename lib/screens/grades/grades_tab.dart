import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/translations.dart';

class GradesTab extends StatelessWidget {
  final dynamic activeClass;
  const GradesTab({super.key, this.activeClass});

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocaleProvider>(context);
    final lang = loc.locale.languageCode;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppTranslations.translate(lang, 'grades'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add_chart),
                label: Text(
                  lang == 'km' ? 'បញ្ចូលពិន្ទុថ្មី' : 'Enter New Grades',
                ),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  // ignore: deprecated_member_use
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ignore: deprecated_member_use
                    Icon(
                      Icons.grading_rounded,
                      size: 100,
                      // ignore: deprecated_member_use
                      color: Colors.blue.withOpacity(0.2),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      lang == 'km'
                          ? 'មិនទាន់មានទិន្នន័យពិន្ទុនៅឡើយទេ'
                          : 'No Grades Entered Yet',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
