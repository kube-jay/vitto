import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/session_provider.dart';
import '../../features/profile/data/profile_repository.dart';

const supportedLocales = [Locale('en'), Locale('fr')];

/// UI language. Null means "follow the browser". Users may override the
/// language regardless of country (Part II §35); the choice is saved on
/// the profile when signed in and restored on the next sign-in.
class LocaleController extends Notifier<Locale?> {
  bool _userChose = false;
  Locale? _chosen;

  @override
  Locale? build() {
    if (_userChose) return _chosen;
    final saved = ref.watch(myProfileProvider).value?.preferredLocale;
    return saved == null ? null : Locale(saved);
  }

  void select(Locale locale) {
    assert(supportedLocales.contains(locale));
    _userChose = true;
    _chosen = locale;
    state = locale;
    final uid = ref.read(currentUserIdProvider);
    if (uid != null) {
      ref
          .read(profileRepositoryProvider)
          .update(uid, preferredLocale: locale.languageCode)
          .catchError((_) {});
    }
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);
