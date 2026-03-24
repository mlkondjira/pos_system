// lib/presentation/screens/caisse/payment_dialog.dart
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/database/pos_database.dart';
import '../../blocs/auth_bloc.dart';
import '../../blocs/cart_bloc.dart';
import '../../blocs/cash_session_bloc.dart';

class PaymentDialog extends StatefulWidget {
  final CartState cart;
  final PosDatabase db;
  const PaymentDialog({super.key, required this.cart, required this.db});
  @override State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  String _method = 'cash';
  final _amountCtrl = TextEditingController();
  bool _processing = false;
  String? _error;

  double get total => widget.cart.totalTtc;
  double get paid => double.tryParse(_amountCtrl.text.replaceAll(' ', '')) ?? 0;
  double get change => (paid - total).clamp(0, double.infinity);

  @override
  void initState() {
    super.initState();
    _amountCtrl.text = total.toStringAsFixed(0);
  }

  Future<void> _confirm() async {
    if (paid < total) {
      setState(() => _error = 'Montant insuffisant');
      return;
    }
    setState(() { _processing = true; _error = null; });
    try {
      final sessionState = context.read<CashSessionBloc>().state;
      if (sessionState is! CashSessionOpen) {
        setState(() { _error = 'Aucune session de caisse ouverte'; _processing = false; });
        return;
      }
      final userId = context.read<AuthBloc>().state.user?.id ?? 1;

      // Construire les SaleItems
      final items = widget.cart.items.map((i) => SaleItemsCompanion(
        productId: Value(i.productId),
        productName: Value(i.name),
        unitPriceHt: Value(i.unitPriceHt),
        taxRate: Value(i.taxRate),
        quantity: Value(i.quantity),
        discountPct: Value(i.discountPct),
        lineTotal: Value(i.lineTotalTtc),
      )).toList();

      await widget.db.salesDao.createSale(
        userId: userId,
        cashSessionId: sessionState.session.id,
        customerId: widget.cart.customerId,
        items: items,
        paymentMethod: _method,
        amountPaid: paid,
        note: widget.cart.note,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() { _error = 'Erreur: $e'; _processing = false; });
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Container(
      width: 420, padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Encaissement', style: TextStyle(
            fontFamily: 'SpaceGrotesk', fontSize: 20, fontWeight: FontWeight.w700,
          )),
          const Spacer(),
          IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
        ]),
        const SizedBox(height: 20),

        // Montant total
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: [
            const Text('TOTAL À PAYER', style: TextStyle(
              color: Colors.white60, fontSize: 12, letterSpacing: 1,
            )),
            const SizedBox(height: 4),
            Text(Fmt.currency(total), style: const TextStyle(
              color: Colors.white, fontFamily: 'SpaceGrotesk',
              fontSize: 32, fontWeight: FontWeight.w700,
            )),
          ]),
        ),
        const SizedBox(height: 20),

        // Mode de paiement
        const Text('Mode de paiement', style: TextStyle(
          fontWeight: FontWeight.w600, fontSize: 14,
        )),
        const SizedBox(height: 10),
        Row(children: [
          _methodBtn('cash', Icons.money_rounded, 'Espèces'),
          const SizedBox(width: 8),
          _methodBtn('card', Icons.credit_card_rounded, 'Carte'),
          const SizedBox(width: 8),
          _methodBtn('mobile_money', Icons.phone_android_rounded, 'Mobile'),
        ]),
        const SizedBox(height: 20),

        // Montant reçu
        if (_method == 'cash') ...[
          const Text('Montant reçu', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              suffixText: 'FCFA',
              hintText: '0',
            ),
          ),
          const SizedBox(height: 12),
          // Raccourcis billets
          Wrap(spacing: 8, children: [500, 1000, 2000, 5000, 10000].map((v) =>
            ActionChip(
              label: Text(Fmt.currency(v.toDouble())),
              onPressed: () {
                _amountCtrl.text = (paid + v).toStringAsFixed(0);
                setState(() {});
              },
            ),
          ).toList()),
          const SizedBox(height: 12),
          if (paid >= total) Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.successSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Rendu monnaie', style: TextStyle(
                color: AppColors.success, fontWeight: FontWeight.w600,
              )),
              Text(Fmt.currency(change), style: const TextStyle(
                color: AppColors.success, fontFamily: 'SpaceGrotesk',
                fontWeight: FontWeight.w700, fontSize: 16,
              )),
            ]),
          ),
        ],

        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
        ],

        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _processing ? null : _confirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _processing
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Valider la vente', style: TextStyle(
                    fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ),
      ]),
    ),
  );

  Widget _methodBtn(String value, IconData icon, String label) => Expanded(
    child: InkWell(
      onTap: () => setState(() => _method = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _method == value ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _method == value ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Column(children: [
          Icon(icon, size: 20, color: _method == value ? Colors.white : AppColors.textSecondary),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500,
            color: _method == value ? Colors.white : AppColors.textSecondary,
          )),
        ]),
      ),
    ),
  );
}
