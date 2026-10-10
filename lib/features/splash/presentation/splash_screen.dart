import 'dart:math' as math;

import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.onComplete,
    this.displayDuration = const Duration(milliseconds: 2200),
  });

  final VoidCallback? onComplete;
  final Duration displayDuration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  var _didComplete = false;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: widget.displayDuration)
          ..addStatusListener(_handleStatus)
          ..forward();
  }

  void _handleStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _didComplete) return;
    _didComplete = true;
    widget.onComplete?.call();
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_handleStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05050D),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 600;
            final visualWidth = math.min(
              constraints.maxWidth * (compact ? 0.98 : 0.88),
              820.0,
            );
            final visualHeight = math.min(
              constraints.maxHeight * (compact ? 0.68 : 0.72),
              560.0,
            );
            return Column(
              children: [
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: visualWidth,
                      height: visualHeight,
                      child: _BrandStage(compact: compact),
                    ),
                  ),
                ),
                const _BrandCopy(),
                SizedBox(height: compact ? 18 : 28),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BrandStage extends StatelessWidget {
  const _BrandStage({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final center = Offset(
          constraints.maxWidth / 2,
          constraints.maxHeight / 2,
        );
        final logoSize = math.min(
          constraints.maxWidth * (compact ? 0.39 : 0.34),
          constraints.maxHeight * (compact ? 0.45 : 0.48),
        );
        return Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned.fill(
              child: ExcludeSemantics(
                child: CustomPaint(painter: _OrbitPainter()),
              ),
            ),
            Positioned(
              left: center.dx - logoSize / 2,
              top: center.dy - logoSize / 2,
              width: logoSize,
              height: logoSize,
              child: Semantics(
                label: 'Void Scriptor Studio logo',
                image: true,
                child: Image.asset(
                  'assets/logos/void_scriptor_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BrandCopy extends StatelessWidget {
  const _BrandCopy();

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'VOID SCRIPTOR STUDIO',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFFF4EEFF),
              fontSize: compact ? 18 : 22,
              fontWeight: FontWeight.w700,
              letterSpacing: compact ? 2.4 : 3.2,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'LIVING DATABASE FOR WORLDBUILDING',
              style: TextStyle(
                color: const Color(0xFFD7B8FF),
                fontSize: compact ? 8 : 10,
                fontWeight: FontWeight.w500,
                letterSpacing: compact ? 1.35 : 2.0,
              ),
            ),
          ),
          const SizedBox(height: 13),
          const Text(
            'Opening your local workspace',
            style: TextStyle(color: Color(0xFFAAA2BC), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final glow = Paint()
      ..color = const Color(0xFF8A3FFC).withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 42);
    canvas.drawCircle(center, math.min(size.width, size.height) * 0.3, glow);

    for (final scale in const [0.62, 0.82, 1.0]) {
      final rect = Rect.fromCenter(
        center: center,
        width: size.width * scale,
        height: size.height * scale * 0.68,
      );
      canvas.drawOval(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = const Color(0xFF8257FF).withValues(alpha: 0.24),
      );
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter oldDelegate) => false;
}
