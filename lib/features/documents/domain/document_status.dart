import '../../../app/theme/app_colors.dart';
import 'document_item.dart';

/// Expiry state shared by the vault, detail and property strip.
enum ExpiryState { none, valid, soon, tomorrow, today, expired }

extension DocumentExpiry on DocumentItem {
  static const soonDays = 60;

  ExpiryState stateOn(DateTime today) {
    final d = daysToExpiry(today);
    if (d == null) return ExpiryState.none;
    if (d < 0) return ExpiryState.expired;
    if (d == 0) return ExpiryState.today;
    if (d == 1) return ExpiryState.tomorrow;
    if (d <= soonDays) return ExpiryState.soon;
    return ExpiryState.valid;
  }

  /// "Expires in 14 days" · "Expires tomorrow" · "Expired" · "Verified".
  String statusLabel(DateTime today) => switch (stateOn(today)) {
        ExpiryState.expired => 'Expired',
        ExpiryState.today => 'Expires today',
        ExpiryState.tomorrow => 'Expires tomorrow',
        ExpiryState.soon => 'Expires in ${daysToExpiry(today)} days',
        ExpiryState.valid => 'Valid',
        ExpiryState.none => verified ? 'Verified' : 'No expiry',
      };

  Tone toneOn(DateTime today) => switch (stateOn(today)) {
        ExpiryState.expired => Tone.bad,
        ExpiryState.today || ExpiryState.tomorrow || ExpiryState.soon => Tone.warn,
        ExpiryState.valid => Tone.info,
        ExpiryState.none => verified ? Tone.ok : Tone.neutral,
      };
}
