import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/localization/generated/app_localizations.dart';

/// Error codes shared with the server contract (docs/contracts/functions.md).
const _serverCodes = {
  'unauthenticated',
  'forbidden',
  'validation_error',
  'conflict',
  'listing_not_available',
  'invalid_state',
  'payment_pending',
  'provider_unavailable',
  'rate_limited',
  'internal_error',
};

/// A failure the UI can explain. [detail] carries the server's finer reason
/// (e.g. `fixed_price`, `offer_pending`, `already_rated`).
class AppFailure implements Exception {
  const AppFailure(this.code, [this.detail]);

  final String code;
  final String? detail;

  static AppFailure from(Object error) {
    if (error is AppFailure) return error;
    if (error is PostgrestException) {
      if (_serverCodes.contains(error.message)) {
        return AppFailure(error.message, error.details?.toString());
      }
      if (error.code == '42501') return const AppFailure('forbidden');
      if (error.code == '23505') return const AppFailure('conflict');
      return const AppFailure('internal_error');
    }
    if (error is FunctionException) {
      final details = error.details;
      if (details is Map && details['error'] is Map) {
        final code = (details['error'] as Map)['code']?.toString();
        if (code != null && _serverCodes.contains(code)) {
          return AppFailure(code);
        }
      }
      return const AppFailure('internal_error');
    }
    if (error is AuthException) {
      final m = error.message.toLowerCase();
      if (m.contains('invalid login')) {
        return const AppFailure('invalid_credentials');
      }
      if (m.contains('not confirmed')) {
        return const AppFailure('email_not_confirmed');
      }
      if (m.contains('already registered') || m.contains('already exists')) {
        return const AppFailure('user_exists');
      }
      if (m.contains('password')) return const AppFailure('weak_password');
      if (error.statusCode == '429') return const AppFailure('rate_limited');
      return const AppFailure('auth_failed');
    }
    if (error is StorageException) return const AppFailure('upload_failed');
    return const AppFailure('internal_error');
  }

  @override
  String toString() => 'AppFailure($code${detail == null ? '' : ', $detail'})';
}

/// Human message for any error, in the current language.
String failureMessage(AppLocalizations l10n, Object error) {
  final f = AppFailure.from(error);
  switch (f.detail) {
    case 'fixed_price':
      return l10n.errFixedPrice;
    case 'offer_pending':
      return l10n.errOfferPending;
    case 'already_rated':
      return l10n.errAlreadyRated;
    case 'offer_expired':
      return l10n.errOfferExpired;
  }
  return switch (f.code) {
    'no_backend' => l10n.errNoBackend,
    'unauthenticated' => l10n.errUnauthenticated,
    'forbidden' => l10n.errForbidden,
    'validation_error' => l10n.errValidation,
    'conflict' => l10n.errConflict,
    'listing_not_available' => l10n.errListingNotAvailable,
    'invalid_state' => l10n.errInvalidState,
    'payment_pending' => l10n.errPaymentPending,
    'provider_unavailable' => l10n.errProviderUnavailable,
    'rate_limited' => l10n.errRateLimited,
    'invalid_credentials' => l10n.errInvalidCredentials,
    'email_not_confirmed' => l10n.errEmailNotConfirmed,
    'user_exists' => l10n.errUserExists,
    'weak_password' => l10n.errWeakPassword,
    'auth_failed' => l10n.errAuthFailed,
    'upload_failed' => l10n.errUploadFailed,
    _ => l10n.errorGeneric,
  };
}
