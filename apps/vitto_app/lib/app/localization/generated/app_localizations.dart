import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Vitto'**
  String get appTitle;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Buy and sell in Nigeria and Benin'**
  String get tagline;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navSell.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get navSell;

  /// No description provided for @navInbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get navInbox;

  /// No description provided for @navDeals.
  ///
  /// In en, this message translates to:
  /// **'My Deals'**
  String get navDeals;

  /// No description provided for @navFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get navFavorites;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get navProfile;

  /// No description provided for @navAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get navAdmin;

  /// No description provided for @navHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get navHelp;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUp;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPassword;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @countryNigeria.
  ///
  /// In en, this message translates to:
  /// **'Nigeria'**
  String get countryNigeria;

  /// No description provided for @countryBenin.
  ///
  /// In en, this message translates to:
  /// **'Benin'**
  String get countryBenin;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search Listings'**
  String get searchHint;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @latestListings.
  ///
  /// In en, this message translates to:
  /// **'Latest Listings'**
  String get latestListings;

  /// No description provided for @noListingsYet.
  ///
  /// In en, this message translates to:
  /// **'No active Listings yet.'**
  String get noListingsYet;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'This screen is part of milestone {milestone}.'**
  String comingSoon(String milestone);

  /// No description provided for @demoModeBanner.
  ///
  /// In en, this message translates to:
  /// **'Demo mode: no backend configured.'**
  String get demoModeBanner;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @screenListingDetails.
  ///
  /// In en, this message translates to:
  /// **'Listing'**
  String get screenListingDetails;

  /// No description provided for @screenPublicProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get screenPublicProfile;

  /// No description provided for @screenCreateListing.
  ///
  /// In en, this message translates to:
  /// **'Create Listing'**
  String get screenCreateListing;

  /// No description provided for @screenEditListing.
  ///
  /// In en, this message translates to:
  /// **'Edit Listing'**
  String get screenEditListing;

  /// No description provided for @screenMyListings.
  ///
  /// In en, this message translates to:
  /// **'My Listings'**
  String get screenMyListings;

  /// No description provided for @screenConversation.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get screenConversation;

  /// No description provided for @screenDealDetails.
  ///
  /// In en, this message translates to:
  /// **'Deal'**
  String get screenDealDetails;

  /// No description provided for @screenEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get screenEditProfile;

  /// No description provided for @screenReports.
  ///
  /// In en, this message translates to:
  /// **'My reports'**
  String get screenReports;

  /// No description provided for @screenAdminUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get screenAdminUsers;

  /// No description provided for @screenAdminListings.
  ///
  /// In en, this message translates to:
  /// **'Listings'**
  String get screenAdminListings;

  /// No description provided for @screenAdminCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get screenAdminCategories;

  /// No description provided for @screenAdminReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get screenAdminReports;

  /// No description provided for @screenAdminDisputes.
  ///
  /// In en, this message translates to:
  /// **'Disputes'**
  String get screenAdminDisputes;

  /// No description provided for @screenAdminPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments & payouts'**
  String get screenAdminPayments;

  /// No description provided for @screenTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get screenTerms;

  /// No description provided for @screenPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get screenPrivacy;

  /// No description provided for @listingStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get listingStatusDraft;

  /// No description provided for @listingStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get listingStatusActive;

  /// No description provided for @listingStatusReserved.
  ///
  /// In en, this message translates to:
  /// **'Reserved'**
  String get listingStatusReserved;

  /// No description provided for @listingStatusSold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get listingStatusSold;

  /// No description provided for @listingStatusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get listingStatusArchived;

  /// No description provided for @listingStatusSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get listingStatusSuspended;

  /// No description provided for @offerStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get offerStatusPending;

  /// No description provided for @offerStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get offerStatusAccepted;

  /// No description provided for @offerStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get offerStatusRejected;

  /// No description provided for @offerStatusCountered.
  ///
  /// In en, this message translates to:
  /// **'Countered'**
  String get offerStatusCountered;

  /// No description provided for @offerStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get offerStatusExpired;

  /// No description provided for @offerStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get offerStatusCancelled;

  /// No description provided for @dealStatusAwaitingPayment.
  ///
  /// In en, this message translates to:
  /// **'Awaiting payment'**
  String get dealStatusAwaitingPayment;

  /// No description provided for @dealStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get dealStatusPaid;

  /// No description provided for @dealStatusAwaitingHandover.
  ///
  /// In en, this message translates to:
  /// **'Awaiting handover'**
  String get dealStatusAwaitingHandover;

  /// No description provided for @dealStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get dealStatusCompleted;

  /// No description provided for @dealStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get dealStatusCancelled;

  /// No description provided for @dealStatusDisputed.
  ///
  /// In en, this message translates to:
  /// **'Disputed'**
  String get dealStatusDisputed;

  /// No description provided for @conditionNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get conditionNew;

  /// No description provided for @conditionUsed.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get conditionUsed;

  /// No description provided for @negotiable.
  ///
  /// In en, this message translates to:
  /// **'Negotiable'**
  String get negotiable;

  /// No description provided for @fixedPrice.
  ///
  /// In en, this message translates to:
  /// **'Fixed price'**
  String get fixedPrice;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
