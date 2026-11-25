/// Strips every non-digit character, producing the digits-only international
/// number that wa.me links expect (e.g. `"+961 70 123 456"` → `"96170123456"`).
String digitsOnly(String phone) => phone.replaceAll(RegExp(r'\D'), '');
