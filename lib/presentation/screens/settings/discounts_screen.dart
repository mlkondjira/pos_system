import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../core/di/injection.dart';
import '../../../data/services/printer_service.dart'; // Chemin corrigé vers la couche data
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/database/pos_database.dart';
import 'package:intl/intl.dart';
import '../../blocs/discounts_bloc.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/sync_status_widget.dart';

class DiscountsScreen extends StatefulWidget {
  const DiscountsScreen({super.key});

  @override
  State<DiscountsScreen> createState() => _DiscountsScreenState();
}

class _DiscountsScreenState extends State<DiscountsScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'active'; // 'active', 'expired', 'archived'
  final _searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DiscountsBloc>()..add(LoadDiscounts()),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: const Text(
            'Gestion des Remises',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          actions: [
            const SyncStatusWidget(),
            BlocBuilder<DiscountsBloc, DiscountsState>(
              builder: (context, state) {
                final now = DateTime.now();
                final hasExpired = state.discounts.any(
                  (d) =>
                      !d.isArchived &&
                      d.endDate != null &&
                      now.isAfter(d.endDate!),
                );

                if (hasExpired && _selectedFilter != 'archived') {
                  return IconButton(
                    icon: const Icon(Icons.inventory_2_outlined),
                    tooltip: 'Archiver les remises expirées',
                    onPressed: () => _confirmArchiveAllExpired(context),
                  );
                }
                return Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.picture_as_pdf_outlined,
                        color: AppColors.primary,
                      ),
                      tooltip: 'Rapport mensuel',
                      onPressed: () => _generateMonthlyReport(context),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<DiscountsBloc, DiscountsState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.discounts.isEmpty) {
              return const EmptyState(
                icon: Icons.confirmation_number_outlined,
                title: 'Aucune remise configurée',
                subtitle: 'Créez des coupons pour vos campagnes marketing.',
              );
            }

            final now = DateTime.now();

            // Calcul des compteurs pour les badges
            final activeCount = state.discounts
                .where(
                  (d) =>
                      !d.isArchived &&
                      (d.endDate == null || !now.isAfter(d.endDate!)),
                )
                .length;
            final expiredCount = state.discounts
                .where(
                  (d) =>
                      !d.isArchived &&
                      d.endDate != null &&
                      now.isAfter(d.endDate!),
                )
                .length;
            final archivedCount = state.discounts
                .where((d) => d.isArchived)
                .length;

            // 1. Filtrage par statut
            var filteredDiscounts = state.discounts.where((d) {
              if (_selectedFilter == 'archived') {
                return d.isArchived;
              }
              if (d.isArchived) {
                return false; // Ne pas montrer les archivés dans les autres onglets
              }

              final bool isExpired =
                  d.endDate != null && now.isAfter(d.endDate!);
              if (_selectedFilter == 'expired') {
                return isExpired;
              }
              return !isExpired; // Par défaut: Actives
            }).toList();

            // 2. Filtrage par recherche
            if (_searchQuery.isNotEmpty) {
              filteredDiscounts = filteredDiscounts
                  .where(
                    (d) => d.name.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
                  )
                  .toList();
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: PosSearchBar(
                    controller: _searchCtrl,
                    hint: 'Chercher un coupon...',
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                _buildFilterChips(
                  active: activeCount,
                  expired: expiredCount,
                  archived: archivedCount,
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredDiscounts.length,
                    itemBuilder: (context, index) {
                      final d = filteredDiscounts[index];
                      final bool isExpired =
                          d.endDate != null && now.isAfter(d.endDate!);
                      final today = now.toIso8601String().split('T')[0];
                      final wasNotifiedToday =
                          state.notifiedDates[d.id] == today;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Opacity(
                          opacity: isExpired ? 0.5 : 1.0,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: (d.isActive && !isExpired)
                                  ? AppColors.successSoft
                                  : AppColors.bg,
                              child: Icon(
                                d.type == 'percentage'
                                    ? Icons.percent_rounded
                                    : Icons.money_rounded,
                                color: (d.isActive && !isExpired)
                                    ? AppColors.success
                                    : AppColors.textMuted,
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  d.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    decoration: isExpired
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                if (isExpired) ...[
                                  const SizedBox(width: 8),
                                  const StatusBadge(
                                    label: 'EXPIRÉ',
                                    color: AppColors.danger,
                                  ),
                                ] else if (wasNotifiedToday) ...[
                                  const SizedBox(width: 8),
                                  const Tooltip(
                                    message:
                                        'Une alerte d\'expiration a été envoyée aujourd\'hui pour cette promotion.',
                                    child: Icon(
                                      Icons.notification_important_rounded,
                                      color: AppColors.warning,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'Valeur: ${d.type == 'percentage' ? "${d.value}%" : Fmt.currency(d.value)}',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Min. achat: ${Fmt.currency(d.minAmount)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  'Usage: ${d.currentUsage}${d.usageLimit != null ? " / ${d.usageLimit}" : ""}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        (d.usageLimit != null &&
                                            d.currentUsage >= d.usageLimit!)
                                        ? AppColors.danger
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                if (d.endDate != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Expire le: ${Fmt.date(d.endDate!)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isExpired
                                            ? AppColors.danger
                                            : AppColors.textSecondary,
                                        fontWeight: isExpired
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_rounded,
                                    color: AppColors.primary,
                                  ),
                                  onPressed: () =>
                                      _showForm(context, discount: d),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.restart_alt_rounded,
                                    color: AppColors.warning,
                                  ),
                                  tooltip: 'Réinitialiser l\'usage',
                                  onPressed: () =>
                                      _confirmResetUsage(context, d),
                                ),
                                if (isExpired)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.archive_outlined,
                                      color: AppColors.textSecondary,
                                    ),
                                    tooltip: 'Archiver',
                                    onPressed: () =>
                                        _confirmArchive(context, d),
                                  ),
                                // Bouton de restauration pour les remises archivées
                                if (d.isArchived)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.unarchive_outlined,
                                      color: AppColors.success,
                                    ),
                                    tooltip: 'Restaurer',
                                    onPressed: () =>
                                        _confirmRestore(context, d),
                                  ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: AppColors.danger,
                                  ),
                                  onPressed: () => _confirmDelete(context, d),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton.extended(
            onPressed: () => _showForm(context),
            icon: const Icon(Icons.add),
            label: const Text('NOUVELLE REMISE'),
            backgroundColor: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Future<void> _generateMonthlyReport(BuildContext context) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final stats = await getIt<PosDatabase>().getCouponUsageStats(start, end);

    if (stats.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucun coupon utilisé ce mois-ci.'),
            backgroundColor: AppColors.info,
          ),
        );
      }
      return;
    }

    final monthName = DateFormat('MMMM yyyy', 'fr_FR').format(now);
    final tableData = stats
        .map(
          (s) => [
            s['code'].toString(),
            s['count'].toString(),
            Fmt.currency(s['discount'] as double),
            Fmt.currency(s['revenue'] as double),
          ],
        )
        .toList();

    await getIt<PrinterService>().sharePdfReport(
      fileName: 'Rapport_Coupons_${DateFormat('yyyyMM').format(now)}',
      introText: 'Performance des coupons de réduction - $monthName',
      shareMessage:
          'Voici le rapport d\'utilisation des coupons pour le mois de $monthName.',
      subject: 'Rapport Coupons POS - $monthName',
      tableHeaders: ['Code Coupon', 'Usage', 'Remise Totale', 'CA Généré'],
      tableData: tableData,
    );
  }

  Widget _buildFilterChips({
    required int active,
    required int expired,
    required int archived,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _filterChip(
            'active',
            'Actives',
            Icons.check_circle_outline_rounded,
            active,
          ),
          const SizedBox(width: 8),
          _filterChip('expired', 'Expirées', Icons.history_rounded, expired),
          const SizedBox(width: 8),
          _filterChip('archived', 'Archives', Icons.archive_outlined, archived),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label, IconData icon, int count) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : AppColors.textSecondary,
      ),
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedFilter = value);
      },
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  void _confirmArchiveAllExpired(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tout archiver ?'),
        content: const Text(
          'Voulez-vous déplacer toutes les remises expirées vers les archives ? Elles ne seront plus utilisables en caisse.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ANNULER'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<DiscountsBloc>().add(ArchiveAllExpiredDiscounts());
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('ARCHIVER TOUT'),
          ),
        ],
      ),
    );
  }

  void _confirmResetUsage(BuildContext context, Discount d) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Réinitialiser le compteur ?'),
        content: Text(
          'Voulez-vous remettre à zéro le nombre d\'utilisations pour "${d.name}" ?\nActuellement : ${d.currentUsage}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ANNULER'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<DiscountsBloc>().add(ResetDiscountUsage(d.id));
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('RÉINITIALISER'),
          ),
        ],
      ),
    );
  }

  void _confirmRestore(BuildContext context, Discount d) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurer la remise ?'),
        content: Text(
          'La remise "${d.name}" sera de nouveau visible et pourra être appliquée en caisse.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ANNULER'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<DiscountsBloc>().add(RestoreDiscount(d.id));
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('RESTAURER'),
          ),
        ],
      ),
    );
  }

  void _confirmArchive(BuildContext context, Discount d) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archiver la remise ?'),
        content: Text(
          'La remise "${d.name}" sera masquée de la liste et ne pourra plus être appliquée en caisse.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ANNULER'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<DiscountsBloc>().add(ArchiveDiscount(d.id));
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('ARCHIVER'),
          ),
        ],
      ),
    );
  }

  void _showForm(BuildContext context, {Discount? discount}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DiscountFormDialog(
        discount: discount,
        onSave: (companion) =>
            context.read<DiscountsBloc>().add(UpsertDiscount(companion)),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Discount d) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('Voulez-vous vraiment supprimer la remise "${d.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ANNULER'),
          ),
          TextButton(
            onPressed: () {
              context.read<DiscountsBloc>().add(DeleteDiscount(d.id));
              Navigator.pop(ctx);
            },
            child: const Text(
              'SUPPRIMER',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

class DiscountFormDialog extends StatefulWidget {
  final Discount? discount;
  final Function(DiscountsCompanion) onSave;
  const DiscountFormDialog({super.key, this.discount, required this.onSave});

  @override
  State<DiscountFormDialog> createState() => _DiscountFormDialogState();
}

class _DiscountFormDialogState extends State<DiscountFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl, _valueCtrl, _minAmountCtrl, _limitCtrl;
  late String _type;
  late bool _isActive, _limitPerCustomer;
  DateTime? _startDate, _endDate;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.discount?.name);
    _valueCtrl = TextEditingController(
      text: widget.discount?.value.toString() ?? '',
    );
    _minAmountCtrl = TextEditingController(
      text: widget.discount?.minAmount.toString() ?? '0',
    );
    _limitCtrl = TextEditingController(
      text: widget.discount?.usageLimit?.toString() ?? '',
    );
    _type = widget.discount?.type ?? 'percentage';
    _isActive = widget.discount?.isActive ?? true;
    _limitPerCustomer = widget.discount?.limitPerCustomer ?? false;
    _startDate = widget.discount?.startDate;
    _endDate = widget.discount?.endDate;
  }

  Future<void> _pickDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
      helpText: isStart ? 'Date de début de validité' : 'Date d\'expiration',
    );
    if (date != null) {
      setState(() => isStart ? _startDate = date : _endDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.discount == null ? 'Ajouter une remise' : 'Modifier la remise',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Code / Nom (ex: SOLDES10)',
                ),
                validator: (v) => v!.isEmpty ? 'Requis' : null,
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Type de calcul'),
                items: const [
                  DropdownMenuItem(
                    value: 'percentage',
                    child: Text('Pourcentage (%)'),
                  ),
                  DropdownMenuItem(value: 'fixed', child: Text('Montant Fixe')),
                ],
                onChanged: (v) => setState(() => _type = v!),
              ), // Correction: Ajout des accolades pour l'instruction `setState`
              // L'erreur était sur `setState(() => _type = v!)` qui est une seule instruction,
              // mais le linter préfère les accolades même pour une seule ligne.
              const SizedBox(height: 16),
              TextFormField(
                controller: _valueCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Valeur',
                  suffixText: _type == 'percentage' ? '%' : 'FCFA',
                ),
                validator: (v) =>
                    double.tryParse(v ?? '') == null ? 'Invalide' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _minAmountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Montant min. d\'achat',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _limitCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Limite d\'usage totale',
                  hintText: 'Ex: 50 (Laisser vide pour illimité)',
                ),
              ),
              SwitchListTile(
                title: const Text('Remise active'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                activeThumbColor: AppColors.success,
              ),
              SwitchListTile(
                title: const Text('Une seule fois par client'),
                value: _limitPerCustomer,
                onChanged: (v) => setState(() => _limitPerCustomer = v),
                activeThumbColor: AppColors.primary,
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.date_range_rounded,
                  color: AppColors.primary,
                ),
                title: const Text(
                  'Date de début',
                  style: TextStyle(fontSize: 13),
                ),
                subtitle: Text(
                  _startDate == null ? 'Immédiat' : Fmt.date(_startDate!),
                ),
                trailing: _startDate != null
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() => _startDate = null),
                      )
                    : null,
                onTap: () => _pickDate(true),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.event_busy_rounded,
                  color: AppColors.danger,
                ),
                title: const Text(
                  'Date d\'expiration',
                  style: TextStyle(fontSize: 13),
                ),
                subtitle: Text(
                  _endDate == null ? 'Jamais' : Fmt.date(_endDate!),
                ),
                trailing: _endDate != null
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() => _endDate = null),
                      )
                    : null,
                onTap: () => _pickDate(false),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ANNULER'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            final shopId = await getIt<PosDatabase>().getSetting('shop_id');
            final companion = DiscountsCompanion(
              id: widget.discount == null
                  ? const Value.absent()
                  : Value(widget.discount!.id),
              name: Value(_nameCtrl.text.trim().toUpperCase()),
              type: Value(_type),
              value: Value(double.parse(_valueCtrl.text)),
              minAmount: Value(double.tryParse(_minAmountCtrl.text) ?? 0.0),
              isActive: Value(_isActive),
              usageLimit: Value(int.tryParse(_limitCtrl.text)),
              limitPerCustomer: Value(_limitPerCustomer),
              startDate: Value(_startDate),
              endDate: Value(_endDate),
              shopId: Value(shopId),
            );
            if (!mounted) {
              return;
            }
            widget.onSave(companion);
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          child: const Text('ENREGISTRER'),
        ),
      ],
    );
  }
}
