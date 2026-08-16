import 'package:flutter/material.dart';

/// Creative OS overview panel (Step 40.16).
class CreativeOsPanel extends StatelessWidget {
  const CreativeOsPanel({
    super.key,
    required this.briefCount,
    required this.stage,
  });

  final int briefCount;
  final String stage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Creative OS', style: TextStyle(fontSize: 20)),
        const SizedBox(height: 12),
        Text('Briefs: $briefCount'),
        Text('Stage: $stage'),
      ],
    );
  }
}
