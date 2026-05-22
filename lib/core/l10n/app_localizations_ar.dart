// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'GPOS';

  @override
  String get appSubtitle => 'نظام نقطة البيع';

  @override
  String version(String version) {
    return 'الإصدار $version';
  }

  @override
  String get ok => 'موافق';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get delete => 'حذف';

  @override
  String get edit => 'تعديل';

  @override
  String get add => 'إضافة';

  @override
  String get close => 'إغلاق';

  @override
  String get confirm => 'تأكيد';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get search => 'بحث';

  @override
  String get filter => 'تصفية';

  @override
  String get all => 'الكل';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get error => 'خطأ';

  @override
  String get success => 'نجاح';

  @override
  String get warning => 'تحذير';

  @override
  String get next => 'التالي';

  @override
  String get back => 'رجوع';

  @override
  String get finish => 'إنهاء';

  @override
  String get apply => 'تطبيق';

  @override
  String get validate => 'تحقق';

  @override
  String get continue_action => 'متابعة';

  @override
  String get quit => 'خروج';

  @override
  String get new_item => 'جديد';

  @override
  String get refresh => 'تحديث';

  @override
  String get export => 'تصدير';

  @override
  String get import => 'استيراد';

  @override
  String get print => 'طباعة';

  @override
  String get share => 'مشاركة';

  @override
  String get send => 'إرسال';

  @override
  String get download => 'تنزيل';

  @override
  String get start => 'بدء';

  @override
  String get stop => 'إيقاف';

  @override
  String get reset => 'إعادة تعيين';

  @override
  String get unknown => 'غير معروف';

  @override
  String get optional => 'اختياري';

  @override
  String get required_field => 'مطلوب';

  @override
  String get settings => 'الإعدادات';

  @override
  String get help => 'مساعدة';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get login_title => 'الدخول إلى النظام';

  @override
  String get login_cloud => 'الوصول إلى السحابة';

  @override
  String get login_staff_mode => 'وضع الموظفين';

  @override
  String get login_cloud_mode => 'وضع السحابة';

  @override
  String get login_my_shop => 'متجري';

  @override
  String get login_role_cashier => 'أمين الصندوق';

  @override
  String get login_role_manager => 'المدير';

  @override
  String get login_role_owner => 'المالك';

  @override
  String get login_email => 'البريد الإلكتروني';

  @override
  String get login_password => 'كلمة المرور';

  @override
  String get login_pin => 'رمز PIN';

  @override
  String get login_enter_pin => 'أدخل رمز PIN';

  @override
  String login_hello(String name) {
    return 'مرحباً، $name';
  }

  @override
  String get login_no_users => 'لا يوجد مستخدمون مسجلون لهذا الدور';

  @override
  String get login_forgot_password => 'نسيت كلمة المرور؟';

  @override
  String get login_connect => 'تسجيل الدخول';

  @override
  String get login_change_user => 'تغيير المستخدم';

  @override
  String get login_error_invalid =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  @override
  String get login_error_unconfirmed =>
      'البريد الإلكتروني غير مؤكد. تحقق من بريدك.';

  @override
  String get login_error_rate_limit => 'محاولات كثيرة. انتظر بضع دقائق.';

  @override
  String get login_reset_sent => 'تم إرسال رابط إعادة تعيين كلمة المرور';

  @override
  String get nav_caisse => 'الصندوق';

  @override
  String get nav_products => 'المنتجات';

  @override
  String get nav_inventory => 'الجرد';

  @override
  String get nav_sales => 'المبيعات';

  @override
  String get nav_customers => 'العملاء';

  @override
  String get nav_reports => 'التقارير';

  @override
  String get nav_settings => 'الإعدادات';

  @override
  String get nav_dashboard => 'لوحة التحكم';

  @override
  String get cashier_title => 'الصندوق';

  @override
  String get cashier_empty_cart => 'سلة التسوق فارغة';

  @override
  String get cashier_start_hint => 'حدد المنتجات للبدء.';

  @override
  String get cashier_search_hint => 'ابحث عن منتج أو امسح الباركود...';

  @override
  String get cashier_no_results => 'لا توجد منتجات تطابق بحثك.';

  @override
  String get cashier_no_products => 'لا توجد منتجات';

  @override
  String get cashier_validate_sale => 'تأكيد البيع';

  @override
  String get cashier_verify_price => 'التحقق من السعر/المخزون';

  @override
  String get cashier_flashlight => 'المصباح';

  @override
  String get cashier_out_of_stock => 'نفد المخزون';

  @override
  String get cashier_no_category => 'بدون فئة';

  @override
  String get cashier_apply_coupon => 'تطبيق كوبون';

  @override
  String get cashier_discount_pct => 'نسبة مئوية (%)';

  @override
  String get cashier_discount_fixed => 'مبلغ ثابت';

  @override
  String get cashier_credit_required => 'مطلوب للمبيعات الآجلة';

  @override
  String get cashier_printer_disconnected => 'الطابعة غير متصلة أو غير مهيأة';

  @override
  String get cashier_whatsapp_quick => 'واتساب سريع (نص)';

  @override
  String get cashier_whatsapp_pdf => 'مشاركة الإيصال PDF';

  @override
  String cashier_send_to(String phone) {
    return 'إرسال مباشر إلى $phone';
  }

  @override
  String get cashier_send_whatsapp => 'إرسال عبر واتساب / SMS';

  @override
  String get cashier_ignore => 'تجاهل';

  @override
  String get cashier_options => 'خيارات';

  @override
  String get cashier_remain_to_pay => 'المبلغ المتبقي';

  @override
  String get payment_title => 'الدفع';

  @override
  String get payment_total => 'المبلغ الإجمالي';

  @override
  String get payment_method => 'طريقة الدفع';

  @override
  String get payment_cash => 'نقداً';

  @override
  String get payment_wave => 'Wave';

  @override
  String get payment_orange_money => 'Orange Money';

  @override
  String get payment_card => 'بطاقة بنكية';

  @override
  String get payment_credit => 'آجل';

  @override
  String get payment_mobile_money => 'موبايل موني';

  @override
  String get payment_amount_given => 'المبلغ المدفوع';

  @override
  String get payment_change => 'الباقي';

  @override
  String get payment_confirm => 'تأكيد الدفع';

  @override
  String get payment_success => 'تم تسجيل الدفع بنجاح.';

  @override
  String get payment_invalid_amount => 'مبلغ غير صالح';

  @override
  String get payment_amount_exceeded =>
      'لا يمكن أن يتجاوز المبلغ الرصيد المستحق';

  @override
  String get payment_amount_paid => 'المبلغ المدفوع';

  @override
  String get payment_record => 'تسجيل دفعة';

  @override
  String get products_title => 'كتالوج المنتجات';

  @override
  String get products_new => 'منتج جديد';

  @override
  String get products_import_csv => 'استيراد المنتجات (CSV)';

  @override
  String get products_print_labels => 'طباعة الملصقات';

  @override
  String get products_scan_barcode => 'مسح الباركود';

  @override
  String get products_restock => 'إعادة التخزين';

  @override
  String products_stock(String name) {
    return 'المخزون — $name';
  }

  @override
  String get products_delete_confirm => 'حذف المنتج';

  @override
  String get products_delete_photo => 'حذف الصورة';

  @override
  String get products_camera => 'الكاميرا';

  @override
  String get products_gallery => 'المعرض';

  @override
  String get products_logo => 'الشعار';

  @override
  String get products_saving => 'جاري الحفظ...';

  @override
  String get form_name => 'الاسم';

  @override
  String get form_price => 'السعر';

  @override
  String get form_price_ht => 'السعر بدون ضريبة';

  @override
  String get form_price_ttc => 'السعر شامل الضريبة';

  @override
  String get form_cost_price => 'سعر الشراء';

  @override
  String get form_stock => 'المخزون';

  @override
  String get form_stock_alert => 'حد التنبيه';

  @override
  String get form_category => 'الفئة';

  @override
  String get form_barcode => 'الباركود';

  @override
  String get form_description => 'الوصف';

  @override
  String get form_tax_rate => 'نسبة الضريبة';

  @override
  String get form_unit => 'الوحدة';

  @override
  String get form_expiry => 'تاريخ الانتهاء';

  @override
  String get form_supplier => 'المورد';

  @override
  String get form_email => 'البريد الإلكتروني';

  @override
  String get form_phone => 'الهاتف';

  @override
  String get form_address => 'العنوان';

  @override
  String get form_city => 'المدينة';

  @override
  String get form_country => 'البلد';

  @override
  String get form_notes => 'ملاحظات';

  @override
  String get form_required_name => 'الاسم مطلوب';

  @override
  String get form_required_price => 'السعر مطلوب';

  @override
  String get form_invalid_price => 'سعر غير صالح';

  @override
  String get form_invalid_email => 'بريد إلكتروني غير صالح';

  @override
  String get sales_title => 'سجل المبيعات';

  @override
  String get sales_empty => 'لا توجد مبيعات لهذه الفترة';

  @override
  String get sales_filter_status => 'تصفية حسب حالة الدفع';

  @override
  String get sales_status_all => 'الكل';

  @override
  String get sales_status_paid => 'مدفوعة بالكامل';

  @override
  String get sales_status_credit => 'آجلة';

  @override
  String get sales_status_partial => 'مدفوعة جزئياً';

  @override
  String get sales_status_cancelled => 'ملغاة';

  @override
  String get sales_status_completed => 'مُحصَّلة';

  @override
  String get sales_status_due => 'مستحقة';

  @override
  String get inventory_title => 'الجرد';

  @override
  String get inventory_new_session => 'جلسة جديدة';

  @override
  String get inventory_in_progress => 'قيد التنفيذ';

  @override
  String get inventory_completed => 'مكتملة';

  @override
  String inventory_discrepancy(int count) {
    return '$count فرق(وق)';
  }

  @override
  String get customers_title => 'العملاء';

  @override
  String get customers_new => 'عميل جديد';

  @override
  String get customers_debt => 'رصيد مستحق';

  @override
  String get customers_no_debt => 'لا ديون';

  @override
  String customers_loyalty_points(int points) {
    return '$points نقطة';
  }

  @override
  String get reports_title => 'التقارير';

  @override
  String get reports_daily => 'يومي';

  @override
  String get reports_weekly => 'أسبوعي';

  @override
  String get reports_monthly => 'شهري';

  @override
  String get reports_revenue => 'رقم الأعمال';

  @override
  String get reports_sales_count => 'عدد المبيعات';

  @override
  String get reports_avg_basket => 'متوسط الفاتورة';

  @override
  String get reports_top_products => 'أفضل المنتجات';

  @override
  String get reports_tax_summary => 'ملخص الضرائب';

  @override
  String get reports_export_csv => 'تصدير CSV';

  @override
  String get reports_export_pdf => 'تصدير PDF';

  @override
  String get reports_period => 'الفترة';

  @override
  String get reports_from => 'من';

  @override
  String get reports_to => 'إلى';

  @override
  String get cash_drawer_title => 'الصندوق';

  @override
  String get cash_drawer_open => 'فتح الصندوق';

  @override
  String get cash_drawer_close => 'إغلاق الصندوق';

  @override
  String get cash_drawer_starting_amount => 'رأس المال الابتدائي';

  @override
  String get cash_drawer_closing_amount => 'مبلغ الإغلاق';

  @override
  String get cash_drawer_session_total => 'إجمالي الجلسة';

  @override
  String cash_drawer_hello(String name) {
    return 'مرحباً، $name';
  }

  @override
  String get cash_drawer_start_day => 'يرجى إدخال رأس المال لبدء اليوم.';

  @override
  String get settings_title => 'الإعدادات';

  @override
  String get settings_shop_name => 'اسم المتجر';

  @override
  String get settings_shop_address => 'العنوان';

  @override
  String get settings_shop_phone => 'الهاتف';

  @override
  String get settings_terminal_name => 'اسم الجهاز';

  @override
  String get settings_receipt_footer => 'تذييل الإيصال';

  @override
  String get settings_receipt_footer_default => 'شكراً لزيارتكم!';

  @override
  String get settings_printer => 'الطابعة';

  @override
  String get settings_printer_connect => 'توصيل طابعة';

  @override
  String get settings_printer_usb => 'طابعة USB حرارية';

  @override
  String get settings_printer_system => 'طابعة النظام (PDF)';

  @override
  String get settings_printer_new => 'إقران جهاز جديد';

  @override
  String get settings_printer_unknown => 'جهاز غير معروف';

  @override
  String get settings_printer_no_usb => 'لم يتم اكتشاف طابعة USB.';

  @override
  String get settings_printer_none => 'لا توجد طابعة مثبتة.';

  @override
  String get settings_choose_printer => 'اختر طابعة';

  @override
  String get settings_choose_printer_usb => 'اختر طابعة USB';

  @override
  String get settings_bluetooth_permissions => 'أذونات البلوتوث';

  @override
  String get settings_pin_new => 'رمز PIN جديد';

  @override
  String get settings_password_new => 'كلمة مرور جديدة';

  @override
  String get settings_password_changed => 'تم تغيير كلمة المرور';

  @override
  String get settings_admin_only => 'للمسؤولين فقط';

  @override
  String get settings_new_store => 'متجر جديد';

  @override
  String get settings_add_store => 'إضافة متجر جديد';

  @override
  String get settings_create_switch => 'إنشاء والتبديل';

  @override
  String get settings_export_anyway => 'تصدير على أي حال';

  @override
  String get settings_security_breach => 'خرق أمني حرج';

  @override
  String get settings_critical_action => 'إجراء حرج';

  @override
  String get settings_decrypt => 'فك التشفير';

  @override
  String get settings_restore => 'استعادة';

  @override
  String get settings_restore_success => 'تمت الاستعادة بنجاح';

  @override
  String get settings_restore_secure => 'استعادة آمنة';

  @override
  String get settings_cleanup => 'تنظيف البيانات';

  @override
  String get settings_clean => 'تنظيف';

  @override
  String get settings_understood => 'فهمت';

  @override
  String get settings_preparing_catalog => 'جاري تحضير الكتالوج...';

  @override
  String get settings_saved => 'تم الحفظ!';

  @override
  String get settings_currency => 'العملة';

  @override
  String get settings_language => 'اللغة';

  @override
  String get settings_country => 'البلد';

  @override
  String get settings_tax_rate_default => 'نسبة الضريبة الافتراضية';

  @override
  String get settings_theme => 'المظهر';

  @override
  String get sync_idle => 'غير متصل';

  @override
  String get sync_syncing => 'جاري المزامنة...';

  @override
  String get sync_up_to_date => 'البيانات محدّثة';

  @override
  String get sync_error => 'خطأ في المزامنة';

  @override
  String get sync_partial => 'مزامنة جزئية — إعادة المحاولة';

  @override
  String get sync_in_progress => 'مزامنة...';

  @override
  String get sync_done => 'تمت المزامنة';

  @override
  String stock_low(int count) {
    return '$count منتج(ات) منخفض المخزون';
  }

  @override
  String get currency_fcfa => 'فرنك CFA';

  @override
  String get currency_gnf => 'فرنك غيني';

  @override
  String get currency_xof => 'XOF';

  @override
  String get country_senegal => 'السنغال';

  @override
  String get country_mali => 'مالي';

  @override
  String get country_cote_divoire => 'ساحل العاج';

  @override
  String get country_guinee => 'غينيا';

  @override
  String get country_benin => 'بنين';

  @override
  String get country_burkina => 'بوركينا فاسو';

  @override
  String get country_togo => 'توغو';

  @override
  String get country_niger => 'النيجر';

  @override
  String get error_network => 'لا يوجد اتصال بالإنترنت';

  @override
  String get error_session_expired => 'انتهت الجلسة — يرجى تسجيل الدخول مجدداً';

  @override
  String get error_generic => 'حدث خطأ. يرجى المحاولة مجدداً.';

  @override
  String error_capture(String error) {
    return 'خطأ في الالتقاط: $error';
  }

  @override
  String get error_print_failed => 'فشلت الطباعة';

  @override
  String get date_today => 'اليوم';

  @override
  String get date_yesterday => 'أمس';

  @override
  String get date_this_week => 'هذا الأسبوع';

  @override
  String get date_this_month => 'هذا الشهر';

  @override
  String get date_last_7_days => 'آخر 7 أيام';

  @override
  String get date_last_30_days => 'آخر 30 يوماً';

  @override
  String get dashboard_title => 'نظرة عامة';

  @override
  String get dashboard_all_stores => 'جميع المتاجر';

  @override
  String get dashboard_best_store => 'أفضل متجر';

  @override
  String get dashboard_total_revenue => 'إجمالي المبيعات';

  @override
  String get dashboard_total_sales => 'المبيعات';

  @override
  String get dashboard_active_stores => 'المتاجر النشطة';

  @override
  String get dashboard_stock_alerts => 'تنبيهات المخزون';

  @override
  String get dashboard_period_today => 'اليوم';

  @override
  String get dashboard_period_week => '7 أيام';

  @override
  String get dashboard_period_month => '30 يوماً';

  @override
  String get dashboard_no_stores => 'لا توجد متاجر مسجلة';

  @override
  String get dashboard_no_stores_hint =>
      'افتح تطبيق GPOS على كل جهاز لتسجيل المتاجر تلقائياً.';

  @override
  String dashboard_last_updated(String time) {
    return 'تحديث $time';
  }

  @override
  String get dashboard_sign_out => 'تسجيل الخروج';

  @override
  String get dashboard_sign_out_confirm => 'سيتم توجيهك إلى شاشة تسجيل الدخول.';

  @override
  String get dashboard_disconnect => 'خروج';

  @override
  String get category_food => 'مواد غذائية';

  @override
  String get category_beverages => 'مشروبات';

  @override
  String get category_hygiene => 'نظافة';

  @override
  String get category_electronics => 'إلكترونيات';

  @override
  String get category_clothing => 'ملابس';

  @override
  String get category_home => 'منزل';

  @override
  String get category_beauty => 'جمال';

  @override
  String get category_books => 'كتب';

  @override
  String get category_sports => 'رياضة';

  @override
  String get category_toys => 'ألعاب';

  @override
  String get category_automotive => 'سيارات';

  @override
  String get category_garden => 'حديقة';

  @override
  String get category_other => 'أخرى';

  @override
  String get category_none => 'بدون فئة';
}
