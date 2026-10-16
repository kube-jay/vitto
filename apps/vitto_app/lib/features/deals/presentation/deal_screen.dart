import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/utils/picked_image.dart';
import '../../../core/widgets/common.dart';
import '../../auth/data/session_provider.dart';
import '../../listings/presentation/widgets/listing_card.dart';
import '../../ratings/data/rating_repository.dart';
import '../../reports/data/report_repository.dart';
import '../data/deal_repository.dart';
import '../domain/deal.dart';
import '../domain/deal_status.dart';
import 'deal_labels.dart';

/// One Deal from agreement to rating (Part I §10–16).
class DealScreen extends ConsumerWidget {
  const DealScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return AsyncBody(
      value: ref.watch(dealProvider(id)),
      onRetry: () => ref.invalidate(dealProvider(id)),
      builder: (deal) => deal == null
          ? EmptyState(icon: Icons.lock_outline, title: l10n.errForbidden)
          : _DealView(deal: deal),
    );
  }
}

class _DealView extends ConsumerWidget {
  const _DealView({required this.deal});

  final Deal deal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final uid = ref.watch(currentUserIdProvider);
    final isParticipant = deal.isBuyer(uid) || deal.isSeller(uid);
    final other = deal.counterpart(uid);
    final listing = deal.listing;
    final s = deal.status;
    final type = deal.transactionType;

    Widget panel;
    if (!isParticipant) {
      panel = _AdminNote(deal: deal);
    } else if (s == DealStatus.awaitingPayment && type == null) {
      panel = _ChooseMode(deal: deal);
    } else if (s == DealStatus.awaitingPayment) {
      panel = _OnlinePayment(deal: deal);
    } else if ((s == DealStatus.paid || s == DealStatus.awaitingHandover) &&
        type == TransactionType.online) {
      panel = _OnlineHandover(deal: deal);
    } else if (s == DealStatus.awaitingHandover) {
      panel = _OfflineHandover(deal: deal);
    } else if (s == DealStatus.completed) {
      panel = _Completed(deal: deal);
    } else if (s == DealStatus.disputed) {
      panel = _Disputed(deal: deal);
    } else {
      panel = _InfoBox(icon: Icons.block, text: l10n.dealCancelledNote);
    }

    return PageBody(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: listing == null
                      ? null
                      : () => context.push(Routes.listingPath(listing.id)),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: ListingImage(path: listing?.coverPath),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              listing?.title ?? '—',
                              style: theme.textTheme.titleMedium,
                            ),
                            Text(
                              deal.agreed.format(localeTag(context)),
                              style: theme.textTheme.titleLarge,
                            ),
                            if (deal.originalAmountMinor !=
                                deal.agreedAmountMinor)
                              Text(
                                l10n.listedPrice(
                                  deal.original.format(localeTag(context)),
                                ),
                                style: const TextStyle(
                                  color: VittoColors.muted,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusChip(
                      label: dealStatusLabel(l10n, s),
                      strong: s == DealStatus.completed,
                    ),
                    if (type != null)
                      StatusChip(
                        label: type == TransactionType.online
                            ? l10n.modeOnline
                            : l10n.modeOffline,
                      ),
                    if (isParticipant)
                      StatusChip(
                        label: deal.isBuyer(uid)
                            ? l10n.youAreBuying
                            : l10n.youAreSelling,
                      ),
                  ],
                ),
                if (other != null) ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      ProfileAvatar(profile: other, radius: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () =>
                              context.push(Routes.profilePath(other.id)),
                          child: Text(other.displayName),
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: Text(l10n.chat),
                        onPressed: () => context.push(
                          Routes.conversationPath(deal.conversationId),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _Steps(deal: deal),
        const SizedBox(height: 16),
        panel,
        if (isParticipant) _SecondaryActions(deal: deal),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.icon, required this.text, this.child});

  final IconData icon;
  final String text;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VittoColors.navySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: VittoColors.navy),
              const SizedBox(width: 10),
              Expanded(child: Text(text)),
            ],
          ),
          if (child != null) ...[const SizedBox(height: 14), child!],
        ],
      ),
    );
  }
}

/// Simple progress list: what is done and what comes next.
class _Steps extends StatelessWidget {
  const _Steps({required this.deal});

  final Deal deal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = deal.status;
    final online = deal.transactionType == TransactionType.online;
    final done = s == DealStatus.completed;
    final steps = <(String, bool)>[
      (l10n.stepAgreed, true),
      (l10n.stepModeChosen, deal.transactionType != null),
      if (online) (l10n.stepPaid, s != DealStatus.awaitingPayment),
      (online ? l10n.stepHandoverCode : l10n.stepBothConfirm, done),
      (l10n.stepRate, done),
    ];
    if (s == DealStatus.cancelled) return const SizedBox.shrink();
    return Column(
      children: [
        for (final (label, ok) in steps)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Icon(
                  ok ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 20,
                  color: ok ? VittoColors.navy : VittoColors.line,
                ),
                const SizedBox(width: 10),
                Text(label),
              ],
            ),
          ),
      ],
    );
  }
}

class _ChooseMode extends ConsumerWidget {
  const _ChooseMode({required this.deal});

  final Deal deal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(dealRepositoryProvider);
    Widget option(
      IconData icon,
      String title,
      String body,
      TransactionType mode,
    ) => Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          if (await confirmDialog(context, title: title, message: body)) {
            if (context.mounted) {
              await runGuarded(context, () => repo.selectMode(deal.id, mode));
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 32, color: VittoColors.navy),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(body),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.chooseModeTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        option(
          Icons.credit_card,
          l10n.modeOnline,
          l10n.modeOnlineHint,
          TransactionType.online,
        ),
        const SizedBox(height: 8),
        option(
          Icons.people_outline,
          l10n.modeOffline,
          l10n.modeOfflineHint,
          TransactionType.offline,
        ),
      ],
    );
  }
}

class _OnlinePayment extends ConsumerWidget {
  const _OnlinePayment({required this.deal});

  final Deal deal;

  Future<void> _pay(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(dealRepositoryProvider);
    final start = await runGuarded(context, () => repo.startPayment(deal.id));
    if (start == null || !context.mounted) return;
    if (start.mode == 'mock') {
      final success = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.testPaymentTitle),
          content: Text(l10n.testPaymentBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.simulateFailure),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.simulateSuccess),
            ),
          ],
        ),
      );
      if (success != null && context.mounted) {
        await runGuarded(
          context,
          () => repo.completeMockPayment(start.reference, success: success),
        );
      }
    } else if (start.checkoutUrl != null) {
      await launchUrl(
        Uri.parse(start.checkoutUrl!),
        webOnlyWindowName: '_self',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final uid = ref.watch(currentUserIdProvider);
    final payments = ref.watch(dealPaymentsProvider(deal.id)).value ?? const [];
    final pending = payments.where((p) => p.status == 'pending').toList();
    final failed = payments.isNotEmpty && payments.last.status == 'failed';

    if (!deal.isBuyer(uid)) {
      return _InfoBox(
        icon: Icons.hourglass_top,
        text: pending.isEmpty
            ? l10n.waitingForPayment
            : l10n.paymentPendingNote,
      );
    }
    return _InfoBox(
      icon: Icons.lock_outline,
      text: l10n.payOnlineHint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l10n.paymentFailedNote,
                style: const TextStyle(color: VittoColors.danger),
              ),
            ),
          if (pending.isNotEmpty) ...[
            Text(l10n.paymentPendingNote),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => runGuarded(
                context,
                () => ref.read(dealRepositoryProvider).reconcile(deal.id),
              ),
              child: Text(l10n.checkPaymentStatus),
            ),
            const SizedBox(height: 8),
          ],
          FilledButton(
            onPressed: () => _pay(context, ref),
            child: Text(l10n.payAmount(deal.agreed.format(localeTag(context)))),
          ),
        ],
      ),
    );
  }
}

class _OnlineHandover extends ConsumerWidget {
  const _OnlineHandover({required this.deal});

  final Deal deal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final uid = ref.watch(currentUserIdProvider);
    final repo = ref.read(dealRepositoryProvider);
    final problem = deal.confirmationProblemAt != null;

    if (deal.isBuyer(uid)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (problem)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _InfoBox(
                icon: Icons.help_outline,
                text: l10n.didYouReceive,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed: () async {
                        if (await confirmDialog(
                          context,
                          title: l10n.confirmReceivedTitle,
                          message: l10n.confirmReceivedBody,
                        )) {
                          if (context.mounted) {
                            await runGuarded(
                              context,
                              () => repo.buyerAnswer(deal.id, true, null),
                            );
                          }
                        }
                      },
                      child: Text(l10n.yesReceived),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        final note = await textPrompt(
                          context,
                          title: l10n.describeProblem,
                          required: true,
                        );
                        if (note != null && context.mounted) {
                          await runGuarded(
                            context,
                            () => repo.buyerAnswer(deal.id, false, note),
                          );
                        }
                      },
                      child: Text(l10n.noProblem),
                    ),
                  ],
                ),
              ),
            ),
          _InfoBox(
            icon: Icons.verified_user_outlined,
            text: l10n.codeBuyerHint,
            child: _CodePanel(dealId: deal.id),
          ),
        ],
      );
    }

    // Seller
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoBox(
          icon: Icons.inventory_2_outlined,
          text: deal.status == DealStatus.paid
              ? l10n.paidSellerHint
              : l10n.codeSellerHint,
          child: _CodeEntry(dealId: deal.id),
        ),
        const SizedBox(height: 12),
        if (problem)
          Text(l10n.waitingBuyerAnswer)
        else
          OutlinedButton.icon(
            icon: const Icon(Icons.report_gmailerrorred),
            label: Text(l10n.problemWithConfirmation),
            onPressed: () async {
              final note = await textPrompt(
                context,
                title: l10n.problemWithConfirmation,
                hint: l10n.problemWithConfirmationHint,
              );
              if (note != null && context.mounted) {
                await runGuarded(
                  context,
                  () => repo.reportConfirmationProblem(deal.id, note),
                );
              }
            },
          ),
      ],
    );
  }
}

/// Buyer's 6-digit code with a live expiry countdown (DEC-13).
class _CodePanel extends ConsumerStatefulWidget {
  const _CodePanel({required this.dealId});

  final String dealId;

  @override
  ConsumerState<_CodePanel> createState() => _CodePanelState();
}

class _CodePanelState extends ConsumerState<_CodePanel> {
  String? _code;
  DateTime? _expires;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _generate() async {
    final l10n = AppLocalizations.of(context);
    if (!await confirmDialog(
      context,
      title: l10n.showCodeConfirmTitle,
      message: l10n.showCodeConfirmBody,
    )) {
      return;
    }
    if (!mounted) return;
    final res = await runGuarded(
      context,
      () => ref.read(dealRepositoryProvider).handoverCode(widget.dealId),
    );
    if (res == null || !mounted) return;
    setState(() {
      _code = res.code;
      _expires = res.expiresAt;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final left = _expires?.difference(DateTime.now());
    final expired = left != null && left.isNegative;
    if (_code == null || expired) {
      return FilledButton(
        onPressed: _generate,
        child: Text(expired ? l10n.newCode : l10n.showMyCode),
      );
    }
    final mm = left!.inMinutes.toString().padLeft(2, '0');
    final ss = (left.inSeconds % 60).toString().padLeft(2, '0');
    return Column(
      children: [
        SelectableText(
          _code!.split('').join(' '),
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: VittoColors.navy,
            letterSpacing: 4,
          ),
        ),
        Text(l10n.codeExpiresIn('$mm:$ss')),
        TextButton(onPressed: _generate, child: Text(l10n.newCode)),
      ],
    );
  }
}

class _CodeEntry extends ConsumerStatefulWidget {
  const _CodeEntry({required this.dealId});

  final String dealId;

  @override
  ConsumerState<_CodeEntry> createState() => _CodeEntryState();
}

class _CodeEntryState extends ConsumerState<_CodeEntry> {
  final _code = TextEditingController();
  String? _message;
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!RegExp(r'^\d{6}$').hasMatch(_code.text)) {
      setState(() => _message = l10n.codeSixDigits);
      return;
    }
    setState(() => _busy = true);
    final res = await runGuarded(
      context,
      () => ref
          .read(dealRepositoryProvider)
          .confirmOnline(widget.dealId, _code.text),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (res == null) return;
      _message = res.ok
          ? null
          : switch (res.error) {
              'invalid_code' => l10n.codeInvalid(res.attemptsLeft ?? 0),
              'code_expired' => l10n.codeExpired,
              'code_locked' => l10n.codeLocked,
              _ => l10n.codeNotGenerated,
            };
    });
    if (res?.ok == true) {
      ref.invalidate(dealPayoutProvider(widget.dealId));
      showSnack(context, l10n.dealCompletedSnack);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _code,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(letterSpacing: 8),
          decoration: InputDecoration(
            hintText: '••••••',
            counterText: '',
            errorText: _message,
          ),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(l10n.confirmHandover),
        ),
      ],
    );
  }
}

class _OfflineHandover extends ConsumerWidget {
  const _OfflineHandover({required this.deal});

  final Deal deal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final uid = ref.watch(currentUserIdProvider);
    final confirmed =
        ref.watch(dealConfirmationsProvider(deal.id)).value ?? const {};
    final iConfirmed = confirmed.contains(uid);
    final otherConfirmed = confirmed.length - (iConfirmed ? 1 : 0) > 0;

    return _InfoBox(
      icon: Icons.people_outline,
      text: l10n.offlineHint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ConfirmRow(label: l10n.you, done: iConfirmed),
          _ConfirmRow(label: l10n.theOtherParty, done: otherConfirmed),
          const SizedBox(height: 10),
          if (!iConfirmed)
            FilledButton(
              onPressed: () async {
                if (await confirmDialog(
                  context,
                  title: l10n.confirmExchangeTitle,
                  message: l10n.confirmExchangeBody,
                )) {
                  if (!context.mounted) return;
                  await runGuarded(
                    context,
                    () => ref
                        .read(dealRepositoryProvider)
                        .confirmOffline(deal.id),
                  );
                  ref.invalidate(dealConfirmationsProvider(deal.id));
                }
              },
              child: Text(l10n.confirmExchange),
            )
          else
            Text(l10n.waitingOtherConfirm),
        ],
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({required this.label, required this.done});

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.schedule,
            size: 18,
            color: done ? VittoColors.navy : VittoColors.muted,
          ),
          const SizedBox(width: 8),
          Text('$label: ${done ? l10n.confirmed : l10n.notYetConfirmed}'),
        ],
      ),
    );
  }
}

class _Completed extends ConsumerWidget {
  const _Completed({required this.deal});

  final Deal deal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final uid = ref.watch(currentUserIdProvider);
    final payout =
        deal.isSeller(uid) && deal.transactionType == TransactionType.online
        ? ref.watch(dealPayoutProvider(deal.id)).value
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoBox(
          icon: Icons.celebration_outlined,
          text: l10n.dealCompletedNote,
        ),
        if (payout != null) ...[
          const SizedBox(height: 12),
          _InfoBox(
            icon: Icons.account_balance_wallet_outlined,
            text: '${l10n.payout}: ${payoutStatusLabel(l10n, payout.status)}',
          ),
        ],
        const SizedBox(height: 16),
        _RatingSection(deal: deal),
      ],
    );
  }
}

class _RatingSection extends ConsumerStatefulWidget {
  const _RatingSection({required this.deal});

  final Deal deal;

  @override
  ConsumerState<_RatingSection> createState() => _RatingSectionState();
}

class _RatingSectionState extends ConsumerState<_RatingSection> {
  int _stars = 0;
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final uid = ref.watch(currentUserIdProvider);
    final other = widget.deal.counterpart(uid);
    final mine = ref.watch(myDealRatingProvider(widget.deal.id));
    return mine.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => ErrorState(error: e),
      data: (rating) {
        if (rating != null) {
          return Row(
            children: [
              Text('${l10n.yourRating}: '),
              StarRow(value: rating.stars.toDouble()),
            ],
          );
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.rateUser(other?.displayName ?? ''),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (var i = 1; i <= 5; i++)
                      IconButton(
                        tooltip: '$i',
                        iconSize: 34,
                        onPressed: () => setState(() => _stars = i),
                        icon: Icon(
                          i <= _stars ? Icons.star : Icons.star_border,
                          color: const Color(0xFFF2A900),
                        ),
                      ),
                  ],
                ),
                TextField(
                  controller: _comment,
                  maxLength: 500,
                  maxLines: 2,
                  decoration: InputDecoration(hintText: l10n.ratingCommentHint),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _stars == 0
                      ? null
                      : () async {
                          await runGuarded(
                            context,
                            () => ref
                                .read(ratingRepositoryProvider)
                                .submit(
                                  widget.deal.id,
                                  _stars,
                                  _comment.text.trim().isEmpty
                                      ? null
                                      : _comment.text.trim(),
                                ),
                          );
                          ref.invalidate(myDealRatingProvider(widget.deal.id));
                        },
                  child: Text(l10n.submitRating),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Disputed extends ConsumerWidget {
  const _Disputed({required this.deal});

  final Deal deal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final uid = ref.watch(currentUserIdProvider);
    final evidence = ref.watch(dealEvidenceProvider(deal.id)).value ?? const [];
    return _InfoBox(
      icon: Icons.gavel_outlined,
      text: l10n.disputedNote,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.evidenceFiles(evidence.length)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.upload_file),
            label: Text(l10n.addEvidence),
            onPressed: () async {
              final img = await pickSingleImage();
              if (img == null || !context.mounted) return;
              final note = await textPrompt(context, title: l10n.evidenceNote);
              if (!context.mounted) return;
              await runGuarded(
                context,
                () => ref
                    .read(reportRepositoryProvider)
                    .addEvidence(
                      dealId: deal.id,
                      uid: uid!,
                      bytes: img.bytes,
                      mime: img.mime,
                      note: note,
                    ),
              );
              ref.invalidate(dealEvidenceProvider(deal.id));
            },
          ),
        ],
      ),
    );
  }
}

class _AdminNote extends ConsumerWidget {
  const _AdminNote({required this.deal});

  final Deal deal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final evidence = ref.watch(dealEvidenceProvider(deal.id)).value ?? const [];
    return _InfoBox(
      icon: Icons.admin_panel_settings_outlined,
      text: l10n.adminViewingDeal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (deal.confirmationProblemNote != null)
            Text('${l10n.sellerNote}: ${deal.confirmationProblemNote}'),
          for (final e in evidence)
            TextButton.icon(
              icon: const Icon(Icons.attachment),
              label: Text(
                '${formatDateTime(context, e.createdAt)} ${e.note ?? ''}',
              ),
              onPressed: () async {
                final url = await runGuarded(
                  context,
                  () => ref.read(reportRepositoryProvider).evidenceUrl(e.path),
                );
                if (url != null) await launchUrl(Uri.parse(url));
              },
            ),
        ],
      ),
    );
  }
}

/// Cancel (DEC-07) and dispute entry points.
class _SecondaryActions extends ConsumerWidget {
  const _SecondaryActions({required this.deal});

  final Deal deal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(dealRepositoryProvider);
    final s = deal.status;
    final canCancel =
        s == DealStatus.awaitingPayment ||
        (s == DealStatus.awaitingHandover &&
            deal.transactionType == TransactionType.offline);
    final canDispute = s == DealStatus.paid || s == DealStatus.awaitingHandover;
    final canSwitch =
        deal.transactionType != null &&
        (s == DealStatus.awaitingPayment ||
            (s == DealStatus.awaitingHandover &&
                deal.transactionType == TransactionType.offline));
    if (!canCancel && !canDispute) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (canSwitch)
            TextButton(
              onPressed: () => runGuarded(
                context,
                () => repo.selectMode(
                  deal.id,
                  deal.transactionType == TransactionType.online
                      ? TransactionType.offline
                      : TransactionType.online,
                ),
              ),
              child: Text(
                deal.transactionType == TransactionType.online
                    ? l10n.switchToOffline
                    : l10n.switchToOnline,
              ),
            ),
          if (canCancel)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: VittoColors.danger),
              onPressed: () async {
                final reason = await textPrompt(
                  context,
                  title: l10n.cancelDealTitle,
                  hint: l10n.cancelDealHint,
                );
                if (reason != null && context.mounted) {
                  await runGuarded(context, () => repo.cancel(deal.id, reason));
                }
              },
              child: Text(l10n.cancelDeal),
            ),
          if (canDispute)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: VittoColors.danger),
              onPressed: () async {
                final details = await textPrompt(
                  context,
                  title: l10n.reportProblemTitle,
                  hint: l10n.reportProblemHint,
                  required: true,
                );
                if (details != null && context.mounted) {
                  await runGuarded(
                    context,
                    () => repo.raiseDispute(deal.id, 'other', details),
                  );
                }
              },
              child: Text(l10n.reportProblem),
            ),
        ],
      ),
    );
  }
}
