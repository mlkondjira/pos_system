import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import 'core/theme/app_theme.dart';
import 'presentation/blocs/auth_bloc.dart';
import 'data/database/pos_database.dart';
import 'core/ui/liquid_glass_icon.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _selectedRole = 'cashier';
  User? _selectedUser;
  List<User> _usersForRole = [];
  bool _fetchingUsers = true;
  String _pin = '';

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isObscure = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUsersForRole(_selectedRole);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _onDigitPress(String digit) {
    if (_pin.length < 4) {
      setState(() => _pin += digit);
      if (_pin.length == 4) {
        if (_selectedUser == null) return;
        context.read<AuthBloc>().add(LoginRequested(_pin, _selectedUser!.id));
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  void _submitOwnerLogin() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      context.read<AuthBloc>().add(
        LoginWithEmailRequested(_emailCtrl.text.trim(), _passCtrl.text),
      );
    }
  }

  void _resetPassword() {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer une adresse email valide'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    context.read<AuthBloc>().add(PasswordResetRequested(email));
  }

  Future<void> _fetchUsersForRole(String role) async {
    if (role == 'owner') {
      setState(() {
        _usersForRole = [];
        _selectedUser = null;
        _fetchingUsers = false;
      });
      return;
    }
    setState(() => _fetchingUsers = true);
    final db = context.read<PosDatabase>();
    final users = await db.getUsersByRole(role);
    if (!mounted) return;
    setState(() {
      _usersForRole = users;
      _fetchingUsers = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667EEA), // Indigo
              Color(0xFF764BA2), // Violet
              Color(0xFFF093FB), // Rose clair
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.error != null) {
              setState(() {
                _pin = '';
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error!),
                  backgroundColor: AppColors.danger,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            if (state.info != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.info!),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // CORRECTION : BoxShadow avec blurRadius fixe,
                    // pas d'animation → pas de risque d'interpolation négative
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            spreadRadius: 0, // ← 0 au lieu de 5 (spreadRadius cause aussi le crash)
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.point_of_sale,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'POS System',
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildRoleSelector(),
                    const SizedBox(height: 32),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildContent(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_selectedRole == 'owner') return _buildOwnerLogin();
    if (_fetchingUsers) {
      return const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(),
      );
    }
    if (_selectedUser == null) return _buildUserSelection();
    return _buildPinLogin();
  }

  Widget _buildRoleSelector() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _roleTab('Caissier', Icons.person_outline, 'cashier'),
              _roleTab('Admin', Icons.shield_outlined, 'admin'),
              _roleTab('Propriétaire', Icons.cloud_circle_outlined, 'owner'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleTab(String label, IconData icon, String role) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRole = role;
            _pin = '';
            _selectedUser = null;
          });
          _fetchUsersForRole(role);
        },
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LiquidGlassIcon(icon: icon, selected: isSelected, accentColor: Colors.white),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserSelection() {
    if (_usersForRole.isEmpty) {
      return Column(
        key: const ValueKey('no_users'),
        children: [
          Icon(
            Icons.no_accounts,
            color: Colors.white.withValues(alpha: 0.6),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun compte "${_selectedRole == 'admin' ? 'Administrateur' : 'Caissier'}" actif.',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Veuillez en créer un dans les paramètres via un compte admin.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return GridView.builder(
      key: const ValueKey('user_selection'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.9,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _usersForRole.length,
      itemBuilder: (context, index) {
        final user = _usersForRole[index];
        return GestureDetector(
          onTap: () => setState(() => _selectedUser = user),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor:
                    Colors.white.withValues(alpha: 0.2),
                child: Text(
                  user.name.isNotEmpty
                      ? user.name.substring(0, 1).toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user.name,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPinLogin() {
    return Column(
      key: ValueKey('pin_mode_${_selectedUser?.id ?? 0}'),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() {
              _selectedUser = null;
              _pin = '';
            }),
            icon: const Icon(Icons.arrow_back_ios, size: 14),
            label: const Text('Changer d\'utilisateur'),
            style: TextButton.styleFrom(
                foregroundColor: Colors.white70),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Bonjour, ${_selectedUser?.name ?? ''}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Entrez votre code PIN',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            final filled = index < _pin.length;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: filled
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 20,
          runSpacing: 20,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 1; i <= 9; i++) _numBtn(i.toString()),
            const SizedBox(width: 80, height: 80),
            _numBtn('0'),
            _iconBtn(Icons.backspace_outlined, _onBackspace),
          ],
        ),
      ],
    );
  }

  Widget _buildOwnerLogin() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          key: const ValueKey('owner_mode'),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.5)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Connexion Cloud',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) =>
                      v != null && v.contains('@') ? null : 'Email invalide',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passCtrl,
                  style: const TextStyle(color: Colors.white),
                  obscureText: _isObscure,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_isObscure
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () =>
                          setState(() => _isObscure = !_isObscure),
                    ),
                  ),
                  validator: (v) => v != null && v.isNotEmpty
                      ? null
                      : 'Mot de passe requis',
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    child: const Text(
                      'Mot de passe oublié ?',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitOwnerLogin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Se connecter au Dashboard'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _numBtn(String text) {
    return SizedBox(
      width: 80,
      height: 80,
      child: OutlinedButton(
        onPressed: () => _onDigitPress(text),
        style: OutlinedButton.styleFrom(
          shape: const CircleBorder(),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
          backgroundColor: Colors.white.withValues(alpha: 0.1),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: 80,
      height: 80,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          shape: const CircleBorder(),
          foregroundColor: Colors.white,
        ),
        child: Icon(icon, size: 28),
      ),
    );
  }
}