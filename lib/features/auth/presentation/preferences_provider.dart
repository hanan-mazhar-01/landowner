import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/regions.dart';
import '../domain/app_user.dart';
import 'auth_providers.dart';

@immutable
class Preferences {
  const Preferences({
    this.currency = 'PKR · Rs',
    this.dateFormat = '26 Sep 2026',
    this.weekStart = 'Monday',
    this.language = 'English',
    this.biometric = false,
  });

  final String currency, dateFormat, weekStart, language;
  final bool biometric;

  /// "PKR · Rs", "AED · AED " … — letter symbols get a trailing space so
  /// amounts read "AED 1,000" rather than "AED1,000".
  static final currencies = [
    for (final c in Regions.currencies)
      '${c.code} · ${c.symbol}${RegExp(r'^[A-Za-z]{2,}$').hasMatch(c.symbol) ? ' ' : ''}',
  ];
  static const dateFormats = ['26 Sep 2026', '26/09/2026', '09/26/2026', '2026-09-26'];
  static const weekStarts = ['Monday', 'Sunday', 'Saturday'];
  static const languages = ['English'];

  String get symbol => currency.split(' · ').last;
  String get code => currency.split(' · ').first;

  /// Matches a profile currency (from location setup) to a display option.
  static String currencyFor(String code, String symbol) => currencies.firstWhere(
        (c) => c.startsWith('$code · '),
        orElse: () => '$code · $symbol',
      );

  Preferences copyWith({String? currency, String? dateFormat, String? weekStart, String? language, bool? biometric}) =>
      Preferences(
        currency: currency ?? this.currency,
        dateFormat: dateFormat ?? this.dateFormat,
        weekStart: weekStart ?? this.weekStart,
        language: language ?? this.language,
        biometric: biometric ?? this.biometric,
      );
}

/// Display preferences, persisted on the device. Applies the currency symbol
/// and date pattern to the shared formatters (display only — amounts are never
/// converted). Until the user picks a currency here, the one chosen during
/// location setup (stored on the profile) is used.
class PreferencesController extends Notifier<Preferences> {
  static const _kCurrency = 'prefs.currency';
  static const _kDateFormat = 'prefs.dateFormat';
  static const _kBiometric = 'prefs.biometric';

  bool _userPickedCurrency = false;

  @override
  Preferences build() {
    ref.listen<AppUser?>(currentUserProvider, (_, user) => _adoptProfileCurrency(user));
    _restore();
    return const Preferences();
  }

  Future<void> _restore() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final currency = sp.getString(_kCurrency);
      _userPickedCurrency = currency != null;
      final user = ref.read(currentUserProvider);
      _apply(state.copyWith(
        currency: currency ?? (user == null ? null : Preferences.currencyFor(user.currencyCode, user.currencySymbol)),
        dateFormat: sp.getString(_kDateFormat),
        biometric: sp.getBool(_kBiometric),
      ));
    } catch (e) {
      debugPrint('Preferences restore failed: $e');
    }
  }

  void _adoptProfileCurrency(AppUser? user) {
    if (user == null || _userPickedCurrency) return;
    _apply(state.copyWith(currency: Preferences.currencyFor(user.currencyCode, user.currencySymbol)));
  }

  void _apply(Preferences p) {
    Money.symbol = p.symbol;
    Dates.setPattern(switch (p.dateFormat) {
      '26/09/2026' => 'dd/MM/y',
      '09/26/2026' => 'MM/dd/y',
      '2026-09-26' => 'y-MM-dd',
      _ => 'd MMM y',
    });
    state = p;
  }

  Future<void> update(Preferences p) async {
    final currencyChanged = p.currency != state.currency;
    _apply(p);
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_kDateFormat, p.dateFormat);
      await sp.setBool(_kBiometric, p.biometric);
      if (currencyChanged) {
        _userPickedCurrency = true;
        await sp.setString(_kCurrency, p.currency);
        // Keep the profile in step so other devices pick up the same currency.
        final repo = ref.read(authRepositoryProvider);
        final user = repo.currentUser;
        if (user != null) {
          await repo.updateProfile(
            name: user.name,
            email: user.email,
            phone: user.phone,
            currencyCode: p.code,
            currencySymbol: p.symbol.trim(),
          );
        }
      }
    } catch (e) {
      debugPrint('Preferences save failed: $e');
    }
  }
}

final preferencesProvider = NotifierProvider<PreferencesController, Preferences>(PreferencesController.new);
