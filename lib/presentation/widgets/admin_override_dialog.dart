import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/di/injection.dart';
import '../../../data/database/pos_database.dart';

class AdminOverrideDialog extends StatefulWidget {
  final String reason;
  const AdminOverrideDialog({super.key, required this.reason});

  @override
  State<AdminOverrideDialog> createState() => _AdminOverrideDialogState();
}

class _AdminOverrideDialogState extends State<AdminOverrideDialog> {
  final _pinCtrl = TextEditingController();
  final _db = getIt<PosDatabase>();
  String? _error;
  bool _loading = false;

  Future<void> _verify() async {
    if (_pinCtrl.text.length < 4) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final admin = await _db.verifyAdminOverride(_pinCtrl.text);

    if (admin != null) {
      if (mounted) Navigator.pop(context, admin);
    } else {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'PIN Administrateur incorrect';
          _pinCtrl.clear();
        });
        HapticFeedback.vibrate();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.lock_person_rounded, color: AppColors.warning),
          SizedBox(width: 10),
          Text('Autorisation Requise'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.reason,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _pinCtrl,
            enabled: !_loading,
            obscureText: true,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              letterSpacing: 10,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            decoration: InputDecoration(
              hintText: 'PIN',
              errorText: _error,
              counterText: '',
            ),
            onChanged: (v) => v.length == 4 ? _verify() : null,
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}
