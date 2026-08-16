import 'package:flutter/material.dart';

/// Automation curve editor (Step 34.17).
class AutomationCurveEditor extends StatelessWidget {
  const AutomationCurveEditor({
    super.key,
    required this.pointCount,
    required this.segmentCount,
  });

  final int pointCount;
  final int segmentCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Automation Curve', style: TextStyle(fontSize: 18)),
        const SizedBox(height: 8),
        Text('Points: $pointCount'),
        Text('Segments: $segmentCount'),
      ],
    );
  }
}
