import 'dart:io';

void main() {
  final file = File('lib/screens/dashboard/overview_dashboard_view.dart');
  var content = file.readAsStringSync();

  content = content.replaceAll(
    "import 'package:google_fonts/google_fonts.dart';",
    "",
  );
  content = content.replaceAll(
    "GoogleFonts.notoSansKhmer(",
    "TextStyle(fontFamily: 'Khmer OS Battambang', ",
  );
  content = content.replaceAll(
    "GoogleFonts.outfit(",
    "TextStyle(fontFamily: 'Calibri Light', ",
  );

  file.writeAsStringSync(content);
  // ignore: avoid_print
  print('Done fixing fonts');
}
