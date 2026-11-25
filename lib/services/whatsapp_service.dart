import 'package:url_launcher/url_launcher.dart';

/// Snackbar text shown when a wa.me link can't be opened.
const whatsAppLaunchFailedMessage = 'Could not open WhatsApp — is it installed?';

/// Builds a `https://wa.me/<digits>` link, optionally with a prefilled
/// message. [digits] must already be digits-only (see `digitsOnly`).
Uri buildWhatsAppUri(String digits, {String? text}) {
  if (text == null) return Uri.parse('https://wa.me/$digits');
  return Uri.parse('https://wa.me/$digits?text=${Uri.encodeComponent(text)}');
}

/// Opens [uri] in the WhatsApp app (or browser fallback). Returns `false` if
/// nothing could handle it; may also throw, as [launchUrl] does.
Future<bool> launchWhatsApp(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);
