// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

void executePrint(String fullHtml, String title, bool isLandscape) {
  // Remove any existing print frame
  html.document.getElementById('bls_html_print_frame')?.remove();

  final blob = html.Blob([fullHtml], 'text/html;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);

  final iframe = html.IFrameElement()
    ..id = 'bls_html_print_frame'
    ..src = url
    ..style.position = 'fixed'
    ..style.right = '0'
    ..style.bottom = '0'
    ..style.width = '10px'
    ..style.height = '10px'
    ..style.opacity = '0.01'
    ..style.pointerEvents = 'none'
    ..style.border = '0';

  html.document.body?.append(iframe);

  // Revoke blob URL and remove iframe after dialog completes
  Future.delayed(const Duration(seconds: 20), () {
    try {
      iframe.remove();
      html.Url.revokeObjectUrl(url);
    } catch (_) {}
  });
}
