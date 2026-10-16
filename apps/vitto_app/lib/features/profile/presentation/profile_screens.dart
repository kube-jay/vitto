import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../app/localization/locale_controller.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/utils/picked_image.dart';
import '../../../core/widgets/common.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/session_provider.dart';
import '../../listings/data/listing_repository.dart';
import '../../listings/presentation/widgets/listing_card.dart';
import '../../ratings/data/rating_repository.dart';
import '../../reports/presentation/report_dialog.dart';
import '../data/profile_repository.dart';
import '../domain/profile.dart';

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Row(
      children: [
        ProfileAvatar(profile: profile, radius: 34),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(profile.displayName, style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (profile.ratingCount > 0) ...[
                    Text(
                      profile.averageRating.toStringAsFixed(1),
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(width: 4),
                    StarRow(value: profile.averageRating),
                    const SizedBox(width: 4),
                    Text(l10n.reviewsCount(profile.ratingCount)),
                  ] else
                    Text(l10n.noRatingsYet),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                [
                  l10n.completedDealsCount(profile.completedDealsCount),
                  if (profile.joinedAt != null)
                    l10n.memberSince(formatDate(context, profile.joinedAt!)),
                ].join(' · '),
                style: const TextStyle(color: VittoColors.muted),
              ),
              Text(
                [
                  ?profile.city,
                  profile.countryCode == 'NG'
                      ? l10n.countryNigeria
                      : l10n.countryBenin,
                ].join(', '),
                style: const TextStyle(color: VittoColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "My profile" hub, Avito-style menu.
class MyProfileScreen extends ConsumerWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isAdmin = ref.watch(isAdminProvider).value ?? false;
    return AsyncBody(
      value: ref.watch(myProfileProvider),
      onRetry: () => ref.invalidate(myProfileProvider),
      builder: (p) {
        if (p == null) return const SizedBox.shrink();
        Widget item(IconData icon, String label, VoidCallback onTap) =>
            ListTile(
              leading: Icon(icon, color: VittoColors.navy),
              title: Text(label),
              trailing: const Icon(Icons.chevron_right),
              onTap: onTap,
            );
        return PageBody(
          children: [
            _ProfileHeader(profile: p),
            if (p.isSuspended)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  l10n.accountSuspendedNote,
                  style: const TextStyle(color: VittoColors.danger),
                ),
              ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.push(Routes.profilePath(p.id)),
              child: Text(l10n.viewPublicProfile),
            ),
            const SizedBox(height: 8),
            item(
              Icons.inventory_2_outlined,
              l10n.screenMyListings,
              () => context.push(Routes.myListings),
            ),
            item(
              Icons.handshake_outlined,
              l10n.navDeals,
              () => context.push(Routes.deals),
            ),
            item(
              Icons.favorite_border,
              l10n.navFavorites,
              () => context.push(Routes.favorites),
            ),
            item(
              Icons.flag_outlined,
              l10n.screenReports,
              () => context.push(Routes.reports),
            ),
            item(
              Icons.edit_outlined,
              l10n.screenEditProfile,
              () => context.push(Routes.editProfile),
            ),
            item(Icons.translate, l10n.language, () async {
              final locale = await showDialog<Locale>(
                context: context,
                builder: (context) => SimpleDialog(
                  title: Text(l10n.language),
                  children: [
                    SimpleDialogOption(
                      onPressed: () =>
                          Navigator.pop(context, const Locale('en')),
                      child: Text(l10n.languageEnglish),
                    ),
                    SimpleDialogOption(
                      onPressed: () =>
                          Navigator.pop(context, const Locale('fr')),
                      child: Text(l10n.languageFrench),
                    ),
                  ],
                ),
              );
              if (locale != null) {
                ref.read(localeProvider.notifier).select(locale);
              }
            }),
            item(
              Icons.help_outline,
              l10n.navHelp,
              () => context.push(Routes.help),
            ),
            if (isAdmin)
              item(
                Icons.admin_panel_settings_outlined,
                l10n.navAdmin,
                () => context.push(Routes.admin),
              ),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.logout, color: VittoColors.danger),
              title: Text(
                l10n.signOut,
                style: const TextStyle(color: VittoColors.danger),
              ),
              onTap: () async {
                await runGuarded(
                  context,
                  () => ref.read(authRepositoryProvider).signOut(),
                );
                if (context.mounted) context.go(Routes.home);
              },
            ),
          ],
        );
      },
    );
  }
}

class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final uid = ref.watch(currentUserIdProvider);
    return AsyncBody(
      value: ref.watch(profileProvider(id)),
      onRetry: () => ref.invalidate(profileProvider(id)),
      builder: (p) {
        if (p == null) {
          return EmptyState(
            icon: Icons.person_off_outlined,
            title: l10n.profileUnavailable,
          );
        }
        final listings = ref.watch(sellerListingsProvider(id));
        final ratings = ref.watch(userRatingsProvider(id)).value ?? const [];
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _ProfileHeader(profile: p)),
                        if (uid != null && uid != p.id)
                          IconButton(
                            tooltip: l10n.reportUser,
                            icon: const Icon(Icons.flag_outlined),
                            onPressed: () => showReportDialog(
                              context,
                              ref,
                              targetKind: 'user',
                              targetId: p.id,
                            ),
                          ),
                      ],
                    ),
                    SectionTitle(l10n.activeListings),
                  ],
                ),
              ),
            ),
            ...listings.when(
              data: (items) => [
                if (items.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(l10n.nothingHere),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: ListingSliverGrid(listings: items),
                  ),
              ],
              loading: () => [
                const SliverToBoxAdapter(child: LinearProgressIndicator()),
              ],
              error: (e, _) => [
                SliverToBoxAdapter(child: ErrorState(error: e)),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList.list(
                children: [
                  SectionTitle(l10n.reviews),
                  if (ratings.isEmpty) Text(l10n.noRatingsYet),
                  for (final r in ratings)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: ProfileAvatar(profile: r.author, radius: 18),
                      title: Row(
                        children: [
                          StarRow(value: r.stars.toDouble(), size: 14),
                          const SizedBox(width: 8),
                          Text(
                            formatDate(context, r.createdAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      subtitle: Text(
                        [r.author?.displayName ?? '', ?r.comment].join(' — '),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncBody(
      value: ref.watch(myProfileProvider),
      onRetry: () => ref.invalidate(myProfileProvider),
      builder: (p) =>
          p == null ? const SizedBox.shrink() : _EditProfileForm(profile: p),
    );
  }
}

class _EditProfileForm extends ConsumerStatefulWidget {
  const _EditProfileForm({required this.profile});

  final Profile profile;

  @override
  ConsumerState<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends ConsumerState<_EditProfileForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile.displayName);
  late final _city = TextEditingController(text: widget.profile.city);
  late String _country = widget.profile.countryCode;
  late String? _region = widget.profile.regionCode;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _changeAvatar() async {
    final img = await pickSingleImage();
    if (img == null || !mounted) return;
    final repo = ref.read(profileRepositoryProvider);
    await runGuarded(context, () async {
      final path = await repo.uploadAvatar(
        widget.profile.id,
        img.bytes,
        img.mime,
      );
      await repo.update(widget.profile.id, avatarPath: path);
    });
    ref.invalidate(myProfileProvider);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final ok = await runGuarded(context, () async {
      await ref
          .read(profileRepositoryProvider)
          .update(
            widget.profile.id,
            displayName: _name.text.trim(),
            countryCode: _country,
            regionCode: _region,
            clearRegion: _region == null,
            city: _city.text.trim(),
          );
      return true;
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok == true) {
      ref.invalidate(myProfileProvider);
      showSnack(context, AppLocalizations.of(context).saved);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final regions = ref.watch(regionsProvider(_country)).value ?? const [];
    return Form(
      key: _form,
      child: PageBody(
        children: [
          Text(
            l10n.screenEditProfile,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ProfileAvatar(profile: widget.profile, radius: 34),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: _changeAvatar,
                child: Text(l10n.changePhoto),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _name,
            maxLength: 60,
            decoration: InputDecoration(labelText: l10n.displayName),
            validator: (v) =>
                v == null || v.trim().isEmpty ? l10n.validRequired : null,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _country,
            decoration: InputDecoration(labelText: l10n.country),
            items: [
              DropdownMenuItem(value: 'NG', child: Text(l10n.countryNigeria)),
              DropdownMenuItem(value: 'BJ', child: Text(l10n.countryBenin)),
            ],
            onChanged: (v) => setState(() {
              _country = v!;
              _region = null;
            }),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            key: ValueKey(_country),
            initialValue: regions.any((r) => r.code == _region)
                ? _region
                : null,
            decoration: InputDecoration(labelText: l10n.region),
            items: [
              DropdownMenuItem(value: null, child: Text(l10n.any)),
              for (final r in regions)
                DropdownMenuItem(value: r.code, child: Text(r.name)),
            ],
            onChanged: (v) => setState(() => _region = v),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _city,
            maxLength: 80,
            decoration: InputDecoration(labelText: l10n.city),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _busy ? null : _save, child: Text(l10n.save)),
        ],
      ),
    );
  }
}
