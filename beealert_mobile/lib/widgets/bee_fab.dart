import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Floating bee button that pulses to draw attention
class BeeFab extends StatefulWidget {
  final VoidCallback onPressed;

  const BeeFab({super.key, required this.onPressed});

  @override
  State<BeeFab> createState() => _BeeFabState();
}

class _BeeFabState extends State<BeeFab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: FloatingActionButton(
        onPressed: widget.onPressed,
        backgroundColor: gradientStart,
        elevation: 6,
        child: const Text(
          '🐝',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
