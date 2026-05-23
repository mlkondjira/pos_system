import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:flutter/foundation.dart' show debugPrint;
import '../../core/di/injection.dart';
import '../../core/utils/notification_service.dart';
import 'package:drift/drift.dart';
import '../../data/database/pos_database.dart';

abstract class DiscountsEvent extends Equatable {
  const DiscountsEvent();
  @override
  List<Object?> get props => [];
}

class LoadDiscounts extends DiscountsEvent {}

class UpsertDiscount extends DiscountsEvent {
  final DiscountsCompanion companion;
  const UpsertDiscount(this.companion);
  @override
  List<Object?> get props => [companion];
}

class DeleteDiscount extends DiscountsEvent {
  final int id;
  const DeleteDiscount(this.id);
  @override
  List<Object?> get props => [id];
}

class RestoreDiscount extends DiscountsEvent {
  final int id;
  const RestoreDiscount(this.id);
  @override
  List<Object?> get props => [id];
}

class ArchiveAllExpiredDiscounts extends DiscountsEvent {}

class CheckExpiringDiscounts extends DiscountsEvent {}

class ArchiveDiscount extends DiscountsEvent {
  final int id;
  const ArchiveDiscount(this.id);
  @override
  List<Object?> get props => [id];
}

class ResetDiscountUsage extends DiscountsEvent {
  final int id;
  const ResetDiscountUsage(this.id);
  @override
  List<Object?> get props => [id];
}

class _UpdateDiscounts extends DiscountsEvent {
  final List<Discount> discounts;
  final Map<int, String> notifiedDates;
  const _UpdateDiscounts(this.discounts, this.notifiedDates);
  @override
  List<Object?> get props => [discounts, notifiedDates];
}

class DiscountsState extends Equatable {
  final List<Discount> discounts;
  final Map<int, String> notifiedDates;
  final bool isLoading;
  final String? error;

  const DiscountsState({
    this.discounts = const [],
    this.notifiedDates = const {},
    this.isLoading = false,
    this.error,
  });

  DiscountsState copyWith({
    List<Discount>? discounts,
    Map<int, String>? notifiedDates,
    bool? isLoading,
    String? error,
  }) {
    return DiscountsState(
      discounts: discounts ?? this.discounts,
      notifiedDates: notifiedDates ?? this.notifiedDates,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [discounts, notifiedDates, isLoading, error];
}

class DiscountsBloc extends Bloc<DiscountsEvent, DiscountsState> {
  final PosDatabase _db;
  StreamSubscription? _subscription;

  DiscountsBloc(this._db) : super(const DiscountsState()) {
    on<LoadDiscounts>(_onLoadDiscounts);
    on<_UpdateDiscounts>(
      (event, emit) => emit(
        state.copyWith(
          discounts: event.discounts,
          notifiedDates: event.notifiedDates,
          isLoading: false,
        ),
      ),
    );
    on<UpsertDiscount>(_onUpsertDiscount);
    on<DeleteDiscount>(_onDeleteDiscount);
    on<ArchiveDiscount>(_onArchiveDiscount);
    on<RestoreDiscount>(_onRestoreDiscount);
    on<ResetDiscountUsage>(_onResetDiscountUsage);
    on<ArchiveAllExpiredDiscounts>(_onArchiveAllExpiredDiscounts);
    on<CheckExpiringDiscounts>(_onCheckExpiringDiscounts);
  }

  Future<void> _onLoadDiscounts(
    LoadDiscounts event,
    Emitter<DiscountsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    final shopId = await _db.getSetting('shop_id') ?? '';

    // Récupérer les dates des dernières notifications envoyées pour chaque remise
    final allSettings = await _db.getAllSettings();
    final notifiedDates = <int, String>{};
    allSettings.forEach((key, value) {
      if (key.startsWith('last_notif_discount_')) {
        final id = int.tryParse(key.replaceFirst('last_notif_discount_', ''));
        if (id != null) notifiedDates[id] = value;
      }
    });

    _subscription?.cancel();
    _subscription =
        (_db.select(
          _db.discounts,
        )..where((d) => d.shopId.equals(shopId))).watch().listen((data) {
          add(_UpdateDiscounts(data, notifiedDates));
        });

    // Lancer la vérification automatique des expirations et l'archivage
    add(CheckExpiringDiscounts());
  }

  Future<void> _onUpsertDiscount(
    UpsertDiscount event,
    Emitter<DiscountsState> emit,
  ) async {
    final id = await _db
        .into(_db.discounts)
        .insertOnConflictUpdate(event.companion);
    final data = await (_db.select(
      _db.discounts,
    )..where((d) => d.id.equals(id))).getSingle();
    await _db.enqueue(
      entityType: 'discount',
      entityId: id,
      payload: data.toJson(),
    );
  }

  Future<void> _onArchiveDiscount(
    ArchiveDiscount event,
    Emitter<DiscountsState> emit,
  ) async {
    await (_db.update(_db.discounts)..where((d) => d.id.equals(event.id)))
        .write(const DiscountsCompanion(isArchived: Value(true)));
    final data = await (_db.select(
      _db.discounts,
    )..where((d) => d.id.equals(event.id))).getSingle();
    await _db.enqueue(
      entityType: 'discount',
      entityId: event.id,
      payload: data.toJson(),
    );
  }

  Future<void> _onRestoreDiscount(
    RestoreDiscount event,
    Emitter<DiscountsState> emit,
  ) async {
    await (_db.update(
      _db.discounts,
    )..where((d) => d.id.equals(event.id))).write(
      const DiscountsCompanion(isArchived: Value(false), isActive: Value(true)),
    );
    final data = await (_db.select(
      _db.discounts,
    )..where((d) => d.id.equals(event.id))).getSingle();
    await _db.enqueue(
      entityType: 'discount',
      entityId: event.id,
      payload: data.toJson(),
    );
  }

  Future<void> _onArchiveAllExpiredDiscounts(
    ArchiveAllExpiredDiscounts event,
    Emitter<DiscountsState> emit,
  ) async {
    final now = DateTime.now();
    // Identifier les remises expirées qui ne sont pas encore archivées
    final toArchive = state.discounts
        .where(
          (d) => !d.isArchived && d.endDate != null && now.isAfter(d.endDate!),
        )
        .toList();

    if (toArchive.isEmpty) return;

    await _db.transaction(() async {
      for (final d in toArchive) {
        await (_db.update(_db.discounts)..where((tbl) => tbl.id.equals(d.id)))
            .write(const DiscountsCompanion(isArchived: Value(true)));
        final updated = await (_db.select(
          _db.discounts,
        )..where((tbl) => tbl.id.equals(d.id))).getSingle();
        await _db.enqueue(
          entityType: 'discount',
          entityId: d.id,
          payload: updated.toJson(),
        );
      }
    });
  }

  Future<void> _onResetDiscountUsage(
    ResetDiscountUsage event,
    Emitter<DiscountsState> emit,
  ) async {
    await (_db.update(_db.discounts)..where((d) => d.id.equals(event.id)))
        .write(const DiscountsCompanion(currentUsage: Value(0)));
    final data = await (_db.select(
      _db.discounts,
    )..where((d) => d.id.equals(event.id))).getSingle();
    await _db.enqueue(
      entityType: 'discount',
      entityId: event.id,
      payload: data.toJson(),
    );
  }

  Future<void> _onDeleteDiscount(
    DeleteDiscount event,
    Emitter<DiscountsState> emit,
  ) async {
    await (_db.delete(_db.discounts)..where((d) => d.id.equals(event.id))).go();
    await _db.enqueue(
      entityType: 'discount',
      entityId: event.id,
      action: 'delete',
      payload: {},
    );
  }

  Future<void> _onCheckExpiringDiscounts(
    CheckExpiringDiscounts event,
    Emitter<DiscountsState> emit,
  ) async {
    try {
      // 1. Archivage automatique des remises déjà expirées
      await _db.archiveExpiredDiscounts();

      // 2. Gestion des notifications pour celles qui expirent bientôt
      final expiring = await _db.getDiscountsExpiringSoon();
      if (expiring.isEmpty) return;

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final notificationService = getIt<NotificationService>();

      for (final d in expiring) {
        final key = 'last_notif_discount_${d.id}';
        final lastNotif = await _db.getSetting(key);

        if (lastNotif != today && d.endDate != null) {
          await notificationService.showDiscountExpiryNotification(
            discountId: d.id,
            name: d.name,
            endDate: d.endDate!,
          );
          await _db.setSetting(key, today);
        }
      }
    } catch (e) {
      debugPrint(
        'DiscountsBloc: Erreur lors de la vérification des expirations: $e',
      );
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
