import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/data/profile_repository.dart';

/// Which country the user is browsing (null = both). Defaults to the
/// signed-in user's country; Listings never change currency (DEC-08).
class BrowseCountry extends Notifier<String?> {
  bool _userChose = false;
  String? _chosen;

  @override
  String? build() {
    final profile = ref.watch(myProfileProvider).value;
    return _userChose ? _chosen : profile?.countryCode;
  }

  void select(String? country) {
    _userChose = true;
    _chosen = country;
    state = country;
  }
}

final browseCountryProvider = NotifierProvider<BrowseCountry, String?>(
  BrowseCountry.new,
);
