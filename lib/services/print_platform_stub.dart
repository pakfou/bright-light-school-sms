import 'dart:convert';
import 'dart:io';
import '../utils/string_utils.dart';

void executePrint(String fullHtml, String title, bool isLandscape) {
  try {
    final tempDir = Directory.systemTemp;
    final sanitizedTitle = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    // ignore: unnecessary_brace_in_string_interps
    final file = File('${tempDir.path}\\bls_print_${sanitizedTitle}.html');
    final safeHtml = fullHtml.toWellFormed();
    file.writeAsStringSync(safeHtml, encoding: utf8);

    if (Platform.isWindows) {
      Process.run('cmd', ['/c', 'start', '', file.path]);
    } else if (Platform.isMacOS) {
      Process.run('open', [file.path]);
    } else if (Platform.isLinux) {
      Process.run('xdg-open', [file.path]);
    }
  } catch (e) {
    // ignore: avoid_print
    print('Desktop print error: $e');
  }
}
