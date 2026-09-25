import 'package:flutter/material.dart';

/// Typography of the keypad / wheel Figma (file AzF7…, frames 621:* – 707:*).
///
/// The whole design is set in Elms Sans at four weights; the keypad digits are
/// Dotum in Figma, rendered here with the bundled open-licensed substitute
/// (KeypadDigits = Nanum Gothic, Latin subset). Elms Sans is a variable font,
/// so each weight is applied through FontVariation('wght') to hit the designed
/// instance exactly (a plain FontWeight would only pick the default instance).
class BType {
  BType._();

  static const String family = 'ElmsSans';
  static const String keypadFamily = 'KeypadDigits';

  static const FontWeight extraLight = FontWeight.w200;
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;

  /// An Elms Sans style at a (device-pixel) [size]. Figma "line-height: normal"
  /// is the font's own metrics, which is Flutter's default when height is null.
  static TextStyle elms(
    double size, {
    FontWeight weight = light,
    Color color = Colors.black,
    double? height,
  }) {
    return TextStyle(
      fontFamily: family,
      fontWeight: weight,
      fontVariations: [FontVariation('wght', weight.value.toDouble())],
      fontSize: size,
      height: height,
      color: color,
      letterSpacing: 0,
    );
  }

  /// Keypad digit (Figma: Dotum Regular 36, #272727).
  static TextStyle keypad(double size, {Color color = const Color(0xFF272727)}) {
    return TextStyle(fontFamily: keypadFamily, fontSize: size, color: color, height: 1);
  }
}
