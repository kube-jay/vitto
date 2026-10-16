import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../data/demo_categories.dart';

/// Homepage: one search box, category tiles, latest active Listings
/// (Part I В§7). Listing data arrives with VT-012; this renders the empty state.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1100
        ? 6
        : width >= 700
        ? 4
        : 3;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.tagline, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    hintText: l10n.searchEverything,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (q) => context.go(
                    Uri(
                      path: Routes.search,
                      queryParameters: {'q': q},
                    ).toString(),
                  ),
                ),
                const SizedBox(height: 24),
                Text(l10n.categories, style: theme.textTheme.titleLarge),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid.builder(
            itemCount: demoCategories.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: columns == 3 ? 0.9 : 1.6,
            ),
            itemBuilder: (context, i) {
              final c = demoCategories[i];
              return _CategoryTile(
                icon: c.icon,
                label: c.name(locale),
                onTap: () => context.go('/c/${c.slug}'),
              );
            },
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.latestListings, style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                _EmptyListings(
                  title: l10n.noListingsYet,
                  hint: l10n.latestListingsEmptyHint,
                  action: l10n.postListing,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: VittoColors.field,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Icon(icon, size: 28, color: VittoColors.navy),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyListings extends StatelessWidget {
  const _EmptyListings({
    required this.title,
    required this.hint,
    required this.action,
  });

  final String title;
  final String hint;
  final String action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.storefront_outlined,
              size: 40,
              color: VittoColors.navy,
            ),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: VittoColors.muted,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go(Routes.sell),
              child: Text(action),
            ),
          ],
        ),
      ),
    );
  }
}
