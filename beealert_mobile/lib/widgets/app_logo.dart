import 'package:flutter/material.dart';

/// The BEE-Alert green circular logo with transparent background.
/// Use [size] to control width/height.
class AppLogo extends StatelessWidget {
  final double size;

  /// [blendWithBackground] is kept for API compatibility but no longer
  /// adds a white circle — the PNG already has a transparent background.
  // ignore: avoid_init_to_null
  final bool blendWithBackground;

  const AppLogo({
    super.key,
    this.size = 60,
    this.blendWithBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
