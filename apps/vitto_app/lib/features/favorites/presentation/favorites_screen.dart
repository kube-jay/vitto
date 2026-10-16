import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../core/widgets/common.dart';
import '../../listings/presentation/widgets/listing_card.dart';
import '../data/favorites_repository.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return AsyncBody(
      value: ref.watch(favoriteListingsProvider),
      onRetry: () => ref.invalidate(favoriteListingsProvider),
      builder: (items) => CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            sliver: SliverToBoxAdapter(
              child: Text(
                l10n.navFavorites,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          if (items.isEmpty)
            SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.favorite_border,
                title: l10n.favoritesEmpty,
                message: l10n.favoritesEmptyHint,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: ListingSliverGrid(listings: items, showStatus: true),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
