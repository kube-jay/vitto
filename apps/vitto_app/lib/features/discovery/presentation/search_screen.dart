import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/config/market.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/common.dart';
import '../../listings/data/listing_repository.dart';
import '../../listings/presentation/widgets/listing_card.dart';
import '../../profile/data/profile_repository.dart';
import '../data/discovery_repository.dart';

/// Opens search pre-filtered by a category slug ("/c/phones-tablets").
class CategoryScreen extends ConsumerWidget {
  const CategoryScreen({super.key, required this.slug, required this.query});

  final String slug;
  final Map<String, String> query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncBody(
      value: ref.watch(categoriesProvider),
      onRetry: () => ref.invalidate(categoriesProvider),
      builder: (cats) {
        final match = cats.where((c) => c.slug == slug);
        final filters = SearchFilters.fromQuery(
          query,
        ).copyWith(categoryId: () => match.isEmpty ? null : match.first.id);
        return SearchScreen(filters: filters);
      },
    );
  }
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, required this.filters});

  final SearchFilters filters;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final _query = TextEditingController(text: widget.filters.query);

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _apply(SearchFilters f) => context.replace(
    Uri(path: Routes.search, queryParameters: f.toQuery()).toString(),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = widget.filters;
    final results = ref.watch(searchResultsProvider(f));
    final notifier = ref.read(searchResultsProvider(f).notifier);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _query,
                  autofocus: f.query.isEmpty && f.categoryId == null,
                  decoration: InputDecoration(
                    hintText: l10n.searchEverything,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (q) => _apply(f.copyWith(query: q.trim())),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.tune),
                      label: Text(
                        f.activeFilterCount == 0
                            ? l10n.filters
                            : '${l10n.filters} (${f.activeFilterCount})',
                      ),
                      onPressed: () async {
                        final next = await showModalBottomSheet<SearchFilters>(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => _FilterSheet(initial: f),
                        );
                        if (next != null) _apply(next);
                      },
                    ),
                    DropdownButton<SortOrder>(
                      value: f.sort,
                      underline: const SizedBox.shrink(),
                      items: [
                        DropdownMenuItem(
                          value: SortOrder.newest,
                          child: Text(l10n.sortNewest),
                        ),
                        DropdownMenuItem(
                          value: SortOrder.priceAsc,
                          child: Text(l10n.sortPriceAsc),
                        ),
                        DropdownMenuItem(
                          value: SortOrder.priceDesc,
                          child: Text(l10n.sortPriceDesc),
                        ),
                      ],
                      onChanged: (s) => _apply(f.copyWith(sort: s)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        ...results.when(
          data: (items) => items.isEmpty
              ? [
                  SliverToBoxAdapter(
                    child: EmptyState(
                      icon: Icons.search_off,
                      title: l10n.noResults,
                      message: l10n.noResultsHint,
                    ),
                  ),
                ]
              : [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: ListingSliverGrid(listings: items),
                  ),
                  if (notifier.hasMore)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: OutlinedButton(
                            onPressed: () =>
                                runGuarded(context, notifier.loadMore),
                            child: Text(l10n.loadMore),
                          ),
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
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
                onRetry: () => ref.invalidate(searchResultsProvider(f)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({required this.initial});

  final SearchFilters initial;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late SearchFilters f = widget.initial;
  late final _min = TextEditingController(text: _major(f.minPriceMinor));
  late final _max = TextEditingController(text: _major(f.maxPriceMinor));

  String get _currency =>
      Market.fromCountryCode(f.country ?? 'NG').currencyCode;

  String _major(int? minor) {
    if (minor == null) return '';
    final exp = Market.fromCountryCode(f.country ?? 'NG').currencyExponent;
    var div = 1;
    for (var i = 0; i < exp; i++) {
      div *= 10;
    }
    return (minor ~/ div).toString();
  }

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final regions = f.country == null
        ? null
        : ref.watch(regionsProvider(f.country!)).value;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.filters, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: f.country,
                decoration: InputDecoration(labelText: l10n.country),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.allCountries)),
                  DropdownMenuItem(
                    value: 'NG',
                    child: Text(l10n.countryNigeria),
                  ),
                  DropdownMenuItem(value: 'BJ', child: Text(l10n.countryBenin)),
                ],
                onChanged: (v) => setState(() {
                  f = f.copyWith(
                    country: () => v,
                    region: () => null,
                    minPriceMinor: () => null,
                    maxPriceMinor: () => null,
                  );
                  _min.clear();
                  _max.clear();
                }),
              ),
              const SizedBox(height: 12),
              if (regions != null)
                DropdownButtonFormField<String?>(
                  initialValue: f.region,
                  decoration: InputDecoration(labelText: l10n.region),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.any)),
                    for (final r in regions)
                      DropdownMenuItem(value: r.code, child: Text(r.name)),
                  ],
                  onChanged: (v) =>
                      setState(() => f = f.copyWith(region: () => v)),
                ),
              if (regions != null) const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: f.categoryId,
                decoration: InputDecoration(labelText: l10n.category),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(l10n.allCategories),
                  ),
                  for (final c in categories)
                    DropdownMenuItem(value: c.id, child: Text(c.name(locale))),
                ],
                onChanged: (v) =>
                    setState(() => f = f.copyWith(categoryId: () => v)),
              ),
              const SizedBox(height: 12),
              if (f.country != null)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _min,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: '${l10n.priceMin} ($_currency)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _max,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: '${l10n.priceMax} ($_currency)',
                        ),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  l10n.pickCountryForPrice,
                  style: const TextStyle(color: VittoColors.muted),
                ),
              const SizedBox(height: 16),
              Text(l10n.condition),
              const SizedBox(height: 6),
              SegmentedButton<String?>(
                segments: [
                  ButtonSegment(value: null, label: Text(l10n.any)),
                  ButtonSegment(value: 'new', label: Text(l10n.conditionNew)),
                  ButtonSegment(value: 'used', label: Text(l10n.conditionUsed)),
                ],
                selected: {f.condition},
                onSelectionChanged: (s) =>
                    setState(() => f = f.copyWith(condition: () => s.first)),
              ),
              const SizedBox(height: 16),
              Text(l10n.priceType),
              const SizedBox(height: 6),
              SegmentedButton<bool?>(
                segments: [
                  ButtonSegment(value: null, label: Text(l10n.any)),
                  ButtonSegment(value: true, label: Text(l10n.negotiable)),
                  ButtonSegment(value: false, label: Text(l10n.fixedPrice)),
                ],
                selected: {f.negotiable},
                onSelectionChanged: (s) =>
                    setState(() => f = f.copyWith(negotiable: () => s.first)),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(
                        context,
                        SearchFilters(
                          query: widget.initial.query,
                          country: widget.initial.country,
                          sort: widget.initial.sort,
                        ),
                      ),
                      child: Text(l10n.reset),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        int? parse(String s) => s.trim().isEmpty
                            ? null
                            : Money.tryParse(s, _currency)?.minor;
                        Navigator.pop(
                          context,
                          f.copyWith(
                            minPriceMinor: () => parse(_min.text),
                            maxPriceMinor: () => parse(_max.text),
                          ),
                        );
                      },
                      child: Text(l10n.showResults),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
