import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_provider.dart';
import '../../auth/data/session_provider.dart';
import '../domain/rating.dart';

class RatingRepository {
  RatingRepository(this._db);

  final SupabaseClient _db;

  Future<List<Rating>> forUser(String userId) async {
    final rows = await _db
        .from('ratings')
        .select(Rating.columns)
        .eq('recipient_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
    return rows.map(Rating.fromJson).toList();
  }

  Future<Rating?> mineForDeal(String dealId, String uid) async {
    final row = await _db
        .from('ratings')
        .select(Rating.columns)
        .eq('deal_id', dealId)
        .eq('author_id', uid)
        .maybeSingle();
    return row == null ? null : Rating.fromJson(row);
  }

  /// Server checks: Deal completed, caller is a participant, once per side.
  Future<void> submit(String dealId, int stars, String? comment) => _db.rpc(
    'rating_submit',
    params: {'p_deal_id': dealId, 'p_stars': stars, 'p_comment': comment},
  );
}

final ratingRepositoryProvider = Provider(
  (ref) => RatingRepository(ref.watch(supabaseProvider)),
);

final userRatingsProvider = FutureProvider.autoDispose
    .family<List<Rating>, String>(
      (ref, uid) => ref.watch(ratingRepositoryProvider).forUser(uid),
    );

final myDealRatingProvider = FutureProvider.autoDispose.family<Rating?, String>(
  (ref, dealId) async {
    final uid = ref.watch(currentUserIdProvider);
    if (uid == null) return null;
    return ref.watch(ratingRepositoryProvider).mineForDeal(dealId, uid);
  },
);
