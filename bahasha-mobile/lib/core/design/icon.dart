import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';

/// A Figma icon rendered from its SVG asset, sized in design pixels scaled by
/// [scale]. Keeps every screen's icon usage identical.
///
/// By default the icon is tinted with [color]. Icons exported from Figma with
/// their own multi-colour artwork (e.g. the blue arrow-circle with a white
/// arrow, the two-tone toggle) pass [tint] false to render exactly as drawn.
class DesignIcon extends StatelessWidget {
  const DesignIcon(
    this.name, {
    super.key,
    required this.scale,
    this.size = 24,
    this.width,
    this.height,
    this.color = AppColors.ink,
    this.tint = true,
  });

  final String name; // e.g. 'menu', 'send', 'x_red', 'chevron_down'
  final double scale;
  final double size;

  /// Non-square artwork (chevron 24×27, backspace 28×19.6) overrides [size].
  final double? width;
  final double? height;
  final Color color;
  final bool tint;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/$name.svg',
      width: (width ?? size) * scale,
      height: (height ?? size) * scale,
      colorFilter: tint ? ColorFilter.mode(color, BlendMode.srcIn) : null,
    );
  }
}
