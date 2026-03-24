// lib/data/database/pin_confirmation_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/di/injection.dart';
import '../../core/theme/app_theme.dart';
import '../database/pos_database.dart';
import '../../presentation/blocs/auth_bloc.dart';

class PinConfirmationDialog extends StatefulWidget {
  final String title;
  final String message;

  const PinConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  State<PinConfirmationDialog> createState() => _PinConfirmationDialogState();
}

class _PinConfirmationDialogState extends State<PinConfirmationDialog> {
  String _pin = '';
  String? _error;
  final _db = getIt<PosDatabase>();

  void _onDigitPress(String digit) {
    if (_pin.length < 4) {
      setState(() => _pin += digit);
      if (_pin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _error = null;
      });
    }
  }

  Future<void> _verifyPin() async {
    final actor = context.read<AuthBloc>().state.user;
    if (actor == null) {
      Navigator.pop(context, false);
      return;
    }

    // CORRECTION : Utilise la nouvelle méthode sécurisée `verifyUserPin`
    // qui vérifie le PIN pour un utilisateur spécifique.
    final authorizedUser = await _db.verifyUserPin(actor.id, _pin);

    if (!mounted) return;

    if (authorizedUser != null) {
      Navigator.pop(context, true); // Succès
    } else {
      setState(() {
        _error = 'Code PIN incorrect.';
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.message, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 24),
            // Indicateurs de PIN
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final filled = index < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: filled ? AppColors.primaryLight : AppColors.surfaceLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: filled ? AppColors.primaryLight : AppColors.border,
                    ),
                  ),
                );
              }),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
              ),
            const SizedBox(height: 24),
            // Pavé numérique
            Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: [
                for (var i = 1; i <= 9; i++) _numBtn(i.toString()),
                const SizedBox(width: 60, height: 60),
                _numBtn('0'),
                _iconBtn(Icons.backspace_outlined, _onBackspace),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
      ],
    );
  }

  Widget _numBtn(String text) {
    return SizedBox(
      width: 60,
      height: 60,
      child: OutlinedButton(
        onPressed: () => _onDigitPress(text),
        style: OutlinedButton.styleFrom(
          shape: const CircleBorder(),
          side: const BorderSide(color: AppColors.border),
          backgroundColor: AppColors.surface,
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: 60,
      height: 60,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          shape: const CircleBorder(),
          foregroundColor: AppColors.danger,
        ),
        child: Icon(icon, size: 24),
      ),
    );
  }
}