import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/database/pos_database.dart';
import '../../blocs/auth_bloc.dart';
import '../../widgets/shared_widgets.dart';

class StockCheckScreen extends StatefulWidget {
  const StockCheckScreen({super.key});

  @override
  State<StockCheckScreen> createState() => _StockCheckScreenState();
}

class _StockCheckScreenState extends State<StockCheckScreen> {
  final _db = getIt<PosDatabase>();
  bool _isProcessing = false;
  final _focusNode = FocusNode();
  String _barcodeBuffer = '';

  void _handleKeyEvent(KeyEvent event) {
    // On ignore le scan si un champ texte est déjà utilisé (EditableText)
    if (FocusManager.instance.primaryFocus?.context?.widget is EditableText) return;

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_barcodeBuffer.isNotEmpty) {
          _handleBarcode(_barcodeBuffer);
          _barcodeBuffer = '';
        }
      } else if (event.character != null) {
        _barcodeBuffer += event.character!;
      }
    }
  }

  Future<void> _handleBarcode(String barcode) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final product = await _db.getProductByBarcode(barcode);
    final inventoryLine = product != null ? await _db.getActiveInventoryLine(product.id) : null;

    if (!mounted) return;

    if (product != null) {
      // Affichage du résultat dans une feuille modale
      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  ProductImage(imagePath: product.imagePath, size: 64),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Code: ${product.barcode ?? "N/A"}', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Prix de vente', style: TextStyle(fontSize: 16)),
                  Text(
                    Fmt.currency(product.priceHt),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Quantité en stock', style: TextStyle(fontSize: 16)),
                  Text(
                    '${product.stockQty} ${product.unit}',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: product.stockQty <= product.stockAlert ? AppColors.danger : AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final user = context.read<AuthBloc>().state.user;
                        if (user != null) {
                          await _db.recordLoss(productId: product.id, quantity: 1, type: 'defective', userId: user.id);
                          if (context.mounted) {
                            Navigator.pop(context);
                            _showSnack('1 unité défectueuse retirée du stock', AppColors.success);
                          }
                        }
                      },
                      icon: const Icon(Icons.broken_image_outlined, color: Colors.white),
                      label: const Text('Défectueux (-1)', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showLossDialog(product);
                      },
                      icon: const Icon(Icons.report_problem_outlined, color: AppColors.warning),
                      label: const Text('Autre problème', style: TextStyle(color: AppColors.textSecondary)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (inventoryLine != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showInventoryCountDialog(inventoryLine);
                    },
                    icon: const Icon(Icons.edit_note_rounded),
                    label: const Text('Saisir comptage Inventaire'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scanner le suivant'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Produit inconnu : $barcode'), backgroundColor: AppColors.warning),
      );
      await Future.delayed(const Duration(seconds: 1));
    }

    if (mounted) {
      setState(() => _isProcessing = false);
      // Récupère le focus pour le prochain scan physique
      _focusNode.requestFocus();
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
    ));
  }

  Future<void> _showLossDialog(Product product) async {
    final qtyCtrl = TextEditingController(text: '1');
    String lossType = 'defective';
    final user = context.read<AuthBloc>().state.user;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Déclarer une perte'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Produit : ${product.name}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 16),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantité à retirer'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: lossType,
                decoration: const InputDecoration(labelText: 'Raison'),
                items: const [
                  DropdownMenuItem(value: 'defective', child: Text('Défectueux / Cassé')),
                  DropdownMenuItem(value: 'obsolete', child: Text('Obsolète / Invendable')),
                  DropdownMenuItem(value: 'expired', child: Text('Périmé')),
                ],
                onChanged: (v) => setDialogState(() => lossType = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                final qty = int.tryParse(qtyCtrl.text) ?? 0;
                if (qty > 0 && user != null) {
                  await _db.recordLoss(
                    productId: product.id,
                    quantity: qty,
                    type: lossType,
                    userId: user.id,
                  );
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Stock ajusté'), backgroundColor: AppColors.success),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showInventoryCountDialog(InventoryLine line) async {
    final totalCtrl = TextEditingController(text: '${line.countedQty ?? ""}');
    final defectiveCtrl = TextEditingController(text: '${line.defectiveQty}');
    final obsoleteCtrl = TextEditingController(text: '${line.obsoleteQty}');
    final expiredCtrl = TextEditingController(text: '${line.expiredQty}');
    final notesCtrl = TextEditingController(text: line.notes);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Inventaire : ${line.productName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: totalCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Total physique compté', hintText: 'Ex: 10'),
              ),
              const SizedBox(height: 16),
              const SectionLabel('Détails des invendables (inclus dans le total)'),
              const SizedBox(height: 8),
              TextField(
                controller: defectiveCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Défectueux / Cassé', prefixIcon: Icon(Icons.broken_image_outlined)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: obsoleteCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Obsolète / Invendable', prefixIcon: Icon(Icons.history_toggle_off)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: expiredCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Périmé', prefixIcon: Icon(Icons.event_busy_outlined)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Notes particulières'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              final total = int.tryParse(totalCtrl.text) ?? 0;
              final defective = int.tryParse(defectiveCtrl.text) ?? 0;
              final obsolete = int.tryParse(obsoleteCtrl.text) ?? 0;
              final expired = int.tryParse(expiredCtrl.text) ?? 0;

              await _db.updateInventoryLine(
                lineId: line.id,
                countedQty: total,
                defectiveQty: defective,
                obsoleteQty: obsolete,
                expiredQty: expired,
                notes: notesCtrl.text.trim(),
              );

              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Ligne d\'inventaire mise à jour'), backgroundColor: AppColors.success),
                );
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        appBar: AppBar(title: const Text('Vérificateur de Stock')),
        body: Stack(
          children: [
            // Caméra : Uniquement pour les mobiles
            if (!isDesktop)
              MobileScanner(
                onDetect: (capture) {
                  final barcode = capture.barcodes.firstOrNull?.rawValue;
                  if (barcode != null && !_isProcessing) {
                    _handleBarcode(barcode);
                  }
                },
              ),
            
            // Interface Desktop : Prise en charge des lecteurs HID (USB/Bluetooth)
            if (isDesktop)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.qr_code_scanner_rounded, size: 64, color: AppColors.primary),
                    ),
                    const SizedBox(height: 24),
                    const Text('Lecteur physique prêt', 
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    const Text('Scannez un produit avec votre douchette USB ou Bluetooth.', 
                      style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}