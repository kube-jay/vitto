import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_provider.dart';
import '../../auth/data/session_provider.dart';
import '../../listings/domain/listing.dart';

class FavoritesRepository {
  FavoritesRepository(this._db);

  final SupabaseClient _db;

  Future<Set<String>> ids() async {
    final rows = await _db.from('favorites').select('listing_id');
    return {for (final r in rows) r['listing_id'] as String};
  }

  Future<List<Listing>> listings() async {
    final rows = await _db
        .from('favorites')
        .select('created_at, listing:listings(${Listing.columns})')
        .order('created_at', ascending: false);
    return [
      for (final r in rows)
        if (r['listing'] != null)
          Listing.fromJson(r['listing'] as Map<String, dynamic>),
    ];
  }

  Future<void> add(String listingId) =>
      _db.from('favorites').insert({'listing_id': listingId});

  Future<void> remove(String listingId) =>
      _db.from('favorites').delete().eq('listing_id', listingId);
}

final favoritesRepositoryProvider = Provider(
  (ref) => FavoritesRepository(ref.watch(supabaseProvider)),
);

/// Favorited Listing ids for heart icons; empty when signed out.
class FavoriteIds extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    if (ref.watch(currentUserIdProvider) == null) return {};
    return ref.watch(favoritesRepositoryProvider).ids();
  }

  Future<void> toggle(String listingId) async {
    final current = {...?state.value};
    final repo = ref.read(favoritesRepositoryProvider);
    if (current.remove(listingId)) {
      state = AsyncData(current);
      await repo.remove(listingId);
    } else {
      state = AsyncData({...current, listingId});
      await repo.add(listingId);
    }
    ref.invalidate(favoriteListingsProvider);
  }
}

final favoriteIdsProvider = AsyncNotifierProvider<FavoriteIds, Set<String>>(
  FavoriteIds.new,
);

final favoriteListingsProvider = FutureProvider.autoDispose<List<Listing>>(
  (ref) => ref.watch(favoritesRepositoryProvider).listings(),
);
