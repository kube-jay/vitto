import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../app/routes.dart';

/// Homepage with search entry, categories and active Listings (Part I §7).
/// Listing data arrives with VT-012; this renders the empty state.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.tagline, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            prefixIcon: const Icon(Icons.search),
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (q) => context.go(
            Uri(path: Routes.search, queryParameters: {'q': q}).toString(),
          ),
        ),
        const SizedBox(height: 24),
        Text(l10n.categories, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(l10n.comingSoon('M2')),
        const SizedBox(height: 24),
        Text(l10n.latestListings, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(l10n.noListingsYet),
      ],
    );
  }
}
