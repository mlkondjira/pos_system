import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/database/pos_database.dart';
import '../../../data/database/sales_dao.dart';
import '../../../data/services/printer_service.dart';
import '../../blocs/auth_bloc.dart';
import '../../widgets/shared_widgets.dart';

class CustomerDebtDetailScreen extends StatefulWidget {
  final DebtorSummary debtor;

  const CustomerDebtDetailScreen({super.key, required this.debtor});

  @override
  State<CustomerDebtDetailScreen> createState() =>
      _CustomerDebtDetailScreenState();
}

class _CustomerDebtDetailScreenState extends State<CustomerDebtDetailScreen> {
  final Set<int> _selectedSaleIds = {};
  bool _isSelectionMode = false;
  List<Sale> _currentUnpaidSales = [];

  String _refQuery = '';
  DateTimeRange? _dateRange;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = getIt<PosDatabase>();
    final allSelected =
        _currentUnpaidSales.isNotEmpty &&
        _selectedSaleIds.length == _currentUnpaidSales.length;

    return StreamBuilder<List<Sale>>(
      stream: db.salesDao.watchUnpaidSales(
        customerId: widget.debtor.customer.remoteId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _currentUnpaidSales.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final unpaidSales = snapshot.data ?? [];
        _currentUnpaidSales = unpaidSales;

        final filteredSales = _getFilteredSales();
        final liveTotalDebt = filteredSales.fold(
          0.0,
          (sum, s) => sum + s.amountDue,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(
              _isSelectionMode
                  ? '${_selectedSaleIds.length} sélectionnée(s)'
                  : 'Détail des impayés',
            ),
            actions: [
              if (_currentUnpaidSales.isNotEmpty && !_isSelectionMode)
                IconButton(
                  icon: const Icon(
                    Icons.chat_outlined,
                    color: AppColors.success,
                  ),
                  onPressed: _sendWhatsAppSummary,
                  tooltip: 'Envoyer résumé WhatsApp',
                ),
              if (_currentUnpaidSales.isNotEmpty && !_isSelectionMode)
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  onPressed: _exportDebtStatement,
                  tooltip: 'Exporter le relevé',
                ),
              if (_currentUnpaidSales.isNotEmpty)
                IconButton(
                  icon: Icon(allSelected ? Icons.deselect : Icons.select_all),
                  onPressed: _toggleSelectAll,
                  tooltip: allSelected
                      ? 'Tout désélectionner'
                      : 'Tout sélectionner',
                ),
              if (_isSelectionMode)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() {
                    _selectedSaleIds.clear();
                    _isSelectionMode = false;
                  }),
                ),
            ],
          ),
          body: Column(
            children: [
              _buildCustomerHeader(liveTotalDebt, filteredSales),
              _buildFilterBar(),
              Expanded(
                child: filteredSales.isEmpty
                    ? const EmptyState(
                        icon: Icons.check_circle_outline,
                        title: 'Dettes soldées',
                        subtitle: 'Toutes les ventes de ce client sont payées.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredSales.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final sale = filteredSales[index];
                          final isSelected = _selectedSaleIds.contains(sale.id);
                          return _UnpaidSaleCard(
                            sale: sale,
                            isSelected: isSelected,
                            isSelectionMode: _isSelectionMode,
                            onTap: () {
                              if (_isSelectionMode) {
                                _toggleSelection(sale.id);
                              } else {
                                _recordPayment(sale);
                              }
                            },
                            onLongPress: () {
                              if (!_isSelectionMode) {
                                setState(() {
                                  _isSelectionMode = true;
                                  _toggleSelection(sale.id);
                                });
                              }
                            },
                          );
                        },
                      ),
              ),
              if (_selectedSaleIds.isNotEmpty) _buildBulkPayAction(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: PosSearchBar(
                  controller: _searchCtrl,
                  hint: 'Référence (VTE...)',
                  onChanged: (v) => setState(() => _refQuery = v),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _selectDateRange,
                icon: Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: _dateRange != null
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
          if (_dateRange != null || _refQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  if (_dateRange != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(
                          '${Fmt.date(_dateRange!.start)} - ${Fmt.date(_dateRange!.end)}',
                          style: const TextStyle(fontSize: 10),
                        ),
                        onDeleted: () => setState(() => _dateRange = null),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text(
                      'Effacer tout',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Sale> _getFilteredSales() {
    return _currentUnpaidSales.where((s) {
      final matchesRef = s.ref.toLowerCase().contains(_refQuery.toLowerCase());
      bool matchesDate = true;
      if (_dateRange != null) {
        final start = DateTime(
          _dateRange!.start.year,
          _dateRange!.start.month,
          _dateRange!.start.day,
        );
        final end = DateTime(
          _dateRange!.end.year,
          _dateRange!.end.month,
          _dateRange!.end.day,
          23,
          59,
          59,
        );
        matchesDate = s.createdAt.isAfter(start) && s.createdAt.isBefore(end);
      }
      return matchesRef && matchesDate;
    }).toList();
  }

  Future<void> _exportDebtStatement() async {
    final db = getIt<PosDatabase>();
    final shopName = await db.getSetting('shop_name') ?? 'Mon Magasin';

    if (!mounted) return;
    final listToExport = _getFilteredSales();

    if (listToExport.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucune donnée à exporter avec ces filtres.'),
          ),
        );
      }
      return;
    }

    final total = listToExport.fold(0.0, (sum, s) => sum + s.amountDue);

    final introText =
        'RELEVÉ DE COMPTE (CRÉANCES)\n'
        'Client : ${widget.debtor.customer.name}\n'
        "Période : ${_dateRange != null ? '${Fmt.date(_dateRange!.start)} au ${Fmt.date(_dateRange!.end)}' : 'Toutes les créances'}\n"
        'Nombre de factures : ${listToExport.length}';

    final List<String> headers = ['Date', 'Référence', 'Reste à payer'];
    final List<List<String>> data = listToExport
        .map(
          (s) => [Fmt.dateTime(s.createdAt), s.ref, Fmt.currency(s.amountDue)],
        )
        .toList();

    data.add(['', 'TOTAL DÛ', Fmt.currency(total)]);

    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exportation du relevé'),
        content: const Text(
          'Souhaitez-vous prévisualiser ou envoyer le relevé ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'PREVIEW'),
            child: const Text('Aperçu'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'WHATSAPP_TEXT'),
            child: const Text('WhatsApp (Texte)'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'SHARE'),
            child: const Text('Partager'),
          ),
        ],
      ),
    );

    if (choice == null || !mounted) return;

    final printer = getIt<PrinterService>();
    final fileName =
        'Releve_${widget.debtor.customer.name.replaceAll(' ', '_')}';

    if (choice == 'PREVIEW') {
      await printer.previewPdfReport(
        introText: introText,
        title: fileName,
        tableHeaders: headers,
        tableData: data,
      );
    } else if (choice == 'WHATSAPP_TEXT') {
      await _sendWhatsAppSummary();
    } else {
      if (!mounted) return;
      await printer.sharePdfReport(
        fileName: fileName,
        introText: introText,
        shareMessage:
            'Bonjour ${widget.debtor.customer.name}, voici le relevé de vos impayés chez $shopName.',
        subject: 'Relevé de compte',
        tableHeaders: headers,
        tableData: data,
      );
    }
  }

  Future<void> _sendWhatsAppSummary() async {
    if (widget.debtor.customer.phone == null ||
        widget.debtor.customer.phone!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Le client n\'a pas de numéro de téléphone enregistré.',
          ),
        ),
      );
      return;
    }

    final list = _getFilteredSales();
    final total = list.fold(0.0, (sum, s) => sum + s.amountDue);
    final phone = widget.debtor.customer.phone!.replaceAll(RegExp(r'\D'), '');

    final message =
        "Bonjour ${widget.debtor.customer.name}, voici l'état de votre compte chez nous :"
        '\n\nTotal dû : ${Fmt.currency(total)}'
        '\nNombre de factures impayées : ${list.length}'
        "\nPériode : ${_dateRange != null ? '${Fmt.date(_dateRange!.start)} au ${Fmt.date(_dateRange!.end)}' : 'Toutes les créances'}."
        '\n\nMerci de régulariser votre situation dès que possible.';

    final uri = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _selectDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (range != null) {
      setState(() => _dateRange = range);
    }
  }

  void _clearFilters() {
    setState(() {
      _refQuery = '';
      _dateRange = null;
      _searchCtrl.clear();
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedSaleIds.length == _currentUnpaidSales.length) {
        _selectedSaleIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedSaleIds.addAll(_currentUnpaidSales.map((s) => s.id));
        _isSelectionMode = true;
      }
    });
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedSaleIds.contains(id)) {
        _selectedSaleIds.remove(id);
        if (_selectedSaleIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedSaleIds.add(id);
      }
    });
  }

  Widget _buildBulkPayAction() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: _recordBulkPayment,
          icon: const Icon(Icons.payments_outlined),
          label: const Text('Payer la sélection'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: AppColors.success,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerHeader(double liveTotal, List<Sale> filteredSales) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.bg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.textSecondary,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.debtor.customer.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.phone_outlined,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.debtor.customer.phone ?? 'Aucun numéro',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'RELIQUAT TOTAL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.danger,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                Fmt.currency(liveTotal),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              if (filteredSales.isNotEmpty) ...[
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () =>
                      _recordBulkPayment(specificSales: filteredSales),
                  icon: const Icon(Icons.done_all, size: 16),
                  label: const Text(
                    'Tout solder',
                    style: TextStyle(fontSize: 11),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _recordPayment(Sale sale) async {
    final db = getIt<PosDatabase>();
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;

    final controller = TextEditingController(
      text: sale.amountDue.toStringAsFixed(0),
    );
    final formKey = GlobalKey<FormState>();
    String selectedMethod = 'cash';

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Enregistrer un règlement'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Référence : ${sale.ref}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Montant versé',
                    suffixText: 'FCFA',
                  ),
                  validator: (v) {
                    final val = double.tryParse(v ?? '');
                    if (val == null || val <= 0) return 'Montant invalide';
                    if (val > sale.amountDue) return 'Dépasse le solde dû';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedMethod,
                  decoration: const InputDecoration(
                    labelText: 'Méthode de paiement',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Espèces')),
                    DropdownMenuItem(value: 'wave', child: Text('Wave')),
                    DropdownMenuItem(
                      value: 'orange_money',
                      child: Text('Orange Money'),
                    ),
                    DropdownMenuItem(
                      value: 'card',
                      child: Text('Carte bancaire'),
                    ),
                  ],
                  onChanged: (v) => setDialogState(() => selectedMethod = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
              },
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    await db.recordPayment(
      saleId: sale.id,
      paymentMethod: selectedMethod,
      amountPaid: double.parse(controller.text),
      userId: user.id,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Paiement enregistré'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _recordBulkPayment({List<Sale>? specificSales}) async {
    final db = getIt<PosDatabase>();
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;

    final salesToPay =
        specificSales ??
        _currentUnpaidSales
            .where((s) => _selectedSaleIds.contains(s.id))
            .toList();
    if (salesToPay.isEmpty) return;

    final totalToPay = salesToPay.fold(0.0, (sum, s) => sum + s.amountDue);
    final controller = TextEditingController(
      text: totalToPay.toStringAsFixed(0),
    );
    final formKey = GlobalKey<FormState>();
    String selectedMethod = 'cash';

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Règlement groupé'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${salesToPay.length} ventes sélectionnées'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Montant total reçu',
                    suffixText: 'FCFA',
                  ),
                  validator: (v) => double.tryParse(v ?? '') == null
                      ? 'Montant invalide'
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedMethod,
                  decoration: const InputDecoration(
                    labelText: 'Méthode de paiement',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Espèces')),
                    DropdownMenuItem(value: 'wave', child: Text('Wave')),
                    DropdownMenuItem(
                      value: 'orange_money',
                      child: Text('Orange Money'),
                    ),
                    DropdownMenuItem(
                      value: 'card',
                      child: Text('Carte bancaire'),
                    ),
                  ],
                  onChanged: (v) => setDialogState(() => selectedMethod = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
              },
              child: const Text('Valider'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    await db.recordBulkPayment(
      saleIds: salesToPay.map((s) => s.id).toList(),
      paymentMethod: selectedMethod,
      totalAmountPaid: double.parse(controller.text),
      userId: user.id,
    );

    if (!mounted) return;

    // Impression du reçu récapitulatif thermique
    await _printBulkPaymentTicket(
      customer: widget.debtor.customer,
      totalPaid: double.parse(controller.text),
      method: selectedMethod,
      saleRefs: salesToPay.map((s) => s.ref).toList(),
    );

    if (!mounted) return;
    setState(() {
      _selectedSaleIds.clear();
      _isSelectionMode = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Paiements groupés enregistrés'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _printBulkPaymentTicket({
    required Customer customer,
    required double totalPaid,
    required String method,
    required List<String> saleRefs,
  }) async {
    if (!mounted) return;
    final user = context.read<AuthBloc>().state.user;
    final userName = user?.name ?? 'Utilisateur';

    final text = PrinterService.buildBulkPaymentTicket(
      customer: customer,
      totalPaid: totalPaid,
      paymentMethod: method,
      saleRefs: saleRefs,
      userName: userName,
    );

    final success = await getIt<PrinterService>().printReport(text);
    if (mounted && !success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imprimante non connectée ou introuvable.'),
        ),
      );
    }
  }
}

class _UnpaidSaleCard extends StatelessWidget {
  final Sale sale;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _UnpaidSaleCard({
    required this.sale,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.04)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                ),
              ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: isSelectionMode
            ? Checkbox(
                value: isSelected,
                onChanged: (_) => onTap(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              )
            : Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
        title: Text(
          sale.ref,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          'Émise le ${Fmt.date(sale.createdAt)}',
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Fmt.currency(sale.amountDue),
              style: const TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const Text(
              'À PAYER',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
