import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  static const String _themeKey = 'milo_theme_mode';
  final FlutterSecureStorage _storage;

  ThemeCubit(this._storage) : super(ThemeMode.dark);

  Future<void> loadTheme() async {
    try {
      final saved = await _storage.read(key: _themeKey);
      if (saved == 'light') {
        emit(ThemeMode.light);
      } else {
        emit(ThemeMode.dark);
      }
    } catch (_) {
      emit(ThemeMode.dark);
    }
  }

  Future<void> toggleTheme() async {
    final nextMode =
    state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    emit(nextMode);
    try {
      await _storage.write(
        key: _themeKey,
        value: nextMode == ThemeMode.light ? 'light' : 'dark',
      );
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (state == mode) return;
    emit(mode);
    try {
      await _storage.write(
        key: _themeKey,
        value: mode == ThemeMode.light ? 'light' : 'dark',
      );
    } catch (_) {}
  }
}