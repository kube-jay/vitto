import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/common.dart';
import '../../auth/data/session_provider.dart';
import '../../listings/presentation/widgets/listing_card.dart';
import '../data/conversation_repository.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final uid = ref.watch(currentUserIdProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(inboxProvider),
      child: AsyncBody(
        value: ref.watch(inboxProvider),
        onRetry: () => ref.invalidate(inboxProvider),
        builder: (items) => items.isEmpty
            ? ListView(
                children: [
                  EmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: l10n.inboxEmpty,
                    message: l10n.inboxEmptyHint,
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: items.length + 1,
                separatorBuilder: (_, _) => const Divider(indent: 88),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Text(
                        l10n.navInbox,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    );
                  }
                  final c = items[i - 1];
                  final other = c.otherParty(uid ?? '');
                  final listing = c.listing;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: SizedBox(
                      width: 56,
                      height: 56,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ListingImage(path: listing?.coverPath),
                      ),
                    ),
                    title: Text(
                      listing?.title ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: c.hasUnread
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                    subtitle: Text(
                      '${other?.displayName ?? ''} · '
                      '${c.isBuyer(uid ?? '') ? l10n.youAreBuying : l10n.youAreSelling}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatDate(context, c.lastMessageAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (c.hasUnread)
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: VittoColors.navy,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    onTap: () => context.push(Routes.conversationPath(c.id)),
                  );
                },
              ),
      ),
    );
  }
}
