import 'package:flutter/material.dart';

/// Shot detail view (Step 35.17).
class ShotDetailView extends StatelessWidget {
  const ShotDetailView({
    super.key,
    required this.shotName,
    required this.cameraLabel,
    required this.takeCount,
  });

  final String shotName;
  final String cameraLabel;
  final int takeCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(shotName, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 8),
        Text('Camera: $cameraLabel'),
        Text('Takes: $takeCount'),
      ],
    );
  }
}
