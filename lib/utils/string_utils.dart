/// Utility extensions for string sanitization and safe UTF encoding.
extension SafeStringUtf16Helper on String {
  /// Ensures the string is 100% well-formed UTF-16.
  /// Replaces any isolated/unpaired surrogate code units with the Unicode replacement character (\uFFFD).
  String toWellFormed() {
    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      final unit = codeUnitAt(i);
      if (unit >= 0xD800 && unit <= 0xDBFF) {
        // High surrogate
        if (i + 1 < length) {
          final nextUnit = codeUnitAt(i + 1);
          if (nextUnit >= 0xDC00 && nextUnit <= 0xDFFF) {
            // Valid surrogate pair
            buffer.writeCharCode(unit);
            buffer.writeCharCode(nextUnit);
            i++;
            continue;
          }
        }
        // Unpaired high surrogate
        buffer.writeCharCode(0xFFFD);
      } else if (unit >= 0xDC00 && unit <= 0xDFFF) {
        // Unpaired low surrogate
        buffer.writeCharCode(0xFFFD);
      } else {
        buffer.writeCharCode(unit);
      }
    }
    return buffer.toString();
  }
}
