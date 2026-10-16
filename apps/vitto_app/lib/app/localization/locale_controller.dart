import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const supportedLocales = [Locale('en'), Locale('fr')];

/// User-selected UI language. Null means "follow the device/browser".
///
/// Users may override the language regardless of their country (Part II §35).
/// TODO(VT-008): persist the choice on the User profile.
class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() => null;

  void select(Locale locale) {
    assert(supportedLocales.contains(locale));
    state = locale;
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);
