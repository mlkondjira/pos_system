import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../core/constants/supabase_config.dart';
import '../../../data/database/pos_database.dart';

// --- Events ---
abstract class UsersEvent extends Equatable {
  const UsersEvent();
  @override
  List<Object?> get props => [];
}

class LoadUsers extends UsersEvent {}

class AddUser extends UsersEvent {
  final String name;
  final String pin;
  final String role;
  final String? email;
  final String? password;
  
  const AddUser({
    required this.name, 
    required this.pin, 
    required this.role,
    this.email,
    this.password,
  });
}

class UpdateUser extends UsersEvent {
  final int id;
  final String name;
  final String pin;
  final String role;
  final bool isActive;
  final int actorId;
  const UpdateUser({required this.id, required this.name, required this.pin, required this.role, required this.isActive, required this.actorId});
}

class DeleteUser extends UsersEvent {
  final int id;
  final int actorId;
  const DeleteUser({required this.id, required this.actorId});
}

// --- State ---
class UsersState extends Equatable {
  final List<User> users;
  final bool isLoading;
  final String? error;

  const UsersState({
    this.users = const [],
    this.isLoading = false,
    this.error,
  });

  UsersState copyWith({List<User>? users, bool? isLoading, String? error, bool? clearError}) {
    return UsersState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: clearError == true ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [users, isLoading, error];
}

// --- Bloc ---
class UsersBloc extends Bloc<UsersEvent, UsersState> {
  final PosDatabase _db;

  UsersBloc(this._db) : super(const UsersState()) {
    on<LoadUsers>(_onLoadUsers);
    on<AddUser>(_onAddUser);
    on<UpdateUser>(_onUpdateUser);
    on<DeleteUser>(_onDeleteUser);
  }

  Future<void> _onLoadUsers(LoadUsers event, Emitter<UsersState> emit) async {
    emit(state.copyWith(isLoading: true));
    await emit.forEach(
      _db.watchAllUsers(),
      onData: (users) => state.copyWith(users: users, isLoading: false),
      onError: (e, _) => state.copyWith(isLoading: false, error: e.toString()),
    );
  }

  Future<void> _onAddUser(AddUser event, Emitter<UsersState> emit) async {
    try {
      if (event.role == 'owner') {
        // CAS PROPRIÉTAIRE : Création compte Cloud
        if (event.email == null || event.password == null) {
          throw Exception("Email et mot de passe requis pour le propriétaire");
        }

        final tempClient = sb.SupabaseClient(
          SupabaseConfig.supabaseUrl,
          SupabaseConfig.supabaseAnonKey,
          // CORRECTION : Désactiver PKCE pour ce client temporaire aussi
          // car aucun stockage n'est fourni pour ce client jetable.
          authOptions: const sb.AuthClientOptions(authFlowType: sb.AuthFlowType.implicit),
        );

        final response = await tempClient.auth.signUp(
          email: event.email!,
          password: event.password!,
          data: {'name': event.name},
        );

        if (response.user == null) {
          throw Exception("Échec de la création de l'utilisateur Cloud.");
        }
        
        await _db.addUser(UsersCompanion.insert(
          name: event.name,
          pinHash: 'CLOUD_AUTH', // Marqueur pour authentification non-PIN
          role: Value(event.role),
          email: Value(event.email),
          supabaseId: Value(response.user!.id),
        ));
      } else {
        // CAS CAISSIER/ADMIN : Création compte Local (PIN)
        await _db.createUserWithPin(
          name: event.name,
          pin: event.pin,
          role: event.role,
        );
      }
    } catch (e) {
      emit(state.copyWith(error: "Erreur lors de l'ajout: $e"));
    }
  }

  Future<void> _onUpdateUser(UpdateUser event, Emitter<UsersState> emit) async {
    try {
      // SÉCURITÉ : Empêcher la modification du dernier administrateur
      // On cherche l'utilisateur actuel dans l'état
      final currentUser = state.users.firstWhere(
        (u) => u.id == event.id,
        orElse: () => throw Exception("Utilisateur non trouvé"),
      );

      // Si c'est un admin et qu'on essaie de changer son rôle ou de le désactiver
      // On considère 'admin' et 'owner' comme des rôles privilégiés
      final isCurrentPrivileged = ['admin', 'owner'].contains(currentUser.role);
      final willBePrivileged = ['admin', 'owner'].contains(event.role);

      if (isCurrentPrivileged && (!willBePrivileged || !event.isActive)) {
        final privilegedCount = state.users.where((u) => ['admin', 'owner'].contains(u.role) && u.isActive).length;
        if (privilegedCount <= 1) {
          emit(state.copyWith(error: "Impossible de modifier le dernier administrateur/propriétaire actif."));
          return;
        }
      }

      // Si un nouveau PIN a été fourni (non vide), on le hache.
      if (event.pin.isNotEmpty) {
        await _db.updateUserPin(userId: event.id, newPin: event.pin);
      }

      final companion = UsersCompanion(
          id: Value(event.id),
          name: Value(event.name),
          role: Value(event.role),
          isActive: Value(event.isActive));
      await _db.updateUser(companion);

      // --- AUDIT LOG ---
      // Log PIN change
      if (event.pin.isNotEmpty) {
        await _db.addAuditLog(
          actorId: event.actorId,
          action: 'user_pin_changed',
          targetEntityType: 'user',
          targetEntityId: event.id,
          details: jsonEncode({'targetName': currentUser.name}),
        );
      }

      // Log role change
      if (currentUser.role != event.role) {
        await _db.addAuditLog(
          actorId: event.actorId,
          action: 'user_role_changed',
          targetEntityType: 'user',
          targetEntityId: event.id,
          details: jsonEncode({
            'from': currentUser.role,
            'to': event.role,
            'targetName': currentUser.name
          }),
        );
      }
      // Log deactivation/activation
      if (currentUser.isActive != event.isActive) {
        await _db.addAuditLog(
          actorId: event.actorId,
          action: event.isActive ? 'user_activated' : 'user_deactivated',
          targetEntityType: 'user',
          targetEntityId: event.id,
          details: jsonEncode({'targetName': currentUser.name}),
        );
      }
    } catch (e) {
      emit(state.copyWith(error: "Erreur de mise à jour: $e"));
    }
  }

  Future<void> _onDeleteUser(DeleteUser event, Emitter<UsersState> emit) async {
    try {
      // SÉCURITÉ : Empêcher la suppression du dernier administrateur
      final currentUser = state.users.firstWhere(
        (u) => u.id == event.id,
        orElse: () => throw Exception("Utilisateur non trouvé"),
      );

      if (['admin', 'owner'].contains(currentUser.role)) {
        final privilegedCount = state.users.where((u) => ['admin', 'owner'].contains(u.role) && u.isActive).length;
        if (privilegedCount <= 1) {
          emit(state.copyWith(error: "Impossible de supprimer le dernier administrateur/propriétaire."));
          return;
        }
      }

      await _db.softDeleteUser(event.id);

      // --- AUDIT LOG ---
      await _db.addAuditLog(
        actorId: event.actorId,
        action: 'user_deactivated', // soft delete is a deactivation
        targetEntityType: 'user',
        targetEntityId: event.id,
        details: jsonEncode({
          'reason': 'deleted_from_ui',
          'targetName': currentUser.name
        }),
      );
    } catch (e) {
      emit(state.copyWith(error: "Erreur de suppression: $e"));
    }
  }
}