import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const AppWrapper());
}

class AppWrapper extends StatelessWidget {
  const AppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // On web or desktop, wrap in a mobile phone frame
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return MaterialApp(
        title: 'BEE-Alert',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        builder: (context, child) {
          return Scaffold(
            backgroundColor: const Color(0xFF1A1A2E),
            body: Center(
              child: _MobileFrame(child: child ?? const SizedBox()),
            ),
          );
        },
        initialRoute: '/',
        routes: appRoutes,
      );
    }
    return const BeeAlertApp();
  }
}

class _MobileFrame extends StatelessWidget {
  final Widget child;
  const _MobileFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 390,
      height: 844,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 50,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        children: [
          // App content
          child,
          // Phone border overlay
          IgnorePointer(
            child: CustomPaint(
              painter: _PhoneFramePainter(),
              size: const Size(390, 844),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Outer rounded border
    final borderPaint = Paint()
      ..color = const Color(0xFF3A3A3A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(40),
      ),
      borderPaint,
    );

    // Dynamic island
    final notchPaint = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width / 2, 16),
          width: 110,
          height: 28,
        ),
        const Radius.circular(14),
      ),
      notchPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
