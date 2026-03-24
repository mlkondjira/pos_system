// lib/presentation/screens/cash_drawer/open_cash_drawer_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../blocs/auth_bloc.dart';
import '../../blocs/cash_session_bloc.dart';

class OpenCashDrawerScreen extends StatefulWidget {
  const OpenCashDrawerScreen({super.key});

  @override
  State<OpenCashDrawerScreen> createState() =>
      _OpenCashDrawerScreenState();
}

class _OpenCashDrawerScreenState extends State<OpenCashDrawerScreen> {
  final _amountCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final amount =
          double.tryParse(_amountCtrl.text.replaceAll(' ', '')) ?? 0.0;
      final userId = context.read<AuthBloc>().state.user!.id;
      context
          .read<CashSessionBloc>()
          .add(OpenSession(startingCash: amount, userId: userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;

    return Scaffold(
      // CORRECTION : backgroundColor sur le Scaffold pour que le
      // Container gradient couvre tout l'écran sans overflow
      backgroundColor: AppColors.bgGradientStart,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667EEA),
              Color(0xFF764BA2),
              Color(0xFFF093FB),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        // CORRECTION : SafeArea + SingleChildScrollView pour éviter
        // le RenderFlex overflow sur petits écrans / claviers ouverts
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              // Hauteur minimale = écran complet pour centrer le contenu
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom -
                    48,
              ),
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 64,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Bonjour, ${user?.name ?? ''}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Veuillez saisir le fond de caisse\npour démarrer la journée.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _amountCtrl,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Fond de caisse initial',
                          suffixText: Fmt.currency(0, symbol: 'FCFA')
                              .replaceAll('0 ', ''),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez saisir un montant';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Ouvrir la caisse'),
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
}