import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/database/pos_database.dart';

abstract class ThemeEvent extends Equatable {
  const ThemeEvent();
  @override
  List<Object?> get props => [];
}

class ToggleTheme extends ThemeEvent {}
class LoadTheme extends ThemeEvent {}

class ThemeState extends Equatable {
  final ThemeMode themeMode;
  const ThemeState(this.themeMode);
  @override
  List<Object?> get props => [themeMode];
}

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final PosDatabase _db;

  ThemeBloc(this._db) : super(const ThemeState(ThemeMode.light)) {
    on<LoadTheme>((event, emit) async {
      final mode = await _db.getSetting('theme_mode');
      emit(ThemeState(mode == 'dark' ? ThemeMode.dark : ThemeMode.light));
    });

    on<ToggleTheme>((event, emit) async {
      final newMode = state.themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
      await _db.setSetting('theme_mode', newMode == ThemeMode.dark ? 'dark' : 'light');
      emit(ThemeState(newMode));
    });
  }
}