import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
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
/// import 'l10n/app_localizations.dart';
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
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// Nom de l'application
  ///
  /// In fr, this message translates to:
  /// **'GPOS'**
  String get appName;

  /// Sous-titre affiché sur l'écran de connexion
  ///
  /// In fr, this message translates to:
  /// **'Système de vente'**
  String get appSubtitle;

  /// Affichage de la version
  ///
  /// In fr, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @ok.
  ///
  /// In fr, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get add;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @search.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In fr, this message translates to:
  /// **'Filtrer'**
  String get filter;

  /// No description provided for @all.
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get all;

  /// No description provided for @yes.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get no;

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get error;

  /// No description provided for @success.
  ///
  /// In fr, this message translates to:
  /// **'Succès'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In fr, this message translates to:
  /// **'Attention'**
  String get warning;

  /// No description provided for @next.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get next;

  /// No description provided for @back.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;

  /// No description provided for @finish.
  ///
  /// In fr, this message translates to:
  /// **'Terminer'**
  String get finish;

  /// No description provided for @apply.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get apply;

  /// No description provided for @validate.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get validate;

  /// No description provided for @continue_action.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continue_action;

  /// No description provided for @quit.
  ///
  /// In fr, this message translates to:
  /// **'Quitter'**
  String get quit;

  /// No description provided for @new_item.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau'**
  String get new_item;

  /// No description provided for @refresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get refresh;

  /// No description provided for @export.
  ///
  /// In fr, this message translates to:
  /// **'Exporter'**
  String get export;

  /// No description provided for @import.
  ///
  /// In fr, this message translates to:
  /// **'Importer'**
  String get import;

  /// No description provided for @print.
  ///
  /// In fr, this message translates to:
  /// **'Imprimer'**
  String get print;

  /// No description provided for @share.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get share;

  /// No description provided for @send.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get send;

  /// No description provided for @download.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger'**
  String get download;

  /// No description provided for @start.
  ///
  /// In fr, this message translates to:
  /// **'Démarrer'**
  String get start;

  /// No description provided for @stop.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter'**
  String get stop;

  /// No description provided for @reset.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get reset;

  /// No description provided for @unknown.
  ///
  /// In fr, this message translates to:
  /// **'Inconnu'**
  String get unknown;

  /// No description provided for @optional.
  ///
  /// In fr, this message translates to:
  /// **'Optionnel'**
  String get optional;

  /// No description provided for @required_field.
  ///
  /// In fr, this message translates to:
  /// **'Requis'**
  String get required_field;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings;

  /// No description provided for @help.
  ///
  /// In fr, this message translates to:
  /// **'Aide'**
  String get help;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get logout;

  /// Titre de l'écran de connexion
  ///
  /// In fr, this message translates to:
  /// **'ACCÈS SYSTÈME'**
  String get login_title;

  /// No description provided for @login_cloud.
  ///
  /// In fr, this message translates to:
  /// **'ACCÉDER AU CLOUD'**
  String get login_cloud;

  /// No description provided for @login_staff_mode.
  ///
  /// In fr, this message translates to:
  /// **'MODE STAFF'**
  String get login_staff_mode;

  /// No description provided for @login_cloud_mode.
  ///
  /// In fr, this message translates to:
  /// **'MODE CLOUD'**
  String get login_cloud_mode;

  /// No description provided for @login_my_shop.
  ///
  /// In fr, this message translates to:
  /// **'MON COMMERCE'**
  String get login_my_shop;

  /// No description provided for @login_role_cashier.
  ///
  /// In fr, this message translates to:
  /// **'Caissier'**
  String get login_role_cashier;

  /// No description provided for @login_role_manager.
  ///
  /// In fr, this message translates to:
  /// **'Gérant'**
  String get login_role_manager;

  /// No description provided for @login_role_owner.
  ///
  /// In fr, this message translates to:
  /// **'Propriétaire'**
  String get login_role_owner;

  /// No description provided for @login_email.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get login_email;

  /// No description provided for @login_password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get login_password;

  /// No description provided for @login_pin.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN'**
  String get login_pin;

  /// No description provided for @login_enter_pin.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre code PIN'**
  String get login_enter_pin;

  /// No description provided for @login_hello.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour, {name}'**
  String login_hello(String name);

  /// No description provided for @login_no_users.
  ///
  /// In fr, this message translates to:
  /// **'Aucun utilisateur inscrit pour ce rôle'**
  String get login_no_users;

  /// No description provided for @login_forgot_password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get login_forgot_password;

  /// No description provided for @login_connect.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get login_connect;

  /// No description provided for @login_change_user.
  ///
  /// In fr, this message translates to:
  /// **'Changer d\'utilisateur'**
  String get login_change_user;

  /// No description provided for @login_error_invalid.
  ///
  /// In fr, this message translates to:
  /// **'Email ou mot de passe incorrect.'**
  String get login_error_invalid;

  /// No description provided for @login_error_unconfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Email non confirmé. Vérifiez votre boîte mail.'**
  String get login_error_unconfirmed;

  /// No description provided for @login_error_rate_limit.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives. Attendez quelques minutes.'**
  String get login_error_rate_limit;

  /// No description provided for @login_reset_sent.
  ///
  /// In fr, this message translates to:
  /// **'Email de réinitialisation envoyé'**
  String get login_reset_sent;

  /// No description provided for @nav_caisse.
  ///
  /// In fr, this message translates to:
  /// **'Caisse'**
  String get nav_caisse;

  /// No description provided for @nav_products.
  ///
  /// In fr, this message translates to:
  /// **'Produits'**
  String get nav_products;

  /// No description provided for @nav_inventory.
  ///
  /// In fr, this message translates to:
  /// **'Inventaire'**
  String get nav_inventory;

  /// No description provided for @nav_sales.
  ///
  /// In fr, this message translates to:
  /// **'Ventes'**
  String get nav_sales;

  /// No description provided for @nav_customers.
  ///
  /// In fr, this message translates to:
  /// **'Clients'**
  String get nav_customers;

  /// No description provided for @nav_reports.
  ///
  /// In fr, this message translates to:
  /// **'Rapports'**
  String get nav_reports;

  /// No description provided for @nav_settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get nav_settings;

  /// No description provided for @nav_dashboard.
  ///
  /// In fr, this message translates to:
  /// **'Dashboard'**
  String get nav_dashboard;

  /// No description provided for @cashier_title.
  ///
  /// In fr, this message translates to:
  /// **'Caisse'**
  String get cashier_title;

  /// No description provided for @cashier_empty_cart.
  ///
  /// In fr, this message translates to:
  /// **'Votre panier est vide'**
  String get cashier_empty_cart;

  /// No description provided for @cashier_start_hint.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez des articles pour commencer.'**
  String get cashier_start_hint;

  /// No description provided for @cashier_search_hint.
  ///
  /// In fr, this message translates to:
  /// **'Chercher un article ou scanner...'**
  String get cashier_search_hint;

  /// No description provided for @cashier_no_results.
  ///
  /// In fr, this message translates to:
  /// **'Aucun article ne correspond à votre recherche.'**
  String get cashier_no_results;

  /// No description provided for @cashier_no_products.
  ///
  /// In fr, this message translates to:
  /// **'Aucun produit'**
  String get cashier_no_products;

  /// No description provided for @cashier_validate_sale.
  ///
  /// In fr, this message translates to:
  /// **'Valider la vente'**
  String get cashier_validate_sale;

  /// No description provided for @cashier_verify_price.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier prix/stock'**
  String get cashier_verify_price;

  /// No description provided for @cashier_flashlight.
  ///
  /// In fr, this message translates to:
  /// **'Lampe torche'**
  String get cashier_flashlight;

  /// No description provided for @cashier_out_of_stock.
  ///
  /// In fr, this message translates to:
  /// **'ÉPUISÉ'**
  String get cashier_out_of_stock;

  /// No description provided for @cashier_no_category.
  ///
  /// In fr, this message translates to:
  /// **'Sans catégorie'**
  String get cashier_no_category;

  /// No description provided for @cashier_apply_coupon.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer un coupon'**
  String get cashier_apply_coupon;

  /// No description provided for @cashier_discount_pct.
  ///
  /// In fr, this message translates to:
  /// **'Pourcentage (%)'**
  String get cashier_discount_pct;

  /// No description provided for @cashier_discount_fixed.
  ///
  /// In fr, this message translates to:
  /// **'Montant Fixe'**
  String get cashier_discount_fixed;

  /// No description provided for @cashier_credit_required.
  ///
  /// In fr, this message translates to:
  /// **'Requis pour les ventes à crédit'**
  String get cashier_credit_required;

  /// No description provided for @cashier_printer_disconnected.
  ///
  /// In fr, this message translates to:
  /// **'Imprimante déconnectée ou non configurée'**
  String get cashier_printer_disconnected;

  /// No description provided for @cashier_whatsapp_quick.
  ///
  /// In fr, this message translates to:
  /// **'WhatsApp Rapide (Texte)'**
  String get cashier_whatsapp_quick;

  /// No description provided for @cashier_whatsapp_pdf.
  ///
  /// In fr, this message translates to:
  /// **'Partager le reçu PDF complet'**
  String get cashier_whatsapp_pdf;

  /// No description provided for @cashier_send_to.
  ///
  /// In fr, this message translates to:
  /// **'Envoi direct au {phone}'**
  String cashier_send_to(String phone);

  /// No description provided for @cashier_send_whatsapp.
  ///
  /// In fr, this message translates to:
  /// **'ENVOYER PAR WHATSAPP / SMS'**
  String get cashier_send_whatsapp;

  /// No description provided for @cashier_ignore.
  ///
  /// In fr, this message translates to:
  /// **'IGNORER'**
  String get cashier_ignore;

  /// No description provided for @cashier_options.
  ///
  /// In fr, this message translates to:
  /// **'Options'**
  String get cashier_options;

  /// No description provided for @cashier_remain_to_pay.
  ///
  /// In fr, this message translates to:
  /// **'Reste à payer'**
  String get cashier_remain_to_pay;

  /// No description provided for @payment_title.
  ///
  /// In fr, this message translates to:
  /// **'Paiement'**
  String get payment_title;

  /// No description provided for @payment_total.
  ///
  /// In fr, this message translates to:
  /// **'Total à payer'**
  String get payment_total;

  /// No description provided for @payment_method.
  ///
  /// In fr, this message translates to:
  /// **'Méthode de paiement'**
  String get payment_method;

  /// No description provided for @payment_cash.
  ///
  /// In fr, this message translates to:
  /// **'Espèces'**
  String get payment_cash;

  /// No description provided for @payment_wave.
  ///
  /// In fr, this message translates to:
  /// **'Wave'**
  String get payment_wave;

  /// No description provided for @payment_orange_money.
  ///
  /// In fr, this message translates to:
  /// **'Orange Money'**
  String get payment_orange_money;

  /// No description provided for @payment_card.
  ///
  /// In fr, this message translates to:
  /// **'Carte bancaire'**
  String get payment_card;

  /// No description provided for @payment_credit.
  ///
  /// In fr, this message translates to:
  /// **'À crédit'**
  String get payment_credit;

  /// No description provided for @payment_mobile_money.
  ///
  /// In fr, this message translates to:
  /// **'Mobile Money'**
  String get payment_mobile_money;

  /// No description provided for @payment_amount_given.
  ///
  /// In fr, this message translates to:
  /// **'Montant remis'**
  String get payment_amount_given;

  /// No description provided for @payment_change.
  ///
  /// In fr, this message translates to:
  /// **'Monnaie à rendre'**
  String get payment_change;

  /// No description provided for @payment_confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le paiement'**
  String get payment_confirm;

  /// No description provided for @payment_success.
  ///
  /// In fr, this message translates to:
  /// **'Paiement enregistré avec succès.'**
  String get payment_success;

  /// No description provided for @payment_invalid_amount.
  ///
  /// In fr, this message translates to:
  /// **'Montant invalide'**
  String get payment_invalid_amount;

  /// No description provided for @payment_amount_exceeded.
  ///
  /// In fr, this message translates to:
  /// **'Le montant ne peut pas dépasser le solde dû'**
  String get payment_amount_exceeded;

  /// No description provided for @payment_amount_paid.
  ///
  /// In fr, this message translates to:
  /// **'Montant payé'**
  String get payment_amount_paid;

  /// No description provided for @payment_record.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer un paiement'**
  String get payment_record;

  /// No description provided for @products_title.
  ///
  /// In fr, this message translates to:
  /// **'Catalogue produits'**
  String get products_title;

  /// No description provided for @products_new.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau produit'**
  String get products_new;

  /// No description provided for @products_import_csv.
  ///
  /// In fr, this message translates to:
  /// **'Importer des produits (CSV)'**
  String get products_import_csv;

  /// No description provided for @products_print_labels.
  ///
  /// In fr, this message translates to:
  /// **'Imprimer des étiquettes'**
  String get products_print_labels;

  /// No description provided for @products_scan_barcode.
  ///
  /// In fr, this message translates to:
  /// **'Scanner un code-barres'**
  String get products_scan_barcode;

  /// No description provided for @products_restock.
  ///
  /// In fr, this message translates to:
  /// **'Réapprovisionner'**
  String get products_restock;

  /// No description provided for @products_stock.
  ///
  /// In fr, this message translates to:
  /// **'Stock — {name}'**
  String products_stock(String name);

  /// No description provided for @products_delete_confirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le produit'**
  String get products_delete_confirm;

  /// No description provided for @products_delete_photo.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la photo'**
  String get products_delete_photo;

  /// No description provided for @products_camera.
  ///
  /// In fr, this message translates to:
  /// **'Appareil photo'**
  String get products_camera;

  /// No description provided for @products_gallery.
  ///
  /// In fr, this message translates to:
  /// **'Galerie'**
  String get products_gallery;

  /// No description provided for @products_logo.
  ///
  /// In fr, this message translates to:
  /// **'Logo'**
  String get products_logo;

  /// No description provided for @products_saving.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement...'**
  String get products_saving;

  /// No description provided for @form_name.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get form_name;

  /// No description provided for @form_price.
  ///
  /// In fr, this message translates to:
  /// **'Prix'**
  String get form_price;

  /// No description provided for @form_price_ht.
  ///
  /// In fr, this message translates to:
  /// **'Prix HT'**
  String get form_price_ht;

  /// No description provided for @form_price_ttc.
  ///
  /// In fr, this message translates to:
  /// **'Prix TTC'**
  String get form_price_ttc;

  /// No description provided for @form_cost_price.
  ///
  /// In fr, this message translates to:
  /// **'Prix d\'achat'**
  String get form_cost_price;

  /// No description provided for @form_stock.
  ///
  /// In fr, this message translates to:
  /// **'Stock'**
  String get form_stock;

  /// No description provided for @form_stock_alert.
  ///
  /// In fr, this message translates to:
  /// **'Seuil d\'alerte'**
  String get form_stock_alert;

  /// No description provided for @form_category.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get form_category;

  /// No description provided for @form_barcode.
  ///
  /// In fr, this message translates to:
  /// **'Code-barres'**
  String get form_barcode;

  /// No description provided for @form_description.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get form_description;

  /// No description provided for @form_tax_rate.
  ///
  /// In fr, this message translates to:
  /// **'Taux TVA'**
  String get form_tax_rate;

  /// No description provided for @form_unit.
  ///
  /// In fr, this message translates to:
  /// **'Unité'**
  String get form_unit;

  /// No description provided for @form_expiry.
  ///
  /// In fr, this message translates to:
  /// **'Date d\'expiration'**
  String get form_expiry;

  /// No description provided for @form_supplier.
  ///
  /// In fr, this message translates to:
  /// **'Fournisseur'**
  String get form_supplier;

  /// No description provided for @form_email.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email'**
  String get form_email;

  /// No description provided for @form_phone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get form_phone;

  /// No description provided for @form_address.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get form_address;

  /// No description provided for @form_city.
  ///
  /// In fr, this message translates to:
  /// **'Ville'**
  String get form_city;

  /// No description provided for @form_country.
  ///
  /// In fr, this message translates to:
  /// **'Pays'**
  String get form_country;

  /// No description provided for @form_notes.
  ///
  /// In fr, this message translates to:
  /// **'Notes'**
  String get form_notes;

  /// No description provided for @form_required_name.
  ///
  /// In fr, this message translates to:
  /// **'Le nom est requis'**
  String get form_required_name;

  /// No description provided for @form_required_price.
  ///
  /// In fr, this message translates to:
  /// **'Le prix est requis'**
  String get form_required_price;

  /// No description provided for @form_invalid_price.
  ///
  /// In fr, this message translates to:
  /// **'Prix invalide'**
  String get form_invalid_price;

  /// No description provided for @form_invalid_email.
  ///
  /// In fr, this message translates to:
  /// **'Email invalide'**
  String get form_invalid_email;

  /// No description provided for @sales_title.
  ///
  /// In fr, this message translates to:
  /// **'Historique des ventes'**
  String get sales_title;

  /// No description provided for @sales_empty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune vente sur cette période'**
  String get sales_empty;

  /// No description provided for @sales_filter_status.
  ///
  /// In fr, this message translates to:
  /// **'Filtrer par statut de paiement'**
  String get sales_filter_status;

  /// No description provided for @sales_status_all.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get sales_status_all;

  /// No description provided for @sales_status_paid.
  ///
  /// In fr, this message translates to:
  /// **'Entièrement payées'**
  String get sales_status_paid;

  /// No description provided for @sales_status_credit.
  ///
  /// In fr, this message translates to:
  /// **'Dues (à crédit)'**
  String get sales_status_credit;

  /// No description provided for @sales_status_partial.
  ///
  /// In fr, this message translates to:
  /// **'Partiellement payées'**
  String get sales_status_partial;

  /// No description provided for @sales_status_cancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulées'**
  String get sales_status_cancelled;

  /// No description provided for @sales_status_completed.
  ///
  /// In fr, this message translates to:
  /// **'Encaissée'**
  String get sales_status_completed;

  /// No description provided for @sales_status_due.
  ///
  /// In fr, this message translates to:
  /// **'Due'**
  String get sales_status_due;

  /// No description provided for @inventory_title.
  ///
  /// In fr, this message translates to:
  /// **'Inventaire'**
  String get inventory_title;

  /// No description provided for @inventory_new_session.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle session'**
  String get inventory_new_session;

  /// No description provided for @inventory_in_progress.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get inventory_in_progress;

  /// No description provided for @inventory_completed.
  ///
  /// In fr, this message translates to:
  /// **'Terminée'**
  String get inventory_completed;

  /// No description provided for @inventory_discrepancy.
  ///
  /// In fr, this message translates to:
  /// **'{count} écart(s)'**
  String inventory_discrepancy(int count);

  /// No description provided for @customers_title.
  ///
  /// In fr, this message translates to:
  /// **'Clients'**
  String get customers_title;

  /// No description provided for @customers_new.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau client'**
  String get customers_new;

  /// No description provided for @customers_debt.
  ///
  /// In fr, this message translates to:
  /// **'Crédit en cours'**
  String get customers_debt;

  /// No description provided for @customers_no_debt.
  ///
  /// In fr, this message translates to:
  /// **'Aucune dette'**
  String get customers_no_debt;

  /// No description provided for @customers_loyalty_points.
  ///
  /// In fr, this message translates to:
  /// **'{points} points'**
  String customers_loyalty_points(int points);

  /// No description provided for @reports_title.
  ///
  /// In fr, this message translates to:
  /// **'Rapports'**
  String get reports_title;

  /// No description provided for @reports_daily.
  ///
  /// In fr, this message translates to:
  /// **'Journalier'**
  String get reports_daily;

  /// No description provided for @reports_weekly.
  ///
  /// In fr, this message translates to:
  /// **'Hebdomadaire'**
  String get reports_weekly;

  /// No description provided for @reports_monthly.
  ///
  /// In fr, this message translates to:
  /// **'Mensuel'**
  String get reports_monthly;

  /// No description provided for @reports_revenue.
  ///
  /// In fr, this message translates to:
  /// **'Chiffre d\'affaires'**
  String get reports_revenue;

  /// No description provided for @reports_sales_count.
  ///
  /// In fr, this message translates to:
  /// **'Nombre de ventes'**
  String get reports_sales_count;

  /// No description provided for @reports_avg_basket.
  ///
  /// In fr, this message translates to:
  /// **'Panier moyen'**
  String get reports_avg_basket;

  /// No description provided for @reports_top_products.
  ///
  /// In fr, this message translates to:
  /// **'Meilleurs produits'**
  String get reports_top_products;

  /// No description provided for @reports_tax_summary.
  ///
  /// In fr, this message translates to:
  /// **'Récapitulatif TVA'**
  String get reports_tax_summary;

  /// No description provided for @reports_export_csv.
  ///
  /// In fr, this message translates to:
  /// **'Exporter en CSV'**
  String get reports_export_csv;

  /// No description provided for @reports_export_pdf.
  ///
  /// In fr, this message translates to:
  /// **'Exporter en PDF'**
  String get reports_export_pdf;

  /// No description provided for @reports_period.
  ///
  /// In fr, this message translates to:
  /// **'Période'**
  String get reports_period;

  /// No description provided for @reports_from.
  ///
  /// In fr, this message translates to:
  /// **'Du'**
  String get reports_from;

  /// No description provided for @reports_to.
  ///
  /// In fr, this message translates to:
  /// **'Au'**
  String get reports_to;

  /// No description provided for @cash_drawer_title.
  ///
  /// In fr, this message translates to:
  /// **'Caisse'**
  String get cash_drawer_title;

  /// No description provided for @cash_drawer_open.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir la caisse'**
  String get cash_drawer_open;

  /// No description provided for @cash_drawer_close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer la caisse'**
  String get cash_drawer_close;

  /// No description provided for @cash_drawer_starting_amount.
  ///
  /// In fr, this message translates to:
  /// **'Fond de caisse initial'**
  String get cash_drawer_starting_amount;

  /// No description provided for @cash_drawer_closing_amount.
  ///
  /// In fr, this message translates to:
  /// **'Fond de clôture'**
  String get cash_drawer_closing_amount;

  /// No description provided for @cash_drawer_session_total.
  ///
  /// In fr, this message translates to:
  /// **'TOTAL SESSION'**
  String get cash_drawer_session_total;

  /// No description provided for @cash_drawer_hello.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour, {name}'**
  String cash_drawer_hello(String name);

  /// No description provided for @cash_drawer_start_day.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir le fond de caisse pour démarrer la journée.'**
  String get cash_drawer_start_day;

  /// No description provided for @settings_title.
  ///
  /// In fr, this message translates to:
  /// **'PARAMÈTRES'**
  String get settings_title;

  /// No description provided for @settings_shop_name.
  ///
  /// In fr, this message translates to:
  /// **'Nom du magasin'**
  String get settings_shop_name;

  /// No description provided for @settings_shop_address.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get settings_shop_address;

  /// No description provided for @settings_shop_phone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get settings_shop_phone;

  /// No description provided for @settings_terminal_name.
  ///
  /// In fr, this message translates to:
  /// **'Nom du terminal'**
  String get settings_terminal_name;

  /// No description provided for @settings_receipt_footer.
  ///
  /// In fr, this message translates to:
  /// **'Pied de reçu'**
  String get settings_receipt_footer;

  /// No description provided for @settings_receipt_footer_default.
  ///
  /// In fr, this message translates to:
  /// **'Merci de votre visite !'**
  String get settings_receipt_footer_default;

  /// No description provided for @settings_printer.
  ///
  /// In fr, this message translates to:
  /// **'Imprimante'**
  String get settings_printer;

  /// No description provided for @settings_printer_connect.
  ///
  /// In fr, this message translates to:
  /// **'Connecter une imprimante'**
  String get settings_printer_connect;

  /// No description provided for @settings_printer_usb.
  ///
  /// In fr, this message translates to:
  /// **'Imprimante USB thermique'**
  String get settings_printer_usb;

  /// No description provided for @settings_printer_system.
  ///
  /// In fr, this message translates to:
  /// **'Imprimante système (PDF)'**
  String get settings_printer_system;

  /// No description provided for @settings_printer_new.
  ///
  /// In fr, this message translates to:
  /// **'Appairer un nouvel appareil'**
  String get settings_printer_new;

  /// No description provided for @settings_printer_unknown.
  ///
  /// In fr, this message translates to:
  /// **'Appareil inconnu'**
  String get settings_printer_unknown;

  /// No description provided for @settings_printer_no_usb.
  ///
  /// In fr, this message translates to:
  /// **'Aucune imprimante USB détectée.'**
  String get settings_printer_no_usb;

  /// No description provided for @settings_printer_none.
  ///
  /// In fr, this message translates to:
  /// **'Aucune imprimante installée sur ce système.'**
  String get settings_printer_none;

  /// No description provided for @settings_choose_printer.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une imprimante'**
  String get settings_choose_printer;

  /// No description provided for @settings_choose_printer_usb.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une imprimante USB'**
  String get settings_choose_printer_usb;

  /// No description provided for @settings_bluetooth_permissions.
  ///
  /// In fr, this message translates to:
  /// **'Permissions Bluetooth'**
  String get settings_bluetooth_permissions;

  /// No description provided for @settings_pin_new.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau code PIN'**
  String get settings_pin_new;

  /// No description provided for @settings_password_new.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get settings_password_new;

  /// No description provided for @settings_password_changed.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe modifié'**
  String get settings_password_changed;

  /// No description provided for @settings_admin_only.
  ///
  /// In fr, this message translates to:
  /// **'Accès réservé aux administrateurs'**
  String get settings_admin_only;

  /// No description provided for @settings_new_store.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau magasin'**
  String get settings_new_store;

  /// No description provided for @settings_add_store.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un nouveau magasin'**
  String get settings_add_store;

  /// No description provided for @settings_create_switch.
  ///
  /// In fr, this message translates to:
  /// **'Créer et basculer'**
  String get settings_create_switch;

  /// No description provided for @settings_export_anyway.
  ///
  /// In fr, this message translates to:
  /// **'Exporter quand même'**
  String get settings_export_anyway;

  /// No description provided for @settings_security_breach.
  ///
  /// In fr, this message translates to:
  /// **'Faille de sécurité critique'**
  String get settings_security_breach;

  /// No description provided for @settings_critical_action.
  ///
  /// In fr, this message translates to:
  /// **'Action critique'**
  String get settings_critical_action;

  /// No description provided for @settings_decrypt.
  ///
  /// In fr, this message translates to:
  /// **'Déchiffrer'**
  String get settings_decrypt;

  /// No description provided for @settings_restore.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer'**
  String get settings_restore;

  /// No description provided for @settings_restore_success.
  ///
  /// In fr, this message translates to:
  /// **'Restauration réussie'**
  String get settings_restore_success;

  /// No description provided for @settings_restore_secure.
  ///
  /// In fr, this message translates to:
  /// **'Restauration sécurisée'**
  String get settings_restore_secure;

  /// No description provided for @settings_cleanup.
  ///
  /// In fr, this message translates to:
  /// **'Nettoyage des justificatifs'**
  String get settings_cleanup;

  /// No description provided for @settings_clean.
  ///
  /// In fr, this message translates to:
  /// **'Nettoyer'**
  String get settings_clean;

  /// No description provided for @settings_understood.
  ///
  /// In fr, this message translates to:
  /// **'Compris'**
  String get settings_understood;

  /// No description provided for @settings_preparing_catalog.
  ///
  /// In fr, this message translates to:
  /// **'Préparation du catalogue...'**
  String get settings_preparing_catalog;

  /// No description provided for @settings_saved.
  ///
  /// In fr, this message translates to:
  /// **'Enregistré !'**
  String get settings_saved;

  /// No description provided for @settings_currency.
  ///
  /// In fr, this message translates to:
  /// **'Devise'**
  String get settings_currency;

  /// No description provided for @settings_language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get settings_language;

  /// No description provided for @settings_country.
  ///
  /// In fr, this message translates to:
  /// **'Pays'**
  String get settings_country;

  /// No description provided for @settings_tax_rate_default.
  ///
  /// In fr, this message translates to:
  /// **'Taux TVA par défaut'**
  String get settings_tax_rate_default;

  /// No description provided for @settings_theme.
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get settings_theme;

  /// No description provided for @sync_idle.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne'**
  String get sync_idle;

  /// No description provided for @sync_syncing.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation en cours...'**
  String get sync_syncing;

  /// No description provided for @sync_up_to_date.
  ///
  /// In fr, this message translates to:
  /// **'Données synchronisées'**
  String get sync_up_to_date;

  /// No description provided for @sync_error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de synchronisation'**
  String get sync_error;

  /// No description provided for @sync_partial.
  ///
  /// In fr, this message translates to:
  /// **'Sync partielle — réessai en cours'**
  String get sync_partial;

  /// No description provided for @sync_in_progress.
  ///
  /// In fr, this message translates to:
  /// **'Sync en cours...'**
  String get sync_in_progress;

  /// No description provided for @sync_done.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisé'**
  String get sync_done;

  /// No description provided for @stock_low.
  ///
  /// In fr, this message translates to:
  /// **'{count} produit(s) en stock faible'**
  String stock_low(int count);

  /// No description provided for @currency_fcfa.
  ///
  /// In fr, this message translates to:
  /// **'FCFA'**
  String get currency_fcfa;

  /// No description provided for @currency_gnf.
  ///
  /// In fr, this message translates to:
  /// **'GNF'**
  String get currency_gnf;

  /// No description provided for @currency_xof.
  ///
  /// In fr, this message translates to:
  /// **'XOF'**
  String get currency_xof;

  /// No description provided for @country_senegal.
  ///
  /// In fr, this message translates to:
  /// **'Sénégal'**
  String get country_senegal;

  /// No description provided for @country_mali.
  ///
  /// In fr, this message translates to:
  /// **'Mali'**
  String get country_mali;

  /// No description provided for @country_cote_divoire.
  ///
  /// In fr, this message translates to:
  /// **'Côte d\'Ivoire'**
  String get country_cote_divoire;

  /// No description provided for @country_guinee.
  ///
  /// In fr, this message translates to:
  /// **'Guinée'**
  String get country_guinee;

  /// No description provided for @country_benin.
  ///
  /// In fr, this message translates to:
  /// **'Bénin'**
  String get country_benin;

  /// No description provided for @country_burkina.
  ///
  /// In fr, this message translates to:
  /// **'Burkina Faso'**
  String get country_burkina;

  /// No description provided for @country_togo.
  ///
  /// In fr, this message translates to:
  /// **'Togo'**
  String get country_togo;

  /// No description provided for @country_niger.
  ///
  /// In fr, this message translates to:
  /// **'Niger'**
  String get country_niger;

  /// No description provided for @error_network.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion internet'**
  String get error_network;

  /// No description provided for @error_session_expired.
  ///
  /// In fr, this message translates to:
  /// **'Session expirée — reconnectez-vous'**
  String get error_session_expired;

  /// No description provided for @error_generic.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Veuillez réessayer.'**
  String get error_generic;

  /// No description provided for @error_capture.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la capture : {error}'**
  String error_capture(String error);

  /// No description provided for @error_print_failed.
  ///
  /// In fr, this message translates to:
  /// **'L\'impression a échoué'**
  String get error_print_failed;

  /// No description provided for @date_today.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get date_today;

  /// No description provided for @date_yesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get date_yesterday;

  /// No description provided for @date_this_week.
  ///
  /// In fr, this message translates to:
  /// **'Cette semaine'**
  String get date_this_week;

  /// No description provided for @date_this_month.
  ///
  /// In fr, this message translates to:
  /// **'Ce mois'**
  String get date_this_month;

  /// No description provided for @date_last_7_days.
  ///
  /// In fr, this message translates to:
  /// **'7 derniers jours'**
  String get date_last_7_days;

  /// No description provided for @date_last_30_days.
  ///
  /// In fr, this message translates to:
  /// **'30 derniers jours'**
  String get date_last_30_days;

  /// No description provided for @dashboard_title.
  ///
  /// In fr, this message translates to:
  /// **'Vue d\'ensemble'**
  String get dashboard_title;

  /// No description provided for @dashboard_all_stores.
  ///
  /// In fr, this message translates to:
  /// **'Tous magasins'**
  String get dashboard_all_stores;

  /// No description provided for @dashboard_best_store.
  ///
  /// In fr, this message translates to:
  /// **'Meilleur magasin'**
  String get dashboard_best_store;

  /// No description provided for @dashboard_total_revenue.
  ///
  /// In fr, this message translates to:
  /// **'CA total'**
  String get dashboard_total_revenue;

  /// No description provided for @dashboard_total_sales.
  ///
  /// In fr, this message translates to:
  /// **'Ventes'**
  String get dashboard_total_sales;

  /// No description provided for @dashboard_active_stores.
  ///
  /// In fr, this message translates to:
  /// **'Magasins actifs'**
  String get dashboard_active_stores;

  /// No description provided for @dashboard_stock_alerts.
  ///
  /// In fr, this message translates to:
  /// **'Alertes stock'**
  String get dashboard_stock_alerts;

  /// No description provided for @dashboard_period_today.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get dashboard_period_today;

  /// No description provided for @dashboard_period_week.
  ///
  /// In fr, this message translates to:
  /// **'7 jours'**
  String get dashboard_period_week;

  /// No description provided for @dashboard_period_month.
  ///
  /// In fr, this message translates to:
  /// **'30 jours'**
  String get dashboard_period_month;

  /// No description provided for @dashboard_no_stores.
  ///
  /// In fr, this message translates to:
  /// **'Aucun magasin enregistré'**
  String get dashboard_no_stores;

  /// No description provided for @dashboard_no_stores_hint.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrez l\'application POS sur chaque appareil pour enregistrer automatiquement les magasins.'**
  String get dashboard_no_stores_hint;

  /// No description provided for @dashboard_last_updated.
  ///
  /// In fr, this message translates to:
  /// **'Màj {time}'**
  String dashboard_last_updated(String time);

  /// No description provided for @dashboard_sign_out.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get dashboard_sign_out;

  /// No description provided for @dashboard_sign_out_confirm.
  ///
  /// In fr, this message translates to:
  /// **'Vous serez redirigé vers l\'écran de connexion.'**
  String get dashboard_sign_out_confirm;

  /// No description provided for @dashboard_disconnect.
  ///
  /// In fr, this message translates to:
  /// **'Déconnecter'**
  String get dashboard_disconnect;

  /// No description provided for @category_food.
  ///
  /// In fr, this message translates to:
  /// **'Alimentation'**
  String get category_food;

  /// No description provided for @category_beverages.
  ///
  /// In fr, this message translates to:
  /// **'Boissons'**
  String get category_beverages;

  /// No description provided for @category_hygiene.
  ///
  /// In fr, this message translates to:
  /// **'Hygiène'**
  String get category_hygiene;

  /// No description provided for @category_electronics.
  ///
  /// In fr, this message translates to:
  /// **'Électronique'**
  String get category_electronics;

  /// No description provided for @category_clothing.
  ///
  /// In fr, this message translates to:
  /// **'Vêtements'**
  String get category_clothing;

  /// No description provided for @category_home.
  ///
  /// In fr, this message translates to:
  /// **'Maison'**
  String get category_home;

  /// No description provided for @category_beauty.
  ///
  /// In fr, this message translates to:
  /// **'Beauté'**
  String get category_beauty;

  /// No description provided for @category_books.
  ///
  /// In fr, this message translates to:
  /// **'Livres'**
  String get category_books;

  /// No description provided for @category_sports.
  ///
  /// In fr, this message translates to:
  /// **'Sports'**
  String get category_sports;

  /// No description provided for @category_toys.
  ///
  /// In fr, this message translates to:
  /// **'Jouets'**
  String get category_toys;

  /// No description provided for @category_automotive.
  ///
  /// In fr, this message translates to:
  /// **'Automobile'**
  String get category_automotive;

  /// No description provided for @category_garden.
  ///
  /// In fr, this message translates to:
  /// **'Jardin'**
  String get category_garden;

  /// No description provided for @category_other.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get category_other;

  /// No description provided for @category_none.
  ///
  /// In fr, this message translates to:
  /// **'Sans catégorie'**
  String get category_none;
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
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
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
