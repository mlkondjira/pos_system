import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/pos_database.dart';
import '../../blocs/auth_bloc.dart';
import '../../blocs/users_bloc.dart';
import '../../widgets/shared_widgets.dart';
import 'user_form_dialog.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String _searchQuery = '';
  bool _showInactive = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<UsersBloc>()..add(LoadUsers()),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: const Text(
            'Gestion des Utilisateurs',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(
                _showInactive
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              tooltip: _showInactive
                  ? 'Masquer les inactifs'
                  : 'Afficher les inactifs',
              onPressed: () => setState(() => _showInactive = !_showInactive),
            ),
          ],
        ),
        body: BlocBuilder<UsersBloc, UsersState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.error != null) {
              return Center(
                child: Text(
                  'Erreur: ${state.error}',
                  style: const TextStyle(color: AppColors.danger),
                ),
              );
            }

            final filteredUsers = state.users.where((user) {
              // `final` pour `prefer_final_locals`
              final matchesSearch = user.name.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );
              final matchesStatus = _showInactive || user.isActive;
              return matchesSearch && matchesStatus;
            }).toList();

            if (filteredUsers.isEmpty && state.users.isEmpty) {
              return const EmptyState(
                icon: Icons.people_alt_outlined,
                title: 'Aucun utilisateur configuré',
                subtitle: 'Créez des comptes pour votre personnel.',
              );
            } else if (filteredUsers.isEmpty) {
              return const EmptyState(
                icon: Icons.filter_alt_off_outlined,
                title: 'Aucun utilisateur trouvé',
                subtitle: 'Ajustez vos filtres ou votre recherche.',
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: PosSearchBar(
                    controller: TextEditingController(
                      text: _searchQuery,
                    ), // Ajout du contrôleur
                    hint: 'Rechercher un utilisateur...',
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: user.isActive
                                ? AppColors.primaryLight
                                : AppColors.textMuted.withValues(
                                    alpha: 0.3,
                                  ), // `withOpacity` est déprécié
                            child: Icon(
                              user.role == 'admin' || user.role == 'owner'
                                  ? Icons.verified_user_outlined
                                  : Icons.person_outline,
                              color: user.isActive
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                          title: Text(
                            user.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: user.isActive
                                  ? null
                                  : TextDecoration.lineThrough,
                            ),
                          ),
                          subtitle: Text(
                            'Rôle: ${user.role.toUpperCase()}${user.isActive ? '' : ' (Inactif)'}',
                            style: TextStyle(
                              color: user.isActive
                                  ? AppColors.textSecondary
                                  : AppColors.textMuted,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: AppColors.primary,
                                ),
                                onPressed: () =>
                                    _showUserForm(context, user: user),
                              ),
                              if (user.isActive)
                                IconButton(
                                  icon: const Icon(
                                    Icons.person_off_outlined,
                                    color: AppColors.danger,
                                  ),
                                  tooltip: 'Désactiver l\'utilisateur',
                                  onPressed: () =>
                                      _confirmSoftDelete(context, user),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showUserForm(context),
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('NOUVEL UTILISATEUR'),
          backgroundColor: AppColors.primary,
        ),
      ),
    );
  }

  void _showUserForm(BuildContext context, {User? user}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UserFormDialog(user: user),
    );
  }

  void _confirmSoftDelete(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Désactiver l\'utilisateur ?'),
        content: Text(
          'Voulez-vous vraiment désactiver "${user.name}" ? Il ne pourra plus se connecter.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final currentActor = context.read<AuthBloc>().state.user;
              if (currentActor != null) {
                context.read<UsersBloc>().add(
                  SoftDeleteUser(userId: user.id, adminId: currentActor.id),
                );
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Désactiver'),
          ),
        ],
      ),
    );
  }
}
