import 'package:flutter_test/flutter_test.dart';
import 'package:vitto_app/features/deals/domain/deal_status.dart';
import 'package:vitto_app/features/listings/domain/listing_status.dart';
import 'package:vitto_app/features/offers/domain/offer_status.dart';

void main() {
  test('wire values match Part I exactly', () {
    expect(ListingStatus.values.map((s) => s.wire), [
      'draft',
      'active',
      'reserved',
      'sold',
      'archived',
      'suspended',
    ]);
    expect(OfferStatus.values.map((s) => s.wire), [
      'pending',
      'accepted',
      'rejected',
      'countered',
      'expired',
      'cancelled',
    ]);
    expect(DealStatus.values.map((s) => s.wire), [
      'awaiting_payment',
      'paid',
      'awaiting_handover',
      'completed',
      'cancelled',
      'disputed',
    ]);
  });

  test('round-trips and rejects unknown values', () {
    for (final s in DealStatus.values) {
      expect(DealStatus.fromWire(s.wire), s);
    }
    expect(() => DealStatus.fromWire('shipped'), throwsArgumentError);
    expect(() => OfferStatus.fromWire('bid'), throwsArgumentError);
    expect(() => ListingStatus.fromWire('promoted'), throwsArgumentError);
  });

  test('only completed Deals unlock ratings', () {
    expect(DealStatus.values.where((s) => s.unlocksRatings), [
      DealStatus.completed,
    ]);
  });

  test('only active Listings are discoverable', () {
    expect(ListingStatus.values.where((s) => s.isPubliclyDiscoverable), [
      ListingStatus.active,
    ]);
  });
}
