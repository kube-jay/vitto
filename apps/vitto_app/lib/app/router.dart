import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/widgets/app_shell.dart';
import '../features/admin/presentation/admin_screen.dart';
import '../features/auth/data/session_provider.dart';
import '../features/auth/presentation/auth_screens.dart';
import '../features/conversations/presentation/conversation_screen.dart';
import '../features/conversations/presentation/inbox_screen.dart';
import '../features/deals/presentation/deal_screen.dart';
import '../features/deals/presentation/deals_screen.dart';
import '../features/discovery/data/discovery_repository.dart';
import '../features/discovery/presentation/home_screen.dart';
import '../features/discovery/presentation/search_screen.dart';
import '../features/favorites/presentation/favorites_screen.dart';
import '../features/help/presentation/static_pages.dart';
import '../features/listings/presentation/listing_details_screen.dart';
import '../features/listings/presentation/listing_form_screen.dart';
import '../features/listings/presentation/my_listings_screen.dart';
import '../features/profile/presentation/profile_screens.dart';
import '../features/reports/presentation/report_dialog.dart';
import 'routes.dart';

GoRoute _route(String path, Widget Function(GoRouterState s) build) =>
    GoRoute(path: path, builder: (_, s) => build(s));

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(isSignedInProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
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
        final from = state.uri.queryParameters['from'];
        return from != null && from.startsWith('/') ? from : Routes.home;
      }
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.matchedLocation, child: child),
        routes: [
          _route(Routes.home, (_) => const HomeScreen()),
          _route(
            Routes.search,
            (s) => SearchScreen(
              filters: SearchFilters.fromQuery(s.uri.queryParameters),
            ),
          ),
          _route(
            Routes.category,
            (s) => CategoryScreen(
              slug: s.pathParameters['slug']!,
              query: s.uri.queryParameters,
            ),
          ),
          _route(
            Routes.editListing,
            (s) => ListingFormScreen(listingId: s.pathParameters['id']),
          ),
          _route(
            Routes.listing,
            (s) => ListingDetailsScreen(id: s.pathParameters['id']!),
          ),
          _route(
            Routes.publicProfile,
            (s) => PublicProfileScreen(id: s.pathParameters['id']!),
          ),
          _route(
            Routes.login,
            (s) => LoginScreen(from: s.uri.queryParameters['from']),
          ),
          _route(Routes.signup, (_) => const SignupScreen()),
          _route(Routes.resetPassword, (_) => const ResetPasswordScreen()),
          _route(Routes.newPassword, (_) => const NewPasswordScreen()),
          _route(Routes.help, (_) => const HelpScreen()),
          _route(Routes.terms, (_) => const LegalScreen(terms: true)),
          _route(Routes.privacy, (_) => const LegalScreen(terms: false)),
          _route(Routes.me, (_) => const MyProfileScreen()),
          _route(Routes.editProfile, (_) => const EditProfileScreen()),
          _route(Routes.sell, (_) => const ListingFormScreen()),
          _route(Routes.myListings, (_) => const MyListingsScreen()),
          _route(Routes.favorites, (_) => const FavoritesScreen()),
          _route(Routes.inbox, (_) => const InboxScreen()),
          _route(
            Routes.conversation,
            (s) => ConversationScreen(
              id: s.pathParameters['id']!,
              openOffer: s.uri.queryParameters['offer'] == '1',
            ),
          ),
          _route(Routes.deals, (_) => const DealsScreen()),
          _route(Routes.deal, (s) => DealScreen(id: s.pathParameters['id']!)),
          _route(Routes.reports, (_) => const MyReportsScreen()),
          _route(Routes.admin, (_) => const AdminScreen()),
          _route(
            Routes.adminTab,
            (s) => AdminScreen(tab: s.pathParameters['tab']!),
          ),
        ],
      ),
    ],
  );

  // Password-recovery links sign the user in; send them to set a password.
  ref.listen(authEventProvider, (_, next) {
    if (next.value?.event == AuthChangeEvent.passwordRecovery) {
      router.go(Routes.newPassword);
    }
  });
  return router;
});
