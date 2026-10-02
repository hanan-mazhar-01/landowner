import 'package:url_launcher/url_launcher.dart';

/// Opens the native phone / Messages / WhatsApp / Mail apps with a drafted note.
/// Nothing is sent until the user taps send in that app.
abstract final class ContactLauncher {
  static String _digits(String phone) => phone.replaceAll(RegExp(r'[^0-9+]'), '');

  static Future<bool> call(String phone) => _open(Uri(scheme: 'tel', path: _digits(phone)));

  static Future<bool> message(String phone, String body) =>
      _open(Uri(scheme: 'sms', path: _digits(phone), queryParameters: {'body': body}));

  /// Opens a WhatsApp chat with [text] drafted. WhatsApp needs the number in
  /// international form, so a local number ("0300 1234567") gets the owner's
  /// country code ([dialCode], e.g. "92") in place of its leading 0.
  static Future<bool> whatsapp(String phone, String text, {String? dialCode}) {
    final number = internationalDigits(phone, dialCode: dialCode);
    if (number.isEmpty) return Future.value(false);
    return _open(Uri.https('wa.me', '/$number', {if (text.isNotEmpty) 'text': text}));
  }

  /// "+92 300 1234567" / "0092…" / "0300…" (with dialCode 92) → "923001234567".
  static String internationalDigits(String phone, {String? dialCode}) {
    final raw = phone.trim();
    var d = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.startsWith('+')) return d;
    if (d.startsWith('00')) return d.substring(2);
    if (d.startsWith('0') && dialCode != null && dialCode.isNotEmpty) d = '$dialCode${d.substring(1)}';
    return d;
  }

  static Future<bool> email(String to, {required String subject, String body = ''}) =>
      _open(Uri(scheme: 'mailto', path: to, queryParameters: {'subject': subject, if (body.isNotEmpty) 'body': body}));

  static Future<bool> _open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
