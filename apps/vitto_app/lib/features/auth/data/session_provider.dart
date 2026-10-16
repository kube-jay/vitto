import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';

/// Latest auth event (sign-in, sign-out, password recovery, …).
final authEventProvider = StreamProvider<AuthState>((ref) {
  if (!Env.hasBackend) return const Stream.empty();
  return Supabase.instance.client.auth.onAuthStateChange;
});

/// Current Supabase session, or null when signed out / in demo mode.
final sessionProvider = Provider<Session?>((ref) {
  if (!Env.hasBackend) return null;
  ref.watch(authEventProvider);
  return Supabase.instance.client.auth.currentSession;
});

final isSignedInProvider = Provider<bool>(
  (ref) => ref.watch(sessionProvider) != null,
);

final currentUserIdProvider = Provider<String?>(
  (ref) => ref.watch(sessionProvider)?.user.id,
);
