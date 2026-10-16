import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/supabase_provider.dart';
import '../../auth/data/session_provider.dart';
import '../domain/profile.dart';

class ProfileRepository {
  ProfileRepository(this._db);

  final SupabaseClient _db;

  Future<Profile?> fetch(String id) async {
    final row = await _db
        .from('profiles')
        .select(Profile.columns)
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Profile.fromJson(row);
  }

  Future<void> update(
    String id, {
    String? displayName,
    String? countryCode,
    String? regionCode,
    String? city,
    String? preferredLocale,
    String? avatarPath,
    bool clearRegion = false,
  }) async {
    final changes = <String, dynamic>{
      'display_name': ?displayName,
      'country_code': ?countryCode,
      'city': ?city,
      'preferred_locale': ?preferredLocale,
      'avatar_path': ?avatarPath,
      if (regionCode != null || clearRegion) 'region_code': regionCode,
    };
    if (changes.isEmpty) return;
    await _db.from('profiles').update(changes).eq('id', id);
  }

  Future<String> uploadAvatar(String uid, Uint8List bytes, String mime) async {
    final ext = mime.split('/').last == 'jpeg' ? 'jpg' : mime.split('/').last;
    final path = '$uid/${const Uuid().v4()}.$ext';
    await _db.storage
        .from('avatars')
        .uploadBinary(path, bytes, fileOptions: FileOptions(contentType: mime));
    return path;
  }

  Future<List<Region>> regions(String countryCode) async {
    final rows = await _db
        .from('regions')
        .select()
        .eq('country_code', countryCode)
        .order('name', ascending: true);
    return rows.map(Region.fromJson).toList();
  }

  Future<bool> isAdmin() async =>
      (await _db.rpc<bool>('current_user_is_admin')) == true;
}

final profileRepositoryProvider = Provider(
  (ref) => ProfileRepository(ref.watch(supabaseProvider)),
);

final myProfileProvider = FutureProvider<Profile?>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return null;
  return ref.watch(profileRepositoryProvider).fetch(uid);
});

final profileProvider = FutureProvider.autoDispose.family<Profile?, String>(
  (ref, id) => ref.watch(profileRepositoryProvider).fetch(id),
);

final regionsProvider = FutureProvider.family<List<Region>, String>(
  (ref, country) => ref.watch(profileRepositoryProvider).regions(country),
);

final isAdminProvider = FutureProvider<bool>((ref) async {
  if (ref.watch(currentUserIdProvider) == null) return false;
  return ref.watch(profileRepositoryProvider).isAdmin();
});
