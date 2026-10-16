import '../../../core/utils/money.dart';
import 'offer_status.dart';

/// A structured price Offer (Part I §9) – never just a chat message.
class Offer {
  const Offer({
    required this.id,
    required this.conversationId,
    required this.listingId,
    required this.proposerId,
    required this.recipientId,
    required this.amountMinor,
    required this.currency,
    required this.status,
    this.parentOfferId,
    required this.expiresAt,
    required this.createdAt,
  });

  final String id;
  final String conversationId;
  final String listingId;
  final String proposerId;
  final String recipientId;
  final int amountMinor;
  final String currency;
  final OfferStatus status;
  final String? parentOfferId;
  final DateTime expiresAt;
  final DateTime createdAt;

  Money get amount => Money(amountMinor, currency);

  /// Pending offers past their TTL are shown as expired (DEC-12); the
  /// server marks them expired on the next action.
  OfferStatus get effectiveStatus =>
      status == OfferStatus.pending && expiresAt.isBefore(DateTime.now())
      ? OfferStatus.expired
      : status;

  factory Offer.fromJson(Map<String, dynamic> j) => Offer(
    id: j['id'] as String,
    conversationId: j['conversation_id'] as String,
    listingId: j['listing_id'] as String,
    proposerId: j['proposer_id'] as String,
    recipientId: j['recipient_id'] as String,
    amountMinor: (j['amount_minor'] as num).toInt(),
    currency: j['currency'] as String,
    status: OfferStatus.fromWire(j['status'] as String),
    parentOfferId: j['parent_offer_id'] as String?,
    expiresAt: DateTime.parse(j['expires_at'] as String),
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}
