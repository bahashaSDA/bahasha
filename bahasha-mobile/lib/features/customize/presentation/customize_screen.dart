import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/icon.dart';
import '../../../core/design/pixel_canvas.dart';
import '../../../core/theme/app_colors.dart';
import '../../contribution/application/basket_controller.dart';
import '../../contribution/domain/contribution_category.dart';
import '../application/custom_theme.dart';

/// Customize screen — pixel-perfect to the Figma frame (node 239:1453) and fully
/// functional. "Apply for all" turns the whole app white; each "Recolour …" row
/// recolours that category (or the Send button) via a droplet colour-picker with
/// a full smart palette; swiping vertically pages the category rows through every
/// category, exactly like the Home screen scrolls.
class CustomizeScreen extends ConsumerStatefulWidget {
  const CustomizeScreen({super.key});

  @override
  ConsumerState<CustomizeScreen> createState() => _CustomizeScreenState();
}

class _CustomizeScreenState extends ConsumerState<CustomizeScreen> {
  int _page = 0;

  // A smart palette to customise with — Bahasha tones plus a broad, tasteful set.
  static const List<Color> palette = <Color>[
    Colors.white, Color(0xFFD1EFBD), Color(0xFF89D385), Color(0xFF6CD1F0), Color(0xFFA1A1F7),
    Color(0xFF231F4F), Color(0xFF2F7D3A), Color(0xFF1C7FA0), Color(0xFF6D4AFF), Color(0xFFE8A13A),
    Color(0xFFE03131), Color(0xFFEC4899), Color(0xFFF59E0B), Color(0xFF10B981), Color(0xFF3B82F6),
    Color(0xFF8B5CF6), Color(0xFF14B8A6), Color(0xFFEF4444), Color(0xFF0F172A), Color(0xFFF1F5F9),
  ];

  Future<void> _pick(String label, Color current, ValueChanged<Color> onPick) async {
    final chosen = await showModalBottomSheet<Color>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _PaletteSheet(title: label, palette: palette, selected: current),
    );
    if (chosen != null) onPick(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(customThemeProvider.notifier);
    final theme = ref.watch(customThemeProvider).valueOrNull ?? CustomTheme.fallback;
    final categories = ref.watch(categoriesProvider);

    final start = _page * 4;
    final visible = <ContributionCategory>[
      for (var i = start; i < start + 4 && i < categories.length; i++) categories[i],
    ];
    final maxPage = ((categories.length - 1) / 4).floor();

    const bandTop = <double>[496, 576, 656, 736];
    const labelTop = <double>[513, 600, 680, 760];
    const dropTop = <double>[513, 599, 679, 759];

    final panel = theme.background;

    return Scaffold(
      backgroundColor: theme.send,
      body: GestureDetector(
        onVerticalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v < -150 && _page < maxPage) setState(() => _page++);
          if (v > 150 && _page > 0) setState(() => _page--);
        },
        child: PixelCanvas(
          background: theme.send,
          builder: (context, px) => [
            px.band(0, 576, panel),
            // White wave header.
            px.at(0, 0, width: 420, height: 421, child: ClipPath(
              clipper: _WaveClipper(),
              child: const ColoredBox(color: Colors.white),
            )),

            px.at(356, 69, width: 24, height: 24, child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: DesignIcon('menu', scale: px.scale),
            )),

            // Go all White — pick the background/panel colour.
            px.text(40, 242, 'Recolour background', size: 24),
            _droplet(px, 351, 247, theme.background,
                () => _pick('Background', theme.background, controller.setBackground)),

            // Apply for all — whole app white. Long-press to reset to default.
            px.at(40, 305, child: GestureDetector(
              onTap: () async {
                await controller.goAllWhite();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Applied white to the whole app')));
                }
              },
              onLongPress: () async {
                await controller.reset();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reset to the default Bahasha colours')));
                }
              },
              child: const _ApplyPill(),
            )),

            // Category recolour rows (paged; swipe to reveal more).
            for (var i = 0; i < visible.length; i++) ...[
              px.band(bandTop[i], 80, theme.categoryColor(visible[i].code, start + i)),
              px.text(40, labelTop[i], 'Recolour ${_short(visible[i])}', size: 24, width: 290, maxLines: 1, ellipsis: true),
              _droplet(px, 351, dropTop[i], theme.categoryColor(visible[i].code, start + i),
                  () => _pick(_short(visible[i]), theme.categoryColor(visible[i].code, start + i),
                      (c) => controller.setCategory(visible[i].code, c))),
            ],

            // Recolour Send button (fixed).
            px.text(40, 846, 'Recolour Send button', size: 24, weight: FontWeight.w400, color: theme.onSend),
            _droplet(px, 351, 846, theme.send,
                () => _pick('Send button', theme.send, controller.setSend), border: Colors.white),

            // Page indicator hint.
            if (maxPage > 0)
              px.text(40, 806, 'Swipe up for more (${_page + 1}/${maxPage + 1})', size: 12, color: theme.onSend),
          ],
        ),
      ),
    );
  }

  String _short(ContributionCategory c) {
    switch (c.code) {
      case 'tithe':
        return 'Tithe';
      case 'combined_offering':
        return 'Offering';
      case 'local_church_budget':
        return 'Church budget';
      default:
        return c.name;
    }
  }

  Widget _droplet(Px px, double left, double top, Color color, VoidCallback onTap, {Color border = AppColors.ink}) {
    return px.at(left, top, width: 34, height: 34, child: GestureDetector(
      onTap: onTap,
      child: Center(
        child: Transform.rotate(
          angle: -0.785398,
          child: Container(
            width: 24 * px.scale,
            height: 24 * px.scale,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: border.withValues(alpha: 0.8), width: 1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(48), bottomLeft: Radius.circular(48), bottomRight: Radius.circular(48),
              ),
            ),
          ),
        ),
      ),
    ));
  }
}

class _ApplyPill extends StatelessWidget {
  const _ApplyPill();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 1.5)],
      ),
      child: const Text('Apply for all',
          style: TextStyle(fontFamily: 'BahashaSans', fontWeight: FontWeight.w500, fontSize: 16, color: AppColors.ink)),
    );
  }
}

class _PaletteSheet extends StatelessWidget {
  const _PaletteSheet({required this.title, required this.palette, required this.selected});
  final String title;
  final List<Color> palette;
  final Color selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recolour $title', style: const TextStyle(fontFamily: 'BahashaSans', fontSize: 20, color: AppColors.ink)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 14, runSpacing: 14,
            children: palette.map((c) => GestureDetector(
              onTap: () => Navigator.of(context).pop(c),
              child: Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: c, shape: BoxShape.circle,
                  border: Border.all(
                    color: c.toARGB32() == selected.toARGB32() ? AppColors.ink : Colors.black12,
                    width: c.toARGB32() == selected.toARGB32() ? 3 : 1,
                  ),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final h = size.height;
    final path = Path()
      ..lineTo(0, h * 0.86)
      ..cubicTo(size.width * 0.20, h * 0.80, size.width * 0.30, h * 1.0, size.width * 0.50, h * 0.93)
      ..cubicTo(size.width * 0.70, h * 0.86, size.width * 0.82, h * 1.02, size.width, h * 0.90)
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
