// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'GPOS';

  @override
  String get appSubtitle => 'Point of Sale System';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get close => 'Close';

  @override
  String get confirm => 'Confirm';

  @override
  String get retry => 'Retry';

  @override
  String get search => 'Search';

  @override
  String get filter => 'Filter';

  @override
  String get all => 'All';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get warning => 'Warning';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get finish => 'Finish';

  @override
  String get apply => 'Apply';

  @override
  String get validate => 'Validate';

  @override
  String get continue_action => 'Continue';

  @override
  String get quit => 'Quit';

  @override
  String get new_item => 'New';

  @override
  String get refresh => 'Refresh';

  @override
  String get export => 'Export';

  @override
  String get import => 'Import';

  @override
  String get print => 'Print';

  @override
  String get share => 'Share';

  @override
  String get send => 'Send';

  @override
  String get download => 'Download';

  @override
  String get start => 'Start';

  @override
  String get stop => 'Stop';

  @override
  String get reset => 'Reset';

  @override
  String get unknown => 'Unknown';

  @override
  String get optional => 'Optional';

  @override
  String get required_field => 'Required';

  @override
  String get settings => 'Settings';

  @override
  String get help => 'Help';

  @override
  String get logout => 'Logout';

  @override
  String get login_title => 'SYSTEM ACCESS';

  @override
  String get login_cloud => 'ACCESS CLOUD';

  @override
  String get login_staff_mode => 'STAFF MODE';

  @override
  String get login_cloud_mode => 'CLOUD MODE';

  @override
  String get login_my_shop => 'MY STORE';

  @override
  String get login_role_cashier => 'Cashier';

  @override
  String get login_role_manager => 'Manager';

  @override
  String get login_role_owner => 'Owner';

  @override
  String get login_email => 'Email';

  @override
  String get login_password => 'Password';

  @override
  String get login_pin => 'PIN Code';

  @override
  String get login_enter_pin => 'Enter your PIN code';

  @override
  String login_hello(String name) {
    return 'Hello, $name';
  }

  @override
  String get login_no_users => 'No users registered for this role';

  @override
  String get login_forgot_password => 'Forgot password?';

  @override
  String get login_connect => 'Sign in';

  @override
  String get login_change_user => 'Change user';

  @override
  String get login_error_invalid => 'Invalid email or password.';

  @override
  String get login_error_unconfirmed =>
      'Email not confirmed. Check your inbox.';

  @override
  String get login_error_rate_limit => 'Too many attempts. Wait a few minutes.';

  @override
  String get login_reset_sent => 'Password reset email sent';

  @override
  String get nav_caisse => 'Checkout';

  @override
  String get nav_products => 'Products';

  @override
  String get nav_inventory => 'Inventory';

  @override
  String get nav_sales => 'Sales';

  @override
  String get nav_customers => 'Customers';

  @override
  String get nav_reports => 'Reports';

  @override
  String get nav_settings => 'Settings';

  @override
  String get nav_dashboard => 'Dashboard';

  @override
  String get cashier_title => 'Checkout';

  @override
  String get cashier_empty_cart => 'Your cart is empty';

  @override
  String get cashier_start_hint => 'Select items to get started.';

  @override
  String get cashier_search_hint => 'Search an item or scan...';

  @override
  String get cashier_no_results => 'No items match your search.';

  @override
  String get cashier_no_products => 'No products';

  @override
  String get cashier_validate_sale => 'Validate sale';

  @override
  String get cashier_verify_price => 'Verify price/stock';

  @override
  String get cashier_flashlight => 'Flashlight';

  @override
  String get cashier_out_of_stock => 'OUT OF STOCK';

  @override
  String get cashier_no_category => 'No category';

  @override
  String get cashier_apply_coupon => 'Apply a coupon';

  @override
  String get cashier_discount_pct => 'Percentage (%)';

  @override
  String get cashier_discount_fixed => 'Fixed amount';

  @override
  String get cashier_credit_required => 'Required for credit sales';

  @override
  String get cashier_printer_disconnected =>
      'Printer disconnected or not configured';

  @override
  String get cashier_whatsapp_quick => 'Quick WhatsApp (Text)';

  @override
  String get cashier_whatsapp_pdf => 'Share full PDF receipt';

  @override
  String cashier_send_to(String phone) {
    return 'Send directly to $phone';
  }

  @override
  String get cashier_send_whatsapp => 'SEND VIA WHATSAPP / SMS';

  @override
  String get cashier_ignore => 'IGNORE';

  @override
  String get cashier_options => 'Options';

  @override
  String get cashier_remain_to_pay => 'Remaining balance';

  @override
  String get payment_title => 'Payment';

  @override
  String get payment_total => 'Total to pay';

  @override
  String get payment_method => 'Payment method';

  @override
  String get payment_cash => 'Cash';

  @override
  String get payment_wave => 'Wave';

  @override
  String get payment_orange_money => 'Orange Money';

  @override
  String get payment_card => 'Bank card';

  @override
  String get payment_credit => 'On credit';

  @override
  String get payment_mobile_money => 'Mobile Money';

  @override
  String get payment_amount_given => 'Amount given';

  @override
  String get payment_change => 'Change';

  @override
  String get payment_confirm => 'Confirm payment';

  @override
  String get payment_success => 'Payment recorded successfully.';

  @override
  String get payment_invalid_amount => 'Invalid amount';

  @override
  String get payment_amount_exceeded => 'Amount cannot exceed the balance due';

  @override
  String get payment_amount_paid => 'Amount paid';

  @override
  String get payment_record => 'Record a payment';

  @override
  String get products_title => 'Product catalog';

  @override
  String get products_new => 'New product';

  @override
  String get products_import_csv => 'Import products (CSV)';

  @override
  String get products_print_labels => 'Print labels';

  @override
  String get products_scan_barcode => 'Scan barcode';

  @override
  String get products_restock => 'Restock';

  @override
  String products_stock(String name) {
    return 'Stock — $name';
  }

  @override
  String get products_delete_confirm => 'Delete product';

  @override
  String get products_delete_photo => 'Delete photo';

  @override
  String get products_camera => 'Camera';

  @override
  String get products_gallery => 'Gallery';

  @override
  String get products_logo => 'Logo';

  @override
  String get products_saving => 'Saving...';

  @override
  String get form_name => 'Name';

  @override
  String get form_price => 'Price';

  @override
  String get form_price_ht => 'Price (ex. tax)';

  @override
  String get form_price_ttc => 'Price (incl. tax)';

  @override
  String get form_cost_price => 'Cost price';

  @override
  String get form_stock => 'Stock';

  @override
  String get form_stock_alert => 'Alert threshold';

  @override
  String get form_category => 'Category';

  @override
  String get form_barcode => 'Barcode';

  @override
  String get form_description => 'Description';

  @override
  String get form_tax_rate => 'Tax rate';

  @override
  String get form_unit => 'Unit';

  @override
  String get form_expiry => 'Expiry date';

  @override
  String get form_supplier => 'Supplier';

  @override
  String get form_email => 'Email address';

  @override
  String get form_phone => 'Phone';

  @override
  String get form_address => 'Address';

  @override
  String get form_city => 'City';

  @override
  String get form_country => 'Country';

  @override
  String get form_notes => 'Notes';

  @override
  String get form_required_name => 'Name is required';

  @override
  String get form_required_price => 'Price is required';

  @override
  String get form_invalid_price => 'Invalid price';

  @override
  String get form_invalid_email => 'Invalid email';

  @override
  String get sales_title => 'Sales history';

  @override
  String get sales_empty => 'No sales for this period';

  @override
  String get sales_filter_status => 'Filter by payment status';

  @override
  String get sales_status_all => 'All';

  @override
  String get sales_status_paid => 'Fully paid';

  @override
  String get sales_status_credit => 'On credit';

  @override
  String get sales_status_partial => 'Partially paid';

  @override
  String get sales_status_cancelled => 'Cancelled';

  @override
  String get sales_status_completed => 'Collected';

  @override
  String get sales_status_due => 'Due';

  @override
  String get inventory_title => 'Inventory';

  @override
  String get inventory_new_session => 'New session';

  @override
  String get inventory_in_progress => 'In progress';

  @override
  String get inventory_completed => 'Completed';

  @override
  String inventory_discrepancy(int count) {
    return '$count discrepancy(ies)';
  }

  @override
  String get customers_title => 'Customers';

  @override
  String get customers_new => 'New customer';

  @override
  String get customers_debt => 'Outstanding credit';

  @override
  String get customers_no_debt => 'No debt';

  @override
  String customers_loyalty_points(int points) {
    return '$points points';
  }

  @override
  String get reports_title => 'Reports';

  @override
  String get reports_daily => 'Daily';

  @override
  String get reports_weekly => 'Weekly';

  @override
  String get reports_monthly => 'Monthly';

  @override
  String get reports_revenue => 'Revenue';

  @override
  String get reports_sales_count => 'Number of sales';

  @override
  String get reports_avg_basket => 'Average basket';

  @override
  String get reports_top_products => 'Top products';

  @override
  String get reports_tax_summary => 'Tax summary';

  @override
  String get reports_export_csv => 'Export as CSV';

  @override
  String get reports_export_pdf => 'Export as PDF';

  @override
  String get reports_period => 'Period';

  @override
  String get reports_from => 'From';

  @override
  String get reports_to => 'To';

  @override
  String get cash_drawer_title => 'Cash Drawer';

  @override
  String get cash_drawer_open => 'Open register';

  @override
  String get cash_drawer_close => 'Close register';

  @override
  String get cash_drawer_starting_amount => 'Opening float';

  @override
  String get cash_drawer_closing_amount => 'Closing amount';

  @override
  String get cash_drawer_session_total => 'SESSION TOTAL';

  @override
  String cash_drawer_hello(String name) {
    return 'Hello, $name';
  }

  @override
  String get cash_drawer_start_day =>
      'Please enter the opening float to start the day.';

  @override
  String get settings_title => 'SETTINGS';

  @override
  String get settings_shop_name => 'Store name';

  @override
  String get settings_shop_address => 'Address';

  @override
  String get settings_shop_phone => 'Phone';

  @override
  String get settings_terminal_name => 'Terminal name';

  @override
  String get settings_receipt_footer => 'Receipt footer';

  @override
  String get settings_receipt_footer_default => 'Thank you for your visit!';

  @override
  String get settings_printer => 'Printer';

  @override
  String get settings_printer_connect => 'Connect a printer';

  @override
  String get settings_printer_usb => 'USB thermal printer';

  @override
  String get settings_printer_system => 'System printer (PDF)';

  @override
  String get settings_printer_new => 'Pair a new device';

  @override
  String get settings_printer_unknown => 'Unknown device';

  @override
  String get settings_printer_no_usb => 'No USB printer detected.';

  @override
  String get settings_printer_none => 'No printer installed on this system.';

  @override
  String get settings_choose_printer => 'Choose a printer';

  @override
  String get settings_choose_printer_usb => 'Choose a USB printer';

  @override
  String get settings_bluetooth_permissions => 'Bluetooth permissions';

  @override
  String get settings_pin_new => 'New PIN code';

  @override
  String get settings_password_new => 'New password';

  @override
  String get settings_password_changed => 'Password changed';

  @override
  String get settings_admin_only => 'Admin access only';

  @override
  String get settings_new_store => 'New store';

  @override
  String get settings_add_store => 'Add a new store';

  @override
  String get settings_create_switch => 'Create and switch';

  @override
  String get settings_export_anyway => 'Export anyway';

  @override
  String get settings_security_breach => 'Critical security breach';

  @override
  String get settings_critical_action => 'Critical action';

  @override
  String get settings_decrypt => 'Decrypt';

  @override
  String get settings_restore => 'Restore';

  @override
  String get settings_restore_success => 'Restoration successful';

  @override
  String get settings_restore_secure => 'Secure restoration';

  @override
  String get settings_cleanup => 'Credentials cleanup';

  @override
  String get settings_clean => 'Clean';

  @override
  String get settings_understood => 'Got it';

  @override
  String get settings_preparing_catalog => 'Preparing catalog...';

  @override
  String get settings_saved => 'Saved!';

  @override
  String get settings_currency => 'Currency';

  @override
  String get settings_language => 'Language';

  @override
  String get settings_country => 'Country';

  @override
  String get settings_tax_rate_default => 'Default tax rate';

  @override
  String get settings_theme => 'Theme';

  @override
  String get sync_idle => 'Offline';

  @override
  String get sync_syncing => 'Syncing...';

  @override
  String get sync_up_to_date => 'Data synchronized';

  @override
  String get sync_error => 'Sync error';

  @override
  String get sync_partial => 'Partial sync — retrying';

  @override
  String get sync_in_progress => 'Syncing...';

  @override
  String get sync_done => 'Synchronized';

  @override
  String stock_low(int count) {
    return '$count product(s) low in stock';
  }

  @override
  String get currency_fcfa => 'FCFA';

  @override
  String get currency_gnf => 'GNF';

  @override
  String get currency_xof => 'XOF';

  @override
  String get country_senegal => 'Senegal';

  @override
  String get country_mali => 'Mali';

  @override
  String get country_cote_divoire => 'Côte d\'Ivoire';

  @override
  String get country_guinee => 'Guinea';

  @override
  String get country_benin => 'Benin';

  @override
  String get country_burkina => 'Burkina Faso';

  @override
  String get country_togo => 'Togo';

  @override
  String get country_niger => 'Niger';

  @override
  String get error_network => 'No internet connection';

  @override
  String get error_session_expired => 'Session expired — please sign in again';

  @override
  String get error_generic => 'An error occurred. Please try again.';

  @override
  String error_capture(String error) {
    return 'Capture error: $error';
  }

  @override
  String get error_print_failed => 'Print failed';

  @override
  String get date_today => 'Today';

  @override
  String get date_yesterday => 'Yesterday';

  @override
  String get date_this_week => 'This week';

  @override
  String get date_this_month => 'This month';

  @override
  String get date_last_7_days => 'Last 7 days';

  @override
  String get date_last_30_days => 'Last 30 days';

  @override
  String get dashboard_title => 'Overview';

  @override
  String get dashboard_all_stores => 'All stores';

  @override
  String get dashboard_best_store => 'Best store';

  @override
  String get dashboard_total_revenue => 'Total revenue';

  @override
  String get dashboard_total_sales => 'Sales';

  @override
  String get dashboard_active_stores => 'Active stores';

  @override
  String get dashboard_stock_alerts => 'Stock alerts';

  @override
  String get dashboard_period_today => 'Today';

  @override
  String get dashboard_period_week => '7 days';

  @override
  String get dashboard_period_month => '30 days';

  @override
  String get dashboard_no_stores => 'No stores registered';

  @override
  String get dashboard_no_stores_hint =>
      'Open the POS app on each device to automatically register stores.';

  @override
  String dashboard_last_updated(String time) {
    return 'Upd. $time';
  }

  @override
  String get dashboard_sign_out => 'Sign out';

  @override
  String get dashboard_sign_out_confirm =>
      'You will be redirected to the login screen.';

  @override
  String get dashboard_disconnect => 'Sign out';

  @override
  String get category_food => 'Food';

  @override
  String get category_beverages => 'Beverages';

  @override
  String get category_hygiene => 'Hygiene';

  @override
  String get category_electronics => 'Electronics';

  @override
  String get category_clothing => 'Clothing';

  @override
  String get category_home => 'Home';

  @override
  String get category_beauty => 'Beauty';

  @override
  String get category_books => 'Books';

  @override
  String get category_sports => 'Sports';

  @override
  String get category_toys => 'Toys';

  @override
  String get category_automotive => 'Automotive';

  @override
  String get category_garden => 'Garden';

  @override
  String get category_other => 'Other';

  @override
  String get category_none => 'No category';
}
