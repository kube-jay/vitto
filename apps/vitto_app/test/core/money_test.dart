import 'package:flutter_test/flutter_test.dart';
import 'package:vitto_app/core/config/market.dart';
import 'package:vitto_app/core/utils/money.dart';

void main() {
  group('Market', () {
    test('country and currency are fixed pairs', () {
      expect(Market.fromCountryCode('NG').currencyCode, 'NGN');
      expect(Market.fromCountryCode('bj').currencyCode, 'XOF');
      expect(() => Market.fromCountryCode('GH'), throwsArgumentError);
    });
  });

  group('Money.tryParse', () {
    test('NGN uses two minor digits', () {
      expect(Money.tryParse('1500', 'NGN'), const Money(150000, 'NGN'));
      expect(Money.tryParse('1,500.5', 'NGN'), const Money(150050, 'NGN'));
      expect(Money.tryParse('1.505', 'NGN'), isNull);
    });

    test('XOF has no minor digits', () {
      expect(Money.tryParse('25000', 'XOF'), const Money(25000, 'XOF'));
      expect(Money.tryParse('25000.5', 'XOF'), isNull);
    });

    test('rejects garbage', () {
      expect(Money.tryParse('', 'NGN'), isNull);
      expect(Money.tryParse('-5', 'NGN'), isNull);
      expect(Money.tryParse('abc', 'XOF'), isNull);
    });
  });

  group('Money.format', () {
    test('never converts currency when locale changes (AT-18)', () {
      const price = Money(150000, 'NGN');
      expect(price.format('en'), contains('₦'));
      expect(price.format('fr'), contains('₦'));
      expect(price.format('fr'), isNot(contains('FCFA')));
    });

    test('XOF shows whole units', () {
      expect(const Money(25000, 'XOF').format('fr'), contains('25'));
      expect(const Money(25000, 'XOF').format('fr'), isNot(contains(',00')));
    });
  });
}
