// lib/presentation/screens/cash_drawer/close_cash_drawer_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/database/pos_database.dart';
import '../../../data/services/printer_service.dart';
import '../../blocs/auth_bloc.dart';
import '../../blocs/cash_session_bloc.dart';

class CloseCashDrawerScreen extends StatefulWidget {
  const CloseCashDrawerScreen({super.key});

  @override
  State<CloseCashDrawerScreen> createState() => _CloseCashDrawerScreenState();
}

class _CloseCashDrawerScreenState extends State<CloseCashDrawerScreen> {
  final _db = getIt<PosDatabase>();
  final _countedCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _printReport = true; // Imprimer par défaut
  int? _sessionId;
  double _startingCash = 0;
  double _cashSales = 0;
  double _otherSales = 0;
  double _expectedCash = 0;
  double _countedCash = 0;
  double _discrepancy = 0;

  @override
  void initState() {
    super.initState();
    _loadSessionData();
    _countedCtrl.addListener(_onCountedChanged);
  }

  @override
  void dispose() {
    _countedCtrl.removeListener(_onCountedChanged);
    _countedCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSessionData() async {
    final sessionState = context.read<CashSessionBloc>().state;
    if (sessionState is! CashSessionOpen) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final payments = await _db.salesDao.getPaymentsForSession(sessionState.session.id);
    
    final cashSales = payments
        .where((p) => p.method == 'cash')
        .fold<double>(0.0, (sum, p) => sum + p.amount - p.changeGiven);
    
    final otherSales = payments
        .where((p) => p.method != 'cash')
        .fold<double>(0.0, (sum, p) => sum + p.amount - p.changeGiven);

    if (mounted) {
      setState(() {
        _sessionId = sessionState.session.id;
        _startingCash = sessionState.session.startingCash;
        _cashSales = cashSales;
        _otherSales = otherSales;
        _expectedCash = _startingCash + _cashSales;
        _isLoading = false;
      });
    }
  }

  void _onCountedChanged() {
    setState(() {
      _countedCash = double.tryParse(_countedCtrl.text.replaceAll(' ', '')) ?? 0.0;
      _discrepancy = _countedCash - _expectedCash;
    });
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<CashSessionBloc>().add(CloseSession(
        countedCash: _countedCash,
        notes: _notesCtrl.text.trim(),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CashSessionBloc, CashSessionState>(
      listener: (context, state) async {
        if (state is NoCashSession) {
          if (_printReport && _sessionId != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Clôture réussie. Impression du rapport Z...')),
            );
            await _printZReport();
          }
          if (context.mounted) {
            // La session est fermée avec succès.
            // On ferme tous les écrans jusqu'à la racine pour retourner à main.dart
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        }
      },
      child: Scaffold(
        // Le fond est maintenant un dégradé pour l'effet glassmorphism
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true, // Permet au corps de passer sous l'appbar
        appBar: AppBar(
          title: const Text('Fermeture de caisse'),
          backgroundColor: AppColors.surface, // Appbar vitrée
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [AppColors.bgGradientStart, AppColors.bgGradientEnd],
            ),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: kToolbarHeight + MediaQuery.of(context).padding.top), // Espace pour l'appbar
                            _buildSummaryCard(),
                            const SizedBox(height: 24),
                            _buildCountCard(),
                            const SizedBox(height: 24),
                            CheckboxListTile(
                              value: _printReport,
                              onChanged: (v) => setState(() => _printReport = v ?? true),
                              title: const Text('Imprimer le rapport Z', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              activeColor: AppColors.primary,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _submit,
                              child: const Text('Confirmer et fermer la caisse'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Résumé de la session', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const Divider(height: 24),
            _summaryRow('Fond de caisse initial', _startingCash),
            _summaryRow('Ventes en espèces', _cashSales),
            _summaryRow('Autres paiements', _otherSales),
            const Divider(height: 24),
            _summaryRow('Total espèces attendu', _expectedCash, isBold: true, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildCountCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Comptage final', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _countedCtrl,
              autofocus: true,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
              decoration: InputDecoration(
                labelText: 'Montant compté en caisse',
                suffixText: Fmt.currency(0, symbol: 'FCFA').replaceAll('0 ', ''),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Montant requis' : null,
            ),
            const SizedBox(height: 24),
            _discrepancyRow(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                hintText: 'Ex: Erreur de rendu monnaie...',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double amount, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: AppColors.textSecondary)),
          Text(Fmt.currency(amount), style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color ?? AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _discrepancyRow() {
    Color color;
    String label;
    if (_countedCtrl.text.isEmpty) {
      color = AppColors.textMuted;
      label = 'Écart';
    } else if (_discrepancy == 0) {
      color = AppColors.success;
      label = 'Écart (OK)';
    } else {
      color = AppColors.danger;
      label = 'Écart';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12), // ~30/255
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          Text(
            '${_discrepancy >= 0 ? '+' : ''}${Fmt.currency(_discrepancy)}',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Future<void> _printZReport() async {
    try {
      final session = await (_db.select(_db.cashSessions)..where((s) => s.id.equals(_sessionId!))).getSingle();
      final payments = await _db.salesDao.getPaymentsForSession(_sessionId!);
      if (!mounted) return;
      final user = context.read<AuthBloc>().state.user;

      final reportText = PrinterService.buildCashSessionReport(
        session: session,
        userName: user?.name ?? 'Utilisateur',
        payments: payments,
      );

      await getIt<PrinterService>().printReport(reportText);
    } catch (e) {
      debugPrint('Erreur impression Z: $e');
    }
  }
}
