// lib/presentation/screens/caisse/payment_dialog.dart
import 'dart:ui';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/database/pos_database.dart';
import '../../../data/services/printer_service.dart';
import '../../blocs/auth_bloc.dart';
import '../../blocs/cart_bloc.dart';
import '../customers/customer_selection_screen.dart'; // Vous devrez créer cet écran
import '../../blocs/cash_session_bloc.dart';

class PaymentDialog extends StatefulWidget {
  final CartState cart;
  final PosDatabase db;
  final VoidCallback? onCancel;
  final bool isEmbedded;

  const PaymentDialog({
    super.key,
    required this.cart,
    required this.db,
    this.onCancel,
    this.isEmbedded = false,
  });
  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  String _method = 'cash';
  final _amountCtrl = TextEditingController();
  bool _processing = false;
  bool _isPrinting = false;
  bool _printerReady = true; // Par défaut, on suppose que c'est OK
  bool _printFailed = false;
  int? _createdSaleId; // Stocke l'ID pour pouvoir réimprimer
  String? _error;
  bool _isFinalized = false;

  double _calculateChange(double total) {
    final paid = double.tryParse(_amountCtrl.text.replaceAll(' ', '')) ?? 0;
    return (paid - total).clamp(0.0, double.infinity);
  }

  void _onMethodChanged(String method, CartState cart) {
    HapticFeedback.selectionClick();
    setState(() {
      _method = method;
      // Pour les paiements électroniques, on pré-remplit le montant exact par défaut
      if (method != 'cash' && method != 'credit') {
        _amountCtrl.text = cart.totalTtc.toStringAsFixed(0);
      }

      // Si on choisit crédit et qu'aucun client n'est sélectionné,
      // on propose d'ouvrir la page de sélection
      if (method == 'credit' && cart.customerId == null) {
        // Petit délai pour laisser l'animation du bouton se faire
        Future.delayed(const Duration(milliseconds: 200), () {
          _selectCustomer();
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _amountCtrl.text = widget.cart.totalTtc.toStringAsFixed(0);
    _verifyPrinter();
  }

  Future<void> _verifyPrinter() async {
    final autoPrint = await widget.db.getSetting('auto_print_enabled') ?? '1';
    if (autoPrint == '0') return;

    final ready = await getIt<PrinterService>().isReady();
    if (mounted) setState(() => _printerReady = ready);
  }

  /// Termine la transaction en vidant le panier et fermant le dialogue
  void _finalize() {
    if (_isFinalized || !mounted) return;
    _isFinalized = true;
    context.read<CartBloc>().add(ClearCart());
    if (widget.isEmbedded && widget.onCancel != null) widget.onCancel!();
    Navigator.pop(context, true);
  }

  /// Ouvre la page de sélection/création de client
  Future<void> _selectCustomer() async {
    // On suppose que vous créez un CustomerSelectionScreen qui permet
    // de lister les clients existants ET d'en créer un nouveau.
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomerSelectionScreen(),
      ),
    );

    if (result != null && mounted) {
      // Le résultat devrait contenir l'ID et le nom du client sélectionné/créé
      context.read<CartBloc>().add(SetCustomer(result.id, result.name));
    }
  }

  Future<void> _confirm() async {
    final cart = context.read<CartBloc>().state;

    // Prévention des doubles clics
    if (_processing || _isPrinting) return;

    final total = cart.totalTtc;
    final paid = double.tryParse(_amountCtrl.text.replaceAll(' ', '')) ?? 0;

    // Validation : Le montant doit être suffisant sauf pour le crédit
    if (_method != 'credit' && paid < total) {
      HapticFeedback.vibrate();
      setState(() => _error = 'Montant insuffisant');
      return;
    }

    // Validation : Crédit nécessite un client
    if (_method == 'credit' && cart.customerId == null) {
      HapticFeedback.vibrate();
      setState(() => _error = 'Sélectionnez un client pour le crédit');
      return;
    }

    if (_createdSaleId != null) {
      // Si la vente existe déjà (erreur d'impression précédente),
      // on ne fait que relancer l'impression
      await _attemptPrint(_createdSaleId!);
      return;
    }

    setState(() {
      _processing = true;
      _error = null;
      _printFailed = false;
    });

    try {
      final sessionState = context.read<CashSessionBloc>().state;
      if (sessionState is! CashSessionOpen) {
        setState(() {
          _error = 'Aucune session de caisse ouverte';
          _processing = false;
        });
        return;
      }
      final userId = context.read<AuthBloc>().state.user?.id ?? 1;
      final terminalId = await widget.db.getSetting('terminal_id') ?? '';

      // Récupérer l'UUID du client (String) à partir de son ID local (int)
      String? customerRemoteId;
      if (cart.customerId != null) {
        final customer = await (widget.db.select(widget.db.customers)
              ..where((c) => c.id.equals(cart.customerId!)))
            .getSingleOrNull();
        customerRemoteId = customer?.remoteId;
      }

      // Récupération de l'identifiant du magasin pour lier la vente
      final shopId = await widget.db.getSetting('shop_id');
      if (shopId == null || shopId.isEmpty) {
        setState(() {
          _error = 'ID Boutique manquant. Vérifiez vos paramètres.';
          _processing = false;
        });
        return;
      }

      // Construire les SaleItems
      final items = cart.items
          .map((i) => SaleItemsCompanion(
                productId: Value(i.productId),
                productName: Value(i.product.name),
                unitPriceHt: Value(i.product.priceHt),
                taxRate: Value(i.product.taxRate ?? 0.0),
                quantity: Value(i.quantity),
                discountPct: Value(i.discountPct),
                discountAmount: Value(i.discountAmount),
                lineTotal: Value(i.lineTotalTtc),
                barcode: Value(i.product.barcode),
                costPriceAtSale: Value(i.product.costPrice ?? 0.0),
              ))
          .toList();

      final amountDue = (_method == 'credit')
          ? (total - paid).clamp(0.0, double.infinity)
          : 0.0;
      final paymentStatus =
          (_method == 'credit' && amountDue > 0) ? 'due' : 'paid';

      final saleId = await widget.db.salesDao.createSale(
        userId: userId,
        cashSessionId: sessionState.session.id,
        customerId: customerRemoteId,
        shopId: shopId,
        terminalId: terminalId,
        items: items,
        paymentMethod: _method,
        amountPaid: paid,
        amountDue: amountDue,
        paymentStatus: paymentStatus,
        couponCode: cart.couponCode,
        note: cart.note,
      );

      _createdSaleId = saleId;

      HapticFeedback.heavyImpact(); // Succès de la transaction

      if (!mounted) return;

      // --- IMPRESSION AUTOMATIQUE DU TICKET (Si activée) ---
      final autoPrint = await widget.db.getSetting('auto_print_enabled') ?? '1';
      if (!mounted) return;

      if (autoPrint == '1') {
        await _attemptPrint(saleId);
      } else {
        _finalize();
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur: $e';
        _processing = false;
      });
    }
  }

  /// Tente d'imprimer et gère les erreurs de façon élégante
  Future<void> _attemptPrint(int saleId) async {
    setState(() {
      _isPrinting = true;
      _printFailed = false;
    });

    try {
      final printer = getIt<PrinterService>();
      final cashierName =
          context.read<AuthBloc>().state.user?.name ?? 'Caissier';
      final sale = await (widget.db.select(widget.db.sales)
            ..where((s) => s.id.equals(saleId)))
          .getSingle();
      final saleItems = await widget.db.salesDao.getSaleItems(saleId);

      final printItems = saleItems
          .map((i) => {
                'name': i.productName,
                'barcode': i.barcode,
                'qty': i.quantity,
                'price': i.unitPriceHt * (1 + i.taxRate),
                'total': i.lineTotal,
              })
          .toList();

      final success = await printer
          .printReceipt(
            ref: sale.ref,
            date: sale.createdAt,
            cashierName: cashierName,
            items: printItems,
            totalHt: sale.totalHt,
            totalTax: sale.totalTax,
            totalTtc: sale.totalTtc,
            discountAmount: sale.discountAmount,
            paymentMethod: _method,
            amountPaid:
                double.tryParse(_amountCtrl.text.replaceAll(' ', '')) ?? 0,
            changeGiven: _calculateChange(sale.totalTtc),
            customerName: widget.cart.customerName,
            qrData: sale.fiscalHash,
          )
          .timeout(const Duration(seconds: 7));

      if (!mounted) return;

      if (success) {
        _finalize();
      } else {
        setState(() {
          _isPrinting = false;
          _printFailed = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPrinting = false;
          _printFailed = true;
        });
      }
    }
  }

  /// Récupère les données et partage le ticket par WhatsApp/Menu Système
  Future<void> _shareReceipt() async {
    if (_createdSaleId == null) return;

    try {
      final sale = await (widget.db.select(widget.db.sales)
            ..where((s) => s.id.equals(_createdSaleId!)))
          .getSingle();
      final items = await widget.db.salesDao.getSaleItems(_createdSaleId!);

      Customer? customer;
      if (sale.customerId != null) {
        customer = await (widget.db.select(widget.db.customers)
              ..where((c) => c.remoteId.equals(sale.customerId!)))
            .getSingleOrNull();
      }

      if (!mounted) return;

      final cashierName = context.read<AuthBloc>().state.user?.name;
      final paid = double.tryParse(_amountCtrl.text.replaceAll(' ', '')) ?? 0;

      // Si le client a un numéro, on propose le WhatsApp direct (pré-rempli)
      if (customer?.phone != null && customer!.phone!.isNotEmpty) {
        final choice = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (ctx) => SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Options d\'envoi numérique',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              ListTile(
                leading:
                    const Icon(Icons.chat_outlined, color: AppColors.success),
                title: const Text('WhatsApp Rapide (Texte)'),
                subtitle: Text('Envoi direct au ${customer!.phone}'),
                onTap: () => Navigator.pop(ctx, 'WHATSAPP'),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined,
                    color: AppColors.danger),
                title: const Text('Partager le reçu PDF complet'),
                onTap: () => Navigator.pop(ctx, 'PDF'),
              ),
              const SizedBox(height: 8),
            ]),
          ),
        );

        if (choice == 'WHATSAPP') {
          await getIt<PrinterService>().shareSaleViaWhatsApp(
              sale: sale,
              items: items,
              phone: customer.phone!,
              customerName: customer.name);
          return;
        } else if (choice == null) {
          return;
        }
      }

      await getIt<PrinterService>().shareSaleAsPdf(
        sale: sale,
        items: items,
        cashierName: cashierName,
        customerName: customer?.name,
        paymentMethod: _method,
        amountPaid: paid,
        changeGiven: _calculateChange(sale.totalTtc),
      );
    } catch (e) {
      debugPrint('Erreur partage: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget mainContent = Container(
      width: widget.isEmbedded ? double.infinity : 480,
      padding: EdgeInsets.all(widget.isEmbedded ? 16 : 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        gradient: widget.isEmbedded
            ? null
            : LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(widget.isEmbedded ? 0 : 24),
        border: widget.isEmbedded ? null : Border.all(color: AppColors.border),
      ),
      child: BlocListener<CartBloc, CartState>(
        listenWhen: (p, c) => p.totalTtc != c.totalTtc,
        listener: (context, state) {
          // Si le paiement est intégré (Desktop), on maintient le montant reçu
          // aligné sur le total du panier tant que l'utilisateur ne l'a pas modifié.
          if (widget.isEmbedded) {
            _amountCtrl.text = state.totalTtc.toStringAsFixed(0);
          }
        },
        child: BlocBuilder<CartBloc, CartState>(
          builder: (context, cart) {
            final total = cart.totalTtc;
            final paid =
                double.tryParse(_amountCtrl.text.replaceAll(' ', '')) ?? 0;
            final change = (paid - total).clamp(0.0, double.infinity);

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.isEmbedded ? 'Règlement' : 'Encaissement',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (!_printerReady) ...[
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'Imprimante déconnectée ou non configurée',
                          child: Icon(
                            Icons.print_disabled_rounded,
                            color: AppColors.warning.withValues(alpha: 0.8),
                            size: 18,
                          ),
                        ),
                      ],
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.textMuted),
                        onPressed: widget.isEmbedded
                            ? widget.onCancel
                            : () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Montant total
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((255 * 0.2).round()),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'TOTAL À PAYER',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              letterSpacing: 1),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            Fmt.currency(total),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Mode de paiement
                  const Text(
                    'Mode de paiement',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _methodBtn(
                          'cash', Icons.payments_outlined, 'Espèces', cart,
                          width: 105),
                      _methodBtn('wave', Icons.water_drop_rounded, 'Wave', cart,
                          width: 105),
                      _methodBtn('orange_money', Icons.smartphone_rounded,
                          'Orange', cart,
                          width: 105),
                      _methodBtn(
                          'card', Icons.credit_card_outlined, 'Carte', cart,
                          width: 105),
                      _methodBtn('credit', Icons.person_search_outlined,
                          'Crédit', cart,
                          width: 105),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Text(
                    _method == 'credit'
                        ? 'Client bénéficiaire du crédit'
                        : 'Client (Fidélité)',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  _customerPickerTile(cart),

                  const SizedBox(height: 20),

                  // Montant reçu
                  if (_method == 'cash' || _method == 'credit') ...[
                    Text(
                      _method == 'cash'
                          ? 'Montant reçu'
                          : 'Acompte versé (optionnel)',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (value) => setState(() {}),
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        suffixText: 'FCFA',
                        hintText: '0',
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_method == 'cash')
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [500, 1000, 2000, 5000, 10000]
                            .map(
                              (v) => ActionChip(
                                label: Text(Fmt.currency(v.toDouble())),
                                onPressed: () {
                                  _amountCtrl.text =
                                      (paid + v).toStringAsFixed(0);
                                  setState(() {});
                                },
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: 12),
                    if (_method == 'cash' && paid >= total)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Rendu monnaie',
                              style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              Fmt.currency(change),
                              style: const TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    if (_method == 'credit')
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Reste à payer',
                                  style: TextStyle(
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w600,
                                  )),
                              Text(
                                  Fmt.currency(
                                      (total - paid).clamp(0, double.infinity)),
                                  style: const TextStyle(
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  )),
                            ]),
                      ),
                  ],

                  // État d'impression en erreur
                  if (_printFailed) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.dangerSoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.error_outline_rounded,
                                color: AppColors.danger, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text('L\'impression n\'a pas pu aboutir',
                                    style: TextStyle(
                                        color: AppColors.danger
                                            .withValues(alpha: 0.9),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13))),
                          ]),
                          const SizedBox(height: 4),
                          Text(
                              '• Vérifiez que l\'imprimante est allumée\n• Vérifiez qu\'il reste du papier\n• Le Bluetooth doit être activé',
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontSize: 11,
                                  height: 1.4)),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _shareReceipt,
                              icon: const Icon(Icons.share_rounded, size: 18),
                              label: const Text('ENVOYER PAR WHATSAPP / SMS',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(
                                child: OutlinedButton(
                              onPressed: _finalize,
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary,
                                  side: const BorderSide(
                                      color: AppColors.borderDark)),
                              child: const Text('IGNORER',
                                  style: TextStyle(fontSize: 12)),
                            )),
                            const SizedBox(width: 8),
                            Expanded(
                                child: ElevatedButton(
                              onPressed: _isPrinting
                                  ? null
                                  : () => _attemptPrint(_createdSaleId!),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                              ),
                              child: _isPrinting
                                  ? const SizedBox(
                                      width: 15,
                                      height: 15,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Text('RÉESSAYER',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
                            )),
                          ]),
                        ],
                      ),
                    ),
                  ],

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: const TextStyle(
                            color: AppColors.danger, fontSize: 13)),
                  ],

                  if (!_printerReady && _createdSaleId == null) ...[
                    const SizedBox(height: 12),
                    const Row(children: [
                      Icon(Icons.warning_amber_rounded,
                          color: AppColors.warning, size: 16),
                      SizedBox(width: 6),
                      Expanded(
                          child: Text(
                              'Attention: L\'imprimante n\'est pas prête. Le ticket ne sortira pas automatiquement.',
                              style: TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500))),
                    ]),
                  ],

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: _createdSaleId == null
                        ? ElevatedButton(
                            onPressed: _processing ? null : _confirm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              disabledBackgroundColor:
                                  AppColors.success.withValues(alpha: 0.4),
                            ),
                            child: _processing || _isPrinting
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2)),
                                      const SizedBox(width: 12),
                                      Text(
                                        _isPrinting
                                            ? 'IMPRESSION DU TICKET...'
                                            : 'ENREGISTREMENT...',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            letterSpacing: 1),
                                      ),
                                    ],
                                  )
                                : const Text('Valider la vente',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15)),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
    if (widget.isEmbedded) return mainContent;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: mainContent,
      ),
    );
  }

  Widget _customerPickerTile(CartState cart) => InkWell(
        onTap: _selectCustomer,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12), // Use withValues
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(children: [
            const Icon(Icons.person_outline, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cart.customerName ?? 'Cliquer pour choisir un client',
                    style: TextStyle(
                      color: cart.customerName != null
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                      fontWeight: cart.customerName != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  if (cart.customerName == null)
                    const Text('Requis pour les ventes à crédit',
                        style:
                            TextStyle(fontSize: 11, color: AppColors.danger)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: AppColors.textMuted),
          ]),
        ),
      );

  Widget _methodBtn(String value, IconData icon, String label, CartState cart,
          {double? width}) =>
      InkWell(
        onTap: () => _onMethodChanged(value, cart),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _method == value
                ? AppColors.primary
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _method == value
                ? [
                    BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4))
                  ]
                : [],
            border: Border.all(
                color: _method == value
                    ? AppColors.primary
                    : Theme.of(context).dividerColor),
          ),
          child: Column(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(icon,
                  size: 22,
                  color: _method == value
                      ? Colors.white
                      : AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      _method == value ? FontWeight.bold : FontWeight.w500,
                  color: _method == value
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                )),
          ]),
        ),
      );
}
