import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/common.dart';
import '../../listings/domain/listing.dart';
import '../data/offer_repository.dart';
import '../domain/offer.dart';
import '../domain/offer_status.dart';

String offerStatusLabel(AppLocalizations l10n, OfferStatus s) => switch (s) {
  OfferStatus.pending => l10n.offerStatusPending,
  OfferStatus.accepted => l10n.offerStatusAccepted,
  OfferStatus.rejected => l10n.offerStatusRejected,
  OfferStatus.countered => l10n.offerStatusCountered,
  OfferStatus.expired => l10n.offerStatusExpired,
  OfferStatus.cancelled => l10n.offerStatusCancelled,
};

/// Asks for an amount in the Listing currency. Fixed-price Listings only
/// allow the listed price (DEC-03).
Future<int?> showAmountDialog(
  BuildContext context, {
  required Listing listing,
  required String title,
  int? initialMinor,
}) {
  return showDialog<int>(
    context: context,
    builder: (_) =>
        _AmountDialog(listing: listing, title: title, initial: initialMinor),
  );
}

class _AmountDialog extends StatefulWidget {
  const _AmountDialog({
    required this.listing,
    required this.title,
    this.initial,
  });

  final Listing listing;
  final String title;
  final int? initial;

  @override
  State<_AmountDialog> createState() => _AmountDialogState();
}

class _AmountDialogState extends State<_AmountDialog> {
  late final _controller = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!widget.listing.negotiable) {
      _controller.text = _major(widget.listing.priceMinor);
    } else if (widget.initial != null) {
      _controller.text = _major(widget.initial!);
    }
  }

  String _major(int minor) {
    final digits = widget.listing.currency == 'NGN' ? 2 : 0;
    var div = 1;
    for (var i = 0; i < digits; i++) {
      div *= 10;
    }
    return minor % div == 0
        ? '${minor ~/ div}'
        : (minor / div).toStringAsFixed(digits);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fixed = !widget.listing.negotiable;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.listedPrice(widget.listing.price.format(localeTag(context))),
            style: const TextStyle(color: VittoColors.muted),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            enabled: !fixed,
            autofocus: !fixed,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.yourOffer,
              suffixText: widget.listing.currency,
              errorText: _error,
            ),
          ),
          if (fixed) ...[
            const SizedBox(height: 8),
            Text(l10n.fixedPriceOfferNote),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            final m = Money.tryParse(_controller.text, widget.listing.currency);
            if (m == null || m.minor <= 0) {
              setState(() => _error = l10n.validPrice);
              return;
            }
            Navigator.pop(context, m.minor);
          },
          child: Text(l10n.sendOffer),
        ),
      ],
    );
  }
}

/// A structured Offer in the conversation timeline with its actions.
class OfferCard extends ConsumerWidget {
  const OfferCard({
    super.key,
    required this.offer,
    required this.myId,
    required this.listing,
    required this.isCounter,
  });

  final Offer offer;
  final String myId;
  final Listing? listing;
  final bool isCounter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final repo = ref.read(offerRepositoryProvider);
    final mine = offer.proposerId == myId;
    final status = offer.effectiveStatus;
    final open = status == OfferStatus.pending;

    final header = mine
        ? (isCounter ? l10n.yourCounterOffer : l10n.yourOffer)
        : (isCounter ? l10n.theirCounterOffer : l10n.theirOffer);

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: open ? VittoColors.navy : VittoColors.line,
              width: open ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.local_offer_outlined,
                      size: 18,
                      color: VittoColors.navy,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(header, style: theme.textTheme.labelLarge),
                    ),
                    StatusChip(
                      label: offerStatusLabel(l10n, status),
                      strong: status == OfferStatus.accepted,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  offer.amount.format(localeTag(context)),
                  style: theme.textTheme.headlineSmall,
                ),
                if (open)
                  Text(
                    l10n.offerExpires(formatDateTime(context, offer.expiresAt)),
                    style: theme.textTheme.bodySmall,
                  ),
                if (open && !mine) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed: () async {
                          if (!await confirmDialog(
                            context,
                            title: l10n.acceptOfferConfirm,
                            message: l10n.acceptOfferHint,
                            confirmLabel: l10n.accept,
                          )) {
                            return;
                          }
                          if (!context.mounted) return;
                          final dealId = await runGuarded(
                            context,
                            () => repo.accept(offer.id),
                          );
                          ref.invalidate(
                            conversationDealIdProvider(offer.conversationId),
                          );
                          if (dealId != null && context.mounted) {
                            context.push(Routes.dealPath(dealId));
                          }
                        },
                        child: Text(l10n.accept),
                      ),
                      if (listing?.negotiable ?? false)
                        OutlinedButton(
                          onPressed: () async {
                            final amount = await showAmountDialog(
                              context,
                              listing: listing!,
                              title: l10n.counterOffer,
                              initialMinor: offer.amountMinor,
                            );
                            if (amount != null && context.mounted) {
                              await runGuarded(
                                context,
                                () => repo.counter(offer.id, amount),
                              );
                            }
                          },
                          child: Text(l10n.counter),
                        ),
                      TextButton(
                        onPressed: () =>
                            runGuarded(context, () => repo.reject(offer.id)),
                        child: Text(l10n.reject),
                      ),
                    ],
                  ),
                ],
                if (open && mine)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          runGuarded(context, () => repo.cancel(offer.id)),
                      child: Text(l10n.withdrawOffer),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
