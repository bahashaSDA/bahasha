import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/icon.dart';
import '../../../core/design/pixel_canvas.dart';
import '../../../core/theme/app_colors.dart';
import '../application/theme_controller.dart';

/// Customize screen — pixel-perfect to the Figma frame (node 239:1453). A white
/// wave crowns a panel-green top; "Go all White" and an "Apply for all" pill;
/// then "Recolour …" rows (Tithe, Offering, Church budget, Mission, Send button)
/// each with a teardrop colour-picker droplet in that element's current colour,
/// laid out at the exact Figma positions and matching band colours.
class CustomizeScreen extends ConsumerWidget {
  const CustomizeScreen({super.key});

  static const _palette = <Color>[
    AppColors.indigo, Color(0xFF2F7D3A), AppColors.categoryGreen,
    AppColors.categoryCyan, AppColors.categoryViolet, Color(0xFFE8A13A),
    Color(0xFFE03131), Colors.white, Color(0xFFD1EFBD),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(themeControllerProvider.notifier);

    Future<void> pick(String label, Color current, ValueChanged<Color> onPick) async {
      final chosen = await showModalBottomSheet<Color>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => _PaletteSheet(title: label, palette: _palette, selected: current),
      );
      if (chosen != null) onPick(chosen);
    }

    return Scaffold(
      backgroundColor: AppColors.indigo,
      body: PixelCanvas(
        background: AppColors.indigo,
        builder: (context, px) => [
          // Panel green, 0–576, then the coloured bands.
          px.band(0, 576, AppColors.panelGreen),
          // Decorative white wave over the top.
          px.at(0, 0, width: 420, height: 421, child: ClipPath(
            clipper: _WaveClipper(),
            child: const ColoredBox(color: Colors.white),
          )),

          px.at(356, 69, width: 24, height: 24, child: GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: DesignIcon('menu', scale: px.scale),
          )),

          // Go all White.
          px.text(40, 242, 'Go all White', size: 24),
          _droplet(px, 351, 247, Colors.white, () => controller.setBackground(Colors.white)),

          // Apply for all pill.
          px.at(40, 305, child: _ApplyPill(scale: px.scale)),

          // Recolour Tithe (on panel).
          px.text(40, 513, 'Recolour Tithe', size: 24),
          _droplet(px, 351, 513, AppColors.panelGreen,
              () => pick('Tithe', AppColors.panelGreen, controller.setBackground)),

          // Offering (green band).
          px.band(576, 80, AppColors.categoryGreen, shadow: const BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 4))),
          px.text(40, 600, 'Recolour Offering', size: 24),
          _droplet(px, 351, 599, AppColors.categoryGreen,
              () => pick('Offering', AppColors.categoryGreen, controller.setAccent)),

          // Church budget (cyan band).
          px.band(656, 80, AppColors.categoryCyan),
          px.text(40, 680, 'Recolour Church budget', size: 24),
          _droplet(px, 351, 679, AppColors.categoryCyan,
              () => pick('Church budget', AppColors.categoryCyan, controller.setAccent)),

          // Mission (violet band).
          px.band(736, 80, AppColors.categoryViolet),
          px.text(40, 760, 'Recolour Mission', size: 24),
          _droplet(px, 351, 759, AppColors.categoryViolet,
              () => pick('Mission', AppColors.categoryViolet, controller.setAccent)),

          // Send button (indigo base).
          px.text(40, 846, 'Recolour Send button', size: 24, weight: FontWeight.w400, color: AppColors.onIndigo),
          _droplet(px, 351, 846, AppColors.indigo,
              () => pick('Send button', AppColors.indigo, controller.setPrimary), border: Colors.white),
        ],
      ),
    );
  }

  Widget _droplet(Px px, double left, double top, Color color, VoidCallback onTap, {Color border = AppColors.ink}) {
    return px.at(left, top, width: 34, height: 34, child: GestureDetector(
      onTap: onTap,
      child: Center(
        child: Transform.rotate(
          angle: -0.785398, // -45°, the teardrop orientation
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

/// The "Apply for all" white rounded pill (radius 34, medium weight).
class _ApplyPill extends StatelessWidget {
  const _ApplyPill({required this.scale});
  final double scale;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34 * scale),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 1.5)],
      ),
      child: Text('Apply for all',
          style: TextStyle(fontFamily: 'BahashaSans', fontWeight: FontWeight.w500, fontSize: 16 * scale, color: AppColors.ink)),
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
          Text(title, style: const TextStyle(fontFamily: 'BahashaSans', fontSize: 20, color: AppColors.ink)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 14, runSpacing: 14,
            children: palette.map((c) => GestureDetector(
              onTap: () => Navigator.of(context).pop(c),
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: c, shape: BoxShape.circle,
                  border: Border.all(color: c.toARGB32() == selected.toARGB32() ? AppColors.ink : Colors.black12, width: c.toARGB32() == selected.toARGB32() ? 3 : 1),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

/// Wavy bottom edge for the white header, approximating the Figma vector.
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
