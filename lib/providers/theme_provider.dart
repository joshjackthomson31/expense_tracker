import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

const themeBoxName = 'settings';
const _themeKey = 'themeMode';

ThemeMode readSavedThemeMode() {
  if (!Hive.isBoxOpen(themeBoxName)) return ThemeMode.system;
  final stored = Hive.box(themeBoxName).get(_themeKey) as String?;
  return ThemeMode.values.firstWhere(
    (mode) => mode.name == stored,
    orElse: () => ThemeMode.system,
  );
}

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => readSavedThemeMode();

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    if (Hive.isBoxOpen(themeBoxName)) {
      await Hive.box(themeBoxName).put(_themeKey, mode.name);
    }
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
