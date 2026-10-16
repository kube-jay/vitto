import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/widgets/common.dart';
import '../../auth/data/session_provider.dart';
import '../../listings/presentation/widgets/listing_card.dart';
import '../data/deal_repository.dart';
import '../domain/deal_status.dart';
import 'deal_labels.dart';

class DealsScreen extends ConsumerStatefulWidget {
  const DealsScreen({super.key});

  @override
  ConsumerState<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends ConsumerState<DealsScreen> {
  bool _activeOnly = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final uid = ref.watch(currentUserIdProvider);
    return AsyncBody(
      value: ref.watch(myDealsProvider),
      onRetry: () => ref.invalidate(myDealsProvider),
      builder: (all) {
        final deals = _activeOnly
            ? all
                  .where(
                    (d) =>
                        d.status != DealStatus.completed &&
                        d.status != DealStatus.cancelled,
                  )
                  .toList()
            : all;
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(myDealsProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l10n.navDeals,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(l10n.inProgress),
                    selected: _activeOnly,
                    onSelected: (_) => setState(() => _activeOnly = true),
                  ),
                  ChoiceChip(
                    label: Text(l10n.allDeals),
                    selected: !_activeOnly,
                    onSelected: (_) => setState(() => _activeOnly = false),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (deals.isEmpty)
                EmptyState(
                  icon: Icons.handshake_outlined,
                  title: l10n.noDeals,
                  message: l10n.noDealsHint,
                ),
              for (final d in deals)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    leading: SizedBox(
                      width: 56,
                      height: 56,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ListingImage(path: d.listing?.coverPath),
                      ),
                    ),
                    title: Text(
                      d.listing?.title ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${d.agreed.format(localeTag(context))} · '
                      '${d.isBuyer(uid) ? l10n.youAreBuying : l10n.youAreSelling}',
                    ),
                    trailing: StatusChip(
                      label: dealStatusLabel(l10n, d.status),
                      strong: d.status == DealStatus.completed,
                    ),
                    onTap: () => context.push(Routes.dealPath(d.id)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
