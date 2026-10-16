/// Canonical Offer statuses (Part I §9.1). Wire values are exact.
enum OfferStatus {
  pending('pending'),
  accepted('accepted'),
  rejected('rejected'),
  countered('countered'),
  expired('expired'),
  cancelled('cancelled');

  const OfferStatus(this.wire);

  final String wire;

  /// Only a pending Offer can be accepted, rejected or countered.
  bool get isOpen => this == pending;

  static OfferStatus fromWire(String value) => OfferStatus.values.firstWhere(
    (s) => s.wire == value,
    orElse: () => throw ArgumentError.value(value, 'value', 'Unknown status'),
  );
}
