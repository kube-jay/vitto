/// Public client configuration, passed with `--dart-define`.
///
/// Only the Supabase URL and publishable/anon key may ever live here.
/// Service-role keys and payment secrets are server-only.
class Env {
  const Env._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  /// Without a backend the app runs in demo mode with no network calls.
  static bool get hasBackend =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
