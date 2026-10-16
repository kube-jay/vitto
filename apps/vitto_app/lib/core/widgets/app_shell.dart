import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/generated/app_localizations.dart';
import '../../app/localization/locale_controller.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../features/auth/data/session_provider.dart';
import '../config/env.dart';

class _Destination {
  const _Destination(this.path, this.icon, this.label);

  final String path;
  final IconData icon;
  final String Function(AppLocalizations) label;
}

final _destinations = <_Destination>[
  _Destination(Routes.home, Icons.home_outlined, (l) => l.navHome),
  _Destination(Routes.search, Icons.search, (l) => l.navSearch),
  _Destination(Routes.sell, Icons.add_box_outlined, (l) => l.navSell),
  _Destination(Routes.inbox, Icons.chat_bubble_outline, (l) => l.navInbox),
  _Destination(Routes.deals, Icons.handshake_outlined, (l) => l.navDeals),
  _Destination(Routes.me, Icons.person_outline, (l) => l.navProfile),
];

/// Responsive frame: navigation rail on wide screens, bottom bar on phones.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  int get _selectedIndex {
    for (var i = _destinations.length - 1; i >= 0; i--) {
      final path = _destinations[i].path;
      if (path == Routes.home ? location == path : location.startsWith(path)) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.expanded;
    final signedIn = ref.watch(isSignedInProvider);

    void go(int index) => context.go(_destinations[index].path);

    final body = Column(
      children: [
        if (!Env.hasBackend)
          MaterialBanner(
            content: Text(l10n.demoModeBanner),
            actions: const [SizedBox.shrink()],
          ),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Breakpoints.maxContentWidth,
              ),
              child: child,
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () => context.go(Routes.home),
          child: Text(l10n.appTitle),
        ),
        actions: [
          const _LanguageMenu(),
          if (!signedIn)
            TextButton(
              onPressed: () => context.go(Routes.login),
              child: Text(l10n.signIn),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: go,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final d in _destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        label: Text(d.label(l10n)),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: go,
              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,
              destinations: [
                for (final d in _destinations)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    label: d.label(l10n),
                  ),
              ],
            ),
    );
  }
}

class _LanguageMenu extends ConsumerWidget {
  const _LanguageMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<Locale>(
      tooltip: l10n.language,
      icon: const Icon(Icons.translate),
      onSelected: ref.read(localeProvider.notifier).select,
      itemBuilder: (_) => [
        PopupMenuItem(
          value: const Locale('en'),
          child: Text(l10n.languageEnglish),
        ),
        PopupMenuItem(
          value: const Locale('fr'),
          child: Text(l10n.languageFrench),
        ),
      ],
    );
  }
}
