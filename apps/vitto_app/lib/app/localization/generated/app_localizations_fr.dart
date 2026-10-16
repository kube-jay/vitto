// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Vitto';

  @override
  String get tagline => 'Achetez et vendez au Nigeria et au Bénin';

  @override
  String get navHome => 'Accueil';

  @override
  String get navSearch => 'Rechercher';

  @override
  String get navSell => 'Vendre';

  @override
  String get navInbox => 'Messages';

  @override
  String get navDeals => 'Mes transactions';

  @override
  String get navFavorites => 'Favoris';

  @override
  String get navProfile => 'Mon profil';

  @override
  String get navAdmin => 'Administration';

  @override
  String get navHelp => 'Aide';

  @override
  String get signIn => 'Se connecter';

  @override
  String get signUp => 'Créer un compte';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get resetPassword => 'Réinitialiser le mot de passe';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get language => 'Langue';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get country => 'Pays';

  @override
  String get countryNigeria => 'Nigeria';

  @override
  String get countryBenin => 'Bénin';

  @override
  String get searchHint => 'Rechercher des annonces';

  @override
  String get categories => 'Catégories';

  @override
  String get latestListings => 'Dernières annonces';

  @override
  String get noListingsYet => 'Aucune annonce active pour le moment.';

  @override
  String comingSoon(String milestone) {
    return 'Cet écran fait partie du jalon $milestone.';
  }

  @override
  String get demoModeBanner => 'Mode démo : aucun serveur configuré.';

  @override
  String get retry => 'Réessayer';

  @override
  String get loading => 'Chargement…';

  @override
  String get errorGeneric => 'Une erreur s\'est produite. Veuillez réessayer.';

  @override
  String get screenListingDetails => 'Annonce';

  @override
  String get screenPublicProfile => 'Profil';

  @override
  String get screenCreateListing => 'Créer une annonce';

  @override
  String get screenEditListing => 'Modifier l\'annonce';

  @override
  String get screenMyListings => 'Mes annonces';

  @override
  String get screenConversation => 'Conversation';

  @override
  String get screenDealDetails => 'Transaction';

  @override
  String get screenEditProfile => 'Modifier le profil';

  @override
  String get screenReports => 'Mes signalements';

  @override
  String get screenAdminUsers => 'Utilisateurs';

  @override
  String get screenAdminListings => 'Annonces';

  @override
  String get screenAdminCategories => 'Catégories';

  @override
  String get screenAdminReports => 'Signalements';

  @override
  String get screenAdminDisputes => 'Litiges';

  @override
  String get screenAdminPayments => 'Paiements et versements';

  @override
  String get screenTerms => 'Conditions d\'utilisation';

  @override
  String get screenPrivacy => 'Confidentialité';

  @override
  String get listingStatusDraft => 'Brouillon';

  @override
  String get listingStatusActive => 'Active';

  @override
  String get listingStatusReserved => 'Réservée';

  @override
  String get listingStatusSold => 'Vendue';

  @override
  String get listingStatusArchived => 'Archivée';

  @override
  String get listingStatusSuspended => 'Suspendue';

  @override
  String get offerStatusPending => 'En attente';

  @override
  String get offerStatusAccepted => 'Acceptée';

  @override
  String get offerStatusRejected => 'Refusée';

  @override
  String get offerStatusCountered => 'Contre-offre faite';

  @override
  String get offerStatusExpired => 'Expirée';

  @override
  String get offerStatusCancelled => 'Annulée';

  @override
  String get dealStatusAwaitingPayment => 'En attente de paiement';

  @override
  String get dealStatusPaid => 'Payée';

  @override
  String get dealStatusAwaitingHandover => 'En attente de remise';

  @override
  String get dealStatusCompleted => 'Terminée';

  @override
  String get dealStatusCancelled => 'Annulée';

  @override
  String get dealStatusDisputed => 'En litige';

  @override
  String get conditionNew => 'Neuf';

  @override
  String get conditionUsed => 'Occasion';

  @override
  String get negotiable => 'Négociable';

  @override
  String get fixedPrice => 'Prix fixe';

  @override
  String get postListing => 'Déposer une annonce';

  @override
  String get searchEverything => 'Téléphones, meubles, vêtements…';

  @override
  String get latestListingsEmptyHint =>
      'Soyez le premier à publier une annonce près de chez vous.';
}
