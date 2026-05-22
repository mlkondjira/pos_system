// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'GPOS';

  @override
  String get appSubtitle => 'Système de vente';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get add => 'Ajouter';

  @override
  String get close => 'Fermer';

  @override
  String get confirm => 'Confirmer';

  @override
  String get retry => 'Réessayer';

  @override
  String get search => 'Rechercher';

  @override
  String get filter => 'Filtrer';

  @override
  String get all => 'Tout';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get loading => 'Chargement...';

  @override
  String get error => 'Erreur';

  @override
  String get success => 'Succès';

  @override
  String get warning => 'Attention';

  @override
  String get next => 'Suivant';

  @override
  String get back => 'Retour';

  @override
  String get finish => 'Terminer';

  @override
  String get apply => 'Appliquer';

  @override
  String get validate => 'Valider';

  @override
  String get continue_action => 'Continuer';

  @override
  String get quit => 'Quitter';

  @override
  String get new_item => 'Nouveau';

  @override
  String get refresh => 'Actualiser';

  @override
  String get export => 'Exporter';

  @override
  String get import => 'Importer';

  @override
  String get print => 'Imprimer';

  @override
  String get share => 'Partager';

  @override
  String get send => 'Envoyer';

  @override
  String get download => 'Télécharger';

  @override
  String get start => 'Démarrer';

  @override
  String get stop => 'Arrêter';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get unknown => 'Inconnu';

  @override
  String get optional => 'Optionnel';

  @override
  String get required_field => 'Requis';

  @override
  String get settings => 'Paramètres';

  @override
  String get help => 'Aide';

  @override
  String get logout => 'Déconnexion';

  @override
  String get login_title => 'ACCÈS SYSTÈME';

  @override
  String get login_cloud => 'ACCÉDER AU CLOUD';

  @override
  String get login_staff_mode => 'MODE STAFF';

  @override
  String get login_cloud_mode => 'MODE CLOUD';

  @override
  String get login_my_shop => 'MON COMMERCE';

  @override
  String get login_role_cashier => 'Caissier';

  @override
  String get login_role_manager => 'Gérant';

  @override
  String get login_role_owner => 'Propriétaire';

  @override
  String get login_email => 'Email';

  @override
  String get login_password => 'Mot de passe';

  @override
  String get login_pin => 'Code PIN';

  @override
  String get login_enter_pin => 'Entrez votre code PIN';

  @override
  String login_hello(String name) {
    return 'Bonjour, $name';
  }

  @override
  String get login_no_users => 'Aucun utilisateur inscrit pour ce rôle';

  @override
  String get login_forgot_password => 'Mot de passe oublié ?';

  @override
  String get login_connect => 'Se connecter';

  @override
  String get login_change_user => 'Changer d\'utilisateur';

  @override
  String get login_error_invalid => 'Email ou mot de passe incorrect.';

  @override
  String get login_error_unconfirmed =>
      'Email non confirmé. Vérifiez votre boîte mail.';

  @override
  String get login_error_rate_limit =>
      'Trop de tentatives. Attendez quelques minutes.';

  @override
  String get login_reset_sent => 'Email de réinitialisation envoyé';

  @override
  String get nav_caisse => 'Caisse';

  @override
  String get nav_products => 'Produits';

  @override
  String get nav_inventory => 'Inventaire';

  @override
  String get nav_sales => 'Ventes';

  @override
  String get nav_customers => 'Clients';

  @override
  String get nav_reports => 'Rapports';

  @override
  String get nav_settings => 'Paramètres';

  @override
  String get nav_dashboard => 'Dashboard';

  @override
  String get cashier_title => 'Caisse';

  @override
  String get cashier_empty_cart => 'Votre panier est vide';

  @override
  String get cashier_start_hint => 'Sélectionnez des articles pour commencer.';

  @override
  String get cashier_search_hint => 'Chercher un article ou scanner...';

  @override
  String get cashier_no_results =>
      'Aucun article ne correspond à votre recherche.';

  @override
  String get cashier_no_products => 'Aucun produit';

  @override
  String get cashier_validate_sale => 'Valider la vente';

  @override
  String get cashier_verify_price => 'Vérifier prix/stock';

  @override
  String get cashier_flashlight => 'Lampe torche';

  @override
  String get cashier_out_of_stock => 'ÉPUISÉ';

  @override
  String get cashier_no_category => 'Sans catégorie';

  @override
  String get cashier_apply_coupon => 'Appliquer un coupon';

  @override
  String get cashier_discount_pct => 'Pourcentage (%)';

  @override
  String get cashier_discount_fixed => 'Montant Fixe';

  @override
  String get cashier_credit_required => 'Requis pour les ventes à crédit';

  @override
  String get cashier_printer_disconnected =>
      'Imprimante déconnectée ou non configurée';

  @override
  String get cashier_whatsapp_quick => 'WhatsApp Rapide (Texte)';

  @override
  String get cashier_whatsapp_pdf => 'Partager le reçu PDF complet';

  @override
  String cashier_send_to(String phone) {
    return 'Envoi direct au $phone';
  }

  @override
  String get cashier_send_whatsapp => 'ENVOYER PAR WHATSAPP / SMS';

  @override
  String get cashier_ignore => 'IGNORER';

  @override
  String get cashier_options => 'Options';

  @override
  String get cashier_remain_to_pay => 'Reste à payer';

  @override
  String get payment_title => 'Paiement';

  @override
  String get payment_total => 'Total à payer';

  @override
  String get payment_method => 'Méthode de paiement';

  @override
  String get payment_cash => 'Espèces';

  @override
  String get payment_wave => 'Wave';

  @override
  String get payment_orange_money => 'Orange Money';

  @override
  String get payment_card => 'Carte bancaire';

  @override
  String get payment_credit => 'À crédit';

  @override
  String get payment_mobile_money => 'Mobile Money';

  @override
  String get payment_amount_given => 'Montant remis';

  @override
  String get payment_change => 'Monnaie à rendre';

  @override
  String get payment_confirm => 'Confirmer le paiement';

  @override
  String get payment_success => 'Paiement enregistré avec succès.';

  @override
  String get payment_invalid_amount => 'Montant invalide';

  @override
  String get payment_amount_exceeded =>
      'Le montant ne peut pas dépasser le solde dû';

  @override
  String get payment_amount_paid => 'Montant payé';

  @override
  String get payment_record => 'Enregistrer un paiement';

  @override
  String get products_title => 'Catalogue produits';

  @override
  String get products_new => 'Nouveau produit';

  @override
  String get products_import_csv => 'Importer des produits (CSV)';

  @override
  String get products_print_labels => 'Imprimer des étiquettes';

  @override
  String get products_scan_barcode => 'Scanner un code-barres';

  @override
  String get products_restock => 'Réapprovisionner';

  @override
  String products_stock(String name) {
    return 'Stock — $name';
  }

  @override
  String get products_delete_confirm => 'Supprimer le produit';

  @override
  String get products_delete_photo => 'Supprimer la photo';

  @override
  String get products_camera => 'Appareil photo';

  @override
  String get products_gallery => 'Galerie';

  @override
  String get products_logo => 'Logo';

  @override
  String get products_saving => 'Enregistrement...';

  @override
  String get form_name => 'Nom';

  @override
  String get form_price => 'Prix';

  @override
  String get form_price_ht => 'Prix HT';

  @override
  String get form_price_ttc => 'Prix TTC';

  @override
  String get form_cost_price => 'Prix d\'achat';

  @override
  String get form_stock => 'Stock';

  @override
  String get form_stock_alert => 'Seuil d\'alerte';

  @override
  String get form_category => 'Catégorie';

  @override
  String get form_barcode => 'Code-barres';

  @override
  String get form_description => 'Description';

  @override
  String get form_tax_rate => 'Taux TVA';

  @override
  String get form_unit => 'Unité';

  @override
  String get form_expiry => 'Date d\'expiration';

  @override
  String get form_supplier => 'Fournisseur';

  @override
  String get form_email => 'Adresse email';

  @override
  String get form_phone => 'Téléphone';

  @override
  String get form_address => 'Adresse';

  @override
  String get form_city => 'Ville';

  @override
  String get form_country => 'Pays';

  @override
  String get form_notes => 'Notes';

  @override
  String get form_required_name => 'Le nom est requis';

  @override
  String get form_required_price => 'Le prix est requis';

  @override
  String get form_invalid_price => 'Prix invalide';

  @override
  String get form_invalid_email => 'Email invalide';

  @override
  String get sales_title => 'Historique des ventes';

  @override
  String get sales_empty => 'Aucune vente sur cette période';

  @override
  String get sales_filter_status => 'Filtrer par statut de paiement';

  @override
  String get sales_status_all => 'Toutes';

  @override
  String get sales_status_paid => 'Entièrement payées';

  @override
  String get sales_status_credit => 'Dues (à crédit)';

  @override
  String get sales_status_partial => 'Partiellement payées';

  @override
  String get sales_status_cancelled => 'Annulées';

  @override
  String get sales_status_completed => 'Encaissée';

  @override
  String get sales_status_due => 'Due';

  @override
  String get inventory_title => 'Inventaire';

  @override
  String get inventory_new_session => 'Nouvelle session';

  @override
  String get inventory_in_progress => 'En cours';

  @override
  String get inventory_completed => 'Terminée';

  @override
  String inventory_discrepancy(int count) {
    return '$count écart(s)';
  }

  @override
  String get customers_title => 'Clients';

  @override
  String get customers_new => 'Nouveau client';

  @override
  String get customers_debt => 'Crédit en cours';

  @override
  String get customers_no_debt => 'Aucune dette';

  @override
  String customers_loyalty_points(int points) {
    return '$points points';
  }

  @override
  String get reports_title => 'Rapports';

  @override
  String get reports_daily => 'Journalier';

  @override
  String get reports_weekly => 'Hebdomadaire';

  @override
  String get reports_monthly => 'Mensuel';

  @override
  String get reports_revenue => 'Chiffre d\'affaires';

  @override
  String get reports_sales_count => 'Nombre de ventes';

  @override
  String get reports_avg_basket => 'Panier moyen';

  @override
  String get reports_top_products => 'Meilleurs produits';

  @override
  String get reports_tax_summary => 'Récapitulatif TVA';

  @override
  String get reports_export_csv => 'Exporter en CSV';

  @override
  String get reports_export_pdf => 'Exporter en PDF';

  @override
  String get reports_period => 'Période';

  @override
  String get reports_from => 'Du';

  @override
  String get reports_to => 'Au';

  @override
  String get cash_drawer_title => 'Caisse';

  @override
  String get cash_drawer_open => 'Ouvrir la caisse';

  @override
  String get cash_drawer_close => 'Fermer la caisse';

  @override
  String get cash_drawer_starting_amount => 'Fond de caisse initial';

  @override
  String get cash_drawer_closing_amount => 'Fond de clôture';

  @override
  String get cash_drawer_session_total => 'TOTAL SESSION';

  @override
  String cash_drawer_hello(String name) {
    return 'Bonjour, $name';
  }

  @override
  String get cash_drawer_start_day =>
      'Veuillez saisir le fond de caisse pour démarrer la journée.';

  @override
  String get settings_title => 'PARAMÈTRES';

  @override
  String get settings_shop_name => 'Nom du magasin';

  @override
  String get settings_shop_address => 'Adresse';

  @override
  String get settings_shop_phone => 'Téléphone';

  @override
  String get settings_terminal_name => 'Nom du terminal';

  @override
  String get settings_receipt_footer => 'Pied de reçu';

  @override
  String get settings_receipt_footer_default => 'Merci de votre visite !';

  @override
  String get settings_printer => 'Imprimante';

  @override
  String get settings_printer_connect => 'Connecter une imprimante';

  @override
  String get settings_printer_usb => 'Imprimante USB thermique';

  @override
  String get settings_printer_system => 'Imprimante système (PDF)';

  @override
  String get settings_printer_new => 'Appairer un nouvel appareil';

  @override
  String get settings_printer_unknown => 'Appareil inconnu';

  @override
  String get settings_printer_no_usb => 'Aucune imprimante USB détectée.';

  @override
  String get settings_printer_none =>
      'Aucune imprimante installée sur ce système.';

  @override
  String get settings_choose_printer => 'Choisir une imprimante';

  @override
  String get settings_choose_printer_usb => 'Choisir une imprimante USB';

  @override
  String get settings_bluetooth_permissions => 'Permissions Bluetooth';

  @override
  String get settings_pin_new => 'Nouveau code PIN';

  @override
  String get settings_password_new => 'Nouveau mot de passe';

  @override
  String get settings_password_changed => 'Mot de passe modifié';

  @override
  String get settings_admin_only => 'Accès réservé aux administrateurs';

  @override
  String get settings_new_store => 'Nouveau magasin';

  @override
  String get settings_add_store => 'Ajouter un nouveau magasin';

  @override
  String get settings_create_switch => 'Créer et basculer';

  @override
  String get settings_export_anyway => 'Exporter quand même';

  @override
  String get settings_security_breach => 'Faille de sécurité critique';

  @override
  String get settings_critical_action => 'Action critique';

  @override
  String get settings_decrypt => 'Déchiffrer';

  @override
  String get settings_restore => 'Restaurer';

  @override
  String get settings_restore_success => 'Restauration réussie';

  @override
  String get settings_restore_secure => 'Restauration sécurisée';

  @override
  String get settings_cleanup => 'Nettoyage des justificatifs';

  @override
  String get settings_clean => 'Nettoyer';

  @override
  String get settings_understood => 'Compris';

  @override
  String get settings_preparing_catalog => 'Préparation du catalogue...';

  @override
  String get settings_saved => 'Enregistré !';

  @override
  String get settings_currency => 'Devise';

  @override
  String get settings_language => 'Langue';

  @override
  String get settings_country => 'Pays';

  @override
  String get settings_tax_rate_default => 'Taux TVA par défaut';

  @override
  String get settings_theme => 'Thème';

  @override
  String get sync_idle => 'Hors ligne';

  @override
  String get sync_syncing => 'Synchronisation en cours...';

  @override
  String get sync_up_to_date => 'Données synchronisées';

  @override
  String get sync_error => 'Erreur de synchronisation';

  @override
  String get sync_partial => 'Sync partielle — réessai en cours';

  @override
  String get sync_in_progress => 'Sync en cours...';

  @override
  String get sync_done => 'Synchronisé';

  @override
  String stock_low(int count) {
    return '$count produit(s) en stock faible';
  }

  @override
  String get currency_fcfa => 'FCFA';

  @override
  String get currency_gnf => 'GNF';

  @override
  String get currency_xof => 'XOF';

  @override
  String get country_senegal => 'Sénégal';

  @override
  String get country_mali => 'Mali';

  @override
  String get country_cote_divoire => 'Côte d\'Ivoire';

  @override
  String get country_guinee => 'Guinée';

  @override
  String get country_benin => 'Bénin';

  @override
  String get country_burkina => 'Burkina Faso';

  @override
  String get country_togo => 'Togo';

  @override
  String get country_niger => 'Niger';

  @override
  String get error_network => 'Pas de connexion internet';

  @override
  String get error_session_expired => 'Session expirée — reconnectez-vous';

  @override
  String get error_generic => 'Une erreur est survenue. Veuillez réessayer.';

  @override
  String error_capture(String error) {
    return 'Erreur lors de la capture : $error';
  }

  @override
  String get error_print_failed => 'L\'impression a échoué';

  @override
  String get date_today => 'Aujourd\'hui';

  @override
  String get date_yesterday => 'Hier';

  @override
  String get date_this_week => 'Cette semaine';

  @override
  String get date_this_month => 'Ce mois';

  @override
  String get date_last_7_days => '7 derniers jours';

  @override
  String get date_last_30_days => '30 derniers jours';

  @override
  String get dashboard_title => 'Vue d\'ensemble';

  @override
  String get dashboard_all_stores => 'Tous magasins';

  @override
  String get dashboard_best_store => 'Meilleur magasin';

  @override
  String get dashboard_total_revenue => 'CA total';

  @override
  String get dashboard_total_sales => 'Ventes';

  @override
  String get dashboard_active_stores => 'Magasins actifs';

  @override
  String get dashboard_stock_alerts => 'Alertes stock';

  @override
  String get dashboard_period_today => 'Aujourd\'hui';

  @override
  String get dashboard_period_week => '7 jours';

  @override
  String get dashboard_period_month => '30 jours';

  @override
  String get dashboard_no_stores => 'Aucun magasin enregistré';

  @override
  String get dashboard_no_stores_hint =>
      'Ouvrez l\'application POS sur chaque appareil pour enregistrer automatiquement les magasins.';

  @override
  String dashboard_last_updated(String time) {
    return 'Màj $time';
  }

  @override
  String get dashboard_sign_out => 'Se déconnecter';

  @override
  String get dashboard_sign_out_confirm =>
      'Vous serez redirigé vers l\'écran de connexion.';

  @override
  String get dashboard_disconnect => 'Déconnecter';

  @override
  String get category_food => 'Alimentation';

  @override
  String get category_beverages => 'Boissons';

  @override
  String get category_hygiene => 'Hygiène';

  @override
  String get category_electronics => 'Électronique';

  @override
  String get category_clothing => 'Vêtements';

  @override
  String get category_home => 'Maison';

  @override
  String get category_beauty => 'Beauté';

  @override
  String get category_books => 'Livres';

  @override
  String get category_sports => 'Sports';

  @override
  String get category_toys => 'Jouets';

  @override
  String get category_automotive => 'Automobile';

  @override
  String get category_garden => 'Jardin';

  @override
  String get category_other => 'Autre';

  @override
  String get category_none => 'Sans catégorie';
}
