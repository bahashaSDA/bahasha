import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import '../../../core/data/local_database.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../contribution/domain/contribution_category.dart';

/// The giver's live appearance choices, driving colours across the app so the
/// Customize screen genuinely recolours it. Persisted as JSON in
/// AppSettings.customColorsJson, so a relaunch restores the chosen look.
@immutable
class CustomTheme {
  const CustomTheme({required this.background, required this.send, required this.category});

  /// The panel / screen background.
  final Color background;

  /// The Send-contributions bar colour.
  final Color send;

  /// Per-category band colour, keyed by category code. Missing codes fall back
  /// to the Figma cycle by position.
  final Map<String, Color> category;

  static const List<Color> cycle = <Color>[
    AppColors.panelGreen,
    AppColors.categoryGreen,
    AppColors.categoryCyan,
    AppColors.categoryViolet,
  ];

  static const CustomTheme fallback = CustomTheme(
    background: AppColors.panelGreen,
    send: AppColors.indigo,
    category: <String, Color>{},
  );

  /// Colour for a category by code, defaulting to the cyclic Figma palette.
  Color categoryColor(String code, int index) =>
      category[code] ?? cycle[index % cycle.length];

  /// True when "Go all White" is in effect — lets every screen turn white.
  bool get isAllWhite => background == Colors.white && send == Colors.white;

  /// Ink that stays legible on [background].
  Color get onBackground => background.computeLuminance() > 0.6 ? AppColors.ink : AppColors.ink;

  /// Ink that stays legible on the Send bar.
  Color get onSend => send.computeLuminance() > 0.5 ? AppColors.ink : AppColors.onIndigo;

  CustomTheme copyWith({Color? background, Color? send, Map<String, Color>? category}) =>
      CustomTheme(
        background: background ?? this.background,
        send: send ?? this.send,
        category: category ?? this.category,
      );

  static String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  static Color _parse(String h) => Color(int.parse(h.replaceFirst('#', 'FF'), radix: 16));

  String toJson() => jsonEncode(<String, dynamic>{
        'background': _hex(background),
        'send': _hex(send),
        'category': category.map((k, v) => MapEntry(k, _hex(v))),
      });

  factory CustomTheme.fromJson(String? source) {
    if (source == null || source.isEmpty) return fallback;
    try {
      final m = jsonDecode(source) as Map<String, dynamic>;
      final cat = <String, Color>{};
      (m['category'] as Map<String, dynamic>? ?? const {}).forEach((k, v) => cat[k] = _parse(v as String));
      return CustomTheme(
        background: _parse(m['background'] as String),
        send: _parse(m['send'] as String),
        category: cat,
      );
    } catch (_) {
      return fallback;
    }
  }
}

class CustomThemeController extends AsyncNotifier<CustomTheme> {
  @override
  Future<CustomTheme> build() async {
    final db = ref.watch(localDatabaseProvider);
    final row = await (db.select(db.appSettings)..where((t) => t.id.equals(1))).getSingleOrNull();
    return CustomTheme.fromJson(row?.customColorsJson);
  }

  Future<void> _save(CustomTheme theme) async {
    final db = ref.read(localDatabaseProvider);
    await db.into(db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion(id: const Value(1), customColorsJson: Value(theme.toJson())),
        );
    state = AsyncData(theme);
  }

  CustomTheme get _current => state.value ?? CustomTheme.fallback;

  Future<void> setBackground(Color c) => _save(_current.copyWith(background: c));
  Future<void> setSend(Color c) => _save(_current.copyWith(send: c));

  Future<void> setCategory(String code, Color c) {
    final next = Map<String, Color>.from(_current.category)..[code] = c;
    return _save(_current.copyWith(category: next));
  }

  /// "Go all White / Apply for all": turn the entire app white.
  Future<void> goAllWhite() {
    final all = <String, Color>{for (final c in ContributionCategory.seed) c.code: Colors.white};
    return _save(CustomTheme(background: Colors.white, send: Colors.white, category: all));
  }

  /// Restore the default Bahasha palette.
  Future<void> reset() => _save(CustomTheme.fallback);
}

final customThemeProvider =
    AsyncNotifierProvider<CustomThemeController, CustomTheme>(CustomThemeController.new);
