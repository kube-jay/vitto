import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/generated/app_localizations.dart';
import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/network/supabase_provider.dart';
import '../../../../core/widgets/common.dart';
import '../../../auth/data/session_provider.dart';
import '../../../favorites/data/favorites_repository.dart';
import '../../../profile/domain/profile.dart';
import '../../domain/listing.dart';
import '../../domain/listing_status.dart';

/// Listing image from the public bucket, with a neutral fallback.
class ListingImage extends ConsumerWidget {
  const ListingImage({super.key, required this.path, this.fit = BoxFit.cover});

  final String? path;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const placeholder = ColoredBox(
      color: VittoColors.field,
      child: Center(
        child: Icon(Icons.image_outlined, color: VittoColors.muted, size: 36),
      ),
    );
    if (path == null) return placeholder;
    final client = ref.watch(supabaseProvider);
    return Image.network(
      listingImageUrl(client, path!),
      fit: fit,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}

class ListingCard extends ConsumerWidget {
  const ListingCard({
    super.key,
    required this.listing,
    this.showStatus = false,
  });

  final Listing listing;
  final bool showStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final signedIn = ref.watch(isSignedInProvider);
    final favorites = ref.watch(favoriteIdsProvider).value ?? const {};
    final isFav = favorites.contains(listing.id);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push(Routes.listingPath(listing.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ListingImage(path: listing.coverPath),
                  if (signedIn)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white70,
                        ),
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: VittoColors.navy,
                        ),
                        onPressed: () => runGuarded(
                          context,
                          () => ref
                              .read(favoriteIdsProvider.notifier)
                              .toggle(listing.id),
                        ),
                      ),
                    ),
                  if (showStatus)
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: StatusChip(
                        label: listingStatusLabel(
                          AppLocalizations.of(context),
                          listing.status,
                        ),
                        strong: listing.status == ListingStatus.active,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            listing.price.format(localeTag(context)),
            style: theme.textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            listing.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 2),
          Text(
            listing.city,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: VittoColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Responsive grid of Listing cards as a sliver.
class ListingSliverGrid extends StatelessWidget {
  const ListingSliverGrid({
    super.key,
    required this.listings,
    this.showStatus = false,
  });

  final List<Listing> listings;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1100
        ? 5
        : width >= 800
        ? 4
        : width >= 560
        ? 3
        : 2;
    return SliverGrid.builder(
      itemCount: listings.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        mainAxisExtent: width < 560 ? (width - 44) / 2 + 92 : 300,
      ),
      itemBuilder: (_, i) =>
          ListingCard(listing: listings[i], showStatus: showStatus),
    );
  }
}

class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({super.key, required this.profile, this.radius = 22});

  final Profile? profile;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = profile?.avatarPath;
    return CircleAvatar(
      radius: radius,
      backgroundColor: VittoColors.navySoft,
      foregroundImage: path == null
          ? null
          : NetworkImage(avatarUrl(ref.watch(supabaseProvider), path)),
      child: Text(
        profile?.initials ?? '?',
        style: TextStyle(color: VittoColors.navy, fontSize: radius * 0.7),
      ),
    );
  }
}

String listingStatusLabel(AppLocalizations l10n, ListingStatus s) =>
    switch (s) {
      ListingStatus.draft => l10n.listingStatusDraft,
      ListingStatus.active => l10n.listingStatusActive,
      ListingStatus.reserved => l10n.listingStatusReserved,
      ListingStatus.sold => l10n.listingStatusSold,
      ListingStatus.archived => l10n.listingStatusArchived,
      ListingStatus.suspended => l10n.listingStatusSuspended,
    };
