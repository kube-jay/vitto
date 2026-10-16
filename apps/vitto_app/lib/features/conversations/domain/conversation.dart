import '../../listings/domain/listing.dart';
import '../../profile/domain/profile.dart';

/// A Listing-linked Conversation between one buyer and the seller.
class Conversation {
  const Conversation({
    required this.id,
    required this.listingId,
    required this.buyerId,
    required this.sellerId,
    required this.lastMessageAt,
    this.listing,
    this.buyer,
    this.seller,
    this.lastReadAt,
  });

  final String id;
  final String listingId;
  final String buyerId;
  final String sellerId;
  final DateTime lastMessageAt;
  final Listing? listing;
  final Profile? buyer;
  final Profile? seller;
  final DateTime? lastReadAt;

  static const columns =
      'id,listing_id,buyer_id,seller_id,last_message_at,'
      'listing:listings(${Listing.columns}),'
      'buyer:profiles!conversations_buyer_id_fkey(${Profile.columns}),'
      'seller:profiles!conversations_seller_id_fkey(${Profile.columns}),'
      'conversation_reads(user_id,last_read_at)';

  Profile? otherParty(String myId) => myId == buyerId ? seller : buyer;
  bool isBuyer(String myId) => myId == buyerId;
  bool get hasUnread =>
      lastReadAt == null || lastMessageAt.isAfter(lastReadAt!);

  factory Conversation.fromJson(Map<String, dynamic> j, {String? myId}) {
    DateTime? lastRead;
    for (final r in (j['conversation_reads'] as List?) ?? const []) {
      final m = r as Map<String, dynamic>;
      if (m['user_id'] == myId) {
        lastRead = DateTime.parse(m['last_read_at'] as String);
      }
    }
    return Conversation(
      id: j['id'] as String,
      listingId: j['listing_id'] as String,
      buyerId: j['buyer_id'] as String,
      sellerId: j['seller_id'] as String,
      lastMessageAt: DateTime.parse(j['last_message_at'] as String),
      listing: j['listing'] is Map<String, dynamic>
          ? Listing.fromJson(j['listing'] as Map<String, dynamic>)
          : null,
      buyer: j['buyer'] is Map<String, dynamic>
          ? Profile.fromJson(j['buyer'] as Map<String, dynamic>)
          : null,
      seller: j['seller'] is Map<String, dynamic>
          ? Profile.fromJson(j['seller'] as Map<String, dynamic>)
          : null,
      lastReadAt: lastRead,
    );
  }
}

class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    this.systemType,
    this.offerId,
    required this.createdAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final String? systemType;
  final String? offerId;
  final DateTime createdAt;

  bool get isSystem => systemType != null;

  factory Message.fromJson(Map<String, dynamic> j) => Message(
    id: j['id'] as String,
    conversationId: j['conversation_id'] as String,
    senderId: j['sender_id'] as String,
    body: (j['body'] as String?) ?? '',
    systemType: j['system_type'] as String?,
    offerId: j['offer_id'] as String?,
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}
