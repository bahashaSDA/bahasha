import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import '../../../core/data/local_database.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';

/// The live appearance settings. Loaded from the local database (offline-first)
/// and written back on every change, so a reinstall or relaunch restores the
/// look the giver chose. Defaults are the Bahasha Figma palette.
@immutable
class ThemeSettings {
  const ThemeSettings({
    required this.mode,
    required this.primary,
    required this.accent,
    required this.background,
  });

  final String mode; // light | dark | system
  final Color primary;
  final Color accent;
  final Color background;

  static const fallback = ThemeSettings(
    mode: 'system',
    primary: AppColors.indigo,
    accent: AppColors.categoryGreen,
    background: AppColors.panelGreen,
  );

  ThemeSettings copyWith({String? mode, Color? primary, Color? accent, Color? background}) =>
      ThemeSettings(
        mode: mode ?? this.mode,
        primary: primary ?? this.primary,
        accent: accent ?? this.accent,
        background: background ?? this.background,
      );

  static Color _hex(String s) => Color(int.parse(s.replaceFirst('#', 'FF'), radix: 16));
  static String _toHex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

class ThemeController extends AsyncNotifier<ThemeSettings> {
  @override
  Future<ThemeSettings> build() async {
    final db = ref.watch(localDatabaseProvider);
    final row = await (db.select(db.appSettings)..where((t) => t.id.equals(1))).getSingleOrNull();
    if (row == null) return ThemeSettings.fallback;
    return ThemeSettings(
      mode: row.mode,
      primary: ThemeSettings._hex(row.primaryColor),
      accent: ThemeSettings._hex(row.accentColor),
      background: ThemeSettings._hex(row.backgroundColor),
    );
  }

  Future<void> _persist(ThemeSettings s) async {
    final db = ref.read(localDatabaseProvider);
    await db.into(db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion(
            id: const Value(1),
            mode: Value(s.mode),
            primaryColor: Value(ThemeSettings._toHex(s.primary)),
            accentColor: Value(ThemeSettings._toHex(s.accent)),
            backgroundColor: Value(ThemeSettings._toHex(s.background)),
          ),
        );
    state = AsyncData(s);
  }

  Future<void> setPrimary(Color c) async => _persist((state.value ?? ThemeSettings.fallback).copyWith(primary: c));
  Future<void> setAccent(Color c) async => _persist((state.value ?? ThemeSettings.fallback).copyWith(accent: c));
  Future<void> setBackground(Color c) async =>
      _persist((state.value ?? ThemeSettings.fallback).copyWith(background: c));
  Future<void> setMode(String m) async => _persist((state.value ?? ThemeSettings.fallback).copyWith(mode: m));
}

final themeControllerProvider =
    AsyncNotifierProvider<ThemeController, ThemeSettings>(ThemeController.new);
