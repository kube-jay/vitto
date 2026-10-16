import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../core/widgets/common.dart';
import '../data/report_repository.dart';

String reportReasonLabel(AppLocalizations l10n, String reason) =>
    switch (reason) {
      'prohibited_item' => l10n.reasonProhibited,
      'scam' => l10n.reasonScam,
      'offensive' => l10n.reasonOffensive,
      'wrong_info' => l10n.reasonWrongInfo,
      'no_show' => l10n.reasonNoShow,
      'item_not_received' => l10n.reasonNotReceived,
      _ => l10n.reasonOther,
    };

String reportStatusLabel(AppLocalizations l10n, String status) =>
    switch (status) {
      'reviewing' => l10n.reportReviewing,
      'resolved' => l10n.reportResolved,
      'dismissed' => l10n.reportDismissed,
      _ => l10n.reportOpen,
    };

/// Report a user, Listing or Deal to the admins (DEC-10).
Future<void> showReportDialog(
  BuildContext context,
  WidgetRef ref, {
  required String targetKind,
  required String targetId,
}) async {
  final l10n = AppLocalizations.of(context);
  final sent = await showDialog<bool>(
    context: context,
    builder: (_) => _ReportDialog(targetKind: targetKind, targetId: targetId),
  );
  if (sent == true && context.mounted) {
    ref.invalidate(myReportsProvider);
    showSnack(context, l10n.reportSent);
  }
}

class _ReportDialog extends ConsumerStatefulWidget {
  const _ReportDialog({required this.targetKind, required this.targetId});

  final String targetKind;
  final String targetId;

  @override
  ConsumerState<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends ConsumerState<_ReportDialog> {
  String _reason = 'scam';
  final _details = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.reportTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioGroup<String>(
              groupValue: _reason,
              onChanged: (v) => setState(() => _reason = v!),
              child: Column(
                children: [
                  for (final r in reportReasons)
                    RadioListTile<String>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: r,
                      title: Text(reportReasonLabel(l10n, r)),
                    ),
                ],
              ),
            ),
            TextField(
              controller: _details,
              maxLines: 3,
              maxLength: 2000,
              decoration: InputDecoration(hintText: l10n.reportDetailsHint),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _busy
              ? null
              : () async {
                  setState(() => _busy = true);
                  final ok = await runGuarded(context, () async {
                    await ref
                        .read(reportRepositoryProvider)
                        .create(
                          targetKind: widget.targetKind,
                          targetId: widget.targetId,
                          reason: _reason,
                          details: _details.text.trim(),
                        );
                    return true;
                  });
                  if (!context.mounted) return;
                  setState(() => _busy = false);
                  if (ok == true) Navigator.pop(context, true);
                },
          child: Text(l10n.send),
        ),
      ],
    );
  }
}

class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return AsyncBody(
      value: ref.watch(myReportsProvider),
      onRetry: () => ref.invalidate(myReportsProvider),
      builder: (items) => PageBody(
        children: [
          Text(
            l10n.screenReports,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            EmptyState(icon: Icons.flag_outlined, title: l10n.nothingHere),
          for (final r in items)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(reportReasonLabel(l10n, r.reason)),
                subtitle: Text(
                  [
                    formatDate(context, r.createdAt),
                    if (r.details.isNotEmpty) r.details,
                    ?r.resolutionNote,
                  ].join(' · '),
                ),
                trailing: StatusChip(label: reportStatusLabel(l10n, r.status)),
              ),
            ),
        ],
      ),
    );
  }
}
