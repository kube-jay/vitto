import '../../../app/localization/generated/app_localizations.dart';
import '../domain/deal_status.dart';

String dealStatusLabel(AppLocalizations l10n, DealStatus s) => switch (s) {
  DealStatus.awaitingPayment => l10n.dealStatusAwaitingPayment,
  DealStatus.paid => l10n.dealStatusPaid,
  DealStatus.awaitingHandover => l10n.dealStatusAwaitingHandover,
  DealStatus.completed => l10n.dealStatusCompleted,
  DealStatus.cancelled => l10n.dealStatusCancelled,
  DealStatus.disputed => l10n.dealStatusDisputed,
};

String payoutStatusLabel(AppLocalizations l10n, String s) => switch (s) {
  'eligible' => l10n.payoutEligible,
  'requested' => l10n.payoutRequested,
  'paid' => l10n.payoutPaid,
  'failed' => l10n.payoutFailed,
  'reversed' => l10n.payoutReversed,
  _ => l10n.payoutNotEligible,
};
