/// Every route path in one place (Part II §28.2). Widgets never hard-code paths.
abstract final class Routes {
  // Public
  static const home = '/';
  static const search = '/search';
  static const category = '/c/:slug';
  static const listing = '/l/:id';
  static const publicProfile = '/u/:id';
  static const login = '/login';
  static const signup = '/signup';
  static const resetPassword = '/reset-password';
  static const help = '/help';
  static const terms = '/terms';
  static const privacy = '/privacy';

  // Authenticated
  static const me = '/me';
  static const editProfile = '/me/edit';
  static const sell = '/sell';
  static const editListing = '/l/:id/edit';
  static const myListings = '/my-listings';
  static const favorites = '/favorites';
  static const inbox = '/inbox';
  static const conversation = '/inbox/:id';
  static const deals = '/deals';
  static const deal = '/deals/:id';
  static const reports = '/reports';

  // Admin (server re-checks the admin role on every privileged call)
  static const admin = '/admin';
  static const adminUsers = '/admin/users';
  static const adminListings = '/admin/listings';
  static const adminCategories = '/admin/categories';
  static const adminReports = '/admin/reports';
  static const adminDisputes = '/admin/disputes';
  static const adminPayments = '/admin/payments';

  static const _publicPrefixes = [
    search,
    '/c/',
    '/u/',
    login,
    signup,
    resetPassword,
    help,
    terms,
    privacy,
  ];

  /// True when [location] can be viewed without signing in.
  static bool isPublic(String location) {
    if (location == home) return true;
    if (location.startsWith('/l/') && !location.endsWith('/edit')) return true;
    return _publicPrefixes.any(location.startsWith);
  }

  static String listingPath(String id) => '/l/$id';
  static String profilePath(String id) => '/u/$id';
  static String conversationPath(String id) => '/inbox/$id';
  static String dealPath(String id) => '/deals/$id';
}
