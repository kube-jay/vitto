import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/common.dart';
import '../../auth/data/session_provider.dart';
import '../../conversations/data/conversation_repository.dart';
import '../../favorites/data/favorites_repository.dart';
import '../../reports/presentation/report_dialog.dart';
import '../data/listing_repository.dart';
import '../domain/listing.dart';
import '../domain/listing_status.dart';
import 'widgets/listing_card.dart';

class ListingDetailsScreen extends ConsumerWidget {
  const ListingDetailsScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return AsyncBody(
      value: ref.watch(listingProvider(id)),
      onRetry: () => ref.invalidate(listingProvider(id)),
      builder: (listing) => listing == null
          ? EmptyState(
              icon: Icons.inventory_2_outlined,
              title: l10n.errListingNotAvailable,
            )
          : _ListingView(listing: listing),
    );
  }
}

class _ListingView extends ConsumerWidget {
  const _ListingView({required this.listing});

  final Listing listing;

  Future<void> _contact(
    BuildContext context,
    WidgetRef ref, {
    bool openOffer = false,
  }) async {
    if (!ref.read(isSignedInProvider)) {
      context.go(
        Uri(
          path: Routes.login,
          queryParameters: {'from': Routes.listingPath(listing.id)},
        ).toString(),
      );
      return;
    }
    final convId = await runGuarded(
      context,
      () => ref.read(conversationRepositoryProvider).start(listing.id),
    );
    if (convId != null && context.mounted) {
      context.push(
        Uri(
          path: Routes.conversationPath(convId),
          queryParameters: openOffer ? {'offer': '1'} : null,
        ).toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final uid = ref.watch(currentUserIdProvider);
    final isOwner = uid == listing.sellerId;
    final isFav =
        ref.watch(favoriteIdsProvider).value?.contains(listing.id) ?? false;
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final locale = Localizations.localeOf(context);

    final gallery = _Gallery(paths: listing.imagePaths);
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                listing.price.format(localeTag(context)),
                style: theme.textTheme.headlineMedium,
              ),
            ),
            if (uid != null && !isOwner)
              IconButton(
                tooltip: l10n.navFavorites,
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: VittoColors.navy,
                ),
                onPressed: () => runGuarded(
                  context,
                  () =>
                      ref.read(favoriteIdsProvider.notifier).toggle(listing.id),
                ),
              ),
            if (uid != null && !isOwner)
              PopupMenuButton<String>(
                onSelected: (_) => showReportDialog(
                  context,
                  ref,
                  targetKind: 'listing',
                  targetId: listing.id,
                ),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'report',
                    child: Text(l10n.reportListing),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(listing.title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatusChip(
              label: listing.condition == 'new'
                  ? l10n.conditionNew
                  : l10n.conditionUsed,
            ),
            StatusChip(
              label: listing.negotiable ? l10n.negotiable : l10n.fixedPrice,
            ),
            if (listing.category != null)
              StatusChip(label: listing.category!.name(locale)),
            if (listing.status != ListingStatus.active)
              StatusChip(
                label: listingStatusLabel(l10n, listing.status),
                strong: true,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(
              Icons.place_outlined,
              size: 18,
              color: VittoColors.muted,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${listing.city} · ${listing.countryCode == 'NG' ? l10n.countryNigeria : l10n.countryBenin}',
                style: const TextStyle(color: VittoColors.muted),
              ),
            ),
          ],
        ),
        if (listing.publishedAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l10n.postedOn(formatDate(context, listing.publishedAt!)),
              style: const TextStyle(color: VittoColors.muted),
            ),
          ),
        const SizedBox(height: 20),
        if (isOwner)
          _OwnerActions(listing: listing)
        else if (listing.status == ListingStatus.active) ...[
          FilledButton.icon(
            icon: const Icon(Icons.chat_bubble_outline),
            label: Text(l10n.messageSeller),
            onPressed: () => _contact(context, ref),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.local_offer_outlined),
            label: Text(
              listing.negotiable ? l10n.makeOffer : l10n.buyAtThisPrice,
            ),
            onPressed: () => _contact(context, ref, openOffer: true),
          ),
        ] else
          Text(l10n.listingUnavailableNote),
        if (listing.seller != null) ...[
          const SizedBox(height: 20),
          _SellerCard(listing: listing),
        ],
        SectionTitle(l10n.description),
        SelectableText(
          listing.description.isEmpty ? '—' : listing.description,
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: VittoColors.navySoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.shield_outlined, color: VittoColors.navy),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.safetyTip)),
            ],
          ),
        ),
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: gallery),
                const SizedBox(width: 24),
                Expanded(flex: 2, child: info),
              ],
            )
          : Column(children: [gallery, const SizedBox(height: 16), info]),
    );
  }
}

class _Gallery extends StatefulWidget {
  const _Gallery({required this.paths});

  final List<String> paths;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paths = widget.paths.isEmpty ? <String?>[null] : widget.paths;
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                PageView.builder(
                  controller: _controller,
                  itemCount: paths.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) =>
                      ListingImage(path: paths[i], fit: BoxFit.contain),
                ),
                if (paths.length > 1) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton.filledTonal(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => _controller.previousPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton.filledTonal(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => _controller.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (paths.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < paths.length; i++)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _index ? VittoColors.navy : VittoColors.line,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SellerCard extends StatelessWidget {
  const _SellerCard({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final seller = listing.seller!;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: ProfileAvatar(profile: seller),
        title: Text(seller.displayName),
        subtitle: Row(
          children: [
            if (seller.ratingCount > 0) ...[
              StarRow(value: seller.averageRating, size: 14),
              const SizedBox(width: 6),
              Text('(${seller.ratingCount})'),
            ] else
              Text(l10n.noRatingsYet),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                l10n.completedDealsCount(seller.completedDealsCount),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(Routes.profilePath(seller.id)),
      ),
    );
  }
}

class _OwnerActions extends ConsumerWidget {
  const _OwnerActions({required this.listing});

  final Listing listing;

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    ListingStatus status,
  ) async {
    await runGuarded(
      context,
      () => ref.read(listingRepositoryProvider).setStatus(listing.id, status),
    );
    ref.invalidate(listingProvider(listing.id));
    ref.invalidate(myListingsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final s = listing.status;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.yourListing, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (s == ListingStatus.draft || s == ListingStatus.archived)
          FilledButton(
            onPressed: () => _setStatus(context, ref, ListingStatus.active),
            child: Text(l10n.publish),
          ),
        if (s == ListingStatus.draft ||
            s == ListingStatus.active ||
            s == ListingStatus.archived) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => context.push('/l/${listing.id}/edit'),
            child: Text(l10n.edit),
          ),
        ],
        if (s == ListingStatus.active || s == ListingStatus.draft) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () async {
              if (await confirmDialog(context, title: l10n.archiveConfirm)) {
                if (context.mounted) {
                  await _setStatus(context, ref, ListingStatus.archived);
                }
              }
            },
            child: Text(l10n.archive),
          ),
        ],
        if (s == ListingStatus.suspended) Text(l10n.listingSuspendedNote),
      ],
    );
  }
}
