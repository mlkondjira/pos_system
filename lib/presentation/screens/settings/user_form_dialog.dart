import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/pos_database.dart';
import '../../../core/di/injection.dart';
import '../../blocs/auth_bloc.dart';
import '../../blocs/users_bloc.dart';

class UserFormDialog extends StatefulWidget {
  final User? user; // Null for new user, object for editing
  const UserFormDialog({super.key, this.user});

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _confirmPinCtrl = TextEditingController();
  String _role = 'cashier';
  bool _isActive = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _nameCtrl.text = widget.user!.name;
      _role = widget.user!.role;
      _isActive = widget.user!.isActive;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _pinCtrl.dispose();
    _confirmPinCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final currentActor = context.read<AuthBloc>().state.user;
    final usersBloc = context.read<UsersBloc>();
    if (currentActor == null) {
      // Vérifier si l'acteur est null avant toute opération asynchrone
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur: Utilisateur non authentifié.'),
            backgroundColor: AppColors.danger,
          ),
        );
        Navigator.pop(context);
      }
      return;
    }
    try {
      final shopId =
          await getIt<PosDatabase>().getSetting('shop_id') ??
          ''; // Utiliser getIt directement

      if (widget.user == null) {
        // Add new user
        usersBloc.add(
          AddUser(
            name: _nameCtrl.text.trim(),
            pin: _pinCtrl.text,
            role: _role,
            shopId: shopId,
            actorId: currentActor.id,
          ),
        );
      } else {
        // Update existing user
        usersBloc.add(
          UpdateUser(
            userId: widget.user!.id,
            name: _nameCtrl.text.trim(),
            role: _role,
            isActive: _isActive,
            actorId: currentActor.id,
            newPin: _pinCtrl.text.isNotEmpty ? _pinCtrl.text : null,
          ),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.user == null ? 'Ajouter un utilisateur' : 'Modifier utilisateur',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (v) => v!.isEmpty ? 'Le nom est requis' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Rôle'),
                items: const [
                  DropdownMenuItem(value: 'cashier', child: Text('Caissier')),
                  DropdownMenuItem(
                    value: 'admin',
                    child: Text('Administrateur'),
                  ),
                  DropdownMenuItem(value: 'owner', child: Text('Propriétaire')),
                ],
                onChanged: (v) => setState(() => _role = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pinCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: widget.user == null
                      ? 'Code PIN (4 chiffres)'
                      : 'Nouveau code PIN (laisser vide pour ne pas changer)',
                  counterText: '',
                ),
                validator: (v) {
                  if (widget.user == null && (v == null || v.isEmpty)) {
                    return 'Le code PIN est requis pour un nouvel utilisateur';
                  }
                  if (v != null && v.isNotEmpty && v.length != 4) {
                    return 'Le code PIN doit être de 4 chiffres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPinCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'Confirmer le code PIN',
                  counterText: '',
                ),
                validator: (v) {
                  if (_pinCtrl.text.isNotEmpty && v != _pinCtrl.text) {
                    return 'Les codes PIN ne correspondent pas';
                  }
                  return null;
                },
              ),
              if (widget.user != null) ...[
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Actif'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  activeThumbColor:
                      AppColors.success, // `activeColor` est déprécié
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _saveUser,
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Enregistrer'),
        ),
      ],
    );
  }
}
