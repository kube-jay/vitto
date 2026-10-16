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

  @override
  String get postListing => 'Post a Listing';

  @override
  String get searchEverything => 'Search phones, furniture, clothes…';

  @override
  String get latestListingsEmptyHint =>
      'Be the first to post a Listing in your area.';

  @override
  String get accept => 'Accept';

  @override
  String get reject => 'Decline';

  @override
  String get counter => 'Counter';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get send => 'Send';

  @override
  String get edit => 'Edit';

  @override
  String get remove => 'Remove';

  @override
  String get reset => 'Reset';

  @override
  String get restore => 'Restore';

  @override
  String get suspend => 'Suspend';

  @override
  String get publish => 'Publish';

  @override
  String get archive => 'Archive';

  @override
  String get chat => 'Chat';

  @override
  String get any => 'Any';

  @override
  String get you => 'You';

  @override
  String get theOtherParty => 'Other party';

  @override
  String get loadMore => 'Load more';

  @override
  String get seeAll => 'See all';

  @override
  String get nothingHere => 'Nothing here yet.';

  @override
  String get details => 'Details';

  @override
  String get errNoBackend =>
      'Vitto is not connected to its server (demo mode).';

  @override
  String get errUnauthenticated => 'Please sign in to continue.';

  @override
  String get errForbidden => 'You don\'t have access to this.';

  @override
  String get errValidation => 'Some information is missing or invalid.';

  @override
  String get errConflict =>
      'This was already done or conflicts with another action.';

  @override
  String get errListingNotAvailable => 'This Listing is no longer available.';

  @override
  String get errInvalidState => 'This action isn\'t possible at this stage.';

  @override
  String get errPaymentPending =>
      'A payment is in progress. Check its status first.';

  @override
  String get errProviderUnavailable =>
      'Online payment is not available right now.';

  @override
  String get errRateLimited => 'Too many attempts. Please wait a moment.';

  @override
  String get errInvalidCredentials => 'Wrong email or password.';

  @override
  String get errEmailNotConfirmed =>
      'Please confirm your email first (check your inbox).';

  @override
  String get errUserExists => 'An account with this email already exists.';

  @override
  String get errWeakPassword => 'Please choose a stronger password.';

  @override
  String get errAuthFailed => 'Sign-in failed. Please try again.';

  @override
  String get errUploadFailed =>
      'Upload failed. Use a JPG, PNG or WebP under 5 MB.';

  @override
  String get errFixedPrice =>
      'This Listing has a fixed price: offer exactly the listed price.';

  @override
  String get errOfferPending =>
      'There is already an open offer in this conversation.';

  @override
  String get errAlreadyRated => 'You have already rated this deal.';

  @override
  String get errOfferExpired => 'This offer has expired.';

  @override
  String get validEmail => 'Enter a valid email address.';

  @override
  String get validPassword => 'At least 8 characters.';

  @override
  String get validRequired => 'Required';

  @override
  String get validTitle => 'At least 3 characters.';

  @override
  String get validPrice => 'Enter a valid price.';

  @override
  String get validPhotos => 'Add at least one photo to publish.';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get noAccountYet => 'New to Vitto?';

  @override
  String get haveAccount => 'I already have an account';

  @override
  String get displayName => 'Your name';

  @override
  String get oneAccountHint => 'One account to buy and sell.';

  @override
  String get checkYourEmail => 'Check your email';

  @override
  String confirmEmailSent(String email) {
    return 'We sent a confirmation link to $email. Open it, then sign in.';
  }

  @override
  String get agreeToTerms =>
      'By creating an account you accept the Terms of use.';

  @override
  String get sendResetLink => 'Send reset link';

  @override
  String get resetEmailSent =>
      'If an account exists for this email, a reset link is on its way.';

  @override
  String get newPassword => 'Choose a new password';

  @override
  String get passwordUpdated => 'Password updated.';

  @override
  String get allCountries => 'All countries';

  @override
  String get allCategories => 'All categories';

  @override
  String get filters => 'Filters';

  @override
  String get sortNewest => 'Newest';

  @override
  String get sortPriceAsc => 'Price: low to high';

  @override
  String get sortPriceDesc => 'Price: high to low';

  @override
  String get noResults => 'No Listings found';

  @override
  String get noResultsHint => 'Try other words or remove some filters.';

  @override
  String get region => 'State / department';

  @override
  String get category => 'Category';

  @override
  String get condition => 'Condition';

  @override
  String get priceMin => 'Min price';

  @override
  String get priceMax => 'Max price';

  @override
  String get priceType => 'Price type';

  @override
  String get pickCountryForPrice => 'Choose a country to filter by price.';

  @override
  String get showResults => 'Show results';

  @override
  String postedOn(String date) {
    return 'Posted $date';
  }

  @override
  String get messageSeller => 'Message seller';

  @override
  String get makeOffer => 'Make an offer';

  @override
  String get buyAtThisPrice => 'Buy at this price';

  @override
  String get listingUnavailableNote =>
      'This Listing is not available for new offers.';

  @override
  String get description => 'Description';

  @override
  String get safetyTip =>
      'Stay safe: keep the conversation in Vitto, check the item before giving your confirmation code, and meet in a public place.';

  @override
  String get reportListing => 'Report this Listing';

  @override
  String get noRatingsYet => 'No ratings yet';

  @override
  String completedDealsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count completed deals',
      one: '1 completed deal',
      zero: 'No completed deals',
    );
    return '$_temp0';
  }

  @override
  String get yourListing => 'Your Listing';

  @override
  String get archiveConfirm =>
      'Archive this Listing? It will no longer be visible.';

  @override
  String get listingSuspendedNote =>
      'This Listing was suspended by Vitto. Contact support if you think this is a mistake.';

  @override
  String listingImagesCount(int count) {
    return 'Photos ($count/8)';
  }

  @override
  String get photosHint => 'Add 1 to 8 photos. The first one is the cover.';

  @override
  String get addPhotos => 'Add photos';

  @override
  String get cover => 'Cover';

  @override
  String get makeCover => 'Make cover';

  @override
  String get title => 'Title';

  @override
  String get titleHint => 'e.g. iPhone 12, 128 GB, blue';

  @override
  String get descriptionHint =>
      'Condition, size, what\'s included, reason for selling…';

  @override
  String get price => 'Price';

  @override
  String get negotiableHint => 'Buyers can make offers and you can counter.';

  @override
  String get fixedPriceHint => 'Buyers can only offer the listed price.';

  @override
  String get location => 'Location';

  @override
  String get city => 'City / area';

  @override
  String get saveDraft => 'Save as draft';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get listingPublished => 'Your Listing is live!';

  @override
  String get drafts => 'Drafts';

  @override
  String get reservedAndSold => 'Reserved & sold';

  @override
  String get inboxEmpty => 'No conversations yet';

  @override
  String get inboxEmptyHint => 'Message a seller from any Listing to start.';

  @override
  String get youAreBuying => 'Buying';

  @override
  String get youAreSelling => 'Selling';

  @override
  String get viewProfile => 'View profile';

  @override
  String get reportUser => 'Report user';

  @override
  String get dealCreatedBanner => 'Offer accepted – a Deal was created.';

  @override
  String get openDeal => 'Open Deal';

  @override
  String get startConversation => 'Say hello!';

  @override
  String get chatSafetyHint =>
      'Ask about the item and agree on a price with a structured offer.';

  @override
  String get writeMessage => 'Write a message…';

  @override
  String sysOfferAccepted(String who) {
    String _temp0 = intl.Intl.selectLogic(who, {
      'you': 'You accepted the offer',
      'other': 'The offer was accepted',
    });
    return '$_temp0';
  }

  @override
  String sysOfferRejected(String who) {
    String _temp0 = intl.Intl.selectLogic(who, {
      'you': 'You declined the offer',
      'other': 'The offer was declined',
    });
    return '$_temp0';
  }

  @override
  String sysOfferCancelled(String who) {
    String _temp0 = intl.Intl.selectLogic(who, {
      'you': 'You withdrew your offer',
      'other': 'The offer was withdrawn',
    });
    return '$_temp0';
  }

  @override
  String sysDealUpdate(String status) {
    return 'Deal status: $status';
  }

  @override
  String get yourOffer => 'Your offer';

  @override
  String get theirOffer => 'Their offer';

  @override
  String get yourCounterOffer => 'Your counter-offer';

  @override
  String get theirCounterOffer => 'Their counter-offer';

  @override
  String offerExpires(String date) {
    return 'Valid until $date';
  }

  @override
  String get acceptOfferConfirm => 'Accept this offer?';

  @override
  String get acceptOfferHint =>
      'A Deal is created at this price and the Listing is reserved.';

  @override
  String get counterOffer => 'Counter-offer';

  @override
  String get withdrawOffer => 'Withdraw';

  @override
  String listedPrice(String price) {
    return 'Listed at $price';
  }

  @override
  String get fixedPriceOfferNote =>
      'Fixed price – you are offering the listed price.';

  @override
  String get sendOffer => 'Send offer';

  @override
  String get inProgress => 'In progress';

  @override
  String get allDeals => 'All';

  @override
  String get noDeals => 'No deals yet';

  @override
  String get noDealsHint => 'A Deal starts when an offer is accepted.';

  @override
  String get modeOnline => 'Pay online';

  @override
  String get modeOffline => 'Meet in person';

  @override
  String get modeOnlineHint =>
      'The buyer pays through Vitto. The seller is paid after the buyer confirms receipt with a 6-digit code.';

  @override
  String get modeOfflineHint =>
      'Meet, check the item and pay each other directly. Vitto does not handle the money.';

  @override
  String get chooseModeTitle => 'How do you want to complete this deal?';

  @override
  String get stepAgreed => 'Price agreed';

  @override
  String get stepModeChosen => 'Online or in person chosen';

  @override
  String get stepPaid => 'Payment confirmed';

  @override
  String get stepHandoverCode => 'Item handed over (code)';

  @override
  String get stepBothConfirm => 'Both confirm the exchange';

  @override
  String get stepRate => 'Rate each other';

  @override
  String get dealCancelledNote => 'This Deal was cancelled.';

  @override
  String get waitingForPayment => 'Waiting for the buyer to pay online.';

  @override
  String get paymentPendingNote =>
      'Payment is being processed. This page updates automatically.';

  @override
  String get paymentFailedNote =>
      'The last payment attempt failed. You can try again.';

  @override
  String get payOnlineHint =>
      'Your money is confirmed by the payment provider. The seller is only paid after you confirm you received the item.';

  @override
  String get checkPaymentStatus => 'Check payment status';

  @override
  String payAmount(String amount) {
    return 'Pay $amount';
  }

  @override
  String get testPaymentTitle => 'Test payment';

  @override
  String get testPaymentBody =>
      'Test mode: no real money moves. Choose what the payment provider should report.';

  @override
  String get simulateSuccess => 'Simulate success';

  @override
  String get simulateFailure => 'Simulate failure';

  @override
  String get didYouReceive =>
      'The seller says the item was handed over. Did you receive it?';

  @override
  String get confirmReceivedTitle => 'Confirm you received the item?';

  @override
  String get confirmReceivedBody =>
      'The Deal will be completed and the seller can be paid.';

  @override
  String get yesReceived => 'Yes, I received it';

  @override
  String get noProblem => 'No, there\'s a problem';

  @override
  String get describeProblem => 'Describe the problem';

  @override
  String get codeBuyerHint =>
      'When you have the item and have checked it, show your 6-digit code to the seller. Never share it before.';

  @override
  String get showMyCode => 'Show my confirmation code';

  @override
  String get newCode => 'Get a new code';

  @override
  String get showCodeConfirmTitle => 'Have you received and checked the item?';

  @override
  String get showCodeConfirmBody =>
      'Only give the code to the seller after checking the item. The code completes the Deal.';

  @override
  String codeExpiresIn(String time) {
    return 'Expires in $time';
  }

  @override
  String get paidSellerHint =>
      'Payment confirmed. Hand over the item and ask the buyer for their 6-digit code.';

  @override
  String get codeSellerHint =>
      'Enter the buyer\'s 6-digit code to complete the Deal.';

  @override
  String get confirmHandover => 'Confirm handover';

  @override
  String get codeSixDigits => 'The code has 6 digits.';

  @override
  String codeInvalid(int count) {
    return 'Wrong code. $count attempts left.';
  }

  @override
  String get codeExpired =>
      'This code has expired. Ask the buyer for a new one.';

  @override
  String get codeLocked =>
      'Too many wrong attempts. Ask the buyer for a new code.';

  @override
  String get codeNotGenerated => 'The buyer has not generated a code yet.';

  @override
  String get dealCompletedSnack => 'Deal completed!';

  @override
  String get waitingBuyerAnswer =>
      'We asked the buyer to confirm. Waiting for their answer.';

  @override
  String get problemWithConfirmation => 'Problem with confirmation';

  @override
  String get problemWithConfirmationHint =>
      'e.g. I handed over the item but the buyer didn\'t give the code.';

  @override
  String get offlineHint =>
      'Meet in a safe public place, check the item and pay directly. Then both of you confirm here.';

  @override
  String get confirmed => 'confirmed';

  @override
  String get notYetConfirmed => 'not yet';

  @override
  String get confirmExchange => 'I confirm the exchange happened';

  @override
  String get confirmExchangeTitle => 'Confirm the exchange?';

  @override
  String get confirmExchangeBody =>
      'Only confirm after the item and payment were exchanged.';

  @override
  String get waitingOtherConfirm => 'Waiting for the other party to confirm.';

  @override
  String get dealCompletedNote => 'This Deal is completed. Thank you!';

  @override
  String get payout => 'Seller payout';

  @override
  String get payoutNotEligible => 'not eligible';

  @override
  String get payoutEligible => 'ready – will be released by Vitto';

  @override
  String get payoutRequested => 'being sent';

  @override
  String get payoutPaid => 'paid';

  @override
  String get payoutFailed => 'failed – Vitto will retry';

  @override
  String get payoutReversed => 'reversed';

  @override
  String get yourRating => 'Your rating';

  @override
  String rateUser(String name) {
    return 'Rate $name';
  }

  @override
  String get ratingCommentHint => 'Short comment (optional)';

  @override
  String get submitRating => 'Submit rating';

  @override
  String get disputedNote =>
      'Vitto is reviewing this Deal. The seller payout is on hold. Add photos or documents that help.';

  @override
  String evidenceFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files added',
      one: '1 file added',
      zero: 'No files added',
    );
    return '$_temp0';
  }

  @override
  String get addEvidence => 'Add a photo';

  @override
  String get evidenceNote => 'Short note (optional)';

  @override
  String get adminViewingDeal => 'You are viewing this Deal as an admin.';

  @override
  String get sellerNote => 'Seller note';

  @override
  String get switchToOffline => 'Switch to meeting in person';

  @override
  String get switchToOnline => 'Switch to online payment';

  @override
  String get cancelDeal => 'Cancel deal';

  @override
  String get cancelDealTitle => 'Cancel this deal?';

  @override
  String get cancelDealHint => 'Reason (optional)';

  @override
  String get reportProblem => 'Report a problem';

  @override
  String get reportProblemTitle => 'Report a problem to Vitto';

  @override
  String get reportProblemHint => 'What happened? An admin will review it.';

  @override
  String reviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
    );
    return '$_temp0';
  }

  @override
  String memberSince(String date) {
    return 'Member since $date';
  }

  @override
  String get accountSuspendedNote =>
      'Your account is suspended. You can browse but not post or trade.';

  @override
  String get viewPublicProfile => 'View my public profile';

  @override
  String get profileUnavailable => 'This profile is not available.';

  @override
  String get activeListings => 'Active Listings';

  @override
  String get reviews => 'Reviews';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get favoritesEmpty => 'No favorites yet';

  @override
  String get favoritesEmptyHint =>
      'Tap the heart on a Listing to save it here.';

  @override
  String get reportTitle => 'Report';

  @override
  String get reportDetailsHint => 'Add details (optional)';

  @override
  String get reportSent => 'Thanks – our team will review it.';

  @override
  String get reasonProhibited => 'Prohibited item';

  @override
  String get reasonScam => 'Scam or fraud';

  @override
  String get reasonOffensive => 'Offensive content';

  @override
  String get reasonWrongInfo => 'Wrong information';

  @override
  String get reasonNoShow => 'Didn\'t show up';

  @override
  String get reasonNotReceived => 'Item not received';

  @override
  String get reasonOther => 'Other';

  @override
  String get reportOpen => 'Open';

  @override
  String get reportReviewing => 'Reviewing';

  @override
  String get reportResolved => 'Resolved';

  @override
  String get reportDismissed => 'Dismissed';

  @override
  String get searchUsersHint => 'Search by name or email';

  @override
  String get reasonForRecord => 'Reason (kept in the audit log)';

  @override
  String get addCategory => 'Add category';

  @override
  String get openTarget => 'Open';

  @override
  String get resolveComplete => 'Complete deal (pay seller)';

  @override
  String get resolveCancel => 'Cancel deal (refund buyer)';

  @override
  String get resolveHint =>
      'Decision and reason. Refunds are processed manually in the provider dashboard.';

  @override
  String get payoutGateNote =>
      'Payouts are only possible for completed online Deals. Real payouts stay disabled until the provider and legal approvals (DEC-06) are in place.';

  @override
  String get payouts => 'Payouts';

  @override
  String get payments => 'Payments';

  @override
  String get releasePayout => 'Release payout';

  @override
  String get helpTitle => 'How Vitto works';

  @override
  String get helpStep1Title => 'Find or post';

  @override
  String get helpStep1Body =>
      'Search Listings in Nigeria and Benin, or post your own item in minutes.';

  @override
  String get helpStep2Title => 'Chat and offer';

  @override
  String get helpStep2Body =>
      'Message the seller inside Vitto and make a price offer. The seller can accept, decline or counter.';

  @override
  String get helpStep3Title => 'Agree a Deal';

  @override
  String get helpStep3Body =>
      'When an offer is accepted, choose to pay online through Vitto or meet in person.';

  @override
  String get helpStep4Title => 'Confirm';

  @override
  String get helpStep4Body =>
      'Online: the buyer gives a 6-digit code after checking the item. In person: both confirm in the app.';

  @override
  String get helpStep5Title => 'Rate';

  @override
  String get helpStep5Body =>
      'After a completed Deal, rate each other to build trust.';

  @override
  String get safetyTitle => 'Stay safe';

  @override
  String get safetyBody =>
      'Keep all conversations in Vitto. Never share your confirmation code before you have checked the item. Meet in busy public places. Never pay outside Vitto for an online Deal.';

  @override
  String get prohibitedTitle => 'Prohibited items';

  @override
  String get prohibitedBody =>
      'Weapons, drugs, stolen goods, counterfeit products, animals, and anything illegal in Nigeria or Benin are not allowed.';

  @override
  String get supportTitle => 'Need help?';

  @override
  String get supportBody =>
      'Use \"Report\" on a Listing, profile or Deal. Our team reviews reports and disputes, usually within 72 hours.';

  @override
  String get legalDraftNotice =>
      'Draft – to be replaced after legal review for Nigeria and Benin before launch.';

  @override
  String get termsBody =>
      'Vitto is a marketplace that connects buyers and sellers of physical products in Nigeria and Benin. Users are responsible for the accuracy of their Listings and for the items they sell. Online payments are processed by licensed payment providers; Vitto releases seller payouts only after the buyer confirms receipt or an admin decides a dispute. Offline exchanges happen directly between users and Vitto does not handle that money. Prohibited items are not allowed. Vitto may suspend Listings or accounts that break these rules.';

  @override
  String get privacyBody =>
      'We collect only what is needed to run the marketplace: your account details, profile, Listings, messages, offers, deals and reports. Card details are never stored by Vitto; payments are handled by the payment provider. Messages are visible only to the two participants, and to admins when reviewing a report or dispute. You can ask us to delete your account; some records (deals, payments, disputes) are kept as required by law.';
}
