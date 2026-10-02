import 'package:flutter/foundation.dart';

/// A currency the app can display amounts in.
@immutable
class CurrencyInfo {
  const CurrencyInfo(this.code, this.symbol, this.name);
  final String code, symbol, name;
}

/// A country offered during setup, with its ISO code, default currency and
/// international dialling code (used to open WhatsApp chats).
@immutable
class CountryInfo {
  const CountryInfo(this.iso, this.name, this.currency, this.dial);
  final String iso, name, currency, dial;
}

/// Countries and currencies used by location setup and Settings.
abstract final class Regions {
  static const currencies = [
    CurrencyInfo('PKR', 'Rs', 'Pakistani Rupee'),
    CurrencyInfo('USD', '\$', 'US Dollar'),
    CurrencyInfo('AED', 'AED', 'UAE Dirham'),
    CurrencyInfo('SAR', 'SAR', 'Saudi Riyal'),
    CurrencyInfo('QAR', 'QAR', 'Qatari Riyal'),
    CurrencyInfo('KWD', 'KWD', 'Kuwaiti Dinar'),
    CurrencyInfo('OMR', 'OMR', 'Omani Rial'),
    CurrencyInfo('BHD', 'BHD', 'Bahraini Dinar'),
    CurrencyInfo('GBP', '£', 'British Pound'),
    CurrencyInfo('EUR', '€', 'Euro'),
    CurrencyInfo('CAD', 'CA\$', 'Canadian Dollar'),
    CurrencyInfo('AUD', 'A\$', 'Australian Dollar'),
    CurrencyInfo('NZD', 'NZ\$', 'New Zealand Dollar'),
    CurrencyInfo('INR', '₹', 'Indian Rupee'),
    CurrencyInfo('BDT', '৳', 'Bangladeshi Taka'),
    CurrencyInfo('LKR', 'LKR', 'Sri Lankan Rupee'),
    CurrencyInfo('MYR', 'RM', 'Malaysian Ringgit'),
    CurrencyInfo('SGD', 'S\$', 'Singapore Dollar'),
    CurrencyInfo('TRY', '₺', 'Turkish Lira'),
    CurrencyInfo('EGP', 'E£', 'Egyptian Pound'),
    CurrencyInfo('ZAR', 'R', 'South African Rand'),
    CurrencyInfo('NGN', '₦', 'Nigerian Naira'),
    CurrencyInfo('KES', 'KSh', 'Kenyan Shilling'),
    CurrencyInfo('CHF', 'CHF', 'Swiss Franc'),
    CurrencyInfo('JPY', '¥', 'Japanese Yen'),
    CurrencyInfo('CNY', 'CN¥', 'Chinese Yuan'),
  ];

  static const countries = [
    CountryInfo('PK', 'Pakistan', 'PKR', '92'),
    CountryInfo('AE', 'United Arab Emirates', 'AED', '971'),
    CountryInfo('SA', 'Saudi Arabia', 'SAR', '966'),
    CountryInfo('QA', 'Qatar', 'QAR', '974'),
    CountryInfo('KW', 'Kuwait', 'KWD', '965'),
    CountryInfo('OM', 'Oman', 'OMR', '968'),
    CountryInfo('BH', 'Bahrain', 'BHD', '973'),
    CountryInfo('US', 'United States', 'USD', '1'),
    CountryInfo('GB', 'United Kingdom', 'GBP', '44'),
    CountryInfo('CA', 'Canada', 'CAD', '1'),
    CountryInfo('AU', 'Australia', 'AUD', '61'),
    CountryInfo('NZ', 'New Zealand', 'NZD', '64'),
    CountryInfo('IN', 'India', 'INR', '91'),
    CountryInfo('BD', 'Bangladesh', 'BDT', '880'),
    CountryInfo('LK', 'Sri Lanka', 'LKR', '94'),
    CountryInfo('MY', 'Malaysia', 'MYR', '60'),
    CountryInfo('SG', 'Singapore', 'SGD', '65'),
    CountryInfo('TR', 'Turkey', 'TRY', '90'),
    CountryInfo('EG', 'Egypt', 'EGP', '20'),
    CountryInfo('ZA', 'South Africa', 'ZAR', '27'),
    CountryInfo('NG', 'Nigeria', 'NGN', '234'),
    CountryInfo('KE', 'Kenya', 'KES', '254'),
    CountryInfo('DE', 'Germany', 'EUR', '49'),
    CountryInfo('FR', 'France', 'EUR', '33'),
    CountryInfo('IT', 'Italy', 'EUR', '39'),
    CountryInfo('ES', 'Spain', 'EUR', '34'),
    CountryInfo('NL', 'Netherlands', 'EUR', '31'),
    CountryInfo('IE', 'Ireland', 'EUR', '353'),
    CountryInfo('BE', 'Belgium', 'EUR', '32'),
    CountryInfo('PT', 'Portugal', 'EUR', '351'),
    CountryInfo('AT', 'Austria', 'EUR', '43'),
    CountryInfo('GR', 'Greece', 'EUR', '30'),
    CountryInfo('FI', 'Finland', 'EUR', '358'),
    CountryInfo('CH', 'Switzerland', 'CHF', '41'),
    CountryInfo('JP', 'Japan', 'JPY', '81'),
    CountryInfo('CN', 'China', 'CNY', '86'),
  ];

  /// Pinned first in pickers; the rest follow alphabetically.
  static const _pinned = ['Pakistan', 'United Arab Emirates', 'Saudi Arabia', 'United States', 'United Kingdom'];

  static List<String> get countryNames => [
        ..._pinned,
        ...([for (final c in countries) c.name]..removeWhere(_pinned.contains)..sort()),
        'Other',
      ];

  static CurrencyInfo? currency(String code) {
    for (final c in currencies) {
      if (c.code == code) return c;
    }
    return null;
  }

  static CountryInfo? countryByIso(String? iso) {
    if (iso == null) return null;
    for (final c in countries) {
      if (c.iso == iso.toUpperCase()) return c;
    }
    return null;
  }

  static CountryInfo? countryByName(String name) {
    for (final c in countries) {
      if (c.name == name) return c;
    }
    return null;
  }
}
