import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/config/env.dart';
import '../../../core/widgets/common.dart';
import '../../listings/data/listing_repository.dart';
import '../../listings/domain/listing.dart';
import '../../listings/presentation/widgets/listing_card.dart';
import '../data/demo_categories.dart';
import '../data/discovery_repository.dart';
import '../data/market_controller.dart';

/// Homepage: search box, country switch, category tiles and the newest
/// active Listings (Part I §7).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final country = ref.watch(browseCountryProvider);
    final filters = SearchFilters(country: country);
    final latest = Env.hasBackend
        ? ref.watch(searchResultsProvider(filters))
        : const AsyncData(<Listing>[]);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(searchResultsProvider(filters)),
      child: CustomScrollView(
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
                    onSubmitted: (q) => context.push(
                      Uri(
                        path: Routes.search,
                        queryParameters: filters.copyWith(query: q).toQuery(),
                      ).toString(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _CountrySwitch(
                    value: country,
                    onChanged: ref.read(browseCountryProvider.notifier).select,
                  ),
                  const SizedBox(height: 20),
                  Text(l10n.categories, style: theme.textTheme.titleLarge),
                ],
              ),
            ),
          ),
          const _CategoryGrid(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
            sliver: SliverToBoxAdapter(
              child: Text(
                l10n.latestListings,
                style: theme.textTheme.titleLarge,
              ),
            ),
          ),
          ...latest.when(
            data: (items) => items.isEmpty
                ? [
                    SliverToBoxAdapter(
                      child: EmptyState(
                        icon: Icons.storefront_outlined,
                        title: l10n.noListingsYet,
                        message: l10n.latestListingsEmptyHint,
                        action: FilledButton(
                          onPressed: () => context.go(Routes.sell),
                          child: Text(l10n.postListing),
                        ),
                      ),
                    ),
                  ]
                : [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: ListingSliverGrid(listings: items),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: OutlinedButton(
                            onPressed: () => context.push(
                              Uri(
                                path: Routes.search,
                                queryParameters: filters.toQuery(),
                              ).toString(),
                            ),
                            child: Text(l10n.seeAll),
                          ),
                        ),
                      ),
                    ),
                  ],
            loading: () => [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ],
            error: (e, _) => [
              SliverToBoxAdapter(
                child: ErrorState(
                  error: e,
                  onRetry: () => ref.invalidate(searchResultsProvider(filters)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountrySwitch extends StatelessWidget {
  const _CountrySwitch({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget chip(String? code, String label) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: value == code,
        onSelected: (_) => onChanged(code),
        selectedColor: VittoColors.navySoft,
        side: const BorderSide(color: VittoColors.line),
      ),
    );
    return Wrap(
      children: [
        chip('NG', l10n.countryNigeria),
        chip('BJ', l10n.countryBenin),
        chip(null, l10n.allCountries),
      ],
    );
  }
}

class _CategoryGrid extends ConsumerWidget {
  const _CategoryGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context);
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1100
        ? 6
        : width >= 700
        ? 4
        : 3;

    final tiles = <({String slug, String name, IconData icon})>[];
    if (Env.hasBackend) {
      for (final c in ref.watch(categoriesProvider).value ?? const []) {
        if (c.parentId == null) {
          tiles.add((slug: c.slug, name: c.name(locale), icon: c.icon));
        }
      }
    } else {
      for (final c in demoCategories) {
        tiles.add((slug: c.slug, name: c.name(locale), icon: c.icon));
      }
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid.builder(
        itemCount: tiles.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: columns == 3 ? 0.9 : 1.6,
        ),
        itemBuilder: (context, i) => _CategoryTile(
          icon: tiles[i].icon,
          label: tiles[i].name,
          onTap: () => context.push('/c/${tiles[i].slug}'),
        ),
      ),
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
