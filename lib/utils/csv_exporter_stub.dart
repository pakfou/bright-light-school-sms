import 'dart:convert';
import 'dart:io';
import 'string_utils.dart';

void downloadCsv(String csvData, String filename) {
  try {
    final userProfile = Platform.environment['USERPROFILE'] ?? '.';
    final downloadsDir = Directory('$userProfile\\Downloads');
    final targetDir = downloadsDir.existsSync() ? downloadsDir : Directory.current;
    final file = File('${targetDir.path}\\$filename');
    final safeData = csvData.toWellFormed();
    file.writeAsStringSync('\uFEFF$safeData', encoding: utf8);
    // ignore: avoid_print
    print('CSV Exported to: ${file.path}');
  } catch (e) {
    // ignore: avoid_print
    print('Error saving CSV: $e');
  }
}
