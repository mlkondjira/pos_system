import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/database/pos_database.dart';
import '../settings/glass_alert_dialog.dart';
import '../../widgets/shared_widgets.dart';

class DeclareLossDialog extends StatefulWidget {
  final Product product;
  const DeclareLossDialog({super.key, required this.product});

  @override
  State<DeclareLossDialog> createState() => _DeclareLossDialogState();
}

class _DeclareLossDialogState extends State<DeclareLossDialog> {
  final _qtyCtrl = TextEditingController(text: '1');
  final _notesCtrl = TextEditingController();
  String _type = 'defective';
  String? _justificationPath;
  final ImagePicker _picker = ImagePicker();

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        imageQuality: 70,
      );
      if (photo != null) {
        final directory = await getApplicationDocumentsDirectory();
        final String path = p.join(directory.path, 'justifications');
        await Directory(path).create(recursive: true);
        final String fileName = 'loss_${DateTime.now().millisecondsSinceEpoch}${p.extension(photo.path)}';
        final File savedImage = await File(photo.path).copy(p.join(path, fileName));
        setState(() => _justificationPath = savedImage.path);
      }
    } catch (e) {
      debugPrint('Erreur capture justification: $e');
    }
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassAlertDialog(
      title: Row(
        children: [
          ProductImage(imagePath: widget.product.imagePath, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Déclarer une perte : ${widget.product.name}',
              textAlign: TextAlign.start,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Sélectionnez le motif et la quantité à retirer du stock marchandisable.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          TextFormField(
            initialValue: Fmt.currency(widget.product.priceHt),
            readOnly: true,
            enabled: false,
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              labelText: 'Prix de vente actuel',
              prefixIcon: Icon(Icons.sell_outlined),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _type,
            dropdownColor: AppColors.card,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'Motif de la perte'),
            items: const [
              DropdownMenuItem(value: 'defective', child: Text('Endommagé / Défectueux')),
              DropdownMenuItem(value: 'expired', child: Text('Périmé')),
              DropdownMenuItem(value: 'obsolete', child: Text('Obsolète / Invendable')),
            ],
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _qtyCtrl,
            onChanged: (_) => setState(() {}), // Force le rafraîchissement pour recalculer le total
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Quantité à déduire',
              suffixText: widget.product.unit,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Notes additionnelles',
              hintText: 'Ex: Rayon B, casse transport...',
            ),
          ),
          const SizedBox(height: 16),
          // --- SECTION PHOTO JUSTIFICATIVE ---
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: Text(_justificationPath == null ? 'Prendre une photo' : 'Changer la photo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                ),
              ),
              if (_justificationPath != null) ...[
                const SizedBox(width: 12),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(_justificationPath!), width: 42, height: 42, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: -8, right: -8,
                      child: GestureDetector(
                        onTap: () => setState(() => _justificationPath = null),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          // --- RÉSUMÉ FINANCIER DE LA PERTE ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.dangerSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('VALEUR TOTALE :', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5)),
                Text(
                  Fmt.currency((int.tryParse(_qtyCtrl.text) ?? 0) * widget.product.priceHt),
                  style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () {
            final q = int.tryParse(_qtyCtrl.text) ?? 0;
            if (q <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Quantité invalide')),
              );
              return;
            }
            Navigator.pop(context, (
              qty: q, 
              type: _type, 
              notes: _notesCtrl.text.trim(),
              imagePath: _justificationPath
            ));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirmer la perte'),
        ),
      ],
    );
  }
}