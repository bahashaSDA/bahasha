import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../application/theme_controller.dart';

/// Appearance customization: primary, accent and background colours, plus the
/// light/dark/system mode. Every change persists immediately to the local
/// settings (offline-first) and updates a live preview, matching the Figma
/// "customize" screen's colour-picker interaction.
class CustomizeScreen extends ConsumerWidget {
  const CustomizeScreen({super.key});

  // A curated Bahasha-flavoured palette for each swatch row.
  static const _palette = <Color>[
    AppColors.indigo,
    Color(0xFF2F7D3A),
    AppColors.categoryGreen,
    AppColors.categoryCyan,
    AppColors.categoryViolet,
    Color(0xFFE8A13A),
    Color(0xFFE03131),
    Color(0xFF6D4AFF),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(themeControllerProvider);
    final controller = ref.read(themeControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.panelGreen,
      appBar: AppBar(
        backgroundColor: AppColors.panelGreen,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Customize', style: AppTypography.title.copyWith(fontSize: 24)),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.indigo)),
        error: (e, _) => Center(child: Text('$e', style: AppTypography.description)),
        data: (s) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: <Widget>[
            _Preview(settings: s),
            const SizedBox(height: 24),
            _ColorRow(
              label: 'Primary colour',
              selected: s.primary,
              palette: _palette,
              onPick: controller.setPrimary,
            ),
            const SizedBox(height: 20),
            _ColorRow(
              label: 'Accent colour',
              selected: s.accent,
              palette: _palette,
              onPick: controller.setAccent,
            ),
            const SizedBox(height: 20),
            _ColorRow(
              label: 'Background',
              selected: s.background,
              palette: const <Color>[
                AppColors.panelGreen,
                Color(0xFFDEFFCD),
                Color(0xFFEFF6FF),
                Color(0xFFF6F8F4),
                Color(0xFFFFFFFF),
                Color(0xFF17152E),
              ],
              onPick: controller.setBackground,
            ),
            const SizedBox(height: 24),
            _SectionLabel('Theme mode'),
            _ModeSelector(mode: s.mode, onChanged: controller.setMode),
          ],
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.settings});
  final ThemeSettings settings;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 140,
      decoration: BoxDecoration(
        color: settings.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Preview', style: AppTypography.description.copyWith(color: settings.primary)),
          const Spacer(),
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: settings.primary, borderRadius: BorderRadius.circular(12)),
                child: Text('Send', style: AppTypography.description.copyWith(color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Container(
                width: 44,
                height: 40,
                decoration: BoxDecoration(color: settings.accent, borderRadius: BorderRadius.circular(12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.label,
    required this.selected,
    required this.palette,
    required this.onPick,
  });

  final String label;
  final Color selected;
  final List<Color> palette;
  final ValueChanged<Color> onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SectionLabel(label),
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: palette.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final c = palette[i];
              final isSelected = c.toARGB32() == selected.toARGB32();
              return GestureDetector(
                onTap: () => onPick(c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.ink : Colors.black12,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 22)
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.mode, required this.onChanged});
  final String mode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const modes = <({String id, String label, IconData icon})>[
      (id: 'light', label: 'Light', icon: Icons.light_mode_outlined),
      (id: 'dark', label: 'Dark', icon: Icons.dark_mode_outlined),
      (id: 'system', label: 'System', icon: Icons.brightness_auto_outlined),
    ];
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: modes.map((m) {
          final active = m.id == mode;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(m.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: active ? AppColors.indigo : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: <Widget>[
                    Icon(m.icon, size: 20, color: active ? Colors.white : AppColors.inkMuted),
                    const SizedBox(height: 4),
                    Text(
                      m.label,
                      style: AppTypography.description.copyWith(
                        fontSize: 12,
                        color: active ? Colors.white : AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 4),
        child: Text(text, style: AppTypography.rowLabel.copyWith(fontSize: 15, color: AppColors.inkMuted)),
      );
}
