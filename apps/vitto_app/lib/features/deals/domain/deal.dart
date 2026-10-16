import '../../../core/utils/money.dart';
import '../../listings/domain/listing.dart';
import '../../profile/domain/profile.dart';
import 'deal_status.dart';

/// Created when an Offer is accepted (Part I §10). Price is a snapshot.
class Deal {
  const Deal({
    required this.id,
    required this.listingId,
    required this.conversationId,
    required this.buyerId,
    required this.sellerId,
    required this.originalAmountMinor,
    required this.agreedAmountMinor,
    required this.currency,
    this.transactionType,
    required this.status,
    this.confirmationProblemAt,
    this.confirmationProblemNote,
    required this.createdAt,
    this.completedAt,
    this.listing,
    this.buyer,
    this.seller,
  });

  final String id;
  final String listingId;
  final String conversationId;
  final String buyerId;
  final String sellerId;
  final int originalAmountMinor;
  final int agreedAmountMinor;
  final String currency;
  final TransactionType? transactionType;
  final DealStatus status;
  final DateTime? confirmationProblemAt;
  final String? confirmationProblemNote;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Listing? listing;
  final Profile? buyer;
  final Profile? seller;

  Money get agreed => Money(agreedAmountMinor, currency);
  Money get original => Money(originalAmountMinor, currency);

  bool isBuyer(String? uid) => uid == buyerId;
  bool isSeller(String? uid) => uid == sellerId;
  Profile? counterpart(String? uid) => isBuyer(uid) ? seller : buyer;

  static const baseColumns =
      'id,listing_id,conversation_id,buyer_id,seller_id,original_amount_minor,'
      'agreed_amount_minor,currency,transaction_type,status,'
      'confirmation_problem_at,confirmation_problem_note,created_at,completed_at';

  static const columns =
      '$baseColumns,'
      'listing:listings(${Listing.columns}),'
      'buyer:profiles!deals_buyer_id_fkey(${Profile.columns}),'
      'seller:profiles!deals_seller_id_fkey(${Profile.columns})';

  factory Deal.fromJson(Map<String, dynamic> j) => Deal(
    id: j['id'] as String,
    listingId: j['listing_id'] as String,
    conversationId: j['conversation_id'] as String,
    buyerId: j['buyer_id'] as String,
    sellerId: j['seller_id'] as String,
    originalAmountMinor: (j['original_amount_minor'] as num).toInt(),
    agreedAmountMinor: (j['agreed_amount_minor'] as num).toInt(),
    currency: j['currency'] as String,
    transactionType: TransactionType.fromWire(j['transaction_type'] as String?),
    status: DealStatus.fromWire(j['status'] as String),
    confirmationProblemAt: j['confirmation_problem_at'] == null
        ? null
        : DateTime.parse(j['confirmation_problem_at'] as String),
    confirmationProblemNote: j['confirmation_problem_note'] as String?,
    createdAt: DateTime.parse(j['created_at'] as String),
    completedAt: j['completed_at'] == null
        ? null
        : DateTime.parse(j['completed_at'] as String),
    listing: j['listing'] is Map<String, dynamic>
        ? Listing.fromJson(j['listing'] as Map<String, dynamic>)
        : null,
    buyer: j['buyer'] is Map<String, dynamic>
        ? Profile.fromJson(j['buyer'] as Map<String, dynamic>)
        : null,
    seller: j['seller'] is Map<String, dynamic>
        ? Profile.fromJson(j['seller'] as Map<String, dynamic>)
        : null,
  );

  /// Copy with fresh scalar fields (from a realtime row) and the same joins.
  Deal mergeRow(Map<String, dynamic> row) {
    final fresh = Deal.fromJson(row);
    return Deal(
      id: fresh.id,
      listingId: fresh.listingId,
      conversationId: fresh.conversationId,
      buyerId: fresh.buyerId,
      sellerId: fresh.sellerId,
      originalAmountMinor: fresh.originalAmountMinor,
      agreedAmountMinor: fresh.agreedAmountMinor,
      currency: fresh.currency,
      transactionType: fresh.transactionType,
      status: fresh.status,
      confirmationProblemAt: fresh.confirmationProblemAt,
      confirmationProblemNote: fresh.confirmationProblemNote,
      createdAt: fresh.createdAt,
      completedAt: fresh.completedAt,
      listing: listing,
      buyer: buyer,
      seller: seller,
    );
  }
}

/// Buyer → Vitto. Status comes only from provider-verified server events.
class Payment {
  const Payment({
    required this.id,
    required this.provider,
    required this.reference,
    required this.status,
    required this.amountMinor,
    required this.currency,
    required this.createdAt,
  });

  final String id;
  final String provider;
  final String reference;
  final String status; // initialized | pending | successful | failed | refunded
  final int amountMinor;
  final String currency;
  final DateTime createdAt;

  static const columns =
      'id,deal_id,provider,provider_reference,amount_minor,currency,status,'
      'created_at';

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
    id: j['id'] as String,
    provider: j['provider'] as String,
    reference: j['provider_reference'] as String,
    status: j['status'] as String,
    amountMinor: (j['amount_minor'] as num).toInt(),
    currency: j['currency'] as String,
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}

/// Vitto → seller. A separate record from Payment (Part I §12).
class Payout {
  const Payout({
    required this.dealId,
    required this.status,
    required this.amountMinor,
    required this.currency,
  });

  final String dealId;
  final String
  status; // not_eligible | eligible | requested | paid | failed | reversed
  final int amountMinor;
  final String currency;

  factory Payout.fromJson(Map<String, dynamic> j) => Payout(
    dealId: j['deal_id'] as String,
    status: j['status'] as String,
    amountMinor: (j['amount_minor'] as num).toInt(),
    currency: j['currency'] as String,
  );
}
