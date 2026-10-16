import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_provider.dart';
import '../../listings/domain/listing.dart';

enum SortOrder {
  newest('newest'),
  priceAsc('price_asc'),
  priceDesc('price_desc');

  const SortOrder(this.wire);
  final String wire;

  static SortOrder fromWire(String? v) =>
      values.firstWhere((s) => s.wire == v, orElse: () => newest);
}

/// Search filters (Part I §7). Also encoded in the URL for shareable links.
class SearchFilters {
  const SearchFilters({
    this.query = '',
    this.country,
    this.region,
    this.categoryId,
    this.minPriceMinor,
    this.maxPriceMinor,
    this.condition,
    this.negotiable,
    this.sort = SortOrder.newest,
  });

  final String query;
  final String? country;
  final String? region;
  final String? categoryId;
  final int? minPriceMinor;
  final int? maxPriceMinor;
  final String? condition;
  final bool? negotiable;
  final SortOrder sort;

  int get activeFilterCount => [
    region,
    categoryId,
    minPriceMinor,
    maxPriceMinor,
    condition,
    negotiable,
  ].where((v) => v != null).length;

  SearchFilters copyWith({
    String? query,
    String? Function()? country,
    String? Function()? region,
    String? Function()? categoryId,
    int? Function()? minPriceMinor,
    int? Function()? maxPriceMinor,
    String? Function()? condition,
    bool? Function()? negotiable,
    SortOrder? sort,
  }) => SearchFilters(
    query: query ?? this.query,
    country: country != null ? country() : this.country,
    region: region != null ? region() : this.region,
    categoryId: categoryId != null ? categoryId() : this.categoryId,
    minPriceMinor: minPriceMinor != null ? minPriceMinor() : this.minPriceMinor,
    maxPriceMinor: maxPriceMinor != null ? maxPriceMinor() : this.maxPriceMinor,
    condition: condition != null ? condition() : this.condition,
    negotiable: negotiable != null ? negotiable() : this.negotiable,
    sort: sort ?? this.sort,
  );

  Map<String, String> toQuery() => {
    if (query.isNotEmpty) 'q': query,
    'country': ?country,
    'region': ?region,
    'category': ?categoryId,
    if (minPriceMinor != null) 'min': '$minPriceMinor',
    if (maxPriceMinor != null) 'max': '$maxPriceMinor',
    'condition': ?condition,
    if (negotiable != null) 'negotiable': '$negotiable',
    if (sort != SortOrder.newest) 'sort': sort.wire,
  };

  factory SearchFilters.fromQuery(Map<String, String> q) => SearchFilters(
    query: q['q'] ?? '',
    country: q['country'],
    region: q['region'],
    categoryId: q['category'],
    minPriceMinor: int.tryParse(q['min'] ?? ''),
    maxPriceMinor: int.tryParse(q['max'] ?? ''),
    condition: q['condition'],
    negotiable: switch (q['negotiable']) {
      'true' => true,
      'false' => false,
      _ => null,
    },
    sort: SortOrder.fromWire(q['sort']),
  );

  @override
  bool operator ==(Object other) =>
      other is SearchFilters &&
      other.toQuery().toString() == toQuery().toString();

  @override
  int get hashCode => toQuery().toString().hashCode;
}

class DiscoveryRepository {
  DiscoveryRepository(this._db);

  final SupabaseClient _db;

  static const pageSize = 24;

  Future<List<Listing>> search(SearchFilters f, {int page = 0}) async {
    final rows = await _db
        .rpc(
          'search_listings',
          params: {
            'p_query': f.query.isEmpty ? null : f.query,
            'p_country': f.country,
            'p_region': f.region,
            'p_category': f.categoryId,
            'p_min_price': f.minPriceMinor,
            'p_max_price': f.maxPriceMinor,
            'p_condition': f.condition,
            'p_negotiable': f.negotiable,
            'p_sort': f.sort.wire,
          },
        )
        .select(Listing.columns)
        .range(page * pageSize, (page + 1) * pageSize - 1);
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(Listing.fromJson)
        .toList();
  }
}

final discoveryRepositoryProvider = Provider(
  (ref) => DiscoveryRepository(ref.watch(supabaseProvider)),
);

/// Pages of search results; [SearchResults.loadMore] appends the next page.
class SearchResults extends AsyncNotifier<List<Listing>> {
  SearchResults(this.filters);

  final SearchFilters filters;
  int _page = 0;
  bool hasMore = true;

  @override
  Future<List<Listing>> build() async {
    _page = 0;
    final first = await ref.watch(discoveryRepositoryProvider).search(filters);
    hasMore = first.length == DiscoveryRepository.pageSize;
    return first;
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !hasMore) return;
    final next = await ref
        .read(discoveryRepositoryProvider)
        .search(filters, page: _page + 1);
    _page++;
    hasMore = next.length == DiscoveryRepository.pageSize;
    state = AsyncData([...current, ...next]);
  }
}

final searchResultsProvider = AsyncNotifierProvider.autoDispose
    .family<SearchResults, List<Listing>, SearchFilters>(SearchResults.new);
