import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/database/pos_database.dart';

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
  final String shopId;
  final int actorId;
  const AddUser({
    required this.name,
    required this.pin,
    required this.role,
    required this.shopId,
    required this.actorId,
  });
  @override
  List<Object?> get props => [name, pin, role, shopId, actorId];
}

class UpdateUser extends UsersEvent {
  final int userId;
  final String name;
  final String role;
  final bool isActive;
  final int actorId;
  final String? newPin;
  const UpdateUser({
    required this.userId,
    required this.name,
    required this.role,
    required this.isActive,
    required this.actorId,
    this.newPin,
  });
  @override
  List<Object?> get props => [userId, name, role, isActive, actorId, newPin];
}

class SoftDeleteUser extends UsersEvent {
  final int userId;
  final int adminId;
  const SoftDeleteUser({required this.userId, required this.adminId});
  @override
  List<Object?> get props => [userId, adminId];
}

class _UsersUpdated extends UsersEvent {
  final List<User> users;
  const _UsersUpdated(this.users);
  @override
  List<Object?> get props => [users];
}

// --- State ---
class UsersState extends Equatable {
  final List<User> users;
  final bool isLoading;
  final String? error;

  const UsersState({this.users = const [], this.isLoading = false, this.error});

  UsersState copyWith({List<User>? users, bool? isLoading, String? error}) {
    return UsersState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [users, isLoading, error];
}

// --- Bloc ---
class UsersBloc extends Bloc<UsersEvent, UsersState> {
  final PosDatabase _db;
  StreamSubscription? _usersSubscription;

  UsersBloc(this._db) : super(const UsersState()) {
    on<LoadUsers>(_onLoadUsers);
    on<AddUser>(_onAddUser);
    on<UpdateUser>(_onUpdateUser);
    on<SoftDeleteUser>(_onSoftDeleteUser);
    on<_UsersUpdated>(
      (event, emit) =>
          emit(state.copyWith(users: event.users, isLoading: false)),
    );
  }

  Future<void> _onLoadUsers(LoadUsers event, Emitter<UsersState> emit) async {
    emit(state.copyWith(isLoading: true));
    final shopId = await _db.getSetting('shop_id');
    _usersSubscription?.cancel();
    _usersSubscription = _db.watchAllUsers(shopId).listen((users) {
      add(_UsersUpdated(users));
    });
  }

  Future<void> _onAddUser(AddUser event, Emitter<UsersState> emit) async {
    try {
      await _db.createUserWithPin(
        name: event.name,
        pin: event.pin,
        role: event.role,
        shopId: event.shopId,
        actorId: event.actorId,
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onUpdateUser(UpdateUser event, Emitter<UsersState> emit) async {
    try {
      await _db.updateUserWithAudit(
        userId: event.userId,
        name: event.name,
        role: event.role,
        isActive: event.isActive,
        actorId: event.actorId,
        newPin: event.newPin,
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onSoftDeleteUser(
    SoftDeleteUser event,
    Emitter<UsersState> emit,
  ) async {
    try {
      await _db.softDeleteUser(event.userId, event.adminId);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _usersSubscription?.cancel();
    return super.close();
  }
}
