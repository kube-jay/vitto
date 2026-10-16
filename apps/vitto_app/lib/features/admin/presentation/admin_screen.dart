import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/common.dart';
import '../../deals/presentation/deal_labels.dart';
import '../../listings/data/listing_repository.dart';
import '../../listings/domain/listing.dart';
import '../../listings/domain/listing_status.dart';
import '../../listings/presentation/widgets/listing_card.dart';
import '../../profile/data/profile_repository.dart';
import '../../reports/data/report_repository.dart';
import '../../reports/presentation/report_dialog.dart';
import '../data/admin_repository.dart';

const adminTabs = [
  'users',
  'listings',
  'categories',
  'reports',
  'disputes',
  'payments',
];

/// Admin console (Part I §18). Access is enforced by the server; this
/// screen only hides itself from non-admins.
class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key, this.tab = 'reports'});

  final String tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isAdmin = ref.watch(isAdminProvider);
    return AsyncBody(
      value: isAdmin,
      builder: (ok) {
        if (!ok) {
          return EmptyState(icon: Icons.lock_outline, title: l10n.errForbidden);
        }
        final labels = [
          l10n.screenAdminUsers,
          l10n.screenAdminListings,
          l10n.screenAdminCategories,
          l10n.screenAdminReports,
          l10n.screenAdminDisputes,
          l10n.screenAdminPayments,
        ];
        final index = adminTabs.indexOf(tab).clamp(0, adminTabs.length - 1);
        return DefaultTabController(
          length: adminTabs.length,
          initialIndex: index,
          child: Column(
            children: [
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                onTap: (i) => context.replace('/admin/${adminTabs[i]}'),
                tabs: [for (final l in labels) Tab(text: l)],
              ),
              const Expanded(
                child: TabBarView(
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    _UsersTab(),
                    _ListingsTab(),
                    _CategoriesTab(),
                    _ReportsTab(),
                    _DisputesTab(),
                    _PaymentsTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

final _usersQueryProvider = NotifierProvider<_Query, String>(_Query.new);

class _Query extends Notifier<String> {
  @override
  String build() => '';
  void set(String v) => state = v;
}

final _adminUsersProvider = FutureProvider.autoDispose<List<AdminUser>>(
  (ref) =>
      ref.watch(adminRepositoryProvider).users(ref.watch(_usersQueryProvider)),
);

class _UsersTab extends ConsumerWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.searchUsersHint,
            ),
            onSubmitted: ref.read(_usersQueryProvider.notifier).set,
          ),
        ),
        Expanded(
          child: AsyncBody(
            value: ref.watch(_adminUsersProvider),
            onRetry: () => ref.invalidate(_adminUsersProvider),
            builder: (users) => ListView(
              children: [
                for (final u in users)
                  ListTile(
                    title: Text(
                      '${u.displayName}${u.isAdmin ? ' (admin)' : ''}',
                    ),
                    subtitle: Text(
                      '${u.email} · ${u.countryCode} · ${u.city ?? ''} · '
                      '${l10n.completedDealsCount(u.completedDeals)}',
                    ),
                    onTap: () => context.push(Routes.profilePath(u.id)),
                    trailing: u.suspendedAt != null
                        ? OutlinedButton(
                            onPressed: () => _act(context, ref, u, false),
                            child: Text(l10n.restore),
                          )
                        : TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: VittoColors.danger,
                            ),
                            onPressed: u.isAdmin
                                ? null
                                : () => _act(context, ref, u, true),
                            child: Text(l10n.suspend),
                          ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _act(
    BuildContext context,
    WidgetRef ref,
    AdminUser u,
    bool suspend,
  ) async {
    final l10n = AppLocalizations.of(context);
    final reason = await textPrompt(
      context,
      title: suspend ? l10n.suspend : l10n.restore,
      hint: l10n.reasonForRecord,
      required: true,
    );
    if (reason == null || !context.mounted) return;
    await runGuarded(
      context,
      () => ref
          .read(adminRepositoryProvider)
          .setUserSuspension(u.id, suspend, reason),
    );
    ref.invalidate(_adminUsersProvider);
  }
}

final _listingStatusFilter = NotifierProvider<_StatusFilter, String?>(
  _StatusFilter.new,
);

class _StatusFilter extends Notifier<String?> {
  @override
  String? build() => 'active';
  void set(String? v) => state = v;
}

final _adminListingsProvider = FutureProvider.autoDispose<List<Listing>>(
  (ref) => ref
      .watch(adminRepositoryProvider)
      .listings(ref.watch(_listingStatusFilter)),
);

class _ListingsTab extends ConsumerWidget {
  const _ListingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final filter = ref.watch(_listingStatusFilter);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            children: [
              for (final s in ListingStatus.values)
                ChoiceChip(
                  label: Text(listingStatusLabel(l10n, s)),
                  selected: filter == s.wire,
                  onSelected: (_) =>
                      ref.read(_listingStatusFilter.notifier).set(s.wire),
                ),
            ],
          ),
        ),
        Expanded(
          child: AsyncBody(
            value: ref.watch(_adminListingsProvider),
            onRetry: () => ref.invalidate(_adminListingsProvider),
            builder: (items) => ListView(
              children: [
                if (items.isEmpty)
                  EmptyState(icon: Icons.inbox, title: l10n.nothingHere),
                for (final l in items)
                  ListTile(
                    leading: SizedBox(
                      width: 48,
                      height: 48,
                      child: ListingImage(path: l.coverPath),
                    ),
                    title: Text(l.title),
                    subtitle: Text(
                      '${l.price.format(localeTag(context))} · ${l.city}',
                    ),
                    onTap: () => context.push(Routes.listingPath(l.id)),
                    trailing: l.status == ListingStatus.suspended
                        ? OutlinedButton(
                            onPressed: () => _act(context, ref, l, false),
                            child: Text(l10n.restore),
                          )
                        : TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: VittoColors.danger,
                            ),
                            onPressed: () => _act(context, ref, l, true),
                            child: Text(l10n.suspend),
                          ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _act(
    BuildContext context,
    WidgetRef ref,
    Listing l,
    bool suspend,
  ) async {
    final l10n = AppLocalizations.of(context);
    final reason = await textPrompt(
      context,
      title: suspend ? l10n.suspend : l10n.restore,
      hint: l10n.reasonForRecord,
      required: true,
    );
    if (reason == null || !context.mounted) return;
    await runGuarded(
      context,
      () => ref
          .read(adminRepositoryProvider)
          .setListingSuspension(l.id, suspend, reason),
    );
    ref.invalidate(_adminListingsProvider);
  }
}

final _adminCategoriesProvider = FutureProvider.autoDispose<List<Category>>(
  (ref) => ref.watch(adminRepositoryProvider).allCategories(),
);

class _CategoriesTab extends ConsumerWidget {
  const _CategoriesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return AsyncBody(
      value: ref.watch(_adminCategoriesProvider),
      onRetry: () => ref.invalidate(_adminCategoriesProvider),
      builder: (cats) => ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: Text(l10n.addCategory),
              onPressed: () => _edit(context, ref, null),
            ),
          ),
          const SizedBox(height: 8),
          for (final c in cats)
            ListTile(
              leading: Icon(c.icon, color: VittoColors.navy),
              title: Text('${c.nameEn} / ${c.nameFr}'),
              subtitle: Text('${c.slug} · ${c.sortOrder}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: c.active,
                    onChanged: (v) async {
                      await runGuarded(
                        context,
                        () => ref
                            .read(adminRepositoryProvider)
                            .saveCategory(
                              id: c.id,
                              slug: c.slug,
                              nameEn: c.nameEn,
                              nameFr: c.nameFr,
                              sortOrder: c.sortOrder,
                              active: v,
                            ),
                      );
                      ref.invalidate(_adminCategoriesProvider);
                      ref.invalidate(categoriesProvider);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _edit(context, ref, c),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, Category? c) async {
    final l10n = AppLocalizations.of(context);
    final slug = TextEditingController(text: c?.slug);
    final en = TextEditingController(text: c?.nameEn);
    final fr = TextEditingController(text: c?.nameFr);
    final order = TextEditingController(text: '${c?.sortOrder ?? 500}');
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(c == null ? l10n.addCategory : l10n.edit),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: slug,
              decoration: const InputDecoration(labelText: 'slug'),
            ),
            TextField(
              controller: en,
              decoration: const InputDecoration(labelText: 'English'),
            ),
            TextField(
              controller: fr,
              decoration: const InputDecoration(labelText: 'Français'),
            ),
            TextField(
              controller: order,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '#'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (save == true && context.mounted) {
      await runGuarded(
        context,
        () => ref
            .read(adminRepositoryProvider)
            .saveCategory(
              id: c?.id,
              slug: slug.text.trim(),
              nameEn: en.text.trim(),
              nameFr: fr.text.trim(),
              sortOrder: int.tryParse(order.text) ?? 500,
              active: c?.active ?? true,
            ),
      );
      ref.invalidate(_adminCategoriesProvider);
      ref.invalidate(categoriesProvider);
    }
    for (final t in [slug, en, fr, order]) {
      t.dispose();
    }
  }
}

final _reportFilter = NotifierProvider<_StatusFilter2, String?>(
  _StatusFilter2.new,
);

class _StatusFilter2 extends Notifier<String?> {
  @override
  String? build() => 'open';
  void set(String? v) => state = v;
}

final _adminReportsProvider = FutureProvider.autoDispose<List<Report>>(
  (ref) => ref
      .watch(reportRepositoryProvider)
      .list(status: ref.watch(_reportFilter)),
);

class _ReportsTab extends ConsumerWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final filter = ref.watch(_reportFilter);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            children: [
              for (final s in ['open', 'reviewing', 'resolved', 'dismissed'])
                ChoiceChip(
                  label: Text(reportStatusLabel(l10n, s)),
                  selected: filter == s,
                  onSelected: (_) => ref.read(_reportFilter.notifier).set(s),
                ),
            ],
          ),
        ),
        Expanded(
          child: AsyncBody(
            value: ref.watch(_adminReportsProvider),
            onRetry: () => ref.invalidate(_adminReportsProvider),
            builder: (items) => ListView(
              children: [
                if (items.isEmpty)
                  EmptyState(icon: Icons.inbox, title: l10n.nothingHere),
                for (final r in items)
                  Card(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${reportReasonLabel(l10n, r.reason)} · ${r.targetKind}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(formatDateTime(context, r.createdAt)),
                          if (r.details.isNotEmpty) Text(r.details),
                          if (r.resolutionNote != null)
                            Text('→ ${r.resolutionNote}'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              TextButton(
                                onPressed: () => context.push(
                                  switch (r.targetKind) {
                                    'listing' => Routes.listingPath(r.targetId),
                                    'deal' => Routes.dealPath(r.targetId),
                                    _ => Routes.profilePath(r.targetId),
                                  },
                                ),
                                child: Text(l10n.openTarget),
                              ),
                              for (final s in [
                                'reviewing',
                                'resolved',
                                'dismissed',
                              ])
                                if (s != r.status)
                                  OutlinedButton(
                                    onPressed: () async {
                                      final note = await textPrompt(
                                        context,
                                        title: reportStatusLabel(l10n, s),
                                        hint: l10n.reasonForRecord,
                                      );
                                      if (note == null || !context.mounted) {
                                        return;
                                      }
                                      await runGuarded(
                                        context,
                                        () => ref
                                            .read(adminRepositoryProvider)
                                            .updateReport(r.id, s, note),
                                      );
                                      ref.invalidate(_adminReportsProvider);
                                    },
                                    child: Text(reportStatusLabel(l10n, s)),
                                  ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

final _disputesProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(adminRepositoryProvider).disputedDeals(),
);

class _DisputesTab extends ConsumerWidget {
  const _DisputesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return AsyncBody(
      value: ref.watch(_disputesProvider),
      onRetry: () => ref.invalidate(_disputesProvider),
      builder: (deals) => ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (deals.isEmpty)
            EmptyState(icon: Icons.gavel_outlined, title: l10n.nothingHere),
          for (final d in deals)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.listing?.title ?? '—',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      '${d.agreed.format(localeTag(context))} · '
                      '${d.buyer?.displayName ?? ''} → ${d.seller?.displayName ?? ''} · '
                      '${d.transactionType?.wire ?? ''}',
                    ),
                    if (d.confirmationProblemNote != null)
                      Text('${l10n.sellerNote}: ${d.confirmationProblemNote}'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: () => context.push(Routes.dealPath(d.id)),
                          child: Text(l10n.openTarget),
                        ),
                        FilledButton(
                          onPressed: () =>
                              _resolve(context, ref, d.id, 'complete'),
                          child: Text(l10n.resolveComplete),
                        ),
                        OutlinedButton(
                          onPressed: () =>
                              _resolve(context, ref, d.id, 'cancel'),
                          child: Text(l10n.resolveCancel),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _resolve(
    BuildContext context,
    WidgetRef ref,
    String dealId,
    String disposition,
  ) async {
    final l10n = AppLocalizations.of(context);
    final note = await textPrompt(
      context,
      title: disposition == 'complete'
          ? l10n.resolveComplete
          : l10n.resolveCancel,
      hint: l10n.resolveHint,
      required: true,
    );
    if (note == null || !context.mounted) return;
    await runGuarded(
      context,
      () => ref
          .read(adminRepositoryProvider)
          .resolveDispute(dealId, disposition, note),
    );
    ref.invalidate(_disputesProvider);
  }
}

final _payoutsProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(adminRepositoryProvider).payouts(),
);
final _paymentsProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(adminRepositoryProvider).payments(),
);

class _PaymentsTab extends ConsumerWidget {
  const _PaymentsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final payouts = ref.watch(_payoutsProvider);
    final payments = ref.watch(_paymentsProvider).value ?? const [];
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: VittoColors.navySoft,
          child: Text(l10n.payoutGateNote),
        ),
        SectionTitle(l10n.payouts),
        ...payouts.when(
          data: (rows) => [
            if (rows.isEmpty) Text(l10n.nothingHere),
            for (final p in rows)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  Money(p.amountMinor, p.currency).format(localeTag(context)),
                ),
                subtitle: Text(
                  '${payoutStatusLabel(l10n, p.status)}${p.lastError == null ? '' : ' · ${p.lastError}'}',
                ),
                onTap: () => context.push(Routes.dealPath(p.dealId)),
                trailing: p.status == 'eligible' || p.status == 'failed'
                    ? FilledButton(
                        onPressed: () async {
                          if (!await confirmDialog(
                            context,
                            title: l10n.releasePayout,
                          )) {
                            return;
                          }
                          if (!context.mounted) return;
                          await runGuarded(
                            context,
                            () => ref
                                .read(adminRepositoryProvider)
                                .releasePayout(p.dealId),
                          );
                          ref.invalidate(_payoutsProvider);
                        },
                        child: Text(l10n.releasePayout),
                      )
                    : null,
              ),
          ],
          loading: () => [const LinearProgressIndicator()],
          error: (e, _) => [ErrorState(error: e)],
        ),
        SectionTitle(l10n.payments),
        for (final p in payments)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              Money(p.amountMinor, p.currency).format(localeTag(context)),
            ),
            subtitle: Text(
              '${p.provider} · ${p.reference} · ${p.status} · '
              '${formatDateTime(context, p.createdAt)}',
            ),
          ),
      ],
    );
  }
}
