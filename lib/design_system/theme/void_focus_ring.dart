import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import 'void_palette.dart';

/// Menggambar cincin fokus dalam untuk tombol.
///
/// Cincin luar digambar `ButtonStyle.side`; cincin dalam digambar ini dengan
/// warna yang kontras terhadap fill tombol. Dipasang lewat
/// `ButtonStyle.foregroundPainter`, jadi hanya tampil saat state focused.
///
/// Geometri sengaja deterministik: cincin dalam berpusat pada jarak
/// [focusRingWidth] dari tepi, sehingga pixel di offset itu pasti warna cincin.
class VoidFocusRingPainter extends CustomPainter {
  const VoidFocusRingPainter({
    required this.innerColor,
    this.radius = 8.0,
  });

  final Color innerColor;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = ui.RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(focusRingWidth),
      Radius.circular(radius),
    );
    canvas.drawRRect(
      rrect,
      ui.Paint()
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = focusRingInnerWidth
        ..color = innerColor,
    );
  }

  @override
  bool shouldRepaint(VoidFocusRingPainter oldDelegate) =>
      oldDelegate.innerColor != innerColor ||
      oldDelegate.radius != radius;
}
