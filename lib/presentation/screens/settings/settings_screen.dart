// lib/presentation/screens/settings/settings_screen.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../data/services/sync_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:printing/printing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/di/injection.dart';
import '../../../data/database/pos_database.dart';
import '../../blocs/cash_session_bloc.dart';
import '../../blocs/auth_bloc.dart';
import 'users_screen.dart';
import 'cash_session_history_screen.dart';
import 'audit_log_screen.dart';
import '../cash_drawer/close_cash_drawer_screen.dart';
import 'glass_alert_dialog.dart';
import '../../../data/database/pin_confirmation_dialog.dart'; // ← Import du nouveau widget

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  final _db = getIt<PosDatabase>();
  final _shopNameCtrl = TextEditingController();
  final _shopAddressCtrl = TextEditingController();
  final _shopPhoneCtrl = TextEditingController();
  final _footerCtrl = TextEditingController();
  String _printerMac = '';
  String _printerName = '';
  String _shopLogoPath = '';
  bool _loading = true;
  bool _saved = false;
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
    _shopNameCtrl.text = await _db.getSetting('shop_name') ?? '';
    _shopAddressCtrl.text = await _db.getSetting('shop_address') ?? '';
    _shopPhoneCtrl.text = await _db.getSetting('shop_phone') ?? '';
    _footerCtrl.text = await _db.getSetting('receipt_footer') ?? 'Merci de votre visite !';
    _printerMac = await _db.getSetting('printer_mac') ?? '';
    _printerName = await _db.getSetting('printer_name') ?? '';
    _shopLogoPath = await _db.getSetting('shop_logo_path') ?? '';
    setState(() => _loading = false);
    _animationController.forward();
  }

  Future<void> _save() async {
    await _db.setSetting('shop_name', _shopNameCtrl.text.trim());
    await _db.setSetting('shop_address', _shopAddressCtrl.text.trim());
    await _db.setSetting('shop_phone', _shopPhoneCtrl.text.trim());
    await _db.setSetting('receipt_footer', _footerCtrl.text.trim());
    
    // AJOUT : Synchroniser les infos du magasin avec le Cloud
    final cloudSuccess = await getIt<SyncService>().registerShop(
      name: _shopNameCtrl.text.trim(),
      address: _shopAddressCtrl.text.trim(),
    );

    setState(() => _saved = true);
    
    if (!cloudSuccess && mounted) {
      _showSnack('Sauvegarde locale OK. Cloud indisponible (vérifiez votre connexion).', AppColors.warning);
    }

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _saved = false);
  }

  Future<void> _savePrinter(BluetoothDevice device) async {
    await _db.setSetting('printer_mac', device.address);
    await _db.setSetting('printer_name', device.name ?? '');
    setState(() {
      _printerMac = device.address;
      _printerName = device.name ?? '';
    });
    _showSnack(
        'Imprimante "${device.name ?? device.address}" connectée', AppColors.success);
  }

  Future<void> _saveWindowsPrinter(Printer printer) async {
    await _db.setSetting('printer_name', printer.name);
    // L'adresse MAC n'est pas pertinente pour les imprimantes système
    await _db.setSetting('printer_mac', '');
    setState(() {
      _printerName = printer.name;
      _printerMac = '';
    });
    _showSnack('Imprimante par défaut définie sur "${printer.name}"', AppColors.success);
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
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 400);
      if (image == null) return;

      final directory = await getApplicationDocumentsDirectory();
      final String path = p.join(directory.path, 'assets');
      final Directory dir = Directory(path);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final String fileName = 'shop_logo${p.extension(image.path)}';
      final String newPath = p.join(path, fileName);

      final File savedImage = await File(image.path).copy(newPath);

      final oldPath = _shopLogoPath;
      if (oldPath.isNotEmpty && oldPath != savedImage.path) {
        final oldFile = File(oldPath);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      }

      await _db.setSetting('shop_logo_path', savedImage.path);
      setState(() => _shopLogoPath = savedImage.path);
      _showSnack('Logo mis à jour', AppColors.success);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Erreur lors de la sélection du logo: $e', AppColors.danger);
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

      _showSnack('$deletedCount images orphelines supprimées', AppColors.success);
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
        if (value.contains(';') || value.contains('"') || value.contains('\n')) {
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
      final filteredSales = await _db.salesDao.getSalesForPeriod(range.start, range.end);

      if (filteredSales.isEmpty) {
        _showSnack('Aucune vente trouvée pour cette période', AppColors.warning);
        return;
      }

      List<List<dynamic>> rows = [];
      rows.add(['Date', 'Référence', 'Articles', 'Total HT', 'TVA', 'Total TTC', 'Remise', 'Statut', 'Note']);

      for (final s in filteredSales) {
        final items = await _db.salesDao.getSaleItems(s.id);
        final itemsSummary = items.map((i) => '${i.quantity}x ${i.productName}').join(', ');

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

      // CORRECTION : nouvelle API SharePlus (share_plus v10+)
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
              const Text(
                'Entrez un mot de passe pour chiffrer le fichier (recommandé).',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Mot de passe',
                  hintText: 'Laisser vide pour ne pas chiffrer',
                  prefixIcon: Icon(Icons.lock_outline, color: Colors.white70),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
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
            'Le fichier exporté sera lisible par n\'importe qui.\nÊtes-vous sûr de vouloir continuer sans chiffrement ?',
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
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
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
        final iv = enc.IV.fromSecureRandom(16); // Vecteur d'initialisation aléatoire
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
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Minimum 6 caractères',
                prefixIcon: Icon(Icons.lock_outline, color: Colors.white70),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, ctrl.text),
                child: const Text('Valider'),
              ),
            ],
          );
        },
      );

      if (newPassword != null && newPassword.length >= 6) {
        try {
          setState(() => _loading = true);
          await Supabase.instance.client.auth.updateUser(UserAttributes(password: newPassword));
          
          if (!mounted) return;

          // Afficher un dialogue informant de la déconnexion
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => GlassAlertDialog(
              title: const Text('Mot de passe modifié'),
              content: const Text('Pour des raisons de sécurité, vous allez être déconnecté. Veuillez vous reconnecter avec votre nouveau mot de passe.'),
              actions: [
                ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Compris')),
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
        _showSnack('Le mot de passe est trop court', AppColors.warning);
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
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── SÉCURITÉ : Vérification du rôle administrateur ─────────────
    // Cette protection agit comme un pare-feu supplémentaire au cas où
    // la logique de navigation dans main.dart échouerait.
    final user = context.watch<AuthBloc>().state.user;
    // Correction : Autoriser aussi le propriétaire ('owner') à accéder aux paramètres
    final isAllowed = user == null || user.role == 'admin' || user.role == 'owner';
    if (!isAllowed) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 48, color: AppColors.textMuted),
            SizedBox(height: 16),
            Text('Accès réservé aux administrateurs', style: TextStyle(color: AppColors.textMuted)),
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
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryLight));
    }

    final List<Widget> children = [
      // NOUVEAU : Affichage de l'alerte de sécurité si nécessaire
      if (isUsingDefaultPin) _defaultPinWarning(),
      _section('Informations du magasin', [
        _logoPicker(),
        _inputField(_shopNameCtrl, 'Nom du magasin', Icons.store_outlined),
        _inputField(_shopAddressCtrl, 'Adresse', Icons.location_on_outlined),
        _inputField(_shopPhoneCtrl, 'Téléphone', Icons.phone_outlined,
            keyboard: TextInputType.phone),
      ]),
      _section('Reçu thermique', [
        _inputField(_footerCtrl, 'Message de pied de reçu',
            Icons.receipt_outlined,
            maxLines: 2),
        _staticRow('Largeur papier', '80 mm'),
      ]),
      _section('Sécurité', [
        // AJOUT DU BOUTON MODIFIER ACCÈS
        _actionRow('Modifier mes accès (PIN/Mdp)',
            Icons.lock_reset, AppColors.accent, _changeCredentials),
        _actionRow('Gérer les utilisateurs',
            Icons.manage_accounts_outlined, AppColors.primaryLight, _openUsersScreen),
        _actionRow('Journal d\'audit',
            Icons.policy_outlined, AppColors.primaryLight, _openAuditLogScreen),
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
      _section('Rapports', [
        _actionRow('Historique des caisses',
            Icons.history_rounded, AppColors.info, _openCashHistory),
      ]),
      _section('Imprimante', [
        _printerRow(),
      ]),
      _section('Fiscalité & Devise', [
        _staticRow('Devise', 'FCFA'),
        _staticRow('TVA par défaut', '0% (configurable par produit)'),
      ]),
      _section('Données', [
        _actionRow(
          'Forcer la synchronisation',
          Icons.sync_rounded,
          AppColors.info,
          () {
            getIt<SyncService>().syncPending();
            _showSnack('Synchronisation manuelle lancée...', AppColors.info);
          }),
        _actionRow('Exporter ventes (CSV)',
            Icons.download_outlined, AppColors.info, _exportSalesToCSV),
        _actionRow('Sauvegarder la base',
            Icons.shield_outlined, AppColors.warning, _backupDatabase),
        _actionRow('Nettoyer le stockage (images)',
            Icons.cleaning_services_outlined, AppColors.warning, _cleanupImages),
        _actionRow('Réinitialiser les données',
            Icons.delete_forever_outlined, AppColors.danger, _confirmReset),
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
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: Colors.transparent,
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: children.length,
        itemBuilder: (context, index) {
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
      ),
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
          borderRadius: BorderRadius.circular(14),
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
                  const Text('Faille de sécurité critique', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    'Votre compte utilise le code PIN par défaut "0000". Veuillez le changer immédiatement dans "Gérer les utilisateurs".',
                    style: TextStyle(color: Colors.white.withValues(alpha: 230), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 14, color: Colors.white.withValues(alpha: 179)),
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
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            )),
      ),
      Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard, // ← CORRECTION (Glass effect)
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5), // Bordure blanche
        ),
        child: Column(
          children: children.expand((w) {
            final isLast = w == children.last;
            return [
              w,
              if (!isLast) 
                Divider(height: 1, color: AppColors.border.withValues(alpha: 0.5), indent: 16),
            ];
          }).toList(),
        ),
      ),
    ]);
  }

  Widget _logoPicker() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _pickLogo,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: _shopLogoPath.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(File(_shopLogoPath), fit: BoxFit.contain),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, color: AppColors.textMuted),
                          SizedBox(height: 4),
                          Text('Logo', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
              ),
            ],
          ),
        ),
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
        Icon(icon, color: Colors.white70, size: 17),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: ctrl,
            keyboardType: keyboard,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              labelText: label,
              labelStyle:
                  const TextStyle(color: Colors.white70, fontSize: 12),
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
            style: const TextStyle(color: Colors.white, fontSize: 14)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
      ]),
    );
  }

  Widget _printerRow() {
    // ── PROTECTION WINDOWS ───────────────────────────────────
    // Sur Windows, on n'utilise pas le plugin Bluetooth Serial (qui ferait planter).
    // On affiche juste un message informatif.
    if (!Platform.isAndroid) {
      return InkWell(
        onTap: _connectPrinter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(children: [
            const Icon(Icons.print_outlined, color: AppColors.textMuted, size: 17),
            const SizedBox(width: 10),
            Expanded(
              child: Text(_printerName.isEmpty ? 'Choisir une imprimante système' : 'Imprimante : $_printerName',
                  style: TextStyle(color: _printerName.isEmpty ? Colors.white70 : Colors.white, fontSize: 14))),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ]),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        const Icon(Icons.print_outlined, color: AppColors.textMuted, size: 17),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Imprimante Bluetooth',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9), fontSize: 14)),
                Text(
                  _printerMac.isEmpty
                      ? 'Aucune imprimante configurée'
                      : _printerName.isNotEmpty
                          ? '$_printerName ($_printerMac)'
                          : _printerMac,
                  style: TextStyle(
                    color: _printerMac.isEmpty ? Colors.white70 : AppColors.success,
                    fontSize: 11,
                  ),
                ),
              ]),
        ),
        OutlinedButton.icon(
          onPressed: _connectPrinter,
          icon: const Icon(Icons.bluetooth_searching, size: 14),
          label: Text(_printerMac.isEmpty ? 'Connecter' : 'Modifier'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.info,
            side: const BorderSide(color: AppColors.info, width: 0.8),
            textStyle: const TextStyle(fontSize: 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          ),
        ),
      ]),
    );
  }

  Widget _actionRow(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ]),
        ),
      ),
    );
  }

  void _connectPrinter() {
    if (Platform.isAndroid) {
      showDialog(
          context: context, builder: (_) => const _BluetoothDeviceListDialog())
          .then((device) {
        if (device is BluetoothDevice) _savePrinter(device);
      });
    } else {
      // Sur Windows, on affiche la liste des imprimantes système
      showDialog(context: context, builder: (_) => const _WindowsPrinterListDialog())
          .then((printer) {
        if (printer is Printer) _saveWindowsPrinter(printer);
      });
    }
  }

  void _openCashHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CashSessionHistoryScreen()),
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

      _showSnack('Données réinitialisées avec succès', AppColors.success);
    } catch (e) {
      _showSnack('Erreur lors de la réinitialisation : $e', AppColors.danger);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _confirmReset() async {
    // 1. SÉCURITÉ : Demander le PIN avant d'afficher le dialogue de destruction
    final bool? authorized = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PinConfirmationDialog(
        title: 'Action critique',
        message: 'Vous êtes sur le point d\'effacer toutes les données. Entrez votre PIN administrateur.',
      ),
    );

    if (authorized != true) return;
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Réinitialiser les données'),
        content: const Text(
          'Toutes les ventes, produits, clients et inventaires seront définitivement supprimés. Cette action est irréversible.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: _performReset, // Appel de la vraie fonction
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Réinitialiser'),
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
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: '----',
              hintStyle: TextStyle(color: Colors.white24),
              counterText: '',
              border: InputBorder.none,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
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

class _BluetoothDeviceListDialogState
    extends State<_BluetoothDeviceListDialog> {
  List<BluetoothDevice> _devices = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _getPairedDevices();
  }

  Future<void> _getPairedDevices() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      bool? isEnabled = await FlutterBluetoothSerial.instance.isEnabled;
      if (isEnabled != true) {
        setState(() {
          _error = 'Veuillez activer le Bluetooth.';
          _loading = false;
        });
        return;
      }
      _devices = await FlutterBluetoothSerial.instance.getBondedDevices();
    } catch (e) {
      _error = 'Erreur: ${e.toString()}';
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Connecter une imprimante'),
      content: SizedBox(
        width: double.maxFinite,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Text(_error!, style: const TextStyle(color: AppColors.danger))
                : _devices.isEmpty
                    ? const Text(
                        'Aucune imprimante couplée trouvée. Veuillez appairer votre imprimante dans les paramètres Bluetooth de l\'appareil.',
                        style: TextStyle(fontSize: 13),
                      )
                    : _buildDeviceList(),
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
                subtitle: Text(d.address),
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
  State<_WindowsPrinterListDialog> createState() => __WindowsPrinterListDialogState();
}

class __WindowsPrinterListDialogState extends State<_WindowsPrinterListDialog> {
  List<Printer> _printers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _getSystemPrinters();
  }

  Future<void> _getSystemPrinters() async {
    setState(() => _loading = true);
    try {
      _printers = await Printing.listPrinters();
    } catch (e) {
      _error = 'Erreur: ${e.toString()}';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choisir une imprimante'),
      content: SizedBox(
        width: double.maxFinite,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Text(_error!, style: const TextStyle(color: AppColors.danger))
                : _printers.isEmpty
                    ? const Text('Aucune imprimante installée sur ce système.', style: TextStyle(fontSize: 13))
                    : ListView(
                        shrinkWrap: true,
                        children: _printers.map((p) => ListTile(
                          leading: Icon(p.isDefault ? Icons.print_rounded : Icons.print_outlined),
                          title: Text(p.name),
                          subtitle: Text(p.isDefault ? 'Imprimante par défaut' : p.location ?? ''),
                          onTap: () => Navigator.pop(context, p),
                        )).toList(),
                      ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer'))],
    );
  }
}