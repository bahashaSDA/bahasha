import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';

/// A Figma icon rendered from its SVG asset, tinted, sized in design pixels
/// scaled by [scale]. Keeps every screen's icon usage identical.
class DesignIcon extends StatelessWidget {
  const DesignIcon(
    this.name, {
    super.key,
    required this.scale,
    this.size = 24,
    this.color = AppColors.ink,
  });

  final String name; // e.g. 'menu', 'plus', 'x', 'backspace', 'droplet'
  final double scale;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/$name.svg',
      width: size * scale,
      height: size * scale,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
