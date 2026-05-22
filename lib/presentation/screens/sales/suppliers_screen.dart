import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/di/injection.dart';
import '../../../core/services/navigation_service.dart';
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
      appBar: AppBar(title: const Text('Gestion Fournisseurs')),
      body: FutureBuilder<String?>(
        future: _db.getSetting('shop_id'),
        builder: (context, shopSnap) {
          if (!shopSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<List<Supplier>>(
            stream: (_db.select(
              _db.suppliers,
            )..where((s) => s.shopId.equals(shopSnap.data!))).watch(),
            builder: (context, snapshot) {
              final list = snapshot.data ?? [];
              if (list.isEmpty) {
                return const EmptyState(
                  icon: Icons.business_center_outlined,
                  title: 'Aucun fournisseur',
                  subtitle: 'Ajoutez vos partenaires pour gérer vos achats.',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _SupplierCard(
                  supplier: list[index],
                  onEdit: () => _showForm(list[index]),
                  onDelete: () => _confirmDelete(list[index]),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(null),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau fournisseur'),
      ),
    );
  }

  void _showForm(Supplier? supplier) {
    showDialog(
      context: context,
      builder: (_) => _SupplierFormDialog(supplier: supplier),
    );
  }

  void _confirmDelete(Supplier supplier) async {
    final confirmed = await getIt<NavigationService>().showConfirm(
      title: 'Supprimer ?',
      content: 'Voulez-vous supprimer le fournisseur ${supplier.name} ?',
      confirmLabel: 'Supprimer',
      isDestructive: true,
    );
    if (confirmed) await _db.deleteSupplier(supplier.id);
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

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.business_rounded,
            color: AppColors.textSecondary,
            size: 24,
          ),
        ),
        title: Text(
          supplier.name,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              supplier.phone ?? supplier.email ?? 'Aucun contact',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _quickContact(
                  Icons.call_rounded,
                  'Appeler',
                  AppColors.primary,
                  () => _launch('tel:${supplier.phone}'),
                ),
                const SizedBox(width: 12),
                _quickContact(
                  Icons.mail_rounded,
                  'Email',
                  AppColors.info,
                  () => _launch('mailto:${supplier.email}'),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
          onSelected: (val) => val == 'edit' ? onEdit() : onDelete(),
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'edit', child: Text('Modifier')),
            const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
          ],
        ),
      ),
    );
  }

  Widget _quickContact(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
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
  late TextEditingController _nameCtrl, _phoneCtrl, _emailCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.supplier?.name);
    _phoneCtrl = TextEditingController(text: widget.supplier?.phone);
    _emailCtrl = TextEditingController(text: widget.supplier?.email);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.supplier == null ? 'Nouveau Fournisseur' : 'Modifier'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nom *'),
              validator: (v) => v!.isEmpty ? 'Requis' : null,
            ),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'Téléphone'),
            ),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
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

    await db.upsertSupplier(
      SuppliersCompanion(
        id: widget.supplier == null
            ? const Value.absent()
            : Value(widget.supplier!.id),
        name: Value(_nameCtrl.text),
        phone: Value(_phoneCtrl.text),
        email: Value(_emailCtrl.text),
        shopId: Value(shopId),
      ),
    );
    if (mounted) Navigator.pop(context);
  }
}
