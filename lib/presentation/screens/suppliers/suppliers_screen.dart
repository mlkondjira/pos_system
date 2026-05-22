import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/pos_database.dart';
import '../../widgets/shared_widgets.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final _db = getIt<PosDatabase>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(),
      body: FutureBuilder<String?>(
        future: _db.getSetting('shop_id'),
        builder: (context, shopSnap) {
          if (!shopSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final shopId = shopSnap.data!;

          return StreamBuilder<List<Supplier>>(
            stream: (_db.select(
              _db.suppliers,
            )..where((s) => s.shopId.equals(shopId))).watch(),
            builder: (context, snapshot) {
              final list = snapshot.data ?? [];
              if (list.isEmpty) {
                return const EmptyState(
                  icon: Icons.business_center_outlined,
                  title: 'Aucun fournisseur',
                  subtitle:
                      'Ajoutez vos partenaires pour gérer vos achats et réapprovisionnements.',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _SupplierCard(
                  supplier: list[index],
                  onEdit: () => _showForm(context, list[index]),
                  onDelete: () => _confirmDelete(context, list[index]),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau fournisseur'),
      ),
    );
  }

  void _showForm(BuildContext context, Supplier? supplier) {
    showDialog(
      context: context,
      builder: (_) => _SupplierFormDialog(supplier: supplier),
    );
  }

  void _confirmDelete(BuildContext context, Supplier supplier) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le fournisseur ?'),
        content: Text(
          'Voulez-vous vraiment supprimer ${supplier.name} ?\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _db.deleteSupplier(supplier.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fournisseur supprimé avec succès'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression : $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }
}

class _SupplierCard extends StatelessWidget {
  final Supplier supplier;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SupplierCard({
    required this.supplier,
    required this.onEdit,
    required this.onDelete,
  });

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber.replaceAll(RegExp(r'\s+'), ''),
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _sendWhatsApp(String phoneNumber) async {
    // Nettoyage pour ne garder que les chiffres (format requis par wa.me : 22177...)
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final Uri whatsappUri = Uri.parse('https://wa.me/$cleanNumber');

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: const Icon(Icons.business, color: AppColors.primary, size: 20),
        ),
        title: Text(
          supplier.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              supplier.phone ?? supplier.email ?? 'Aucun contact enregistré',
            ),
            if (supplier.address != null && supplier.address!.isNotEmpty)
              Text(
                supplier.address!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (supplier.phone != null && supplier.phone!.isNotEmpty)
              IconButton(
                icon: const Icon(
                  Icons.phone_forwarded_outlined,
                  color: AppColors.success,
                  size: 20,
                ),
                onPressed: () => _makeCall(supplier.phone!),
                tooltip: 'Appeler le fournisseur',
              ),
            if (supplier.phone != null && supplier.phone!.isNotEmpty)
              IconButton(
                icon: const Icon(
                  Icons.chat_outlined,
                  color: AppColors.accent,
                  size: 20,
                ),
                onPressed: () => _sendWhatsApp(supplier.phone!),
                tooltip: 'Envoyer un message WhatsApp',
              ),
            PopupMenuButton<String>(
              onSelected: (val) => val == 'edit' ? onEdit() : onDelete(),
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Supprimer',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SupplierFormDialog extends StatefulWidget {
  final Supplier? supplier;
  const _SupplierFormDialog({this.supplier});

  @override
  State<_SupplierFormDialog> createState() => _SupplierFormDialogState();
}

class _SupplierFormDialogState extends State<_SupplierFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl,
      _phoneCtrl,
      _emailCtrl,
      _addressCtrl,
      _notesCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.supplier?.name);
    _phoneCtrl = TextEditingController(text: widget.supplier?.phone);
    _emailCtrl = TextEditingController(text: widget.supplier?.email);
    _addressCtrl = TextEditingController(text: widget.supplier?.address);
    _notesCtrl = TextEditingController(text: widget.supplier?.notes);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.supplier == null
            ? 'Nouveau Fournisseur'
            : 'Modifier le Fournisseur',
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom de l\'entreprise *',
              ),
              validator: (v) => v!.isEmpty ? 'Requis' : null,
            ), // Ligne 167
            const SizedBox(height: 12), // Ligne 168
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'Téléphone'),
              keyboardType: TextInputType.phone,
            ), // Ligne 169
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(labelText: 'Adresse'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Enregistrer')),
      ],
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    final db = getIt<PosDatabase>();
    final shopId = await db.getSetting('shop_id') ?? '';

    try {
      await db.upsertSupplier(
        SuppliersCompanion(
          id: widget.supplier == null
              ? const Value.absent()
              : Value(widget.supplier!.id),
          name: Value(_nameCtrl.text.trim()),
          phone: Value(_phoneCtrl.text.trim()),
          email: Value(_emailCtrl.text.trim()),
          address: Value(_addressCtrl.text.trim()),
          notes: Value(_notesCtrl.text.trim()),
          shopId: Value(shopId),
        ),
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'enregistrement : $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}
