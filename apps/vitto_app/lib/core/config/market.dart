import 'package:flutter/widgets.dart';

/// The two MVP markets. Country and currency are fixed pairs (DEC-08):
/// a Listing's currency is set by its country and is never converted.
enum Market {
  nigeria(
    countryCode: 'NG',
    currencyCode: 'NGN',
    currencyExponent: 2,
    defaultLocale: Locale('en'),
  ),
  benin(
    countryCode: 'BJ',
    currencyCode: 'XOF',
    currencyExponent: 0,
    defaultLocale: Locale('fr'),
  );

  const Market({
    required this.countryCode,
    required this.currencyCode,
    required this.currencyExponent,
    required this.defaultLocale,
  });

  final String countryCode;
  final String currencyCode;

  /// Number of minor-unit digits used when storing prices as integers.
  final int currencyExponent;
  final Locale defaultLocale;

  static Market fromCountryCode(String code) => Market.values.firstWhere(
    (m) => m.countryCode == code.toUpperCase(),
    orElse: () => throw ArgumentError.value(code, 'code', 'Unknown country'),
  );

  static Market fromCurrencyCode(String code) => Market.values.firstWhere(
    (m) => m.currencyCode == code.toUpperCase(),
    orElse: () => throw ArgumentError.value(code, 'code', 'Unknown currency'),
  );
}
