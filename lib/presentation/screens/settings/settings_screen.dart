// lib/presentation/screens/settings/settings_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/utils/logger_service.dart';
import 'package:flutter/foundation.dart';
import '../../../core/utils/notification_service.dart';
import '../../../data/services/sync_service.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:printing/printing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/di/injection.dart';
import '../../../data/database/pos_database.dart';
import '../../widgets/app_background.dart';
import '../../../data/services/printer_service.dart';
import '../../blocs/cash_session_bloc.dart';
import '../../blocs/theme_bloc.dart';
import '../../blocs/auth_bloc.dart';
import 'users_screen.dart';
import 'discounts_screen.dart'; // Chemin corrigé
import 'cash_session_history_screen.dart';
import 'audit_log_screen.dart';
import '../cash_drawer/close_cash_drawer_screen.dart';
import '../products/stock_check_screen.dart';
import 'glass_alert_dialog.dart';
import 'package:flutter_pos_printer_platform_image_3_sdt/flutter_pos_printer_platform_image_3_sdt.dart'
    as pos_printer;
import '../../../data/database/pin_confirmation_dialog.dart'; // Import du nouveau widget

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final _db = getIt<PosDatabase>();
  final _shopNameCtrl = TextEditingController();
  final _shopAddressCtrl = TextEditingController();
  final _shopPhoneCtrl = TextEditingController();
  final _terminalNameCtrl = TextEditingController();
  final _footerCtrl = TextEditingController();
  final _backlogThresholdCtrl = TextEditingController();
  String _printerMac = '';
  String _printerName = '';
  AppPrinterType _currentPrinterType = AppPrinterType.none; // NEW
  String? _usbVendorId; // NEW
  String? _usbProductId; // NEW
  String _shopLogoPath = '';
  bool _loading = true;
  bool _syncNotificationsEnabled = true;
  bool _scannerSoundEnabled = true;
  bool _autoPrintEnabled = true;
  bool? _fiscalIntegrityOk; // Nouveau: État de l'intégrité fiscale
  bool _saved = false;
  double _uploadProgress = 0;
  String _timeRemaining = '';
  Map<String, dynamic>? _cloudUsage;
  bool _cancelRequested = false;
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  Future<void> _loadSettings() async {
    try {
      _shopNameCtrl.text = await _db.getSetting('shop_name') ?? '';
      _shopAddressCtrl.text = await _db.getSetting('shop_address') ?? '';
      _shopPhoneCtrl.text = await _db.getSetting('shop_phone') ?? '';
      _terminalNameCtrl.text =
          await _db.getSetting('terminal_name') ?? 'Caisse 1';
      _footerCtrl.text =
          await _db.getSetting('receipt_footer') ?? 'Merci de votre visite !';
      _printerMac = await _db.getSetting('printer_mac') ?? '';
      _printerName = await _db.getSetting('printer_name') ?? '';
      _shopLogoPath = await _db.getSetting('shop_logo_path') ?? '';
      _syncNotificationsEnabled =
          (await _db.getSetting('sync_backlog_notifications_enabled') ?? '1') ==
              '1';
      _autoPrintEnabled =
          (await _db.getSetting('auto_print_enabled') ?? '1') == '1';
      _scannerSoundEnabled =
          (await _db.getSetting('scanner_sound_enabled') ?? '1') == '1';
      _backlogThresholdCtrl.text =
          await _db.getSetting('sync_backlog_threshold') ?? '100';
      final printerTypeStr = await _db.getSetting('printer_type'); // NEW
      _currentPrinterType = AppPrinterType.values.firstWhere(
        // NEW
        (e) => e.toString() == 'AppPrinterType.$printerTypeStr',
        orElse: () => AppPrinterType.none,
      );
      // Optimisation : Vérifier uniquement les 100 dernières ventes pour la rapidité de l'UI
      _fiscalIntegrityOk = await _db.salesDao.verifyFiscalIntegrity(limit: 100);
      _fetchCloudUsage();
      _animationController.forward();
    } catch (e) {
      debugPrint(
          'SettingsScreen: Erreur lors du chargement des paramètres: $e');
      _showSnack('Erreur de chargement des paramètres', AppColors.danger);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    await _db.setSetting('shop_name', _shopNameCtrl.text.trim());
    await _db.setSetting('shop_address', _shopAddressCtrl.text.trim());
    await _db.setSetting('shop_phone', _shopPhoneCtrl.text.trim());
    await _db.setSetting('terminal_name', _terminalNameCtrl.text.trim());
    await _db.setSetting('receipt_footer', _footerCtrl.text.trim());
    await _db.setSetting(
        'sync_backlog_threshold', _backlogThresholdCtrl.text.trim());
    await _db.setSetting('printer_type', _currentPrinterType.name); // NEW

    // Informer le service de synchro du changement de nom
    getIt<SyncService>().updateTerminalName(_terminalNameCtrl.text.trim());

    final syncService = getIt<SyncService>();
    bool cloudSuccess = false;
    String? specificError;

    try {
      cloudSuccess = await syncService.registerShop(
        name: _shopNameCtrl.text.trim(),
        address: _shopAddressCtrl.text.trim(),
      );
    } on PostgrestException catch (e) {
      specificError = e.message;
      cloudSuccess = false;
    } catch (e) {
      specificError = e.toString();
      cloudSuccess = false;
    }

    setState(() => _saved = true);

    if (!cloudSuccess && mounted) {
      final user = Supabase.instance.client.auth.currentUser;
      final String errorMsg = user == null
          ? 'Connectez-vous avec votre email.'
          : (specificError ?? 'Vérifiez les droits RLS ou la connexion.');
      _showSnack('Sauvegarde locale OK. $errorMsg', AppColors.warning);
    }

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _saved = false);
  }

  Future<void> _fetchCloudUsage() async {
    try {
      final response = await Supabase.instance.client.rpc('get_project_usage');
      if (mounted) {
        setState(() {
          _cloudUsage = Map<String, dynamic>.from(response);
        });
      }
    } catch (e) {
      debugPrint('Settings: Impossible de récupérer le quota cloud: $e');
    }
  }

  Future<void> _toggleSyncNotifications(bool value) async {
    setState(() => _syncNotificationsEnabled = value);
    await _db.setSetting(
        'sync_backlog_notifications_enabled', value ? '1' : '0');
    if (!value) {
      await getIt<NotificationService>().cancelNotification(999);
    }
  }

  Future<void> _toggleScannerSound(bool value) async {
    setState(() => _scannerSoundEnabled = value);
    await _db.setSetting('scanner_sound_enabled', value ? '1' : '0');
  }

  Future<void> _toggleAutoPrint(bool value) async {
    setState(() => _autoPrintEnabled = value);
    await _db.setSetting('auto_print_enabled', value ? '1' : '0');
  }

  Future<void> _savePrinter(BluetoothDevice device) async {
    await _db.setSetting('printer_mac', device.address ?? '');
    await _db.setSetting('printer_name', device.name ?? '');
    setState(() {
      _currentPrinterType = AppPrinterType.bluetooth; // NEW
      _printerMac = device.address ?? '';
      _printerName = device.name ?? '';
      _usbVendorId = null; // NEW: Clear USB settings
      _usbProductId = null; // NEW: Clear USB settings
    });
    _showSnack('Imprimante "${device.name ?? device.address}" connectée',
        AppColors.success);
  }

  Future<void> _saveUsbPrinter(pos_printer.PrinterDevice printer) async {
    // NEW
    await _db.setSetting(
        'printer_usb_vendor_id', printer.vendorId?.toString() ?? '');
    await _db.setSetting(
        'printer_usb_product_id', printer.productId?.toString() ?? '');
    await _db.setSetting('printer_name', printer.name);
    await _db.setSetting('printer_type', AppPrinterType.usb.name);
    await _db.setSetting('printer_mac', ''); // Clear Bluetooth settings
    setState(() {
      _currentPrinterType = AppPrinterType.usb;
      _usbVendorId = printer.vendorId.toString();
      _usbProductId = printer.productId.toString();
      _printerName = printer.name;
      _printerMac = '';
    });
    _showSnack('Imprimante USB "${printer.name}" connectée', AppColors.success);
  }

  Future<void> _saveSystemPdfPrinter(Printer printer) async {
    await _db.setSetting('printer_name', printer.name);
    await _db.setSetting('printer_type', AppPrinterType.systemPdf.name);
    // L'adresse MAC n'est pas pertinente pour les imprimantes système
    await _db.setSetting('printer_mac', '');
    await _db.setSetting('printer_usb_vendor_id', '');
    await _db.setSetting('printer_usb_product_id', '');
    setState(() {
      _currentPrinterType = AppPrinterType.systemPdf;
      _printerName = printer.name;
      _printerMac = '';
      _usbVendorId = null;
      _usbProductId = null;
    });
    _showSnack('Imprimante par défaut définie sur "${printer.name}"',
        AppColors.success);
  }

  Future<void> _testPrint() async {
    // NEW: Check based on current printer type
    if (_currentPrinterType == AppPrinterType.none) {
      _showSnack(
          'Veuillez d\'abord configurer une imprimante', AppColors.warning);
      return;
    }

    try {
      final printerService = getIt<PrinterService>();
      // Vérifier si l'imprimante est prête avant d'imprimer
      final bool printerIsReady = await printerService.isReady();
      if (!printerIsReady) {
        _showSnack(
            'L\'imprimante n\'est pas connectée ou prête.', AppColors.danger);
        return;
      }
      final bool success = await printerService
          .printTestReceipt(); // Lancer l'impression de test
      if (success) {
        _showSnack('Ticket de test envoyé !', AppColors.success);
      }
    } catch (e) {
      _showSnack('Erreur d\'impression : $e', AppColors.danger);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
    ));
  }

  Future<void> _pickLogo() async {
    try {
      final picker = ImagePicker();
      // Sur Windows, maxWidth peut parfois causer des lenteurs au sein du plugin, on peut le garder ou l'enlever
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null || !mounted) return;

      final directory = await getApplicationDocumentsDirectory();
      final String path = p.join(directory.path, 'assets');
      final Directory dir = Directory(path);
      if (!await dir.exists()) await dir.create(recursive: true);

      // Correction Windows : Utiliser un nom unique pour éviter le verrouillage de fichier
      final String fileName =
          'shop_logo_${DateTime.now().millisecondsSinceEpoch}${p.extension(image.path)}';
      final String newPath = p.join(path, fileName);

      // Utiliser les bytes est plus sûr que copy() sur Desktop
      final bytes = await image.readAsBytes();
      await File(newPath).writeAsBytes(bytes);

      final oldPath = _shopLogoPath;

      await _db.setSetting('shop_logo_path', newPath);
      setState(() => _shopLogoPath = newPath);
      _showSnack('Logo mis à jour', AppColors.success);

      // Supprimer l'ancien logo si nécessaire, sans bloquer si Windows refuse (file lock)
      if (oldPath.isNotEmpty && oldPath != newPath) {
        try {
          final oldFile = File(oldPath);
          if (await oldFile.exists()) await oldFile.delete();
        } catch (e) {
          debugPrint(
              'SettingsScreen: Impossible de supprimer l\'ancien logo (fichier verrouillé) : $e');
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Erreur lors de la sélection du logo: $e', AppColors.danger);
    }
  }

  Future<void> _removeLogo() async {
    if (_shopLogoPath.isEmpty) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => GlassAlertDialog(
        title: const Text('Supprimer le logo'),
        content: const Text(
            'Voulez-vous vraiment supprimer le logo du magasin et revenir à l\'icône par défaut ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final oldPath = _shopLogoPath;
      await _db.setSetting('shop_logo_path', '');
      setState(() => _shopLogoPath = '');

      final file = File(oldPath);
      if (await file.exists()) {
        await file.delete();
      }
      _showSnack('Logo supprimé', AppColors.info);
    } catch (e) {
      _showSnack('Logo retiré (Fichier occupé par le système)', AppColors.info);
    }
  }

  String _formatDuration(Duration d) {
    if (d.inSeconds <= 0) return '';
    if (d.inMinutes > 0) {
      return 'environ ${d.inMinutes}m ${d.inSeconds % 60}s restantes';
    }
    return 'environ ${d.inSeconds}s restantes';
  }

  Future<void> _forceUploadCatalog() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => GlassAlertDialog(
        title: const Text('Synchroniser le catalogue'),
        content: const Text(
          'Cette action va renvoyer tous vos produits locaux vers le Cloud pour s\'assurer que votre catalogue est à jour sur tous les terminaux.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Démarrer')),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _loading = true;
      _uploadProgress = 0;
      _timeRemaining = '';
      _cancelRequested = false;
    });
    try {
      final start = DateTime.now();
      await getIt<SyncService>().forceUploadCatalog(
        shouldCancel: () => _cancelRequested,
        onProgress: (p) {
          if (!mounted) return;

          final elapsed = DateTime.now().difference(start);
          String remainingLabel = '';

          // On attend d'avoir au moins 2% de progression pour stabiliser l'estimation
          if (p > 0.02) {
            final totalEstimatedMs = elapsed.inMilliseconds / p;
            final remainingMs = totalEstimatedMs - elapsed.inMilliseconds;
            remainingLabel =
                _formatDuration(Duration(milliseconds: remainingMs.toInt()));
          }

          setState(() {
            _uploadProgress = p;
            _timeRemaining = remainingLabel;
          });
        },
      );
      if (_cancelRequested) {
        _showSnack('Synchronisation annulée', AppColors.warning);
      } else {
        _showSnack('Le catalogue a été ajouté à la file de synchronisation',
            AppColors.success);
      }
    } catch (e) {
      _showSnack('Erreur: $e', AppColors.danger);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _shareLogs() async {
    final logFile = await getIt<LoggerService>().getLogFile();
    if (logFile != null) {
      final now = DateTime.now();
      final timestamp = DateFormat('yyyyMMdd_HHmm').format(now);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(logFile.path, name: 'logs_pos_$timestamp.txt')],
          subject: 'Logs de maintenance POS - $timestamp',
        ),
      );
    } else {
      _showSnack('Aucun fichier de log disponible', AppColors.info);
    }
  }

  Future<void> _cleanupJustifications() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => GlassAlertDialog(
        title: const Text('Nettoyage des justificatifs'),
        content: const Text(
          'Voulez-vous supprimer les photos de justifications (pertes/défectueux) datant de plus de 90 jours pour libérer de l\'espace ?\n\nL\'historique texte sera conservé.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Nettoyer')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      // 1. Purge des anciens (plus de 90 jours)
      final purgedCount = await _db.purgeOldJustificationImages(90);

      // 2. Nettoyage des orphelins (fichiers sans record DB)
      final dbPaths = await _db.getAllJustificationImagePaths();
      final dbPathsSet = Set<String>.from(dbPaths);
      final directory = await getApplicationDocumentsDirectory();
      final justifDir = Directory(p.join(directory.path, 'justifications'));

      int orphanCount = 0;
      if (await justifDir.exists()) {
        final entities = justifDir.listSync();
        for (final entity in entities) {
          if (entity is File && !dbPathsSet.contains(entity.path)) {
            await entity.delete();
            orphanCount++;
          }
        }
      }
      _showSnack(
          '$purgedCount anciennes photos et $orphanCount fichiers orphelins supprimés.',
          AppColors.success);
    } catch (e) {
      _showSnack('Erreur lors du nettoyage : $e', AppColors.danger);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _cleanupImages() async {
    setState(() => _loading = true);
    try {
      final dbPaths = await _db.getAllProductImagePaths();
      final dbPathsSet = Set<String>.from(dbPaths);

      final directory = await getApplicationDocumentsDirectory();
      final imgDir = Directory(p.join(directory.path, 'product_images'));

      if (!await imgDir.exists()) {
        _showSnack('Aucun dossier d\'images à nettoyer', AppColors.info);
        return;
      }

      int deletedCount = 0;
      final entities = imgDir.listSync();

      for (final entity in entities) {
        if (entity is File) {
          if (!dbPathsSet.contains(entity.path)) {
            await entity.delete();
            deletedCount++;
          }
        }
      }

      _showSnack(
          '$deletedCount images orphelines supprimées', AppColors.success);
    } catch (e) {
      _showSnack('Erreur lors du nettoyage : $e', AppColors.danger);
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Convertit une liste de lignes en CSV avec séparateur point-virgule
  /// (compatible Excel FR) — sans dépendance externe
  String _convertToCsv(List<List<dynamic>> rows) {
    return rows.map((row) {
      return row.map((cell) {
        final value = cell?.toString() ?? '';
        // Si la valeur contient un ; ou un guillemet ou un saut de ligne,
        // on l'entoure de guillemets et on échappe les guillemets internes
        if (value.contains(';') ||
            value.contains('"') ||
            value.contains('\n')) {
          return '"${value.replaceAll('"', '""')}"';
        }
        return value;
      }).join(';');
    }).join('\n');
  }

  Future<void> _exportSalesToCSV() async {
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      ),
      helpText: 'PÉRIODE D\'EXPORTATION',
      confirmText: 'EXPORTER',
      saveText: 'CHOISIR',
    );

    if (range == null) return;

    setState(() => _loading = true);
    try {
      final shopId = await _db.getSetting('shop_id') ?? '';
      final filteredSales =
          await _db.salesDao.getSalesForPeriod(range.start, range.end, shopId);

      if (filteredSales.isEmpty) {
        _showSnack(
            'Aucune vente trouvée pour cette période', AppColors.warning);
        return;
      }

      final List<List<dynamic>> rows = [];
      rows.add([
        'Date',
        'Référence',
        'Articles',
        'Total HT',
        'TVA',
        'Total TTC',
        'Remise',
        'Statut',
        'Note'
      ]);

      for (final s in filteredSales) {
        final items = await _db.salesDao.getSaleItems(s.id);
        final itemsSummary =
            items.map((i) => '${i.quantity}x ${i.productName}').join(', ');

        rows.add([
          Fmt.dateTime(s.createdAt),
          s.ref,
          itemsSummary,
          s.totalHt.toStringAsFixed(2),
          s.totalTax.toStringAsFixed(2),
          s.totalTtc.toStringAsFixed(2),
          s.discountAmount.toStringAsFixed(2),
          s.status,
          s.note,
        ]);
      }

      // CORRECTION : implémentation manuelle, plus de dépendance csv
      final String csvData = _convertToCsv(rows);

      final directory = await getTemporaryDirectory();
      final fromStr = DateFormat('yyyyMMdd').format(range.start);
      final toStr = DateFormat('yyyyMMdd').format(range.end);
      final path = p.join(directory.path, 'ventes_${fromStr}_au_$toStr.csv');

      final file = File(path);
      if (await file.exists()) await file.delete();

      // BOM UTF-8 pour compatibilité Microsoft Excel
      final bytes = utf8.encode(csvData);
      final bom = [0xEF, 0xBB, 0xBF];
      await file.writeAsBytes(bom + bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path, mimeType: 'text/csv')],
          subject: 'Export Ventes POS — $fromStr au $toStr',
        ),
      );
    } catch (e) {
      _showSnack('Erreur lors de l\'export : $e', AppColors.danger);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _backupDatabase() async {
    // 1. Demander un mot de passe pour le chiffrement
    final String? password = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final passCtrl = TextEditingController();
        return GlassAlertDialog(
          title: const Text('Sauvegarde de la base'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Entrez un mot de passe pour chiffrer le fichier (recommandé).',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passCtrl,
                obscureText: true,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  hintText: 'Laisser vide pour ne pas chiffrer',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: AppColors.textMuted),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, passCtrl.text),
              child: const Text('Continuer'),
            ),
          ],
        );
      },
    );

    if (password == null) return; // Annulé par l'utilisateur

    if (!mounted) return;

    // 2. Si pas de mot de passe, avertissement de sécurité (Mode non chiffré)
    if (password.isEmpty) {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => GlassAlertDialog(
          title: const Text('⚠️ Sauvegarde non chiffrée'),
          content: const Text(
            'Le fichier exporté sera lisible par n\'importe qui.\nÊtes-vous sûr de vouloir continuer sans chiffrement ?', // Ligne 872
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
              child: const Text('Retour'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
              child: const Text('Exporter quand même'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dbPath = p.join(directory.path, 'pos_database.sqlite');
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        _showSnack('Fichier de base de données introuvable', AppColors.danger);
        return;
      }

      final now = DateTime.now();
      final timestamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}'
          '_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';

      String finalPath = dbPath;
      String finalName = 'backup_pos_$timestamp.sqlite';
      String subject = 'BACKUP POS (Non chiffré) — $timestamp';

      // 3. Chiffrement AES-256 si mot de passe présent
      if (password.isNotEmpty) {
        final plainBytes = await dbFile.readAsBytes();

        // Dérivation de clé : SHA-256 du mot de passe pour obtenir 32 bytes
        final keyBytes = sha256.convert(utf8.encode(password)).bytes;
        final key = enc.Key(Uint8List.fromList(keyBytes));
        final iv =
            enc.IV.fromSecureRandom(16); // Vecteur d'initialisation aléatoire
        final encrypter = enc.Encrypter(enc.AES(key));

        final encrypted = encrypter.encryptBytes(plainBytes, iv: iv);

        // Écriture du fichier : IV (16 bytes) + Contenu chiffré
        // L'IV est nécessaire pour déchiffrer, il n'est pas secret mais doit être unique.
        final tempDir = await getTemporaryDirectory();
        final encFile = File(p.join(tempDir.path, 'backup_pos_$timestamp.enc'));
        await encFile.writeAsBytes(iv.bytes + encrypted.bytes);

        finalPath = encFile.path;
        finalName = 'backup_pos_$timestamp.enc';
        subject = 'BACKUP POS (Sécurisé) — $timestamp';
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(finalPath, name: finalName)],
          subject: subject,
        ),
      );
    } catch (e) {
      _showSnack('Erreur lors de la sauvegarde : $e', AppColors.danger);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _restoreDatabase() async {
    // 1. Sélection du fichier
    final result = await FilePicker.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result == null || result.files.single.path == null) return;
    if (!mounted) return;
    final File pickedFile = File(result.files.single.path!);
    final bool isEncrypted = pickedFile.path.endsWith('.enc');

    // 2. Demander le mot de passe si chiffré
    String password = '';
    if (isEncrypted) {
      password = await showDialog<String>(
            // ignore: use_build_context_synchronously
            context: context,
            builder: (ctx) {
              final ctrl = TextEditingController();
              return GlassAlertDialog(
                title: const Text('Restauration sécurisée'),
                content: TextField(
                  controller: ctrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Mot de passe de déchiffrement'),
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Annuler')),
                  ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, ctrl.text),
                      child: const Text('Déchiffrer')),
                ],
              );
            },
          ) ??
          '';
      if (password.isEmpty) return;
    }

    // 3. Confirmation finale
    final bool? confirm = await showDialog<bool>(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (ctx) => GlassAlertDialog(
        title: const Text('Écraser les données actuelles ?'),
        content: const Text(
            'Toutes les données actuelles seront remplacées par celles de la sauvegarde. L\'application devra redémarrer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('Restaurer')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      Uint8List bytesToRestore;

      if (isEncrypted) {
        final rawBytes = await pickedFile.readAsBytes();
        final iv = enc.IV(rawBytes.sublist(0, 16));
        final encryptedBytes = rawBytes.sublist(16);

        final keyBytes = sha256.convert(utf8.encode(password)).bytes;
        final key = enc.Key(Uint8List.fromList(keyBytes));
        final encrypter = enc.Encrypter(enc.AES(key));

        final decrypted =
            encrypter.decryptBytes(enc.Encrypted(encryptedBytes), iv: iv);
        bytesToRestore = Uint8List.fromList(decrypted);
      } else {
        bytesToRestore = await pickedFile.readAsBytes();
      }

      // 4. Fermer la base, remplacer le fichier et redémarrer
      await _db.close();
      final dbFile = await PosDatabase.getDatabaseFile();
      await dbFile.writeAsBytes(bytesToRestore);

      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => GlassAlertDialog(
          title: const Text('Restauration réussie'),
          content: const Text(
              'La base de données a été restaurée. L\'application va maintenant se fermer pour appliquer les changements.'),
          actions: [
            ElevatedButton(
              onPressed: () => SystemNavigator.pop(),
              child: const Text('Quitter'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showSnack(
          'Erreur de restauration : Mot de passe incorrect ou fichier corrompu.',
          AppColors.danger);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeCredentials() async {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;

    // CAS 1 : Propriétaire Cloud (Changement de mot de passe)
    if (user.role == 'owner' && (user.supabaseId?.isNotEmpty ?? false)) {
      final newPassword = await showDialog<String>(
        context: context,
        builder: (ctx) {
          final ctrl = TextEditingController();
          return GlassAlertDialog(
            title: const Text('Nouveau mot de passe'),
            content: TextField(
              controller: ctrl,
              obscureText: true,
              style: TextStyle(
                  // Ligne 941
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Minimum 6 caractères',
                prefixIcon: Icon(Icons.lock_outline, color: Colors.white70),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Annuler')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, ctrl.text),
                child: const Text('Valider'),
              ),
            ],
          );
        },
      );

      // Regex pour : Min 8 caractères, 1 majuscule, 1 chiffre, 1 caractère spécial
      final passwordRegex =
          RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');

      if (newPassword != null && passwordRegex.hasMatch(newPassword)) {
        try {
          setState(() => _loading = true);
          await Supabase.instance.client.auth
              .updateUser(UserAttributes(password: newPassword));

          if (!mounted) return;

          // Afficher un dialogue informant de la déconnexion
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => GlassAlertDialog(
              title: const Text('Mot de passe modifié'),
              content: const Text(
                  'Pour des raisons de sécurité, vous allez être déconnecté. Veuillez vous reconnecter avec votre nouveau mot de passe.'),
              actions: [
                ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Compris')),
              ],
            ),
          );

          if (!mounted) return;
          context.read<AuthBloc>().add(LogoutRequested());
        } catch (e) {
          _showSnack('Erreur : ${e.toString()}', AppColors.danger);
        } finally {
          if (mounted) setState(() => _loading = false);
        }
      } else if (newPassword != null) {
        _showSnack(
            'Sécurité insuffisante : utilisez 8 caractères min, une majuscule, un chiffre et un symbole.',
            AppColors.warning);
      }
      return;
    }

    // CAS 2 : Admin/Caissier Local (Changement de PIN)
    // D'abord, on vérifie l'ancien PIN pour la sécurité
    final authorized = await showDialog<bool>(
      context: context,
      builder: (_) => const PinConfirmationDialog(
        title: 'Vérification',
        message: 'Entrez votre PIN actuel pour continuer',
      ),
    );

    if (authorized != true || !mounted) return;

    // Ensuite, on demande le nouveau PIN
    final newPin = await showDialog<String>(
      context: context,
      builder: (ctx) => const _NewPinDialog(),
    );

    if (newPin != null && newPin.length == 4) {
      await _db.updateUserPin(userId: user.id, newPin: newPin);
      _showSnack('Code PIN modifié avec succès', AppColors.success);

      // Optionnel : Si l'utilisateur avait le code par défaut, cela rafraîchira l'UI
      // (Nécessite un setState pour enlever le bandeau d'alerte rouge)
      setState(() {});
    }
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _shopAddressCtrl.dispose();
    _shopPhoneCtrl.dispose();
    _footerCtrl.dispose();
    _backlogThresholdCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── SÉCURITÉ : Vérification du rôle administrateur ─────────────
    // Cette protection agit comme un pare-feu supplémentaire au cas où
    // la logique de navigation dans main.dart échouerait.
    final user = context.watch<AuthBloc>().state.user;
    // Autoriser aussi le propriétaire ('owner') à accéder aux paramètres
    final isAllowed =
        user == null || user.role == 'admin' || user.role == 'owner';
    if (!isAllowed) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 48, color: AppColors.textMuted),
            SizedBox(height: 16),
            Text('Accès réservé aux administrateurs',
                style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    // NOUVEAU : Vérification du code PIN par défaut pour l'admin/propriétaire
    bool isUsingDefaultPin = false;
    if (user != null && ['admin', 'owner'].contains(user.role)) {
      // Cet appel est synchrone mais très rapide (calcul de hash)
      isUsingDefaultPin = _db.isUsingDefaultPin(user);
    }

    if (_loading) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: Center(
          child: _uploadProgress > 0
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Préparation du catalogue...',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: _uploadProgress,
                        backgroundColor: AppColors.border,
                        color: AppColors.primary,
                        minHeight: 8,
                      ),
                      const SizedBox(height: 8),
                      Text('${(_uploadProgress * 100).toInt()}%',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                      if (_timeRemaining.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(_timeRemaining,
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500)),
                        ),
                      const SizedBox(height: 24),
                      TextButton.icon(
                        onPressed: () =>
                            setState(() => _cancelRequested = true),
                        icon: const Icon(Icons.stop_circle_outlined,
                            color: AppColors.danger),
                        label: const Text('Annuler l\'opération',
                            style: TextStyle(color: AppColors.danger)),
                      ),
                    ],
                  ),
                )
              : const CircularProgressIndicator(color: AppColors.primaryLight),
        ),
      );
    }

    final List<Widget> children = [
      if (isUsingDefaultPin) _defaultPinWarning(),
      _staticRow('Mode de compilation',
          kReleaseMode ? 'Optimisé (Release)' : 'Développement (Debug)'),
      _section('Affichage', [
        BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, state) {
            return _switchRow(
              'Mode sombre',
              'Optimise l\'interface pour les environnements sombres',
              Icons.dark_mode_outlined,
              state.themeMode == ThemeMode.dark,
              (_) => context.read<ThemeBloc>().add(ToggleTheme()),
            );
          },
        ),
      ]),
      _section('Informations du magasin', [
        _logoPicker(),
        _inputField(_shopNameCtrl, 'Nom du magasin', Icons.store_outlined),
        _inputField(_shopAddressCtrl, 'Adresse', Icons.location_on_outlined),
        _inputField(_shopPhoneCtrl, 'Téléphone', Icons.phone_outlined,
            keyboard: TextInputType.phone),
        _inputField(
            _terminalNameCtrl, 'Nom de cette caisse', Icons.computer_outlined),
        _actionRow('Changer de magasin', Icons.swap_horiz_rounded,
            AppColors.primary, _showShopPicker),
      ]),
      _section('Outils Rapides', [
        _actionRow('Vérifier un stock (Scan)', Icons.qr_code_scanner_rounded,
            AppColors.accent, _openStockCheck),
        _switchRow(
          'Sons du scanner',
          'Émettre un bip lors d\'un scan réussi ou échoué',
          Icons.volume_up_outlined,
          _scannerSoundEnabled,
          _toggleScannerSound,
        ),
      ]),
      _section('Reçu thermique', [
        _inputField(
            _footerCtrl, 'Message de pied de reçu', Icons.receipt_outlined,
            maxLines: 2),
        _staticRow('Largeur papier', '80 mm'),
      ]),
      _section('Sécurité', [
        _actionRow('Modifier mes accès (PIN/Mdp)', Icons.lock_reset,
            AppColors.accent, _changeCredentials),
        _actionRow('Gérer les utilisateurs', Icons.manage_accounts_outlined,
            AppColors.primaryLight, _openUsersScreen),
        _actionRow('Journal d\'audit', Icons.policy_outlined,
            AppColors.primaryLight, _openAuditLogScreen),
        if (_fiscalIntegrityOk != null)
          _fiscalIntegrityIndicator(), // Afficher l'indicateur
        BlocBuilder<CashSessionBloc, CashSessionState>(
          builder: (context, state) {
            if (state is CashSessionOpen) {
              return _actionRow(
                'Fermer la caisse',
                Icons.point_of_sale,
                AppColors.accent,
                _closeCashDrawer,
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ]),
      _section('Promotions', [
        _actionRow('Gérer les remises et coupons', Icons.discount_outlined,
            AppColors.primaryLight, _openDiscountsScreen),
      ]),
      _section('Rapports', [
        _actionRow('Historique des caisses', Icons.history_rounded,
            AppColors.info, _openCashHistory),
      ]),
      _section('Imprimante', [
        _printerRow(),
        _switchRow(
          'Impression automatique',
          'Imprimer le ticket dès la validation de la vente',
          Icons.auto_mode_outlined,
          _autoPrintEnabled,
          _toggleAutoPrint,
        ),
        if (_printerMac.isNotEmpty || _printerName.isNotEmpty)
          _actionRow(
            'Tester l\'imprimante',
            Icons.print_rounded,
            AppColors.success,
            _testPrint,
          ),
      ]),
      _section('Fiscalité & Devise', [
        _staticRow('Devise', 'FCFA'),
        _staticRow('TVA par défaut', '0% (configurable par produit)'),
      ]),
      _section('Données', [
        if (_cloudUsage != null) _quotaWidget(),
        _actionRow(
            'Forcer la synchronisation', Icons.sync_rounded, AppColors.info,
            () async {
          await getIt<SyncService>().forceSync();
          _showSnack('Synchronisation manuelle lancée...', AppColors.info);
        }),
        _actionRow(
          'Synchroniser tout le catalogue',
          Icons.cloud_upload_outlined,
          AppColors.info,
          _forceUploadCatalog,
        ),
        _switchRow(
          'Alertes de retard de synchro',
          'Notifie si la file d\'attente est trop longue',
          Icons.notifications_paused_outlined,
          _syncNotificationsEnabled,
          _toggleSyncNotifications,
        ),
        if (_syncNotificationsEnabled)
          _inputField(
            _backlogThresholdCtrl,
            'Seuil d\'alerte (nb. éléments)',
            Icons.bolt_outlined,
            keyboard: TextInputType.number,
          ),
        _actionRow('Exporter ventes (CSV)', Icons.download_outlined,
            AppColors.info, _exportSalesToCSV),
        _actionRow('Partager les logs techniques', Icons.bug_report_outlined,
            AppColors.info, _shareLogs),
        _actionRow('Sauvegarder la base', Icons.shield_outlined,
            AppColors.warning, _backupDatabase),
        _actionRow(
            'Restaurer une sauvegarde',
            Icons.settings_backup_restore_rounded,
            AppColors.warning,
            _restoreDatabase),
        _actionRow(
            'Nettoyer le stockage (images)',
            Icons.cleaning_services_outlined,
            AppColors.warning,
            _cleanupImages),
        _actionRow(
            'Purger les justificatifs de perte',
            Icons.auto_delete_outlined,
            AppColors.warning,
            _cleanupJustifications),
        _actionRow('Réinitialiser les données', Icons.delete_forever_outlined,
            AppColors.danger, () => _confirmReset(hard: false)),
        _actionRow('WIPE COMPLET (DÉV)', Icons.auto_delete_outlined,
            AppColors.danger, () => _confirmReset(hard: true)),
      ]),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _save,
          icon: Icon(_saved ? Icons.check : Icons.save_rounded, size: 18),
          label: Text(_saved ? 'Enregistré !' : 'Sauvegarder les paramètres'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _saved ? AppColors.success : AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
      const SizedBox(height: 20),
      const Center(
        child: Text(
          'POS System v1.0  ·  Flutter Multiplateforme  ·  Drift SQLite',
          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: 8),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final animation = CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(
                        (0.5 / children.length) * index,
                        1.0,
                        curve: Curves.easeOutCubic,
                      ),
                    );
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(animation),
                        child: children[index],
                      ),
                    );
                  },
                  childCount: children.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quotaWidget() {
    if (_cloudUsage == null) return const SizedBox.shrink();

    final dbSize = _cloudUsage!['db_size_bytes'] as int;
    final dbLimit = _cloudUsage!['db_limit_bytes'] as int;
    final storageSize = _cloudUsage!['storage_size_bytes'] as int;
    final storageLimit = _cloudUsage!['storage_limit_bytes'] as int;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _usageBar('Base de données', dbSize, dbLimit),
          const SizedBox(height: 12),
          _usageBar('Stockage Cloud (Images)', storageSize, storageLimit),
        ],
      ),
    );
  }

  Widget _usageBar(String label, int used, int limit) {
    final percent = (used / limit).clamp(0.0, 1.0);
    final color = percent > 0.9
        ? AppColors.danger
        : (percent > 0.7 ? AppColors.warning : AppColors.success);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            Text(
                '${(used / 1024 / 1024).toStringAsFixed(1)} MB / ${(limit / 1024 / 1024).toInt()} MB',
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(4)),
          child: LinearProgressIndicator(
            // Ligne 751
            value: percent,
            backgroundColor:
                Theme.of(context).dividerColor.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _defaultPinWarning() {
    return GestureDetector(
      onTap: _openUsersScreen,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.dangerSoft,
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          border: Border.all(color: AppColors.danger),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Faille de sécurité critique',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold)), // Ligne 1010
                  const SizedBox(height: 4),
                  const Text(
                    'Votre compte utilise un code PIN non sécurisé. Veuillez le changer immédiatement pour protéger vos données de caisse.',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right,
                size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 8),
        child: Text(title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            )),
      ),
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
                color: AppColors.shadow.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.0
                        : 0.02),
                blurRadius: 10)
          ],
        ),
        child: Column(
          children: children.expand((w) {
            final isLast = w == children.last;
            return [
              w,
              if (!isLast)
                Divider(
                    height: 1,
                    color: AppColors.border.withValues(alpha: 0.5),
                    indent: 16),
            ];
          }).toList(),
        ),
      ),
    ]);
  }

  Widget _logoPicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _pickLogo, // Ligne 1053
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: _shopLogoPath.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.file(
                            File(_shopLogoPath),
                            key: ValueKey(_shopLogoPath),
                            fit: BoxFit.contain,
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                color: AppColors.textMuted),
                            SizedBox(height: 4), // Ligne 1074
                            Text('Logo',
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                ),
              ),
            ),
            if (_shopLogoPath.isNotEmpty)
              Positioned(
                right: -8,
                top: -8,
                child: IconButton(
                  onPressed: _removeLogo,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: AppColors.danger, shape: BoxShape.circle),
                    child: const Icon(Icons.close,
                        size: 14, color: AppColors.textOnDark),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _fiscalIntegrityIndicator() {
    final bool isOk = _fiscalIntegrityOk ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(isOk ? Icons.verified_user_outlined : Icons.security_outlined,
              color: isOk ? AppColors.success : AppColors.danger, size: 18),
          const SizedBox(width: 12),
          Text(
              isOk
                  ? 'Base de données Intègre'
                  : 'Base de données Corrompue', // Ligne 1103
              style: TextStyle(
                  color: isOk
                      ? Theme.of(context).colorScheme.onSurface
                      : AppColors.danger,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _inputField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        Icon(icon, color: AppColors.textMuted, size: 17),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: ctrl,
            keyboardType: keyboard,
            maxLines: maxLines,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
              hintStyle: const TextStyle(color: AppColors.textMuted),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              fillColor: Colors.transparent,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _staticRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        Text(label,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface, fontSize: 14)),
        const Spacer(),
        Text(value,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ]),
    );
  }

  Widget _printerRow() {
    String printerStatusText; // NEW
    IconData printerStatusIcon; // NEW
    Color printerStatusColor; // NEW

    if (_currentPrinterType == AppPrinterType.bluetooth) {
      // NEW
      printerStatusText = _printerMac.isEmpty
          ? 'Aucune imprimante Bluetooth configurée'
          : _printerName.isNotEmpty
              ? '$_printerName ($_printerMac)'
              : _printerMac;
      printerStatusIcon = Icons.bluetooth_connected;
      printerStatusColor =
          _printerMac.isEmpty ? AppColors.textMuted : AppColors.success;
    } else if (_currentPrinterType == AppPrinterType.usb) {
      // NEW
      printerStatusText = (_usbVendorId == null || _usbProductId == null)
          ? 'Aucune imprimante USB configurée'
          : _printerName.isNotEmpty
              ? '$_printerName (USB)'
              : 'Imprimante USB connectée';
      printerStatusIcon = Icons.usb;
      printerStatusColor = (_usbVendorId == null || _usbProductId == null)
          ? AppColors.textMuted // Ligne 1180
          : AppColors.success;
    } else if (_currentPrinterType == AppPrinterType.systemPdf) {
      // NEW
      printerStatusText = _printerName.isEmpty
          ? 'Aucune imprimante système configurée'
          : 'Imprimante système : $_printerName';
      printerStatusIcon = Icons.print_outlined;
      printerStatusColor = // Ligne 1188
          _printerName.isEmpty ? AppColors.textMuted : AppColors.success;
    } else {
      // NEW
      printerStatusText = 'Aucune imprimante configurée';
      printerStatusIcon = Icons.print_disabled_outlined;
      printerStatusColor = AppColors.textMuted;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(printerStatusIcon,
            color: AppColors.textMuted, size: 17), // NEW // Ligne 1194
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Imprimante',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14)),
            Text(
              printerStatusText, // NEW
              style: TextStyle(
                // NEW
                color: printerStatusColor, // NEW
                fontSize: 11,
              ),
            ),
          ]),
        ),
        OutlinedButton.icon(
          onPressed: _connectPrinter,
          icon: const Icon(Icons.settings_ethernet, size: 14), // Changed icon
          label: Text(_currentPrinterType == AppPrinterType.none
              ? 'Connecter'
              : 'Modifier'), // NEW
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.info,
            side: const BorderSide(color: AppColors.info, width: 0.8),
            textStyle: const TextStyle(fontSize: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          ),
        ),
      ]),
    );
  }

  Widget _switchRow(String label, String subtitle, IconData icon, bool value,
      ValueChanged<bool> onChanged) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppColors.textMuted, size: 18),
      title: Text(label,
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      dense: true,
    );
  }

  Widget _actionRow(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8), // Ligne 1040
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(label,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        onTap: onTap,
        hoverColor: color.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
              color: AppColors.border.withValues(alpha: 0.5), width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Future<void> _showShopPicker() async {
    setState(() => _loading = true);
    final syncService = getIt<SyncService>();
    final shops = await syncService.getAvailableShops();
    setState(() => _loading = false);

    if (!mounted) return;

    if (shops.isEmpty) {
      _showSnack(
          'Aucun autre magasin trouvé sur votre compte.', AppColors.warning);
      return;
    }

    final currentShopId = await _db.getSetting('shop_id');
    if (!mounted) return;
    final user = context.read<AuthBloc>().state.user;
    final bool isOwner = user?.role == 'owner';

    await showDialog(
      context: context,
      builder: (ctx) => GlassAlertDialog(
        title: const Text('Sélectionner un magasin'),
        content: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.6,
              maxWidth: double.maxFinite),
          child: ListView(
            shrinkWrap: true,
            children: [
              if (isOwner) ...[
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.add, color: Colors.white, size: 20),
                  ), // Ligne 1293
                  title: const Text('Ajouter un nouveau magasin',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showCreateShopDialog();
                  },
                ),
                const Divider(),
              ],
              ...shops.map((shop) {
                final isSelected = shop['id'] == currentShopId;
                return ListTile(
                  leading: Icon(
                    Icons.store_rounded,
                    color: isSelected ? AppColors.success : AppColors.textMuted,
                  ), // Ligne 1310
                  title: Text(
                    shop['name'],
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.success
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(shop['address'] ?? 'Sans adresse',
                      style: const TextStyle(fontSize: 12)),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.success)
                      : null,
                  onTap: isSelected
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          await syncService.switchShop(shop['id']);
                          _loadSettings(); // Rafraîchir les champs du formulaire
                          _showSnack('Bascule vers ${shop['name']} réussie',
                              AppColors.success);
                        },
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Fermer'))
        ],
      ),
    );
  }

  Future<void> _showCreateShopDialog() async {
    final nameCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final bool? created = await showDialog<bool>(
      context: context,
      builder: (ctx) => GlassAlertDialog(
        title: const Text('Nouveau magasin'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: const InputDecoration(labelText: 'Nom du magasin'),
                validator: (v) => v!.isEmpty ? 'Veuillez saisir un nom' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: addrCtrl,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: const InputDecoration(labelText: 'Adresse'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                final newId = const Uuid().v4();
                final success = await getIt<SyncService>().registerShop(
                  name: nameCtrl.text.trim(),
                  address: addrCtrl.text.trim(),
                  customId: newId,
                );

                if (success) {
                  await getIt<SyncService>().switchShop(newId);
                  if (ctx.mounted) Navigator.pop(ctx, true);
                }
              } catch (e) {
                _showSnack('Erreur: $e', AppColors.danger);
              }
            },
            child: const Text('Créer et basculer'),
          ),
        ],
      ),
    );

    if (created == true) {
      _loadSettings();
      _showSnack('Magasin créé avec succès', AppColors.success);
    }
  }

  void _openStockCheck() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StockCheckScreen()),
    );
  }

  void _connectPrinter() async {
    if (Platform.isAndroid) {
      // Liste des permissions nécessaires (Android 12+)
      final permissions = [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ];

      // Demande de permissions
      final Map<Permission, PermissionStatus> statuses =
          await permissions.request();

      // 1. Vérifier si l'utilisateur a refusé de façon permanente
      final bool isPermanentlyDenied =
          statuses.values.any((s) => s.isPermanentlyDenied);

      if (isPermanentlyDenied) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => GlassAlertDialog(
            title: const Text('Permissions Bluetooth'),
            content: const Text(
              'Vous avez désactivé les permissions Bluetooth. '
              'Pour connecter une imprimante, vous devez les activer manuellement dans les paramètres de l\'application.',
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('ANNULER')),
              ElevatedButton(
                onPressed: () {
                  openAppSettings(); // Ouvre les paramètres système de l'app
                  Navigator.pop(ctx);
                },
                child: const Text('PARAMÈTRES'),
              ),
            ],
          ),
        );
        return;
      }

      // 2. Vérifier si l'utilisateur a refusé (simple)
      if (statuses.values.any((s) => s.isDenied)) {
        _showSnack(
            'Les permissions Bluetooth sont nécessaires pour découvrir et connecter l\'imprimante.',
            AppColors.danger);
        return;
      }

      // 3. Vérifier si le Bluetooth est activé matériellement
      final printerService = getIt<PrinterService>();
      if (!await printerService.isBluetoothOn()) {
        _showSnack('Veuillez activer le Bluetooth sur votre appareil.',
            AppColors.warning);
        // On peut ouvrir directement les paramètres Bluetooth pour aider l'utilisateur
        await BlueThermalPrinter.instance.openSettings;
        return;
      }

      if (!mounted) return;

      showDialog(
              context: context,
              builder: (_) =>
                  const _BluetoothDeviceListDialog()) // Existing Bluetooth dialog
          .then((device) {
        if (device is BluetoothDevice) _savePrinter(device);
      });
    } else if (Platform.isWindows) {
      // Sur Windows, offrir le choix entre USB et imprimante système
      showDialog(
        context: context,
        builder: (ctx) => GlassAlertDialog(
          title: const Text('Sélectionner le type d\'imprimante'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.usb, color: AppColors.primary),
                title: const Text('Imprimante USB thermique'),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(
                      context: context,
                      builder: (_) => const _UsbDeviceListDialog()).then((p) {
                    if (p is pos_printer.PrinterDevice) _saveUsbPrinter(p);
                  });
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.print_outlined, color: AppColors.primary),
                title: const Text('Imprimante système (PDF)'),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(
                          context: context,
                          builder: (_) => const _WindowsPrinterListDialog())
                      .then((p) {
                    if (p is Printer) _saveSystemPdfPrinter(p);
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler'))
          ],
        ),
      );
    } else {
      // Other desktop platforms (Linux, macOS)
      _showSnack(
          'La sélection d\'imprimante n\'est pas encore implémentée pour cette plateforme.',
          AppColors.info);
    }
  }

  void _openCashHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CashSessionHistoryScreen()),
    );
  }

  void _openDiscountsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DiscountsScreen()),
    );
  }

  void _openUsersScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UsersScreen()),
    );
  }

  void _openAuditLogScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AuditLogScreen()),
    );
  }

  void _closeCashDrawer() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CloseCashDrawerScreen()),
    );
  }

  Future<void> _performHardReset() async {
    Navigator.pop(context);
    setState(() => _loading = true);
    try {
      await _db.close(); // 1. Fermer la connexion SQLite
      final file = await PosDatabase.getDatabaseFile();
      if (await file.exists()) {
        await file.delete(); // 2. Supprimer le fichier physique
      }

      if (!mounted) return;
      setState(() => _loading = false);

      // On informe l'utilisateur du succès avant de quitter
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => GlassAlertDialog(
          title: const Text('Wipe complet réussi'),
          content: const Text(
              'Toutes les données locales ont été supprimées. L\'application va maintenant se fermer.'),
          actions: [
            ElevatedButton(
              onPressed: () =>
                  Platform.isWindows ? exit(0) : SystemNavigator.pop(),
              child: const Text('Quitter'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showSnack('Erreur: $e', AppColors.danger);
      setState(() => _loading = false);
    }
  }

  Future<void> _performReset() async {
    Navigator.pop(context); // Fermer le premier dialog
    setState(() => _loading = true);

    try {
      await _db.transaction(() async {
        // 1. Supprimer les données transactionnelles
        await _db.delete(_db.saleItems).go();
        await _db.delete(_db.payments).go();
        await _db.delete(_db.sales).go();

        // 2. Supprimer les stocks et inventaires
        await _db.delete(_db.stockMovements).go();
        await _db.delete(_db.inventoryLines).go();
        await _db.delete(_db.inventorySessions).go();
        await _db.delete(_db.syncQueue).go();

        // 3. Supprimer les données de référence (Optionnel : gardez categories/users si voulu)
        await _db.delete(_db.products).go();
        await _db.delete(_db.customers).go();
        // await _db.delete(_db.categories).go();
      });

      if (!mounted) return;
      setState(() => _loading = false);

      await showDialog(
        context: context,
        builder: (ctx) => GlassAlertDialog(
          title: const Text('Réinitialisation terminée'),
          content: const Text(
              'Les données transactionnelles et le catalogue ont été effacés avec succès.'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _loading = false);
      _showSnack('Erreur lors de la réinitialisation : $e', AppColors.danger);
    }
  }

  Future<void> _confirmReset({bool hard = false}) async {
    // 1. SÉCURITÉ : Demander le PIN avant d'afficher le dialogue de destruction
    final bool? authorized = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PinConfirmationDialog(
        title: 'Action critique',
        message:
            'Vous êtes sur le point d\'effacer toutes les données. Entrez votre PIN administrateur.',
      ),
    );

    if (authorized != true) return;
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(hard ? 'WIPE COMPLET' : 'Réinitialiser les données'),
        content: Text(
          hard
              ? 'Le fichier de base de données sera supprimé et l\'application va se fermer. Le schéma sera recréé au prochain démarrage.'
              : 'Toutes les ventes, produits, clients et inventaires seront définitivement supprimés. Cette action est irréversible.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: hard ? _performHardReset : _performReset,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(hard ? 'WIPE & QUITTER' : 'Réinitialiser'),
          ),
        ],
      ),
    );
  }
}

// WIDGET HELPERS POUR LE CHANGEMENT DE PIN
class _NewPinDialog extends StatefulWidget {
  const _NewPinDialog();

  @override
  State<_NewPinDialog> createState() => _NewPinDialogState();
}

class _NewPinDialogState extends State<_NewPinDialog> {
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return GlassAlertDialog(
      title: const Text('Nouveau code PIN'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Choisissez un nouveau code à 4 chiffres.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 24,
                letterSpacing: 8,
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: '----',
              hintStyle: TextStyle(color: AppColors.textMuted),
              counterText: '',
              border: InputBorder.none,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _ctrl.text),
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

// ── DIALOGUE DE SÉLECTION D'IMPRIMANTE ───────────────────────

class _BluetoothDeviceListDialog extends StatefulWidget {
  const _BluetoothDeviceListDialog();

  @override
  State<_BluetoothDeviceListDialog> createState() =>
      _BluetoothDeviceListDialogState();
}

class _BluetoothDeviceListDialogState extends State<_BluetoothDeviceListDialog>
    with SingleTickerProviderStateMixin {
  List<BluetoothDevice> _devices = [];
  bool _loading = true;
  String? _error;
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _getPairedDevices();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _getPairedDevices() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    _rotationController.repeat();
    try {
      final bool? isEnabled = await BlueThermalPrinter.instance.isOn;
      if (isEnabled != true) {
        setState(() {
          _error = 'Le Bluetooth doit être activé pour lister les imprimantes.';
          _loading = false;
        });
        return;
      }
      _devices = await BlueThermalPrinter.instance.getBondedDevices();
    } catch (e) {
      _error = 'Erreur: ${e.toString()}';
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _rotationController.stop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Connecter une imprimante'),
          RotationTransition(
            turns: _rotationController,
            child: IconButton(
              icon:
                  const Icon(Icons.refresh, size: 20, color: AppColors.primary),
              onPressed: _loading ? null : _getPairedDevices,
              tooltip: 'Actualiser la liste',
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Text(_error!, style: const TextStyle(color: AppColors.danger))
                : _devices.isEmpty
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Aucune imprimante couplée trouvée.',
                            style: TextStyle(fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () =>
                                BlueThermalPrinter.instance.openSettings,
                            icon: const Icon(Icons.settings_bluetooth),
                            label: const Text('Appairer un nouvel appareil'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.info),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildDeviceList(),
                          const Divider(),
                          TextButton.icon(
                            onPressed: () =>
                                BlueThermalPrinter.instance.openSettings,
                            icon: const Icon(Icons.add),
                            label: const Text('Appairer un nouvel appareil'),
                          ),
                        ],
                      ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer')),
      ],
    );
  }

  Widget _buildDeviceList() {
    return ListView(
      shrinkWrap: true,
      children: _devices
          .map((d) => ListTile(
                leading: const Icon(Icons.print_outlined),
                title: Text(d.name ?? 'Appareil inconnu'),
                subtitle: Text(d.address ?? ''),
                onTap: () => Navigator.pop(context, d),
              ))
          .toList(),
    );
  }
}

// ── DIALOGUE DE SÉLECTION D'IMPRIMANTE (WINDOWS) ───────────────

class _WindowsPrinterListDialog extends StatefulWidget {
  const _WindowsPrinterListDialog();

  @override
  State<_WindowsPrinterListDialog> createState() =>
      __WindowsPrinterListDialogState();
}

class __WindowsPrinterListDialogState extends State<_WindowsPrinterListDialog>
    with SingleTickerProviderStateMixin {
  List<Printer> _printers = [];
  bool _loading = true;
  String? _error;
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _getSystemPrinters();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _getSystemPrinters() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    _rotationController.repeat();
    try {
      _printers = await Printing.listPrinters();
    } catch (e) {
      _error = 'Erreur: ${e.toString()}';
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _rotationController.stop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Choisir une imprimante'),
          RotationTransition(
            turns: _rotationController,
            child: IconButton(
              icon:
                  const Icon(Icons.refresh, size: 20, color: AppColors.primary),
              onPressed: _loading ? null : _getSystemPrinters,
              tooltip: 'Actualiser la liste',
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Text(_error!, style: const TextStyle(color: AppColors.danger))
                : _printers.isEmpty
                    ? const Text('Aucune imprimante installée sur ce système.',
                        style: TextStyle(fontSize: 13))
                    : ListView(
                        shrinkWrap: true,
                        children: _printers
                            .map((p) => ListTile(
                                  leading: Icon(p.isDefault
                                      ? Icons.print_rounded
                                      : Icons.print_outlined),
                                  title: Text(p.name),
                                  subtitle: Text(p.isDefault
                                      ? 'Imprimante par défaut'
                                      : p.location ?? ''),
                                  onTap: () => Navigator.pop(context, p),
                                ))
                            .toList(),
                      ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'))
      ],
    );
  }
}

// ── DIALOGUE DE SÉLECTION D'IMPRIMANTE USB (WINDOWS) ───────────────

class _UsbDeviceListDialog extends StatefulWidget {
  const _UsbDeviceListDialog();

  @override
  State<_UsbDeviceListDialog> createState() => __UsbDeviceListDialogState();
}

class __UsbDeviceListDialogState extends State<_UsbDeviceListDialog>
    with SingleTickerProviderStateMixin {
  List<pos_printer.PrinterDevice> _usbPrinters = [];
  bool _loading = true;
  String? _error;
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _getUsbPrinters();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _getUsbPrinters() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    _rotationController.repeat();
    try {
      _usbPrinters = await getIt<PrinterService>().getUsbPrinters();
    } catch (e) {
      _error = 'Erreur: ${e.toString()}';
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _rotationController.stop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Choisir une imprimante USB'),
          RotationTransition(
            turns: _rotationController,
            child: IconButton(
              icon:
                  const Icon(Icons.refresh, size: 20, color: AppColors.primary),
              onPressed: _loading ? null : _getUsbPrinters,
              tooltip: 'Actualiser la liste',
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Text(_error!, style: const TextStyle(color: AppColors.danger))
                : _usbPrinters.isEmpty
                    ? const Text('Aucune imprimante USB détectée.',
                        style: TextStyle(fontSize: 13))
                    : ListView(
                        shrinkWrap: true,
                        children: _usbPrinters
                            .map((p) => ListTile(
                                  leading: const Icon(Icons.usb),
                                  title: Text(p.name),
                                  subtitle: Text(
                                      'Vendor ID: ${p.vendorId}, Product ID: ${p.productId}'),
                                  onTap: () => Navigator.pop(context, p),
                                ))
                            .toList(),
                      ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'))
      ],
    );
  }
}
