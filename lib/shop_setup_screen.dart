import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:pos_system/core/theme/app_theme.dart';
import 'package:pos_system/core/di/injection.dart';
import 'package:pos_system/data/services/sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'email_verification_screen.dart';
import 'package:pos_system/presentation/blocs/auth_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pos_system/data/database/pos_database.dart';
import 'package:pos_system/presentation/widgets/app_background.dart';

class ShopSetupScreen extends StatefulWidget {
  const ShopSetupScreen({super.key});

  @override
  State<ShopSetupScreen> createState() => _ShopSetupScreenState();
}

class _ShopSetupScreenState extends State<ShopSetupScreen> {
  bool _loading = true;
  String _loadingMessage = 'Initialisation...';
  bool _hasError = false;
  String _errorMessage = '';
  String? _failedShopId;
  String? _failedShopName;
  List<Map<String, dynamic>> _existingShops = [];
  final _nameCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isCreating = false;

  StreamSubscription? _connectivitySub;
  bool _isDeviceOnline = true; // Mode optimiste par défaut

  @override
  void initState() {
    super.initState();

    // Mode optimiste par défaut pour éviter les blocages de plugin sur Windows
    _isDeviceOnline = true;

    // Vérification initiale de la connexion
    if (!Platform.isWindows) {
      try {
        Connectivity()
            .checkConnectivity()
            .then((results) {
              if (mounted) {
                setState(
                  () => _isDeviceOnline = results.any(
                    (r) => r != ConnectivityResult.none,
                  ),
                );
              }
            })
            .catchError((_) {}); // Protection contre les erreurs de plateforme

        // Écoute en temps réel des changements de réseau
        _connectivitySub = Connectivity().onConnectivityChanged.listen((
          results,
        ) {
          final isNowOnline = results.any((r) => r != ConnectivityResult.none);
          final wasOffline = !_isDeviceOnline;

          if (mounted) {
            setState(() => _isDeviceOnline = isNowOnline);

            // Si la connexion revient et qu'on était en erreur ou que la liste est vide,
            // on force le rechargement des magasins.
            if (wasOffline &&
                isNowOnline &&
                (_hasError ||
                    (_existingShops.isEmpty && !_isCreating && !_loading))) {
              _checkExistingShops();
            }
          }
        }, onError: (_) {}); // Protection Windows NetworkManager
      } catch (_) {}
    }

    _checkExistingShops();
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _nameCtrl.dispose();
    _addrCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkExistingShops() async {
    setState(() {
      _loading = true;
      _hasError = false;
      _loadingMessage = 'Vérification des magasins...';
    });
    try {
      // --- GESTION DU REDÉMARRAGE PENDANT L'OTP ---
      final cloudUser = Supabase.instance.client.auth.currentUser;
      if (cloudUser != null && cloudUser.emailConfirmedAt == null) {
        if (mounted) {
          setState(() => _loading = false);

          // Si l'utilisateur revient sur l'app sans être vérifié, on tente un renvoi
          try {
            await getIt<SyncService>().sendEmailVerificationOtp(
              cloudUser.email!,
            );
          } catch (_) {
            /* Ignorer le rate limit ici, le bouton resend fera le reste */
          }

          _redirectToVerification(cloudUser.email!);
        }
        return;
      }

      if (!mounted) return;

      final user = context.read<AuthBloc>().state.user;

      // 1. REDIRECTION AUTOMATIQUE POUR LES EMPLOYÉS
      if (user != null && user.role != 'owner' && user.shopId != null) {
        _loadingMessage = 'Connexion à votre magasin...';
        await _connectToShop(user.shopId!, 'Chargement...');
        return;
      }

      // Ajout d'un timeout pour éviter un chargement infini si le réseau est instable
      final shops = await getIt<SyncService>().getAvailableShops().timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw Exception(
          'Délai d\'attente dépassé lors de la récupération des magasins.',
        ),
      );

      if (!mounted) return;

      setState(() {
        _existingShops = shops;
        _loading = false;
        _hasError = false;

        // 2. REDIRECTION PROPRIÉTAIRE (Si un seul magasin existe)
        if (shops.length == 1 && user?.role == 'owner') {
          final shop = shops.first;
          _loadingMessage = 'Préparation de ${shop['name']}...';
          _connectToShop(shop['id'], shop['name']);
        } else if (shops.isEmpty) {
          _isCreating = true;
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
          _errorMessage =
              'Impossible de récupérer vos magasins. Vérifiez votre connexion internet.';
        });
      }
    }
  }

  Future<void> _redirectToVerification(String email) async {
    if (!mounted) return;
    final isVerified = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EmailVerificationScreen(email: email)),
    );

    if (isVerified == true && mounted) {
      await _checkExistingShops(); // Redirection automatique vers le magasin ou la liste
    }
  }

  Future<void> _connectToShop(String shopId, String name) async {
    setState(() {
      _loading = true;
      _hasError = false;
      _loadingMessage = 'Connexion à $name...';
      _failedShopId = shopId;
      _failedShopName = name;
    });

    // On écoute la progression pour l'afficher à l'utilisateur pendant le pré-chargement
    final subscription = getIt<SyncService>().statusStream.listen((progress) {
      if (mounted && progress.status == SyncStatus.syncing) {
        setState(() {
          final pct = (progress.value * 100).toInt();
          _loadingMessage = progress.message.isNotEmpty
              ? '${progress.message} ($pct%)'
              : 'Pré-chargement des données... ($pct%)';
        });
      }
    });

    try {
      await getIt<SyncService>().switchShop(shopId);

      // Après switchShop, on vérifie si la synchro s'est terminée avec succès ou erreur
      final finalStatus = getIt<SyncService>().currentStatus;
      if (finalStatus == SyncStatus.error) {
        final errorMsg = getIt<SyncService>().currentProgress.message.isNotEmpty
            ? getIt<SyncService>().currentProgress.message
            : 'Échec du téléchargement des données. Veuillez réessayer.';
        throw Exception(errorMsg);
      }

      // --- AUTOMATISATION : CRÉATION DU PROPRIÉTAIRE LOCAL ---
      final cloudUser = Supabase.instance.client.auth.currentUser;
      if (cloudUser != null) {
        await getIt<PosDatabase>().ensureLocalOwner(
          supabaseId: cloudUser.id,
          email: cloudUser.email,
        );
      }

      if (mounted) {
        context.read<AuthBloc>().add(ShopSetupCompleted());
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      await subscription.cancel();
    }
  }

  Future<void> _createShop() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _loadingMessage = 'Création de ${_nameCtrl.text}...';
    });
    final String email = _emailCtrl.text.trim();
    final String password = _passCtrl.text;

    try {
      // 1. Authentifier ou enregistrer l'utilisateur Cloud
      AuthResponse? authResponse;
      bool signUpSucceeded = false;
      try {
        authResponse = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
        );
        signUpSucceeded = true; // signUp déclenche l'email automatiquement
      } on AuthException catch (e) {
        if (e.message.contains('already registered')) {
          authResponse = await Supabase.instance.client.auth.signInWithPassword(
            email: email,
            password: password,
          );
        } else {
          rethrow;
        }
      }

      final user =
          authResponse.user ?? Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Échec de l\'authentification Cloud.');

      // 2. Flux de vérification Email
      if (user.emailConfirmedAt == null) {
        if (!mounted) return;

        // Si on a fait un signIn (compte déjà existant), aucun mail n'est parti.
        // On doit donc déclencher l'envoi du code OTP manuellement.
        if (!signUpSucceeded) {
          try {
            await getIt<SyncService>().sendEmailVerificationOtp(email);
          } catch (_) {}
        }

        if (!mounted) return;

        final isVerified = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(email: email),
          ),
        );

        if (isVerified != true) {
          if (mounted) setState(() => _loading = false);
          return;
        }

        // Après vérification, on regarde si le compte avait déjà des magasins
        final shops = await getIt<SyncService>().getAvailableShops();
        if (!mounted) return;

        if (shops.isNotEmpty) {
          await _checkExistingShops();
          return;
        }
      }

      // 3. Création effective du magasin (Email confirmé et pas de magasins existants)
      setState(() => _loadingMessage = 'Création de votre magasin...');
      final newId = const Uuid().v4();
      final success = await getIt<SyncService>().registerShop(
        name: _nameCtrl.text.trim(),
        address: _addrCtrl.text.trim(),
        customId: newId,
      );

      if (success) {
        await _connectToShop(newId, _nameCtrl.text.trim());
      } else {
        throw Exception('Impossible d\'enregistrer le magasin sur le Cloud.');
      }
    } catch (e) {
      // GESTION SPÉCIFIQUE DU RATE LIMIT (Erreur 429)
      if (e is AuthException && e.message.contains('rate limit')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Trop d\'e-mails envoyés. Veuillez patienter 60 secondes ou vérifier vos spams.',
              ),
              backgroundColor: AppColors.warning,
            ),
          );
          setState(() => _loading = false);
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: AppColors.danger,
          ),
        );
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withValues(alpha: 0.08),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: _loading
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(strokeWidth: 3),
                      const SizedBox(height: 16),
                      Text(
                        _loadingMessage,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  )
                : _hasError
                ? _buildErrorView()
                : _isCreating
                ? _buildCreateForm()
                : _buildSelectionList()
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.1),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.signal_wifi_off_rounded,
          size: 64,
          color: AppColors.danger,
        ),
        const SizedBox(height: 16),
        const Text(
          'Problème de connexion',
          style: TextStyle(
            fontSize: 22, // Ligne 411
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _errorMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: !_isDeviceOnline
              ? null
              : () {
                  if (_failedShopId != null) {
                    _connectToShop(_failedShopId!, _failedShopName!);
                  } else {
                    _checkExistingShops();
                  }
                },
          icon: Icon(
            _isDeviceOnline ? Icons.refresh_rounded : Icons.wifi_off_rounded,
          ),
          label: Text(
            _isDeviceOnline
                ? 'Réessayer la connexion'
                : 'En attente de connexion...',
          ),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() {
            _hasError = false;
            _isCreating = true;
            _loading = false;
          }),
          child: const Text(
            'Créer ou connecter un magasin',
            style: TextStyle(color: AppColors.primary),
          ),
        ),
        TextButton(
          onPressed: () => context.read<AuthBloc>().add(LogoutRequested()),
          child: const Text(
            'Déconnexion',
            style: TextStyle(color: AppColors.textMuted),
          ), // Ligne 449
        ),
      ],
    );
  }

  Widget _buildSelectionList() {
    final user = context.read<AuthBloc>().state.user;
    final bool isOwner = user?.role == 'owner';

    // If no shops are found, automatically switch to the creation form.
    if (_existingShops.isEmpty) {
      return _buildCreateForm();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.store_rounded, size: 48, color: AppColors.primary),
        const SizedBox(height: 16),
        const Text(
          'Bienvenue !',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8), // Ligne 463
        const Text(
          'Souhaitez-vous vous connecter à un magasin existant ou en créer un nouveau ?',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        ..._existingShops.map(
          (shop) => ListTile(
            leading: const Icon(
              Icons.location_city_rounded,
              color: AppColors.primary,
            ),
            title: Text(
              shop['name'], // Ligne 475
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(shop['address'] ?? 'Sans adresse'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _connectToShop(shop['id'], shop['name']),
          ),
        ),
        const Divider(height: 32),
        if (isOwner) ...[
          TextButton.icon(
            onPressed: () => setState(() => _isCreating = true),
            icon: const Icon(Icons.add),
            label: const Text('Ouvrir un nouveau magasin'),
          ),
          const SizedBox(height: 16),
        ],
        TextButton(
          onPressed: () => context.read<AuthBloc>().add(LogoutRequested()),
          child: const Text(
            'Déconnexion',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Nouveau Magasin',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: const InputDecoration(
                  labelText: 'Nom du magasin',
                  prefixIcon: Icon(Icons.store_outlined),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Le nom est requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addrCtrl,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: const InputDecoration(
                  labelText: 'Adresse / Ville',
                  prefixIcon: Icon(Icons.map_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Propriétaire',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'L\'email est requis pour le compte Cloud'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passCtrl,
                obscureText: true,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: const InputDecoration(
                  labelText: 'Mot de passe Cloud',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (v) => v == null || v.length < 6
                    ? 'Le mot de passe doit faire au moins 6 caractères'
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _createShop,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Créer le magasin'),
        ),
        if (_existingShops.isNotEmpty)
          TextButton(
            onPressed: () => setState(() => _isCreating = false),
            child: const Text('Retour à la liste des magasins'),
          ),
        if (_existingShops.isEmpty)
          TextButton(
            onPressed: () => context.read<AuthBloc>().add(LogoutRequested()),
            child: const Text(
              'Déjà un compte ? Se déconnecter',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
      ],
    );
  }
}
