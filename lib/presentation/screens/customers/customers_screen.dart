import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/di/injection.dart';

import '../../../data/database/pos_database.dart';
import '../../widgets/shared_widgets.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});
  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = getIt<PosDatabase>();
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.surface,
          child: Row(
            children: [
              Expanded(
                child: PosSearchBar(
                  controller: _searchCtrl,
                  hint: 'Rechercher un client...',
                  onChanged: (q) => setState(() => _query = q),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _openForm(context, null),
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Nouveau'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Customer>>(
            stream: _watchCustomers(db),
            builder: (ctx, snap) {
              final customers = snap.data ?? [];
              final filtered = _query.isEmpty
                  ? customers
                  : customers
                      .where((c) =>
                          c.name.toLowerCase().contains(_query.toLowerCase()) ||
                          (c.phone?.contains(_query) ?? false))
                      .toList();

              if (filtered.isEmpty) {
                return EmptyState(
                  icon: Icons.people_outline,
                  title: 'Aucun client',
                  subtitle: 'Ajoutez des clients pour activer la fidélité',
                  action: ElevatedButton.icon(
                    onPressed: () => _openForm(context, null),
                    icon: const Icon(Icons.person_add, size: 16),
                    label: const Text('Ajouter un client'),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (ctx, i) => _CustomerTile(
                  customer: filtered[i],
                  onEdit: () => _openForm(context, filtered[i]),
                  onDelete: () => _delete(context, filtered[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Stream<List<Customer>> _watchCustomers(PosDatabase db) {
    return (db.select(db.customers)
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .watch();
  }

  void _openForm(BuildContext ctx, Customer? customer) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (_) => _CustomerForm(
        customer: customer,
        db: getIt<PosDatabase>(),
      ),
    );
  }

  void _delete(BuildContext ctx, Customer customer) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer le client'),
        content: Text('Supprimer "${customer.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await (getIt<PosDatabase>().delete(
                    getIt<PosDatabase>().customers,
                  )..where((c) => c.id.equals(customer.id)))
                  .go();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  final Customer customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomerTile({
    required this.customer,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final initials = customer.name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                if (customer.phone != null)
                  Text(
                    customer.phone!,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge(
                label:
                    '${customer.loyaltyPoints.toStringAsFixed(0)} pts',
                color: AppColors.accent,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _iconBtn(Icons.edit_outlined, onEdit, AppColors.info),
                  _iconBtn(
                      Icons.delete_outline, onDelete, AppColors.danger),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, Color color) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: color.withValues(alpha: 0.8)),
        ),
      );
}

class _CustomerForm extends StatefulWidget {
  final Customer? customer;
  final PosDatabase db;
  const _CustomerForm({this.customer, required this.db});

  @override
  State<_CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<_CustomerForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      final c = widget.customer!;
      _nameCtrl.text = c.name;
      _phoneCtrl.text = c.phone ?? '';
      _emailCtrl.text = c.email ?? '';
      _notesCtrl.text = c.notes;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                widget.customer == null ? 'Nouveau client' : 'Modifier client',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              _field(_nameCtrl, 'Nom complet *',
                  validator: (v) =>
                      v!.isEmpty ? 'Champ requis' : null),
              const SizedBox(height: 10),
              _field(_phoneCtrl, 'Téléphone',
                  keyboard: TextInputType.phone),
              const SizedBox(height: 10),
              _field(_emailCtrl, 'Email',
                  keyboard: TextInputType.emailAddress),
              const SizedBox(height: 10),
              _field(_notesCtrl, 'Notes', maxLines: 2),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save, size: 16),
                      label: const Text('Enregistrer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    TextInputType? keyboard,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) =>
      TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final companion = CustomersCompanion(
      id: widget.customer != null
          ? Value(widget.customer!.id)
          : const Value.absent(),
      name: Value(_nameCtrl.text.trim()),
      phone: Value(
          _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text.trim()),
      email: Value(
          _emailCtrl.text.isEmpty ? null : _emailCtrl.text.trim()),
      notes: Value(_notesCtrl.text.trim()),
    );
    await widget.db.into(widget.db.customers).insertOnConflictUpdate(companion);
    if (mounted) Navigator.pop(context);
  }
}
