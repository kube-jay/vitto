import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/common.dart';
import '../../auth/data/session_provider.dart';
import '../../deals/domain/deal_status.dart';
import '../../deals/presentation/deal_labels.dart';
import '../../listings/domain/listing_status.dart';
import '../../listings/presentation/widgets/listing_card.dart';
import '../../offers/data/offer_repository.dart';
import '../../offers/domain/offer.dart';
import '../../offers/domain/offer_status.dart';
import '../../offers/presentation/offer_widgets.dart';
import '../../reports/presentation/report_dialog.dart';
import '../data/conversation_repository.dart';
import '../domain/conversation.dart';

/// Listing-linked chat with structured Offers (Part I §8–9).
class ConversationScreen extends ConsumerWidget {
  const ConversationScreen({
    super.key,
    required this.id,
    this.openOffer = false,
  });

  final String id;
  final bool openOffer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return AsyncBody(
      value: ref.watch(conversationProvider(id)),
      onRetry: () => ref.invalidate(conversationProvider(id)),
      builder: (c) => c == null
          ? EmptyState(icon: Icons.lock_outline, title: l10n.errForbidden)
          : _Chat(conversation: c, openOffer: openOffer),
    );
  }
}

class _Chat extends ConsumerStatefulWidget {
  const _Chat({required this.conversation, required this.openOffer});

  final Conversation conversation;
  final bool openOffer;

  @override
  ConsumerState<_Chat> createState() => _ChatState();
}

class _ChatState extends ConsumerState<_Chat> {
  final _text = TextEditingController();
  bool _sending = false;

  Conversation get c => widget.conversation;

  @override
  void initState() {
    super.initState();
    _markRead();
    if (widget.openOffer) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _makeOffer());
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _markRead() {
    ref
        .read(conversationRepositoryProvider)
        .markRead(c.id)
        .then((_) => ref.invalidate(inboxProvider))
        .catchError((_) {});
  }

  Future<void> _send() async {
    final body = _text.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    final ok = await runGuarded(context, () async {
      await ref.read(conversationRepositoryProvider).send(c.id, body);
      return true;
    });
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok == true) _text.clear();
  }

  Future<void> _makeOffer() async {
    final l10n = AppLocalizations.of(context);
    final listing = c.listing;
    if (listing == null) return;
    final amount = await showAmountDialog(
      context,
      listing: listing,
      title: listing.negotiable ? l10n.makeOffer : l10n.buyAtThisPrice,
    );
    if (amount == null || !mounted) return;
    await runGuarded(
      context,
      () => ref.read(offerRepositoryProvider).create(c.id, amount),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final uid = ref.watch(currentUserIdProvider) ?? '';
    final other = c.otherParty(uid);
    final listing = c.listing;
    final messages = ref.watch(messagesProvider(c.id));
    final offers =
        ref.watch(conversationOffersProvider(c.id)).value ?? const [];
    final offerById = {for (final o in offers) o.id: o};
    final dealId = ref.watch(conversationDealIdProvider(c.id)).value;
    final isBuyer = c.isBuyer(uid);
    final hasPending = offers.any(
      (o) => o.effectiveStatus == OfferStatus.pending,
    );
    final canOffer =
        isBuyer &&
        listing?.status == ListingStatus.active &&
        !hasPending &&
        dealId == null;

    // New messages → mark read and refresh the deal banner after accept.
    ref.listen(messagesProvider(c.id), (prev, next) {
      _markRead();
      if (next.value?.lastOrNull?.systemType == 'offer_accepted') {
        ref.invalidate(conversationDealIdProvider(c.id));
      }
    });

    return Column(
      children: [
        Material(
          color: VittoColors.white,
          shape: const Border(bottom: BorderSide(color: VittoColors.line)),
          child: ListTile(
            leading: SizedBox(
              width: 48,
              height: 48,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ListingImage(path: listing?.coverPath),
              ),
            ),
            title: Text(
              listing?.title ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${listing?.price.format(localeTag(context)) ?? ''} · ${other?.displayName ?? ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: listing == null
                ? null
                : () => context.push(Routes.listingPath(listing.id)),
            trailing: PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'profile' && other != null) {
                  context.push(Routes.profilePath(other.id));
                } else if (v == 'report' && other != null) {
                  showReportDialog(
                    context,
                    ref,
                    targetKind: 'user',
                    targetId: other.id,
                  );
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'profile', child: Text(l10n.viewProfile)),
                PopupMenuItem(value: 'report', child: Text(l10n.reportUser)),
              ],
            ),
          ),
        ),
        if (dealId != null)
          MaterialBanner(
            backgroundColor: VittoColors.navySoft,
            leading: const Icon(
              Icons.handshake_outlined,
              color: VittoColors.navy,
            ),
            content: Text(l10n.dealCreatedBanner),
            actions: [
              FilledButton(
                onPressed: () => context.push(Routes.dealPath(dealId)),
                child: Text(l10n.openDeal),
              ),
            ],
          ),
        Expanded(
          child: AsyncBody(
            value: messages,
            onRetry: () => ref.invalidate(messagesProvider(c.id)),
            builder: (items) {
              if (items.isEmpty) {
                return EmptyState(
                  icon: Icons.waving_hand_outlined,
                  title: l10n.startConversation,
                  message: l10n.chatSafetyHint,
                );
              }
              final reversed = items.reversed.toList();
              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(12),
                itemCount: reversed.length,
                itemBuilder: (context, i) => _MessageItem(
                  message: reversed[i],
                  myId: uid,
                  offer: offerById[reversed[i].offerId],
                  conversation: c,
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: VittoColors.line)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (canOffer)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.local_offer_outlined),
                        label: Text(
                          listing!.negotiable
                              ? l10n.makeOffer
                              : l10n.buyAtThisPrice,
                        ),
                        onPressed: _makeOffer,
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _text,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: 2000,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: InputDecoration(
                          hintText: l10n.writeMessage,
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: l10n.send,
                      onPressed: _sending ? null : _send,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageItem extends StatelessWidget {
  const _MessageItem({
    required this.message,
    required this.myId,
    required this.offer,
    required this.conversation,
  });

  final Message message;
  final String myId;
  final Offer? offer;
  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final mine = message.senderId == myId;

    switch (message.systemType) {
      case 'offer_created' || 'offer_countered':
        if (offer == null) return const SizedBox.shrink();
        return OfferCard(
          offer: offer!,
          myId: myId,
          listing: conversation.listing,
          isCounter: message.systemType == 'offer_countered',
        );
      case 'offer_accepted' ||
          'offer_rejected' ||
          'offer_cancelled' ||
          'deal_update':
        final who = mine ? 'you' : 'other';
        final text = switch (message.systemType) {
          'offer_accepted' => l10n.sysOfferAccepted(who),
          'offer_rejected' => l10n.sysOfferRejected(who),
          'offer_cancelled' => l10n.sysOfferCancelled(who),
          _ => l10n.sysDealUpdate(
            dealStatusLabel(l10n, DealStatus.fromWire(message.body)),
          ),
        };
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: VittoColors.muted,
              ),
            ),
          ),
        );
    }

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? VittoColors.navy : VittoColors.field,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SelectableText(
              message.body,
              style: TextStyle(
                color: mine ? VittoColors.white : VittoColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              TimeOfDay.fromDateTime(
                message.createdAt.toLocal(),
              ).format(context),
              style: theme.textTheme.labelSmall?.copyWith(
                color: mine ? Colors.white70 : VittoColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
