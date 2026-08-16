import 'package:flutter/material.dart';

/// XR studio overview panel (Step 41.16).
class XrStudioPanel extends StatelessWidget {
  const XrStudioPanel({
    super.key,
    required this.sessionState,
    required this.anchorCount,
  });

  final String sessionState;
  final int anchorCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('XR Studio', style: TextStyle(fontSize: 20)),
        const SizedBox(height: 12),
        Text('Session: $sessionState'),
        Text('Anchors: $anchorCount'),
      ],
    );
  }
}
