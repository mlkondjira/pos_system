import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_system/core/di/injection.dart';
import 'package:pos_system/core/theme/app_theme.dart';
import 'package:pos_system/data/services/sync_service.dart';
import 'package:pos_system/presentation/blocs/auth_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _resendTimer;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    // On ne renvoie pas le code automatiquement car Supabase envoie déjà
    // un email lors du signUp dans l'écran précédent.
    _startResendTimer(); // On lance juste le compte à rebours pour le bouton "Renvoyer"
  }

  @override
  void dispose() {
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendCountdown = 60);

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown == 0) {
        timer.cancel();
      } else {
        if (mounted) {
          setState(() => _resendCountdown--);
        }
      }
    });
  }

  Future<void> _sendOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await getIt<SyncService>().sendEmailVerificationOtp(widget.email);
      if (mounted) {
        setState(() => _isLoading = false);
        _startResendTimer();
        _showSnackBar('Code OTP envoyé à ${widget.email}', AppColors.success);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
      _showSnackBar(
        'Erreur lors de l\'envoi du code: $_errorMessage',
        AppColors.danger,
      );
    }
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await getIt<SyncService>().verifyEmailOtp(
        widget.email,
        _otpController.text.trim(),
      );

      // Vérifier si l'email est maintenant confirmé
      await Supabase.instance.client.auth
          .refreshSession(); // Rafraîchir la session pour obtenir le statut à jour
      final user = Supabase.instance.client.auth.currentUser;

      if (user?.emailConfirmedAt != null) {
        if (mounted) {
          _showSnackBar('Email vérifié avec succès !', AppColors.success);
          Navigator.of(
            context,
          ).pop(true); // Indiquer le succès à l'écran précédent
        }
      } else {
        throw Exception(
          'La vérification a réussi mais le statut de l\'email n\'est pas mis à jour. Veuillez réessayer.',
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
      _showSnackBar(
        'Erreur lors de la vérification: $_errorMessage',
        AppColors.danger,
      );
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Future<void> _handleLogout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      context.read<AuthBloc>().add(LogoutRequested());
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérification Email'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _handleLogout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Un code OTP a été envoyé à ${widget.email}. Veuillez le saisir ci-dessous.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Code OTP',
                    prefixIcon: Icon(Icons.vpn_key_outlined),
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? 'Veuillez saisir le code OTP'
                      : null,
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Vérifier le code'),
                ),
                TextButton(
                  onPressed: (_isLoading || _resendCountdown > 0)
                      ? null
                      : _sendOtp,
                  child: Text(
                    _resendCountdown > 0
                        ? 'Renvoyer le code ($_resendCountdown s)'
                        : 'Renvoyer le code',
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading ? null : _handleLogout,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                  ),
                  child: const Text('Utiliser un autre compte'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
