import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/database/pos_database.dart';
import '../../core/utils/error_formatter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

// ── EVENTS ─────────────────────────────────────────
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class LoginRequested extends AuthEvent {
  final String pin;
  final int userId;
  const LoginRequested(this.pin, this.userId);
  @override
  List<Object?> get props => [pin, userId];
}

class LoginWithEmailRequested extends AuthEvent {
  final String email;
  final String password;
  const LoginWithEmailRequested(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}

class PasswordResetRequested extends AuthEvent {
  final String email;
  const PasswordResetRequested(this.email);
  @override
  List<Object?> get props => [email];
}

class LogoutRequested extends AuthEvent {}

class ShopSetupCompleted extends AuthEvent {}

// Événement interne pour gérer les changements de statut de l'utilisateur
class _UserStatusChanged extends AuthEvent {
  final User? user;
  const _UserStatusChanged(this.user);
}

// ── STATE ──────────────────────────────────────────
class AuthState extends Equatable {
  final User? user;
  final bool isAuthenticated;
  final String? error;
  final bool isBeingForceLoggedOut;
  final String? info; // Message d'information (ex: succès envoi email)
  final DateTime?
  setupTimestamp; // Pour forcer le rafraîchissement UI après setup

  const AuthState({
    this.user,
    this.isAuthenticated = false,
    this.error,
    this.isBeingForceLoggedOut = false,
    this.info,
    this.setupTimestamp,
  });

  AuthState copyWith({
    User? user,
    bool? isAuthenticated,
    String? error,
    bool? isBeingForceLoggedOut,
    String? info,
    DateTime? setupTimestamp,
    bool clearError = false,
    bool clearInfo = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: clearError ? null : error ?? this.error,
      isBeingForceLoggedOut:
          isBeingForceLoggedOut ?? this.isBeingForceLoggedOut,
      info: clearInfo ? null : info ?? this.info,
      setupTimestamp: setupTimestamp ?? this.setupTimestamp,
    );
  }

  @override
  List<Object?> get props => [
    user,
    isAuthenticated,
    error,
    isBeingForceLoggedOut,
    info,
    setupTimestamp,
  ];
}

// ── BLOC ───────────────────────────────────────────
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final PosDatabase _db;
  StreamSubscription<User?>? _userStatusSubscription;

  AuthBloc(this._db) : super(const AuthState()) {
    on<LoginRequested>(_onLoginRequested);
    on<LoginWithEmailRequested>(_onLoginWithEmailRequested);
    on<PasswordResetRequested>(_onPasswordResetRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<ShopSetupCompleted>(
      (event, emit) => emit(state.copyWith(setupTimestamp: DateTime.now())),
    );
    on<_UserStatusChanged>(_onUserStatusChanged);
  }

  @override
  Future<void> close() {
    _userStatusSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = await _db.verifyUserPin(event.userId, event.pin);
      emit(AuthState(user: user, isAuthenticated: true));
      _watchUserStatus(user.id);
    } catch (e) {
      // e contient maintenant le message précis : "Code PIN incorrect (1/5)" ou "Compte verrouillé..."
      emit(state.copyWith(error: ErrorFormatter.format(e)));
    }
  }

  Future<void> _onLoginWithEmailRequested(
    LoginWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      // 1. Authentification Cloud via Supabase
      final response = await sb.Supabase.instance.client.auth
          .signInWithPassword(email: event.email, password: event.password);

      if (response.user != null) {
        final sbUser = response.user!;

        // 2. Synchronisation avec la base locale (pour avoir un objet User compatible avec le reste de l'app)
        final user = await _db.ensureLocalOwner(
          supabaseId: sbUser.id,
          email: sbUser.email,
          name: sbUser.userMetadata?['name'] as String?,
        );

        emit(AuthState(user: user, isAuthenticated: true));
        _watchUserStatus(user.id);
      } else {
        emit(state.copyWith(error: 'Échec de la connexion cloud.'));
      }
    } catch (e) {
      emit(state.copyWith(error: ErrorFormatter.format(e)));
    }
  }

  Future<void> _onPasswordResetRequested(
    PasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(clearError: true, clearInfo: true));
      await sb.Supabase.instance.client.auth.resetPasswordForEmail(event.email);
      emit(
        state.copyWith(
          info: 'Email de réinitialisation envoyé à ${event.email}',
        ),
      );
    } on sb.AuthException catch (e) {
      emit(state.copyWith(error: e.message));
    } catch (e) {
      emit(state.copyWith(error: 'Erreur lors de l\'envoi: $e'));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Déconnexion Cloud + Local
    await sb.Supabase.instance.client.auth.signOut();

    // Arrêter la surveillance de l'utilisateur
    await _userStatusSubscription?.cancel();
    _userStatusSubscription = null;
    // Réinitialiser l'état complet
    emit(const AuthState(isAuthenticated: false));
  }

  // Méthode pour s'abonner aux changements de l'utilisateur
  void _watchUserStatus(int userId) {
    _userStatusSubscription?.cancel();
    _userStatusSubscription = _db.watchUser(userId).listen((user) {
      // Ajoute un événement interne pour traiter le changement
      add(_UserStatusChanged(user));
    });
  }

  // Handler pour l'événement de changement de statut
  void _onUserStatusChanged(
    _UserStatusChanged event,
    Emitter<AuthState> emit,
  ) async {
    final user = event.user;
    // Si l'utilisateur est supprimé (null) ou désactivé, et qu'il est actuellement connecté
    if (state.isAuthenticated && (user == null || !user.isActive)) {
      // 1. Émettre l'état pour afficher la bannière
      emit(state.copyWith(isBeingForceLoggedOut: true));

      // 2. Attendre pour que l'utilisateur voie le message
      await Future.delayed(const Duration(seconds: 3));

      // 3. Déclencher la déconnexion réelle
      add(LogoutRequested());
    } else if (state.isAuthenticated && user != null) {
      // Si les données de l'utilisateur ont changé (ex: rôle), mettre à jour l'état
      emit(state.copyWith(user: user));
    }
  }
}
