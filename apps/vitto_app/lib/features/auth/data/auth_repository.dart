import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_provider.dart';

/// Email + password auth with confirmed email (DEC-09). No social login.
class AuthRepository {
  AuthRepository(this._db);

  final SupabaseClient _db;

  String get _origin => Uri.base.origin;

  Future<void> signIn(String email, String password) =>
      _db.auth.signInWithPassword(email: email.trim(), password: password);

  /// Returns true when the user must confirm their email first.
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
    required String countryCode,
    required String locale,
  }) async {
    final res = await _db.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: '$_origin/login',
      data: {
        'display_name': displayName.trim(),
        'country_code': countryCode,
        'preferred_locale': locale,
      },
    );
    return res.session == null;
  }

  Future<void> sendPasswordReset(String email) => _db.auth
      .resetPasswordForEmail(email.trim(), redirectTo: '$_origin/new-password');

  Future<void> updatePassword(String password) =>
      _db.auth.updateUser(UserAttributes(password: password));

  Future<void> signOut() => _db.auth.signOut();
}

final authRepositoryProvider = Provider(
  (ref) => AuthRepository(ref.watch(supabaseProvider)),
);
