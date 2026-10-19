import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../utils/app_logo.dart';

class IdCardView extends StatelessWidget {
  const IdCardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 360,
        height: 520,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
            ),
          ],
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Container(
              height: 115,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppLogo.widget(width: 38, height: 38, shape: BoxShape.circle),
                  const SizedBox(height: 6),
                  const Text(
                    'សាលាប្រាយឡាយ',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Text(
                    'BRIGHT LIGHT PRIMARY SCHOOL',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 46,
              backgroundColor: Color(0xFF2563EB),
              child: Icon(Icons.person, size: 52, color: Colors.white),
            ),
            const SizedBox(height: 12),
            const Text(
              'ហាក់ ប៉ាក់ហ៊្វូរ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const Text(
              'កូដសម្គាល់៖ BLS-202601',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'សិស្សពេញម៉ោង • ថ្នាក់ទី ៥ (វេនព្រឹក)',
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const Spacer(),
            QrImageView(
              data: 'BLS-202601',
              version: QrVersions.auto,
              size: 120.0,
            ),
            const Spacer(),
            const Text(
              'កាតសម្គាល់ផ្លូវការ • Studies Pro',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
