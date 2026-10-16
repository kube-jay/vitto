import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import '../errors/app_failure.dart';

/// The publishable-key Supabase client. Every query goes through RLS; all
/// state transitions go through server functions (Part II §29.2).
final supabaseProvider = Provider<SupabaseClient>((ref) {
  if (!Env.hasBackend) throw const AppFailure('no_backend');
  return Supabase.instance.client;
});

/// Public URL of a Listing image stored in the public bucket.
String listingImageUrl(SupabaseClient client, String path) =>
    client.storage.from('listing-images').getPublicUrl(path);

String avatarUrl(SupabaseClient client, String path) =>
    client.storage.from('avatars').getPublicUrl(path);
