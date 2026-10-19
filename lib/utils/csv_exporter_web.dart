// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'string_utils.dart';

void downloadCsv(String csvData, String filename) {
  try {
    final safeData = csvData.toWellFormed();
    final bytes = [0xEF, 0xBB, 0xBF, ...utf8.encode(safeData)];
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    // ignore: unused_local_variable
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  } catch (e) {
    // ignore: avoid_print
    print('Web CSV download error: $e');
  }
}
