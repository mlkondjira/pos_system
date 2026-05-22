import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/database/pos_database.dart';
import '../../../data/database/sales_dao.dart';
import '../settings/glass_alert_dialog.dart';

enum CustomerSortMode { name, debt }

class CustomerSelectionScreen extends StatefulWidget {
  const CustomerSelectionScreen({super.key});

  @override
  State<CustomerSelectionScreen> createState() => _CustomerSelectionScreenState();
}

class _CustomerSelectionScreenState extends State<CustomerSelectionScreen> {
  final _db = getIt<PosDatabase>();
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _showOnlyDebtors = false;
  CustomerSortMode _sortMode = CustomerSortMode.debt;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _addCustomer() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    final Customer? newCustomer = await showDialog<Customer>(
      context: context,
      builder: (ctx) => GlassAlertDialog(
        title: const Text('Nouveau Client'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                prefixIcon: Icon(Icons.person_outline, color: Colors.white70),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                prefixIcon: Icon(Icons.phone_outlined, color: Colors.white70),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final shopId = await _db.getSetting('shop_id');
              
              final id = await _db.into(_db.customers).insert(
                CustomersCompanion.insert(
                  name: nameCtrl.text.trim(),
                  phone: Value(phoneCtrl.text.trim()),
                  shopId: Value(shopId),
                ),
              );
              
              final created = await (_db.select(_db.customers)..where((c) => c.id.equals(id))).getSingle();
              
              // Enclenche la synchronisation cloud
              await _db.enqueue(entityType: 'customer', entityId: id, payload: created.toJson());
              
              if (ctx.mounted) Navigator.pop(ctx, created);
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );

    if (newCustomer != null && mounted) {
      Navigator.pop(context, newCustomer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Sélectionner un client'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: _addCustomer,
            tooltip: 'Ajouter un client',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Rechercher par nom ou téléphone...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isNotEmpty 
                      ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        })
                      : null,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Dettes uniquement'),
                      selected: _showOnlyDebtors,
                      onSelected: (v) => setState(() => _showOnlyDebtors = v),
                      selectedColor: AppColors.danger.withValues(alpha: 0.1),
                      checkmarkColor: AppColors.danger,
                      labelStyle: TextStyle(
                        color: _showOnlyDebtors ? AppColors.danger : AppColors.textSecondary,
                        fontWeight: _showOnlyDebtors ? FontWeight.bold : FontWeight.normal,
                        fontSize: 11,
                      ),
                    ),
                    ChoiceChip(
                      label: const Text('Trier par Nom'),
                      selected: _sortMode == CustomerSortMode.name,
                      onSelected: (v) => v ? setState(() => _sortMode = CustomerSortMode.name) : null,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        color: _sortMode == CustomerSortMode.name ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                    ChoiceChip(
                      label: const Text('Trier par Dette'),
                      selected: _sortMode == CustomerSortMode.debt,
                      onSelected: (v) => v ? setState(() => _sortMode = CustomerSortMode.debt) : null,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        color: _sortMode == CustomerSortMode.debt ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<DebtorSummary>>(
              stream: _db.salesDao.watchAllCustomersWithDebt(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final debtors = snapshot.data!.where((d) {
                  final matchesQuery = _query.isEmpty || 
                      d.customer.name.toLowerCase().contains(_query) || 
                      (d.customer.phone?.contains(_query) ?? false);
                  
                  final matchesDebt = !_showOnlyDebtors || d.totalDebt > 0;
                  
                  return matchesQuery && matchesDebt;
                }).toList()
                  ..sort((a, b) {
                    if (_sortMode == CustomerSortMode.debt) {
                      final int debtComparison = b.totalDebt.compareTo(a.totalDebt);
                      if (debtComparison != 0) return debtComparison;
                    }
                    return a.customer.name.toLowerCase().compareTo(b.customer.name.toLowerCase());
                  });

                if (debtors.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_outline, size: 64, color: AppColors.textMuted),
                        const SizedBox(height: 16),
                        Text(
                          _query.isEmpty ? 'Aucun client enregistré' : 'Aucun résultat pour "$_query"',
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _addCustomer,
                          icon: const Icon(Icons.add),
                          label: const Text('Créer ce client'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: debtors.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (context, index) {
                    final debtor = debtors[index];
                    final customer = debtor.customer;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          customer.name[0].toUpperCase(),
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        customer.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      subtitle: customer.phone != null && customer.phone!.isNotEmpty
                        ? Text(customer.phone!, style: const TextStyle(color: AppColors.textSecondary))
                        : const Text('Pas de téléphone', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (debtor.totalDebt > 0)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                Fmt.currency(debtor.totalDebt),
                                style: const TextStyle(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          const Icon(Icons.chevron_right, color: AppColors.textMuted),
                        ],
                      ),
                      onTap: () => Navigator.pop(context, customer),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}