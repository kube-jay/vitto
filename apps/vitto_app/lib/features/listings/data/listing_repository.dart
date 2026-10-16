import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/supabase_provider.dart';
import '../../auth/data/session_provider.dart';
import '../domain/listing.dart';
import '../domain/listing_status.dart';

/// Editable Listing fields. Currency is derived by the server from country.
class ListingDraft {
  const ListingDraft({
    required this.categoryId,
    required this.title,
    required this.description,
    required this.priceMinor,
    required this.negotiable,
    required this.condition,
    required this.countryCode,
    this.regionCode,
    required this.city,
  });

  final String categoryId;
  final String title;
  final String description;
  final int priceMinor;
  final bool negotiable;
  final String condition;
  final String countryCode;
  final String? regionCode;
  final String city;

  Map<String, dynamic> toJson() => {
    'category_id': categoryId,
    'title': title.trim(),
    'description': description.trim(),
    'price_minor': priceMinor,
    'negotiable': negotiable,
    'condition': condition,
    'country_code': countryCode,
    'region_code': regionCode,
    'city': city.trim(),
  };
}

class ListingRepository {
  ListingRepository(this._db);

  final SupabaseClient _db;

  Future<Listing?> byId(String id) async {
    final row = await _db
        .from('listings')
        .select(Listing.detailColumns)
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Listing.fromJson(row);
  }

  Future<List<Listing>> mine(String uid) async {
    final rows = await _db
        .from('listings')
        .select(Listing.columns)
        .eq('seller_id', uid)
        .order('updated_at', ascending: false);
    return rows.map(Listing.fromJson).toList();
  }

  Future<List<Listing>> activeBySeller(String uid) async {
    final rows = await _db
        .from('listings')
        .select(Listing.columns)
        .eq('seller_id', uid)
        .eq('status', 'active')
        .order('published_at', ascending: false);
    return rows.map(Listing.fromJson).toList();
  }

  Future<String> create(ListingDraft draft) async {
    final row = await _db
        .from('listings')
        .insert(draft.toJson())
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<void> update(String id, ListingDraft draft) =>
      _db.from('listings').update(draft.toJson()).eq('id', id);

  Future<void> deleteDraft(String id) =>
      _db.from('listings').delete().eq('id', id);

  Future<void> setStatus(String id, ListingStatus status) => _db.rpc(
    'listing_set_status',
    params: {'p_listing_id': id, 'p_status': status.wire},
  );

  /// Uploads to `uid/listing/uuid.ext` and links the image row.
  Future<String> addImage({
    required String uid,
    required String listingId,
    required Uint8List bytes,
    required String mime,
    required int sortOrder,
  }) async {
    final ext = switch (mime) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => 'jpg',
    };
    final path = '$uid/$listingId/${const Uuid().v4()}.$ext';
    await _db.storage
        .from('listing-images')
        .uploadBinary(path, bytes, fileOptions: FileOptions(contentType: mime));
    await _db.from('listing_images').insert({
      'listing_id': listingId,
      'storage_path': path,
      'sort_order': sortOrder,
    });
    return path;
  }

  Future<void> removeImage(String path) async {
    await _db.from('listing_images').delete().eq('storage_path', path);
    await _db.storage.from('listing-images').remove([path]);
  }

  Future<void> reorderImages(List<String> paths) async {
    for (var i = 0; i < paths.length; i++) {
      await _db
          .from('listing_images')
          .update({'sort_order': i})
          .eq('storage_path', paths[i]);
    }
  }

  Future<List<Category>> categories() async {
    final rows = await _db
        .from('categories')
        .select(Category.columns)
        .eq('active', true)
        .order('sort_order', ascending: true);
    return rows.map(Category.fromJson).toList();
  }
}

final listingRepositoryProvider = Provider(
  (ref) => ListingRepository(ref.watch(supabaseProvider)),
);

final listingProvider = FutureProvider.autoDispose.family<Listing?, String>(
  (ref, id) => ref.watch(listingRepositoryProvider).byId(id),
);

final myListingsProvider = FutureProvider.autoDispose<List<Listing>>((
  ref,
) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return const [];
  return ref.watch(listingRepositoryProvider).mine(uid);
});

final sellerListingsProvider = FutureProvider.autoDispose
    .family<List<Listing>, String>(
      (ref, uid) => ref.watch(listingRepositoryProvider).activeBySeller(uid),
    );

final categoriesProvider = FutureProvider<List<Category>>(
  (ref) => ref.watch(listingRepositoryProvider).categories(),
);
