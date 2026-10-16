// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Vitto';

  @override
  String get tagline => 'Buy and sell in Nigeria and Benin';

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navSell => 'Sell';

  @override
  String get navInbox => 'Inbox';

  @override
  String get navDeals => 'My Deals';

  @override
  String get navFavorites => 'Favorites';

  @override
  String get navProfile => 'My profile';

  @override
  String get navAdmin => 'Admin';

  @override
  String get navHelp => 'Help';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Create account';

  @override
  String get signOut => 'Sign out';

  @override
  String get resetPassword => 'Reset password';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get country => 'Country';

  @override
  String get countryNigeria => 'Nigeria';

  @override
  String get countryBenin => 'Benin';

  @override
  String get searchHint => 'Search Listings';

  @override
  String get categories => 'Categories';

  @override
  String get latestListings => 'Latest Listings';

  @override
  String get noListingsYet => 'No active Listings yet.';

  @override
  String comingSoon(String milestone) {
    return 'This screen is part of milestone $milestone.';
  }

  @override
  String get demoModeBanner => 'Demo mode: no backend configured.';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading…';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get screenListingDetails => 'Listing';

  @override
  String get screenPublicProfile => 'Profile';

  @override
  String get screenCreateListing => 'Create Listing';

  @override
  String get screenEditListing => 'Edit Listing';

  @override
  String get screenMyListings => 'My Listings';

  @override
  String get screenConversation => 'Conversation';

  @override
  String get screenDealDetails => 'Deal';

  @override
  String get screenEditProfile => 'Edit profile';

  @override
  String get screenReports => 'My reports';

  @override
  String get screenAdminUsers => 'Users';

  @override
  String get screenAdminListings => 'Listings';

  @override
  String get screenAdminCategories => 'Categories';

  @override
  String get screenAdminReports => 'Reports';

  @override
  String get screenAdminDisputes => 'Disputes';

  @override
  String get screenAdminPayments => 'Payments & payouts';

  @override
  String get screenTerms => 'Terms of use';

  @override
  String get screenPrivacy => 'Privacy';

  @override
  String get listingStatusDraft => 'Draft';

  @override
  String get listingStatusActive => 'Active';

  @override
  String get listingStatusReserved => 'Reserved';

  @override
  String get listingStatusSold => 'Sold';

  @override
  String get listingStatusArchived => 'Archived';

  @override
  String get listingStatusSuspended => 'Suspended';

  @override
  String get offerStatusPending => 'Pending';

  @override
  String get offerStatusAccepted => 'Accepted';

  @override
  String get offerStatusRejected => 'Rejected';

  @override
  String get offerStatusCountered => 'Countered';

  @override
  String get offerStatusExpired => 'Expired';

  @override
  String get offerStatusCancelled => 'Cancelled';

  @override
  String get dealStatusAwaitingPayment => 'Awaiting payment';

  @override
  String get dealStatusPaid => 'Paid';

  @override
  String get dealStatusAwaitingHandover => 'Awaiting handover';

  @override
  String get dealStatusCompleted => 'Completed';

  @override
  String get dealStatusCancelled => 'Cancelled';

  @override
  String get dealStatusDisputed => 'Disputed';

  @override
  String get conditionNew => 'New';

  @override
  String get conditionUsed => 'Used';

  @override
  String get negotiable => 'Negotiable';

  @override
  String get fixedPrice => 'Fixed price';
}
