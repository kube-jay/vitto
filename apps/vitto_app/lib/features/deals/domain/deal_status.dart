/// Canonical Deal statuses (Part I §10.1). Wire values are exact.
enum DealStatus {
  awaitingPayment('awaiting_payment'),
  paid('paid'),
  awaitingHandover('awaiting_handover'),
  completed('completed'),
  cancelled('cancelled'),
  disputed('disputed');

  const DealStatus(this.wire);

  final String wire;

  /// Ratings unlock only after a completed Deal (Part I §16).
  bool get unlocksRatings => this == completed;

  static DealStatus fromWire(String value) => DealStatus.values.firstWhere(
    (s) => s.wire == value,
    orElse: () => throw ArgumentError.value(value, 'value', 'Unknown status'),
  );
}

/// How a Deal is completed (Part I §11). Null until chosen (DEC-11).
enum TransactionType {
  online('online'),
  offline('offline');

  const TransactionType(this.wire);

  final String wire;

  static TransactionType? fromWire(String? value) => value == null
      ? null
      : TransactionType.values.firstWhere((t) => t.wire == value);
}
