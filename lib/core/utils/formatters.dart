import 'package:intl/intl.dart';

/// Currency formatting exactly as the design writes it:
/// `Rs124.8M`, `Rs46K`, `Rs42.5K`, `Rs1.25M`, `Rs46,000`.
abstract final class Money {
  static String symbol = 'Rs';
  static final _grouped = NumberFormat.decimalPattern('en_US');

  /// Millions with one decimal — `fM` in the design.
  /// Below a million it falls back to [k] so small values never read "Rs0.0M".
  static String m(num v) => v < 0 ? '−${m(-v)}' : v < 1e6 ? k(v) : '$symbol${(v / 1e6).toStringAsFixed(1)}M';

  /// Thousands, integer when whole — `fK` in the design.
  static String k(num v) {
    if (v < 0) return '−${Money.k(-v)}';
    // Small amounts read better in full than as "Rs0K" / "Rs0.5K".
    if (v < 1000) return full(v);
    final t = v / 1000;
    final s = v % 1000 == 0 ? t.toStringAsFixed(0) : t.toStringAsFixed(1);
    return '$symbol${s.endsWith('.0') ? s.substring(0, s.length - 2) : s}K';
  }

  /// Compact — K below a million, M with two decimals above (`fKK`).
  static String compact(num v) {
    if (v < 0) return '−${compact(-v)}';
    return v >= 1e6 ? '$symbol${(v / 1e6).toStringAsFixed(2)}M' : k(v);
  }

  /// Full grouped amount — `Rs46,000`.
  static String full(num v) => '$symbol${_grouped.format(v.round())}';

  /// Signed short amount for ledgers — `+Rs120K` / `−Rs20K`.
  static String signed(num v) => '${v >= 0 ? '+' : '−'}${k(v.abs())}';

  /// Plain grouped digits for inputs — `18,500,000`.
  static String digits(num v) => _grouped.format(v.round());

  /// Parses user input like "18,500,000" → 18500000.
  static int parse(String? s) => int.tryParse((s ?? '').replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
}

abstract final class Dates {
  static DateFormat _dMy = DateFormat('d MMM y');

  /// Full-date pattern from Preferences → Date format.
  static void setPattern(String p) => _dMy = DateFormat(p);
  static final _dM = DateFormat('d MMM');
  static final _ddM = DateFormat('dd MMM');
  static final _mY = DateFormat('MMM y');
  static final _long = DateFormat('EEEE, d MMMM');
  static final _hm = DateFormat('HH:mm');
  static final _month = DateFormat('MMMM');
  static final _mon = DateFormat('MMM');

  static String dMy(DateTime d) => _dMy.format(d); // 26 Sep 2026
  static String dM(DateTime d) => _dM.format(d); // 29 Sep
  static String ddM(DateTime d) => _ddM.format(d); // 04 Oct
  static String my(DateTime d) => _mY.format(d); // Mar 2027
  static String longDay(DateTime d) => _long.format(d); // Tuesday, 29 September
  static String hm(DateTime d) => _hm.format(d); // 09:00
  static String month(DateTime d) => _month.format(d); // September
  static String mon(DateTime d) => _mon.format(d); // Sep

  static String ordinal(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    return switch (day % 10) { 1 => '${day}st', 2 => '${day}nd', 3 => '${day}rd', _ => '${day}th' };
  }

  /// "Today", "Yesterday" or "27 Sep".
  static String relativeDay(DateTime d, DateTime today) {
    final diff = DateTime(today.year, today.month, today.day).difference(DateTime(d.year, d.month, d.day)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return dM(d);
  }

  /// "now", "2h", "1d" — notification timestamps.
  static String ago(DateTime d, DateTime now) {
    final m = now.difference(d).inMinutes;
    if (m < 1) return 'now';
    if (m < 60) return '${m}m';
    if (m < 60 * 24) return '${m ~/ 60}h';
    return '${m ~/ (60 * 24)}d';
  }

  /// Calendar-aware month arithmetic (clamps 31 Jan + 1 → 28/29 Feb).
  static DateTime addMonths(DateTime d, int months) {
    final t = DateTime(d.year, d.month + months); // DateTime normalises overflow
    final last = DateTime(t.year, t.month + 1, 0).day;
    return DateTime(t.year, t.month, d.day > last ? last : d.day, d.hour, d.minute);
  }

  static DateTime monthStart(DateTime d) => DateTime(d.year, d.month);
}
