import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class AppAvatar extends StatelessWidget {
  final dynamic photoUrl;
  final double radius;
  final String fallbackText;

  const AppAvatar({
    super.key,
    required this.photoUrl,
    this.radius = 24,
    this.fallbackText = '',
  });

  @override
  Widget build(BuildContext context) {
    final str = (photoUrl ?? '').toString().trim();

    if (str.isEmpty) {
      return _buildFallback();
    }

    // ១. បើជារូបភាព Base64 (Decode ដោយមាន Cache និងកម្រិតទំហំមិនឱ្យគាំង)
    if (str.startsWith('data:image')) {
      try {
        final commaIdx = str.indexOf(',');
        final base64Data = commaIdx != -1 ? str.substring(commaIdx + 1) : str;
        final Uint8List bytes = base64Decode(base64Data);

        return ClipOval(
          child: Image.memory(
            bytes,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            cacheWidth: (radius * 4)
                .toInt(), // កាត់បន្ថយទំហំ RAM ការពារការគាំងលើ Web
            cacheHeight: (radius * 4).toInt(),
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => _buildFallback(),
          ),
        );
      } catch (_) {
        return _buildFallback();
      }
    }

    // ២. បើជា Network URL
    if (str.startsWith('http://') || str.startsWith('https://')) {
      return ClipOval(
        child: Image.network(
          str,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          cacheWidth: (radius * 4).toInt(),
          cacheHeight: (radius * 4).toInt(),
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => _buildFallback(),
        ),
      );
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFEEF2FF),
      child: fallbackText.trim().isNotEmpty
          ? Text(
              fallbackText.trim()[0].toUpperCase(),
              style: TextStyle(
                color: const Color(0xFF4F46E5),
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.8,
              ),
            )
          : const Icon(Icons.person, color: Color(0xFF4F46E5)),
    );
  }
}
