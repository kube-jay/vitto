import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/app_shell.dart';
import '../core/widgets/placeholder_screen.dart';
import '../features/auth/data/session_provider.dart';
import '../features/discovery/presentation/home_screen.dart';
import 'localization/generated/app_localizations.dart';
import 'routes.dart';

GoRoute _placeholder(
  String path,
  String milestone,
  String Function(AppLocalizations) title,
) => GoRoute(
  path: path,
  builder: (context, _) => PlaceholderScreen(
    title: title(AppLocalizations.of(context)),
    milestone: milestone,
  ),
);

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(isSignedInProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    refreshListenable: refresh,
    redirect: (context, state) {
      final signedIn = ref.read(isSignedInProvider);
      final location = state.matchedLocation;
      if (!signedIn && !Routes.isPublic(location)) {
        // Preserve the intended route through sign-in (Part II §35).
        return Uri(
          path: Routes.login,
          queryParameters: {'from': state.uri.toString()},
        ).toString();
      }
      if (signedIn && (location == Routes.login || location == Routes.signup)) {
        return state.uri.queryParameters['from'] ?? Routes.home;
      }
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
          _placeholder(Routes.search, 'M2', (l) => l.navSearch),
          _placeholder(Routes.category, 'M2', (l) => l.categories),
          _placeholder(Routes.listing, 'M2', (l) => l.screenListingDetails),
          _placeholder(Routes.editListing, 'M2', (l) => l.screenEditListing),
          _placeholder(
            Routes.publicProfile,
            'M1',
            (l) => l.screenPublicProfile,
          ),
          _placeholder(Routes.login, 'M1', (l) => l.signIn),
          _placeholder(Routes.signup, 'M1', (l) => l.signUp),
          _placeholder(Routes.resetPassword, 'M1', (l) => l.resetPassword),
          _placeholder(Routes.help, 'M7', (l) => l.navHelp),
          _placeholder(Routes.terms, 'M7', (l) => l.screenTerms),
          _placeholder(Routes.privacy, 'M7', (l) => l.screenPrivacy),
          _placeholder(Routes.me, 'M1', (l) => l.navProfile),
          _placeholder(Routes.editProfile, 'M1', (l) => l.screenEditProfile),
          _placeholder(Routes.sell, 'M2', (l) => l.screenCreateListing),
          _placeholder(Routes.myListings, 'M2', (l) => l.screenMyListings),
          _placeholder(Routes.favorites, 'M2', (l) => l.navFavorites),
          _placeholder(Routes.inbox, 'M3', (l) => l.navInbox),
          _placeholder(Routes.conversation, 'M3', (l) => l.screenConversation),
          _placeholder(Routes.deals, 'M4', (l) => l.navDeals),
          _placeholder(Routes.deal, 'M4', (l) => l.screenDealDetails),
          _placeholder(Routes.reports, 'M5', (l) => l.screenReports),
          _placeholder(Routes.admin, 'M7', (l) => l.navAdmin),
          _placeholder(Routes.adminUsers, 'M7', (l) => l.screenAdminUsers),
          _placeholder(
            Routes.adminListings,
            'M7',
            (l) => l.screenAdminListings,
          ),
          _placeholder(
            Routes.adminCategories,
            'M7',
            (l) => l.screenAdminCategories,
          ),
          _placeholder(Routes.adminReports, 'M7', (l) => l.screenAdminReports),
          _placeholder(
            Routes.adminDisputes,
            'M7',
            (l) => l.screenAdminDisputes,
          ),
          _placeholder(
            Routes.adminPayments,
            'M7',
            (l) => l.screenAdminPayments,
          ),
        ],
      ),
    ],
  );
});
