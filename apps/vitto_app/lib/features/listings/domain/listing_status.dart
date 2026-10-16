/// Canonical Listing statuses (Part I §6.1). Wire values are exact.
enum ListingStatus {
  draft('draft'),
  active('active'),
  reserved('reserved'),
  sold('sold'),
  archived('archived'),
  suspended('suspended');

  const ListingStatus(this.wire);

  final String wire;

  /// Only active Listings are publicly discoverable.
  bool get isPubliclyDiscoverable => this == active;

  static ListingStatus fromWire(String value) =>
      ListingStatus.values.firstWhere(
        (s) => s.wire == value,
        orElse: () =>
            throw ArgumentError.value(value, 'value', 'Unknown status'),
      );
}
