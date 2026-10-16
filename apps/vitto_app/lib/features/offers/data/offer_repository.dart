import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_provider.dart';
import '../domain/offer.dart';

/// All Offer transitions run server-side (offer_create / offer_respond /
/// offer_cancel). The client never writes Offer rows.
class OfferRepository {
  OfferRepository(this._db);

  final SupabaseClient _db;

  Stream<List<Offer>> forConversation(String conversationId) => _db
      .from('offers')
      .stream(primaryKey: ['id'])
      .eq('conversation_id', conversationId)
      .order('created_at', ascending: true)
      .map((rows) => rows.map(Offer.fromJson).toList());

  Future<void> create(String conversationId, int amountMinor) => _db.rpc(
    'offer_create',
    params: {
      'p_conversation_id': conversationId,
      'p_amount_minor': amountMinor,
    },
  );

  Future<void> reject(String offerId) => _db.rpc(
    'offer_respond',
    params: {'p_offer_id': offerId, 'p_action': 'reject'},
  );

  Future<void> counter(String offerId, int amountMinor) => _db.rpc(
    'offer_respond',
    params: {
      'p_offer_id': offerId,
      'p_action': 'counter',
      'p_counter_amount_minor': amountMinor,
    },
  );

  /// Returns the created Deal id.
  Future<String> accept(String offerId) async {
    final res = await _db.rpc<Map<String, dynamic>>(
      'offer_respond',
      params: {'p_offer_id': offerId, 'p_action': 'accept'},
    );
    return res['deal_id'] as String;
  }

  Future<void> cancel(String offerId) =>
      _db.rpc('offer_cancel', params: {'p_offer_id': offerId});

  Future<String?> dealIdForConversation(String conversationId) async {
    final row = await _db
        .from('deals')
        .select('id')
        .eq('conversation_id', conversationId)
        .neq('status', 'cancelled')
        .maybeSingle();
    return row?['id'] as String?;
  }
}

final offerRepositoryProvider = Provider(
  (ref) => OfferRepository(ref.watch(supabaseProvider)),
);

final conversationOffersProvider = StreamProvider.autoDispose
    .family<List<Offer>, String>(
      (ref, id) => ref.watch(offerRepositoryProvider).forConversation(id),
    );

final conversationDealIdProvider = FutureProvider.autoDispose
    .family<String?, String>(
      (ref, id) => ref.watch(offerRepositoryProvider).dealIdForConversation(id),
    );
