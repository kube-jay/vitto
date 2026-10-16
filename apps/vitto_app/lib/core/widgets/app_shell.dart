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
  const _Destination(this.path, this.icon, this.selectedIcon, this.label);

  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String Function(AppLocalizations) label;
}

/// Five simple tabs, Avito-style. My Deals is reached from the profile.
final _destinations = <_Destination>[
  _Destination(Routes.home, Icons.search, Icons.search, (l) => l.navHome),
  _Destination(
    Routes.favorites,
    Icons.favorite_border,
    Icons.favorite,
    (l) => l.navFavorites,
  ),
  _Destination(
    Routes.sell,
    Icons.add_circle_outline,
    Icons.add_circle,
    (l) => l.navSell,
  ),
  _Destination(
    Routes.inbox,
    Icons.chat_bubble_outline,
    Icons.chat_bubble,
    (l) => l.navInbox,
  ),
  _Destination(
    Routes.me,
    Icons.person_outline,
    Icons.person,
    (l) => l.navProfile,
  ),
];

/// Responsive frame: top header on wide screens, bottom tab bar on phones.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  int? get _selectedIndex {
    for (var i = 0; i < _destinations.length; i++) {
      final path = _destinations[i].path;
      if (path == Routes.home ? location == path : location.startsWith(path)) {
        return i;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.expanded;

    final body = Column(
      children: [
        if (!Env.hasBackend) _DemoStrip(text: l10n.demoModeBanner),
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
      appBar: wide ? _WideHeader(selected: _selectedIndex) : _NarrowHeader(),
      body: body,
      bottomNavigationBar: wide
          ? null
          : DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: VittoColors.line)),
              ),
              child: NavigationBar(
                // NavigationBar needs a valid index; nothing is highlighted
                // visually different on routes outside the five tabs.
                selectedIndex: _selectedIndex ?? 0,
                onDestinationSelected: (i) => context.go(_destinations[i].path),
                destinations: [
                  for (final d in _destinations)
                    NavigationDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: d.label(l10n),
                    ),
                ],
              ),
            ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.go(Routes.home),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          'vitto',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: VittoColors.navy,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}

class _NarrowHeader extends ConsumerWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final signedIn = ref.watch(isSignedInProvider);
    return AppBar(
      title: const _Logo(),
      shape: const Border(bottom: BorderSide(color: VittoColors.line)),
      actions: [
        const _LanguageMenu(),
        if (!signedIn)
          TextButton(
            onPressed: () => context.go(Routes.login),
            child: Text(l10n.signIn),
          ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _WideHeader extends ConsumerWidget implements PreferredSizeWidget {
  const _WideHeader({required this.selected});

  final int? selected;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final signedIn = ref.watch(isSignedInProvider);

    // Between the tablet breakpoint and 1200px, links collapse to icons.
    final showLabels = MediaQuery.sizeOf(context).width >= 1200;

    Widget link(int index) {
      final d = _destinations[index];
      final active = selected == index;
      if (!showLabels) {
        return IconButton(
          tooltip: d.label(l10n),
          onPressed: () => context.go(d.path),
          icon: Icon(active ? d.selectedIcon : d.icon),
          color: active ? VittoColors.navy : VittoColors.ink,
        );
      }
      return TextButton.icon(
        onPressed: () => context.go(d.path),
        icon: Icon(active ? d.selectedIcon : d.icon, size: 20),
        label: Text(d.label(l10n)),
        style: TextButton.styleFrom(
          foregroundColor: active ? VittoColors.navy : VittoColors.ink,
        ),
      );
    }

    return Material(
      color: VittoColors.white,
      shape: const Border(bottom: BorderSide(color: VittoColors.line)),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: Breakpoints.maxContentWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const _Logo(),
                  const SizedBox(width: 16),
                  // Long French labels must never overflow the header.
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Row(
                        children: [
                          link(1),
                          link(3),
                          link(4),
                          const _LanguageMenu(),
                          if (!signedIn)
                            TextButton(
                              onPressed: () => context.go(Routes.login),
                              child: Text(l10n.signIn),
                            ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: () => context.go(Routes.sell),
                            icon: const Icon(Icons.add),
                            label: Text(l10n.postListing),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoStrip extends StatelessWidget {
  const _DemoStrip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: VittoColors.navySoft,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: VittoColors.navy),
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
