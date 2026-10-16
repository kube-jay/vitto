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

  /// No description provided for @postListing.
  ///
  /// In en, this message translates to:
  /// **'Post a Listing'**
  String get postListing;

  /// No description provided for @searchEverything.
  ///
  /// In en, this message translates to:
  /// **'Search phones, furniture, clothes…'**
  String get searchEverything;

  /// No description provided for @latestListingsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Be the first to post a Listing in your area.'**
  String get latestListingsEmptyHint;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get reject;

  /// No description provided for @counter.
  ///
  /// In en, this message translates to:
  /// **'Counter'**
  String get counter;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @suspend.
  ///
  /// In en, this message translates to:
  /// **'Suspend'**
  String get suspend;

  /// No description provided for @publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publish;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @any.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get any;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @theOtherParty.
  ///
  /// In en, this message translates to:
  /// **'Other party'**
  String get theOtherParty;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @nothingHere.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.'**
  String get nothingHere;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @errNoBackend.
  ///
  /// In en, this message translates to:
  /// **'Vitto is not connected to its server (demo mode).'**
  String get errNoBackend;

  /// No description provided for @errUnauthenticated.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to continue.'**
  String get errUnauthenticated;

  /// No description provided for @errForbidden.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have access to this.'**
  String get errForbidden;

  /// No description provided for @errValidation.
  ///
  /// In en, this message translates to:
  /// **'Some information is missing or invalid.'**
  String get errValidation;

  /// No description provided for @errConflict.
  ///
  /// In en, this message translates to:
  /// **'This was already done or conflicts with another action.'**
  String get errConflict;

  /// No description provided for @errListingNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'This Listing is no longer available.'**
  String get errListingNotAvailable;

  /// No description provided for @errInvalidState.
  ///
  /// In en, this message translates to:
  /// **'This action isn\'t possible at this stage.'**
  String get errInvalidState;

  /// No description provided for @errPaymentPending.
  ///
  /// In en, this message translates to:
  /// **'A payment is in progress. Check its status first.'**
  String get errPaymentPending;

  /// No description provided for @errProviderUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Online payment is not available right now.'**
  String get errProviderUnavailable;

  /// No description provided for @errRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment.'**
  String get errRateLimited;

  /// No description provided for @errInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong email or password.'**
  String get errInvalidCredentials;

  /// No description provided for @errEmailNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your email first (check your inbox).'**
  String get errEmailNotConfirmed;

  /// No description provided for @errUserExists.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get errUserExists;

  /// No description provided for @errWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Please choose a stronger password.'**
  String get errWeakPassword;

  /// No description provided for @errAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed. Please try again.'**
  String get errAuthFailed;

  /// No description provided for @errUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Use a JPG, PNG or WebP under 5 MB.'**
  String get errUploadFailed;

  /// No description provided for @errFixedPrice.
  ///
  /// In en, this message translates to:
  /// **'This Listing has a fixed price: offer exactly the listed price.'**
  String get errFixedPrice;

  /// No description provided for @errOfferPending.
  ///
  /// In en, this message translates to:
  /// **'There is already an open offer in this conversation.'**
  String get errOfferPending;

  /// No description provided for @errAlreadyRated.
  ///
  /// In en, this message translates to:
  /// **'You have already rated this deal.'**
  String get errAlreadyRated;

  /// No description provided for @errOfferExpired.
  ///
  /// In en, this message translates to:
  /// **'This offer has expired.'**
  String get errOfferExpired;

  /// No description provided for @validEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get validEmail;

  /// No description provided for @validPassword.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters.'**
  String get validPassword;

  /// No description provided for @validRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get validRequired;

  /// No description provided for @validTitle.
  ///
  /// In en, this message translates to:
  /// **'At least 3 characters.'**
  String get validTitle;

  /// No description provided for @validPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid price.'**
  String get validPrice;

  /// No description provided for @validPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add at least one photo to publish.'**
  String get validPhotos;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @noAccountYet.
  ///
  /// In en, this message translates to:
  /// **'New to Vitto?'**
  String get noAccountYet;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get haveAccount;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get displayName;

  /// No description provided for @oneAccountHint.
  ///
  /// In en, this message translates to:
  /// **'One account to buy and sell.'**
  String get oneAccountHint;

  /// No description provided for @checkYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get checkYourEmail;

  /// No description provided for @confirmEmailSent.
  ///
  /// In en, this message translates to:
  /// **'We sent a confirmation link to {email}. Open it, then sign in.'**
  String confirmEmailSent(String email);

  /// No description provided for @agreeToTerms.
  ///
  /// In en, this message translates to:
  /// **'By creating an account you accept the Terms of use.'**
  String get agreeToTerms;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// No description provided for @resetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for this email, a reset link is on its way.'**
  String get resetEmailSent;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password'**
  String get newPassword;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated.'**
  String get passwordUpdated;

  /// No description provided for @allCountries.
  ///
  /// In en, this message translates to:
  /// **'All countries'**
  String get allCountries;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allCategories;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get sortNewest;

  /// No description provided for @sortPriceAsc.
  ///
  /// In en, this message translates to:
  /// **'Price: low to high'**
  String get sortPriceAsc;

  /// No description provided for @sortPriceDesc.
  ///
  /// In en, this message translates to:
  /// **'Price: high to low'**
  String get sortPriceDesc;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No Listings found'**
  String get noResults;

  /// No description provided for @noResultsHint.
  ///
  /// In en, this message translates to:
  /// **'Try other words or remove some filters.'**
  String get noResultsHint;

  /// No description provided for @region.
  ///
  /// In en, this message translates to:
  /// **'State / department'**
  String get region;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @condition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get condition;

  /// No description provided for @priceMin.
  ///
  /// In en, this message translates to:
  /// **'Min price'**
  String get priceMin;

  /// No description provided for @priceMax.
  ///
  /// In en, this message translates to:
  /// **'Max price'**
  String get priceMax;

  /// No description provided for @priceType.
  ///
  /// In en, this message translates to:
  /// **'Price type'**
  String get priceType;

  /// No description provided for @pickCountryForPrice.
  ///
  /// In en, this message translates to:
  /// **'Choose a country to filter by price.'**
  String get pickCountryForPrice;

  /// No description provided for @showResults.
  ///
  /// In en, this message translates to:
  /// **'Show results'**
  String get showResults;

  /// No description provided for @postedOn.
  ///
  /// In en, this message translates to:
  /// **'Posted {date}'**
  String postedOn(String date);

  /// No description provided for @messageSeller.
  ///
  /// In en, this message translates to:
  /// **'Message seller'**
  String get messageSeller;

  /// No description provided for @makeOffer.
  ///
  /// In en, this message translates to:
  /// **'Make an offer'**
  String get makeOffer;

  /// No description provided for @buyAtThisPrice.
  ///
  /// In en, this message translates to:
  /// **'Buy at this price'**
  String get buyAtThisPrice;

  /// No description provided for @listingUnavailableNote.
  ///
  /// In en, this message translates to:
  /// **'This Listing is not available for new offers.'**
  String get listingUnavailableNote;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @safetyTip.
  ///
  /// In en, this message translates to:
  /// **'Stay safe: keep the conversation in Vitto, check the item before giving your confirmation code, and meet in a public place.'**
  String get safetyTip;

  /// No description provided for @reportListing.
  ///
  /// In en, this message translates to:
  /// **'Report this Listing'**
  String get reportListing;

  /// No description provided for @noRatingsYet.
  ///
  /// In en, this message translates to:
  /// **'No ratings yet'**
  String get noRatingsYet;

  /// No description provided for @completedDealsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No completed deals} =1{1 completed deal} other{{count} completed deals}}'**
  String completedDealsCount(int count);

  /// No description provided for @yourListing.
  ///
  /// In en, this message translates to:
  /// **'Your Listing'**
  String get yourListing;

  /// No description provided for @archiveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Archive this Listing? It will no longer be visible.'**
  String get archiveConfirm;

  /// No description provided for @listingSuspendedNote.
  ///
  /// In en, this message translates to:
  /// **'This Listing was suspended by Vitto. Contact support if you think this is a mistake.'**
  String get listingSuspendedNote;

  /// No description provided for @listingImagesCount.
  ///
  /// In en, this message translates to:
  /// **'Photos ({count}/8)'**
  String listingImagesCount(int count);

  /// No description provided for @photosHint.
  ///
  /// In en, this message translates to:
  /// **'Add 1 to 8 photos. The first one is the cover.'**
  String get photosHint;

  /// No description provided for @addPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add photos'**
  String get addPhotos;

  /// No description provided for @cover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get cover;

  /// No description provided for @makeCover.
  ///
  /// In en, this message translates to:
  /// **'Make cover'**
  String get makeCover;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @titleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. iPhone 12, 128 GB, blue'**
  String get titleHint;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Condition, size, what\'s included, reason for selling…'**
  String get descriptionHint;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @negotiableHint.
  ///
  /// In en, this message translates to:
  /// **'Buyers can make offers and you can counter.'**
  String get negotiableHint;

  /// No description provided for @fixedPriceHint.
  ///
  /// In en, this message translates to:
  /// **'Buyers can only offer the listed price.'**
  String get fixedPriceHint;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City / area'**
  String get city;

  /// No description provided for @saveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save as draft'**
  String get saveDraft;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @listingPublished.
  ///
  /// In en, this message translates to:
  /// **'Your Listing is live!'**
  String get listingPublished;

  /// No description provided for @drafts.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get drafts;

  /// No description provided for @reservedAndSold.
  ///
  /// In en, this message translates to:
  /// **'Reserved & sold'**
  String get reservedAndSold;

  /// No description provided for @inboxEmpty.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get inboxEmpty;

  /// No description provided for @inboxEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Message a seller from any Listing to start.'**
  String get inboxEmptyHint;

  /// No description provided for @youAreBuying.
  ///
  /// In en, this message translates to:
  /// **'Buying'**
  String get youAreBuying;

  /// No description provided for @youAreSelling.
  ///
  /// In en, this message translates to:
  /// **'Selling'**
  String get youAreSelling;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get viewProfile;

  /// No description provided for @reportUser.
  ///
  /// In en, this message translates to:
  /// **'Report user'**
  String get reportUser;

  /// No description provided for @dealCreatedBanner.
  ///
  /// In en, this message translates to:
  /// **'Offer accepted – a Deal was created.'**
  String get dealCreatedBanner;

  /// No description provided for @openDeal.
  ///
  /// In en, this message translates to:
  /// **'Open Deal'**
  String get openDeal;

  /// No description provided for @startConversation.
  ///
  /// In en, this message translates to:
  /// **'Say hello!'**
  String get startConversation;

  /// No description provided for @chatSafetyHint.
  ///
  /// In en, this message translates to:
  /// **'Ask about the item and agree on a price with a structured offer.'**
  String get chatSafetyHint;

  /// No description provided for @writeMessage.
  ///
  /// In en, this message translates to:
  /// **'Write a message…'**
  String get writeMessage;

  /// No description provided for @sysOfferAccepted.
  ///
  /// In en, this message translates to:
  /// **'{who, select, you{You accepted the offer} other{The offer was accepted}}'**
  String sysOfferAccepted(String who);

  /// No description provided for @sysOfferRejected.
  ///
  /// In en, this message translates to:
  /// **'{who, select, you{You declined the offer} other{The offer was declined}}'**
  String sysOfferRejected(String who);

  /// No description provided for @sysOfferCancelled.
  ///
  /// In en, this message translates to:
  /// **'{who, select, you{You withdrew your offer} other{The offer was withdrawn}}'**
  String sysOfferCancelled(String who);

  /// No description provided for @sysDealUpdate.
  ///
  /// In en, this message translates to:
  /// **'Deal status: {status}'**
  String sysDealUpdate(String status);

  /// No description provided for @yourOffer.
  ///
  /// In en, this message translates to:
  /// **'Your offer'**
  String get yourOffer;

  /// No description provided for @theirOffer.
  ///
  /// In en, this message translates to:
  /// **'Their offer'**
  String get theirOffer;

  /// No description provided for @yourCounterOffer.
  ///
  /// In en, this message translates to:
  /// **'Your counter-offer'**
  String get yourCounterOffer;

  /// No description provided for @theirCounterOffer.
  ///
  /// In en, this message translates to:
  /// **'Their counter-offer'**
  String get theirCounterOffer;

  /// No description provided for @offerExpires.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String offerExpires(String date);

  /// No description provided for @acceptOfferConfirm.
  ///
  /// In en, this message translates to:
  /// **'Accept this offer?'**
  String get acceptOfferConfirm;

  /// No description provided for @acceptOfferHint.
  ///
  /// In en, this message translates to:
  /// **'A Deal is created at this price and the Listing is reserved.'**
  String get acceptOfferHint;

  /// No description provided for @counterOffer.
  ///
  /// In en, this message translates to:
  /// **'Counter-offer'**
  String get counterOffer;

  /// No description provided for @withdrawOffer.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdrawOffer;

  /// No description provided for @listedPrice.
  ///
  /// In en, this message translates to:
  /// **'Listed at {price}'**
  String listedPrice(String price);

  /// No description provided for @fixedPriceOfferNote.
  ///
  /// In en, this message translates to:
  /// **'Fixed price – you are offering the listed price.'**
  String get fixedPriceOfferNote;

  /// No description provided for @sendOffer.
  ///
  /// In en, this message translates to:
  /// **'Send offer'**
  String get sendOffer;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get inProgress;

  /// No description provided for @allDeals.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allDeals;

  /// No description provided for @noDeals.
  ///
  /// In en, this message translates to:
  /// **'No deals yet'**
  String get noDeals;

  /// No description provided for @noDealsHint.
  ///
  /// In en, this message translates to:
  /// **'A Deal starts when an offer is accepted.'**
  String get noDealsHint;

  /// No description provided for @modeOnline.
  ///
  /// In en, this message translates to:
  /// **'Pay online'**
  String get modeOnline;

  /// No description provided for @modeOffline.
  ///
  /// In en, this message translates to:
  /// **'Meet in person'**
  String get modeOffline;

  /// No description provided for @modeOnlineHint.
  ///
  /// In en, this message translates to:
  /// **'The buyer pays through Vitto. The seller is paid after the buyer confirms receipt with a 6-digit code.'**
  String get modeOnlineHint;

  /// No description provided for @modeOfflineHint.
  ///
  /// In en, this message translates to:
  /// **'Meet, check the item and pay each other directly. Vitto does not handle the money.'**
  String get modeOfflineHint;

  /// No description provided for @chooseModeTitle.
  ///
  /// In en, this message translates to:
  /// **'How do you want to complete this deal?'**
  String get chooseModeTitle;

  /// No description provided for @stepAgreed.
  ///
  /// In en, this message translates to:
  /// **'Price agreed'**
  String get stepAgreed;

  /// No description provided for @stepModeChosen.
  ///
  /// In en, this message translates to:
  /// **'Online or in person chosen'**
  String get stepModeChosen;

  /// No description provided for @stepPaid.
  ///
  /// In en, this message translates to:
  /// **'Payment confirmed'**
  String get stepPaid;

  /// No description provided for @stepHandoverCode.
  ///
  /// In en, this message translates to:
  /// **'Item handed over (code)'**
  String get stepHandoverCode;

  /// No description provided for @stepBothConfirm.
  ///
  /// In en, this message translates to:
  /// **'Both confirm the exchange'**
  String get stepBothConfirm;

  /// No description provided for @stepRate.
  ///
  /// In en, this message translates to:
  /// **'Rate each other'**
  String get stepRate;

  /// No description provided for @dealCancelledNote.
  ///
  /// In en, this message translates to:
  /// **'This Deal was cancelled.'**
  String get dealCancelledNote;

  /// No description provided for @waitingForPayment.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the buyer to pay online.'**
  String get waitingForPayment;

  /// No description provided for @paymentPendingNote.
  ///
  /// In en, this message translates to:
  /// **'Payment is being processed. This page updates automatically.'**
  String get paymentPendingNote;

  /// No description provided for @paymentFailedNote.
  ///
  /// In en, this message translates to:
  /// **'The last payment attempt failed. You can try again.'**
  String get paymentFailedNote;

  /// No description provided for @payOnlineHint.
  ///
  /// In en, this message translates to:
  /// **'Your money is confirmed by the payment provider. The seller is only paid after you confirm you received the item.'**
  String get payOnlineHint;

  /// No description provided for @checkPaymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Check payment status'**
  String get checkPaymentStatus;

  /// No description provided for @payAmount.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount}'**
  String payAmount(String amount);

  /// No description provided for @testPaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Test payment'**
  String get testPaymentTitle;

  /// No description provided for @testPaymentBody.
  ///
  /// In en, this message translates to:
  /// **'Test mode: no real money moves. Choose what the payment provider should report.'**
  String get testPaymentBody;

  /// No description provided for @simulateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Simulate success'**
  String get simulateSuccess;

  /// No description provided for @simulateFailure.
  ///
  /// In en, this message translates to:
  /// **'Simulate failure'**
  String get simulateFailure;

  /// No description provided for @didYouReceive.
  ///
  /// In en, this message translates to:
  /// **'The seller says the item was handed over. Did you receive it?'**
  String get didYouReceive;

  /// No description provided for @confirmReceivedTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm you received the item?'**
  String get confirmReceivedTitle;

  /// No description provided for @confirmReceivedBody.
  ///
  /// In en, this message translates to:
  /// **'The Deal will be completed and the seller can be paid.'**
  String get confirmReceivedBody;

  /// No description provided for @yesReceived.
  ///
  /// In en, this message translates to:
  /// **'Yes, I received it'**
  String get yesReceived;

  /// No description provided for @noProblem.
  ///
  /// In en, this message translates to:
  /// **'No, there\'s a problem'**
  String get noProblem;

  /// No description provided for @describeProblem.
  ///
  /// In en, this message translates to:
  /// **'Describe the problem'**
  String get describeProblem;

  /// No description provided for @codeBuyerHint.
  ///
  /// In en, this message translates to:
  /// **'When you have the item and have checked it, show your 6-digit code to the seller. Never share it before.'**
  String get codeBuyerHint;

  /// No description provided for @showMyCode.
  ///
  /// In en, this message translates to:
  /// **'Show my confirmation code'**
  String get showMyCode;

  /// No description provided for @newCode.
  ///
  /// In en, this message translates to:
  /// **'Get a new code'**
  String get newCode;

  /// No description provided for @showCodeConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Have you received and checked the item?'**
  String get showCodeConfirmTitle;

  /// No description provided for @showCodeConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Only give the code to the seller after checking the item. The code completes the Deal.'**
  String get showCodeConfirmBody;

  /// No description provided for @codeExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'Expires in {time}'**
  String codeExpiresIn(String time);

  /// No description provided for @paidSellerHint.
  ///
  /// In en, this message translates to:
  /// **'Payment confirmed. Hand over the item and ask the buyer for their 6-digit code.'**
  String get paidSellerHint;

  /// No description provided for @codeSellerHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the buyer\'s 6-digit code to complete the Deal.'**
  String get codeSellerHint;

  /// No description provided for @confirmHandover.
  ///
  /// In en, this message translates to:
  /// **'Confirm handover'**
  String get confirmHandover;

  /// No description provided for @codeSixDigits.
  ///
  /// In en, this message translates to:
  /// **'The code has 6 digits.'**
  String get codeSixDigits;

  /// No description provided for @codeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Wrong code. {count} attempts left.'**
  String codeInvalid(int count);

  /// No description provided for @codeExpired.
  ///
  /// In en, this message translates to:
  /// **'This code has expired. Ask the buyer for a new one.'**
  String get codeExpired;

  /// No description provided for @codeLocked.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong attempts. Ask the buyer for a new code.'**
  String get codeLocked;

  /// No description provided for @codeNotGenerated.
  ///
  /// In en, this message translates to:
  /// **'The buyer has not generated a code yet.'**
  String get codeNotGenerated;

  /// No description provided for @dealCompletedSnack.
  ///
  /// In en, this message translates to:
  /// **'Deal completed!'**
  String get dealCompletedSnack;

  /// No description provided for @waitingBuyerAnswer.
  ///
  /// In en, this message translates to:
  /// **'We asked the buyer to confirm. Waiting for their answer.'**
  String get waitingBuyerAnswer;

  /// No description provided for @problemWithConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Problem with confirmation'**
  String get problemWithConfirmation;

  /// No description provided for @problemWithConfirmationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. I handed over the item but the buyer didn\'t give the code.'**
  String get problemWithConfirmationHint;

  /// No description provided for @offlineHint.
  ///
  /// In en, this message translates to:
  /// **'Meet in a safe public place, check the item and pay directly. Then both of you confirm here.'**
  String get offlineHint;

  /// No description provided for @confirmed.
  ///
  /// In en, this message translates to:
  /// **'confirmed'**
  String get confirmed;

  /// No description provided for @notYetConfirmed.
  ///
  /// In en, this message translates to:
  /// **'not yet'**
  String get notYetConfirmed;

  /// No description provided for @confirmExchange.
  ///
  /// In en, this message translates to:
  /// **'I confirm the exchange happened'**
  String get confirmExchange;

  /// No description provided for @confirmExchangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm the exchange?'**
  String get confirmExchangeTitle;

  /// No description provided for @confirmExchangeBody.
  ///
  /// In en, this message translates to:
  /// **'Only confirm after the item and payment were exchanged.'**
  String get confirmExchangeBody;

  /// No description provided for @waitingOtherConfirm.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the other party to confirm.'**
  String get waitingOtherConfirm;

  /// No description provided for @dealCompletedNote.
  ///
  /// In en, this message translates to:
  /// **'This Deal is completed. Thank you!'**
  String get dealCompletedNote;

  /// No description provided for @payout.
  ///
  /// In en, this message translates to:
  /// **'Seller payout'**
  String get payout;

  /// No description provided for @payoutNotEligible.
  ///
  /// In en, this message translates to:
  /// **'not eligible'**
  String get payoutNotEligible;

  /// No description provided for @payoutEligible.
  ///
  /// In en, this message translates to:
  /// **'ready – will be released by Vitto'**
  String get payoutEligible;

  /// No description provided for @payoutRequested.
  ///
  /// In en, this message translates to:
  /// **'being sent'**
  String get payoutRequested;

  /// No description provided for @payoutPaid.
  ///
  /// In en, this message translates to:
  /// **'paid'**
  String get payoutPaid;

  /// No description provided for @payoutFailed.
  ///
  /// In en, this message translates to:
  /// **'failed – Vitto will retry'**
  String get payoutFailed;

  /// No description provided for @payoutReversed.
  ///
  /// In en, this message translates to:
  /// **'reversed'**
  String get payoutReversed;

  /// No description provided for @yourRating.
  ///
  /// In en, this message translates to:
  /// **'Your rating'**
  String get yourRating;

  /// No description provided for @rateUser.
  ///
  /// In en, this message translates to:
  /// **'Rate {name}'**
  String rateUser(String name);

  /// No description provided for @ratingCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Short comment (optional)'**
  String get ratingCommentHint;

  /// No description provided for @submitRating.
  ///
  /// In en, this message translates to:
  /// **'Submit rating'**
  String get submitRating;

  /// No description provided for @disputedNote.
  ///
  /// In en, this message translates to:
  /// **'Vitto is reviewing this Deal. The seller payout is on hold. Add photos or documents that help.'**
  String get disputedNote;

  /// No description provided for @evidenceFiles.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No files added} =1{1 file added} other{{count} files added}}'**
  String evidenceFiles(int count);

  /// No description provided for @addEvidence.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get addEvidence;

  /// No description provided for @evidenceNote.
  ///
  /// In en, this message translates to:
  /// **'Short note (optional)'**
  String get evidenceNote;

  /// No description provided for @adminViewingDeal.
  ///
  /// In en, this message translates to:
  /// **'You are viewing this Deal as an admin.'**
  String get adminViewingDeal;

  /// No description provided for @sellerNote.
  ///
  /// In en, this message translates to:
  /// **'Seller note'**
  String get sellerNote;

  /// No description provided for @switchToOffline.
  ///
  /// In en, this message translates to:
  /// **'Switch to meeting in person'**
  String get switchToOffline;

  /// No description provided for @switchToOnline.
  ///
  /// In en, this message translates to:
  /// **'Switch to online payment'**
  String get switchToOnline;

  /// No description provided for @cancelDeal.
  ///
  /// In en, this message translates to:
  /// **'Cancel deal'**
  String get cancelDeal;

  /// No description provided for @cancelDealTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this deal?'**
  String get cancelDealTitle;

  /// No description provided for @cancelDealHint.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get cancelDealHint;

  /// No description provided for @reportProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get reportProblem;

  /// No description provided for @reportProblemTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a problem to Vitto'**
  String get reportProblemTitle;

  /// No description provided for @reportProblemHint.
  ///
  /// In en, this message translates to:
  /// **'What happened? An admin will review it.'**
  String get reportProblemHint;

  /// No description provided for @reviewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 review} other{{count} reviews}}'**
  String reviewsCount(int count);

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since {date}'**
  String memberSince(String date);

  /// No description provided for @accountSuspendedNote.
  ///
  /// In en, this message translates to:
  /// **'Your account is suspended. You can browse but not post or trade.'**
  String get accountSuspendedNote;

  /// No description provided for @viewPublicProfile.
  ///
  /// In en, this message translates to:
  /// **'View my public profile'**
  String get viewPublicProfile;

  /// No description provided for @profileUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This profile is not available.'**
  String get profileUnavailable;

  /// No description provided for @activeListings.
  ///
  /// In en, this message translates to:
  /// **'Active Listings'**
  String get activeListings;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// No description provided for @favoritesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get favoritesEmpty;

  /// No description provided for @favoritesEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on a Listing to save it here.'**
  String get favoritesEmptyHint;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportTitle;

  /// No description provided for @reportDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Add details (optional)'**
  String get reportDetailsHint;

  /// No description provided for @reportSent.
  ///
  /// In en, this message translates to:
  /// **'Thanks – our team will review it.'**
  String get reportSent;

  /// No description provided for @reasonProhibited.
  ///
  /// In en, this message translates to:
  /// **'Prohibited item'**
  String get reasonProhibited;

  /// No description provided for @reasonScam.
  ///
  /// In en, this message translates to:
  /// **'Scam or fraud'**
  String get reasonScam;

  /// No description provided for @reasonOffensive.
  ///
  /// In en, this message translates to:
  /// **'Offensive content'**
  String get reasonOffensive;

  /// No description provided for @reasonWrongInfo.
  ///
  /// In en, this message translates to:
  /// **'Wrong information'**
  String get reasonWrongInfo;

  /// No description provided for @reasonNoShow.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t show up'**
  String get reasonNoShow;

  /// No description provided for @reasonNotReceived.
  ///
  /// In en, this message translates to:
  /// **'Item not received'**
  String get reasonNotReceived;

  /// No description provided for @reasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reasonOther;

  /// No description provided for @reportOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get reportOpen;

  /// No description provided for @reportReviewing.
  ///
  /// In en, this message translates to:
  /// **'Reviewing'**
  String get reportReviewing;

  /// No description provided for @reportResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get reportResolved;

  /// No description provided for @reportDismissed.
  ///
  /// In en, this message translates to:
  /// **'Dismissed'**
  String get reportDismissed;

  /// No description provided for @searchUsersHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or email'**
  String get searchUsersHint;

  /// No description provided for @reasonForRecord.
  ///
  /// In en, this message translates to:
  /// **'Reason (kept in the audit log)'**
  String get reasonForRecord;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get addCategory;

  /// No description provided for @openTarget.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openTarget;

  /// No description provided for @resolveComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete deal (pay seller)'**
  String get resolveComplete;

  /// No description provided for @resolveCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel deal (refund buyer)'**
  String get resolveCancel;

  /// No description provided for @resolveHint.
  ///
  /// In en, this message translates to:
  /// **'Decision and reason. Refunds are processed manually in the provider dashboard.'**
  String get resolveHint;

  /// No description provided for @payoutGateNote.
  ///
  /// In en, this message translates to:
  /// **'Payouts are only possible for completed online Deals. Real payouts stay disabled until the provider and legal approvals (DEC-06) are in place.'**
  String get payoutGateNote;

  /// No description provided for @payouts.
  ///
  /// In en, this message translates to:
  /// **'Payouts'**
  String get payouts;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @releasePayout.
  ///
  /// In en, this message translates to:
  /// **'Release payout'**
  String get releasePayout;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'How Vitto works'**
  String get helpTitle;

  /// No description provided for @helpStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Find or post'**
  String get helpStep1Title;

  /// No description provided for @helpStep1Body.
  ///
  /// In en, this message translates to:
  /// **'Search Listings in Nigeria and Benin, or post your own item in minutes.'**
  String get helpStep1Body;

  /// No description provided for @helpStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Chat and offer'**
  String get helpStep2Title;

  /// No description provided for @helpStep2Body.
  ///
  /// In en, this message translates to:
  /// **'Message the seller inside Vitto and make a price offer. The seller can accept, decline or counter.'**
  String get helpStep2Body;

  /// No description provided for @helpStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Agree a Deal'**
  String get helpStep3Title;

  /// No description provided for @helpStep3Body.
  ///
  /// In en, this message translates to:
  /// **'When an offer is accepted, choose to pay online through Vitto or meet in person.'**
  String get helpStep3Body;

  /// No description provided for @helpStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get helpStep4Title;

  /// No description provided for @helpStep4Body.
  ///
  /// In en, this message translates to:
  /// **'Online: the buyer gives a 6-digit code after checking the item. In person: both confirm in the app.'**
  String get helpStep4Body;

  /// No description provided for @helpStep5Title.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get helpStep5Title;

  /// No description provided for @helpStep5Body.
  ///
  /// In en, this message translates to:
  /// **'After a completed Deal, rate each other to build trust.'**
  String get helpStep5Body;

  /// No description provided for @safetyTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay safe'**
  String get safetyTitle;

  /// No description provided for @safetyBody.
  ///
  /// In en, this message translates to:
  /// **'Keep all conversations in Vitto. Never share your confirmation code before you have checked the item. Meet in busy public places. Never pay outside Vitto for an online Deal.'**
  String get safetyBody;

  /// No description provided for @prohibitedTitle.
  ///
  /// In en, this message translates to:
  /// **'Prohibited items'**
  String get prohibitedTitle;

  /// No description provided for @prohibitedBody.
  ///
  /// In en, this message translates to:
  /// **'Weapons, drugs, stolen goods, counterfeit products, animals, and anything illegal in Nigeria or Benin are not allowed.'**
  String get prohibitedBody;

  /// No description provided for @supportTitle.
  ///
  /// In en, this message translates to:
  /// **'Need help?'**
  String get supportTitle;

  /// No description provided for @supportBody.
  ///
  /// In en, this message translates to:
  /// **'Use \"Report\" on a Listing, profile or Deal. Our team reviews reports and disputes, usually within 72 hours.'**
  String get supportBody;

  /// No description provided for @legalDraftNotice.
  ///
  /// In en, this message translates to:
  /// **'Draft – to be replaced after legal review for Nigeria and Benin before launch.'**
  String get legalDraftNotice;

  /// No description provided for @termsBody.
  ///
  /// In en, this message translates to:
  /// **'Vitto is a marketplace that connects buyers and sellers of physical products in Nigeria and Benin. Users are responsible for the accuracy of their Listings and for the items they sell. Online payments are processed by licensed payment providers; Vitto releases seller payouts only after the buyer confirms receipt or an admin decides a dispute. Offline exchanges happen directly between users and Vitto does not handle that money. Prohibited items are not allowed. Vitto may suspend Listings or accounts that break these rules.'**
  String get termsBody;

  /// No description provided for @privacyBody.
  ///
  /// In en, this message translates to:
  /// **'We collect only what is needed to run the marketplace: your account details, profile, Listings, messages, offers, deals and reports. Card details are never stored by Vitto; payments are handled by the payment provider. Messages are visible only to the two participants, and to admins when reviewing a report or dispute. You can ask us to delete your account; some records (deals, payments, disputes) are kept as required by law.'**
  String get privacyBody;
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
