import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/pos_database.dart';
import '../../blocs/auth_bloc.dart';
import 'glass_alert_dialog.dart';
import 'users_bloc.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<UsersBloc>()..add(LoadUsers()),
      // On utilise un Builder pour obtenir un BuildContext qui se trouve *sous* le BlocProvider.
      // Sans cela, le context utilisé dans le FloatingActionButton est celui du parent de UsersScreen,
      // qui ne connaît pas le UsersBloc, d'où l'erreur ProviderNotFoundException.
      child: Builder(builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Gestion des utilisateurs'),
          ),
          body: BlocConsumer<UsersBloc, UsersState>(
            listener: (context, state) {
              if (state.error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.error!), backgroundColor: AppColors.danger),
                );
              }
            },
            builder: (context, state) {
              if (state.isLoading && state.users.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: state.users.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final user = state.users[index];
                  return _UserTile(
                    user: user,
                    onTap: () => _showUserForm(context, user),
                  );
                },
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showUserForm(context, null),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter'),
          ),
        );
      }),
    );
  }

  void _showUserForm(BuildContext context, User? user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<UsersBloc>(),
        child: _UserFormDialog(user: user),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final User user;
  final VoidCallback onTap;

  const _UserTile({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOwner = user.role == 'owner';
    final isAdmin = user.role == 'admin';
    final isPrivileged = isAdmin || isOwner;

    return ListTile(
      onTap: onTap,
      tileColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: CircleAvatar(
        backgroundColor: isPrivileged ? AppColors.accentSoft : AppColors.primary.withAlpha(51),
        child: Icon(
          isOwner 
            ? Icons.verified_user 
            : (isAdmin ? Icons.shield_outlined : Icons.person_outline),
          color: isPrivileged ? AppColors.accentDark : AppColors.primaryLight,
        ),
      ),
      // Adaptation du texte pour le mode sombre/transparent
      textColor: Colors.white,
      iconColor: Colors.white70,
      subtitleTextStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
      title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        isOwner 
          ? 'Propriétaire' 
          : (isAdmin ? 'Administrateur' : 'Caissier')
      ),
      trailing: Opacity(
        opacity: user.isActive ? 1.0 : 0.4,
        child: Icon(
          user.isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: user.isActive ? AppColors.success : AppColors.danger,
        ),
      ),
    );
  }
}

class _UserFormDialog extends StatefulWidget {
  final User? user;
  const _UserFormDialog({this.user});

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _pinCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;
  
  String _role = 'cashier';
  bool _isActive = true;

  bool get isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user?.name ?? '');
    // Le champ PIN doit être vide pour la modification pour des raisons de sécurité.
    _pinCtrl = TextEditingController();
    _emailCtrl = TextEditingController(text: widget.user?.email ?? '');
    _passwordCtrl = TextEditingController(); // Vide par sécurité
    _role = widget.user?.role ?? 'cashier';
    _isActive = widget.user?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _pinCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final actorId = context.read<AuthBloc>().state.user?.id;
      if (actorId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur critique: Acteur non identifié.'), backgroundColor: AppColors.danger),
        );
        return;
      }

      if (isEditing) {
        // On envoie le PIN seulement s'il a été modifié.
        // Une chaîne vide indique qu'il ne faut pas le mettre à jour.
        context.read<UsersBloc>().add(UpdateUser(
              id: widget.user!.id,
              name: _nameCtrl.text.trim(),
              pin: _pinCtrl.text.trim(), // Peut être vide
              role: _role,
              isActive: _isActive,
              actorId: actorId,
            ));
      } else {
        context.read<UsersBloc>().add(AddUser(
              name: _nameCtrl.text.trim(),
              pin: _pinCtrl.text.trim(), 
              role: _role,
              email: _role == 'owner' ? _emailCtrl.text.trim() : null,
              password: _role == 'owner' ? _passwordCtrl.text : null,
            ));
      }
      Navigator.of(context).pop();
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => GlassAlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer "${widget.user!.name}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), style: TextButton.styleFrom(foregroundColor: Colors.white70), child: const Text('Non')),
          TextButton(
            onPressed: () {
              final actorId = context.read<AuthBloc>().state.user?.id;
              if (actorId == null) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Erreur critique: Acteur non identifié.'), backgroundColor: AppColors.danger),
                );
                return;
              }
              Navigator.pop(ctx); // Ferme la confirmation
              context.read<UsersBloc>().add(DeleteUser(id: widget.user!.id, actorId: actorId));
              Navigator.pop(context); // Ferme le formulaire
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Oui, supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassAlertDialog(
      title: Text(isEditing ? 'Modifier l\'utilisateur' : 'Nouvel utilisateur'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Nom complet'),
                validator: (v) => v!.trim().isEmpty ? 'Le nom est requis' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey(widget.user), // Assure la reconstruction avec la bonne valeur initiale
                initialValue: _role,
                dropdownColor: const Color(0xFF2D2D44), // Fond sombre pour le menu déroulant
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Rôle'),
                items: const [
                  DropdownMenuItem(value: 'cashier', child: Text('Caissier')),
                  DropdownMenuItem(value: 'admin', child: Text('Administrateur')),
                  DropdownMenuItem(value: 'owner', child: Text('Propriétaire')),
                ],
                onChanged: (v) => setState(() => _role = v!),
              ),
              const SizedBox(height: 16),
              
              // CHAMPS CONDITIONNELS
              if (_role == 'owner') ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(26), // ~10% opacity
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withAlpha(77)), // ~30% opacity
                  ),
                  child: Column(children: [
                    const Text('Identifiants de connexion Cloud', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryLight)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined, size: 18)),
                      validator: (v) => v != null && v.contains('@') ? null : 'Email invalide',
                    ),
                    if (!isEditing) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Mot de passe', prefixIcon: Icon(Icons.lock_outline, size: 18)),
                        obscureText: true,
                        validator: (v) => v != null && v.length >= 6 ? null : 'Min 6 caractères',
                      ),
                    ]
                  ]),
                ),
              ] else ...[
                TextFormField(
                  controller: _pinCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: isEditing ? 'Nouveau PIN (vide = inchangé)' : 'Code PIN (4 chiffres)',
                    counterText: '',
                    prefixIcon: const Icon(Icons.dialpad, size: 18),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  validator: (v) {
                    if (isEditing && (v == null || v.isEmpty)) return null;
                    if (v == null || v.trim().isEmpty) return 'Le PIN est requis';
                    if (v.trim().length != 4) return 'Le PIN doit faire 4 chiffres';
                    return null;
                  },
                ),
              ],

              if (isEditing) ...[
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Compte actif'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  tileColor: Colors.white.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (isEditing)
          TextButton(
            onPressed: _confirmDelete,
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Supprimer'),
          ),
        TextButton(onPressed: () => Navigator.of(context).pop(), style: TextButton.styleFrom(foregroundColor: Colors.white70), child: const Text('Annuler')),
        ElevatedButton(onPressed: _submit, child: const Text('Enregistrer')),
      ],
    );
  }
}