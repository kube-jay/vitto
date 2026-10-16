import 'package:intl/intl.dart';

import '../config/market.dart';

/// An amount in integer minor units. Never use floating point for prices.
class Money {
  const Money(this.minor, this.currencyCode);

  final int minor;
  final String currencyCode;

  int get _exponent => Market.fromCurrencyCode(currencyCode).currencyExponent;

  /// Formats for display in [locale]; the currency itself never changes.
  String format(String locale) {
    final symbol = switch (currencyCode) {
      'NGN' => '₦',
      'XOF' => 'FCFA',
      _ => currencyCode,
    };
    final formatter = NumberFormat.currency(
      locale: locale,
      name: currencyCode,
      symbol: symbol,
      decimalDigits: _exponent,
    );
    return formatter.format(minor / _pow10(_exponent));
  }

  /// Parses a user-entered major-unit amount ("1500" or "1500.50").
  /// Returns null when the input is invalid or has too many decimals.
  static Money? tryParse(String input, String currencyCode) {
    final exponent = Market.fromCurrencyCode(currencyCode).currencyExponent;
    final cleaned = input.replaceAll(RegExp(r'[\s,]'), '');
    final match = RegExp(r'^(\d+)(?:\.(\d+))?$').firstMatch(cleaned);
    if (match == null) return null;
    final fraction = match.group(2) ?? '';
    if (fraction.length > exponent) return null;
    final minor =
        int.parse(match.group(1)!) * _pow10(exponent) +
        (fraction.isEmpty ? 0 : int.parse(fraction.padRight(exponent, '0')));
    return Money(minor, currencyCode);
  }

  static int _pow10(int e) {
    var r = 1;
    for (var i = 0; i < e; i++) {
      r *= 10;
    }
    return r;
  }

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.minor == minor &&
      other.currencyCode == currencyCode;

  @override
  int get hashCode => Object.hash(minor, currencyCode);

  @override
  String toString() => 'Money($minor $currencyCode)';
}
