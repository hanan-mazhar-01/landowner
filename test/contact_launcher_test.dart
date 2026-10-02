import 'package:flutter_test/flutter_test.dart';
import 'package:landowner/core/utils/contact_launcher.dart';

void main() {
  test('local numbers get the owner country code for WhatsApp', () {
    expect(ContactLauncher.internationalDigits('0300 1234567', dialCode: '92'), '923001234567');
    expect(ContactLauncher.internationalDigits('03001234567', dialCode: '92'), '923001234567');
  });

  test('international numbers are kept as they are', () {
    expect(ContactLauncher.internationalDigits('+92 300 1234567', dialCode: '971'), '923001234567');
    expect(ContactLauncher.internationalDigits('0092-300-1234567', dialCode: '971'), '923001234567');
    expect(ContactLauncher.internationalDigits('+971 50 123 4567'), '971501234567');
  });

  test('without a known country code a local number is left as typed', () {
    expect(ContactLauncher.internationalDigits('0300 1234567'), '03001234567');
    expect(ContactLauncher.internationalDigits(''), '');
  });
}
