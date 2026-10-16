import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/widgets/common.dart';
import '../data/listing_repository.dart';
import '../domain/listing_status.dart';
import 'widgets/listing_card.dart';

/// The seller's own Listings grouped by status.
class MyListingsScreen extends ConsumerStatefulWidget {
  const MyListingsScreen({super.key});

  @override
  ConsumerState<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends ConsumerState<MyListingsScreen> {
  String _tab = 'active';

  static const _groups = {
    'active': [ListingStatus.active],
    'drafts': [ListingStatus.draft],
    'in_deal': [ListingStatus.reserved, ListingStatus.sold],
    'archived': [ListingStatus.archived, ListingStatus.suspended],
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = {
      'active': l10n.listingStatusActive,
      'drafts': l10n.drafts,
      'in_deal': l10n.reservedAndSold,
      'archived': l10n.listingStatusArchived,
    };
    return AsyncBody(
      value: ref.watch(myListingsProvider),
      onRetry: () => ref.invalidate(myListingsProvider),
      builder: (all) {
        final shown = all
            .where((l) => _groups[_tab]!.contains(l.status))
            .toList();
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.screenMyListings,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        FilledButton.icon(
                          icon: const Icon(Icons.add),
                          label: Text(l10n.postListing),
                          onPressed: () => context.push(Routes.sell),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final key in _groups.keys)
                          ChoiceChip(
                            label: Text(
                              '${labels[key]} (${all.where((l) => _groups[key]!.contains(l.status)).length})',
                            ),
                            selected: _tab == key,
                            onSelected: (_) => setState(() => _tab = key),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (shown.isEmpty)
              SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: l10n.nothingHere,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: ListingSliverGrid(listings: shown, showStatus: true),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }
}
