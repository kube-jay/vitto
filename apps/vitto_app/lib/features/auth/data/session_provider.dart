import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';

/// Current Supabase session, or null when signed out / in demo mode.
final sessionProvider = StreamProvider<Session?>((ref) async* {
  if (!Env.hasBackend) {
    yield null;
    return;
  }
  final auth = Supabase.instance.client.auth;
  yield auth.currentSession;
  await for (final change in auth.onAuthStateChange) {
    yield change.session;
  }
});

final isSignedInProvider = Provider<bool>(
  (ref) => ref.watch(sessionProvider).value != null,
);
