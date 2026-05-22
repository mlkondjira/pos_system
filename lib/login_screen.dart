import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'data/database/pos_database.dart';
import 'presentation/widgets/app_background.dart';
import 'presentation/blocs/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _db = getIt<PosDatabase>();
  final _pinController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _shopName = '';

  User? _selectedUser;
  String? _selectedRole;
  bool _isEmailMode = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadShopName();
  }

  Future<void> _loadShopName() async {
    final name = await _db.getSetting('shop_name');
    if (mounted) setState(() => _shopName = name ?? 'MON COMMERCE');
  }

  @override
  void dispose() {
    _pinController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onNumpadPress(String value) {
    if (value == 'clear') {
      setState(() => _pinController.clear());
      return;
    }
    if (value == 'back') {
      if (_pinController.text.isNotEmpty) {
        setState(() => _pinController.text =
            _pinController.text.substring(0, _pinController.text.length - 1));
      }
      return;
    }
    if (_pinController.text.length < 4) {
      setState(() => _pinController.text += value);
      HapticFeedback.lightImpact();
      if (_pinController.text.length == 4) {
        Future.delayed(const Duration(milliseconds: 200), _onLoginPressed);
      }
    }
  }

  void _onLoginPressed() {
    if (_isEmailMode) {
      context.read<AuthBloc>().add(
            LoginWithEmailRequested(
              _emailController.text.trim(),
              _passwordController.text,
            ),
          );
    } else {
      if (_selectedUser != null && _pinController.text.length == 4) {
        context.read<AuthBloc>().add(
              LoginRequested(_pinController.text, _selectedUser!.id),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        showBlobs: true,
        child: Stack(
          children: [
            // Bouton flottant pour basculer le mode (Propriétaire / Staff)
            Positioned(
              top: 50,
              right: 20,
              child: _buildModeToggle(),
            ),

            // 3. Contenu principal
            BlocListener<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.error!),
                      backgroundColor: AppColors.danger,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                  _pinController.clear();
                }
              },
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        constraints:
                            BoxConstraints(maxWidth: _isEmailMode ? 420 : 480),
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surface
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surface
                                  .withValues(alpha: 0.5),
                              width: 1.5),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 50,
                                offset: const Offset(0, 25))
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.store_rounded,
                              color: AppColors.primary,
                              size: 48,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _shopName.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 3,
                              ),
                            ),
                            Text(
                              'ACCÈS SYSTÈME',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 32),
                            if (!_isEmailMode)
                              _buildPinForm()
                            else
                              _buildEmailForm(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return OutlinedButton.icon(
      onPressed: () => setState(() => _isEmailMode = !_isEmailMode),
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        side: BorderSide(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      icon: Icon(_isEmailMode ? Icons.dialpad_rounded : Icons.cloud_outlined,
          size: 18, color: Colors.white),
      label: Text(
        _isEmailMode ? 'MODE STAFF' : 'MODE CLOUD',
        style: const TextStyle(
            color: Colors.white, // Ligne 223
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1),
      ),
    );
  }

  Widget _buildPinForm() {
    return Column(
      children: [
        // 1. Sélecteur de Rôles (Cartes Horizontales avec grandes icônes)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildRoleCard('owner', 'Owner', Icons.stars_rounded),
            const SizedBox(width: 8),
            _buildRoleCard(
                'admin', 'Gérant', Icons.admin_panel_settings_rounded),
            const SizedBox(width: 8),
            _buildRoleCard('cashier', 'Caissier', Icons.person_outline_rounded),
          ],
        ),
        const SizedBox(height: 24),

        // 2. Liste des Utilisateurs (Noms) filtrée par le rôle sélectionné
        if (_selectedRole != null)
          StreamBuilder<List<User>>(
            stream: _db.watchAllUsers(),
            builder: (context, snapshot) {
              final allUsers = snapshot.data ?? [];
              final filteredUsers = allUsers
                  .where((u) => u.isActive && u.role == _selectedRole)
                  .toList();

              if (filteredUsers.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Aucun utilisateur inscrit pour ce rôle',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 13)),
                );
              }

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: filteredUsers.map((u) {
                  final isSelected = _selectedUser?.id == u.id;
                  return ChoiceChip(
                    label: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: Text(u.name),
                    ),
                    selected: isSelected,
                    onSelected: (selected) => setState(() {
                      _selectedUser = selected ? u : null;
                      _pinController.clear();
                    }),
                    selectedColor:
                        AppColors.primary.withValues(alpha: 0.2), // Ligne 280
                    backgroundColor: Colors.white.withValues(alpha: 0.4),
                    labelStyle: TextStyle(
                      color: isSelected // Use withValues
                          ? AppColors.primary // Use withValues
                          : Theme.of(context)
                              .colorScheme
                              .onSurface, // Use withValues
                      fontWeight: // Use withValues
                          isSelected
                              ? FontWeight.bold
                              : FontWeight.normal, // Use withValues
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected // Ligne 298
                            ? AppColors.primary
                            : Colors.white.withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

        if (_selectedUser != null) ...[
          const SizedBox(height: 32),
          _buildPinDisplay(),
          const SizedBox(height: 32),
          _buildNumpad(),
        ],
      ],
    );
  }

  Widget _buildPinDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final bool isFilled = _pinController.text.length > index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 12),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled
                ? AppColors.primary // Ligne 322
                : Colors.white.withValues(alpha: 0.3),
            border: Border.all(
                color: isFilled
                    ? AppColors.primary
                    : Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.5),
                width: 2),
            boxShadow: isFilled
                ? [
                    BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 10)
                  ]
                : [],
          ),
        );
      }),
    );
  }

  Widget _buildNumpad() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.2,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          ...['1', '2', '3', '4', '5', '6', '7', '8', '9']
              .map((n) => _numpadButton(n)),
          _numpadButton('clear', icon: Icons.refresh_rounded),
          _numpadButton('0'),
          _numpadButton('back', icon: Icons.backspace_outlined),
        ],
      ),
    );
  }

  Widget _numpadButton(String value, {IconData? icon}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onNumpadPress(value),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            // Use withValues
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .surface
                    .withValues(alpha: 0.4)),
          ),
          child: Center(
            child: icon != null
                ? Icon(icon, color: AppColors.textPrimary, size: 22)
                : Text(value,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.onSurface)),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(String id, String label, IconData icon) {
    final isSelected = _selectedRole == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedRole = id;
          _selectedUser = null;
          _pinController.clear();
        }),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ), // Ligne 391
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.normal, // Use withValues
                color: isSelected
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant, // Use withValues
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailForm() {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: 'Mot de passe',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _onLoginPressed,
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18)),
            child: const Text('ACCÉDER AU CLOUD',
                style:
                    TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
        ),
      ],
    );
  }
}
