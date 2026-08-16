import 'package:flutter/material.dart';

/// Shows render stats + frame descriptor (Step 32.19).
class RenderPreviewPanel extends StatelessWidget {
  const RenderPreviewPanel({
    super.key,
    required this.drawCalls,
    required this.culledCount,
    required this.width,
    required this.height,
  });

  final int drawCalls;
  final int culledCount;
  final int width;
  final int height;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Render Preview', style: TextStyle(fontSize: 20)),
        const SizedBox(height: 12),
        Text('Draw calls: $drawCalls'),
        Text('Culled: $culledCount'),
        Text('Resolution: ${width}x$height'),
      ],
    );
  }
}
