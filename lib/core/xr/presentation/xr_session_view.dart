import 'package:flutter/material.dart';

/// XR session view (Step 41.18).
class XrSessionView extends StatelessWidget {
  const XrSessionView({super.key, required this.state});

  final String state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text('State: $state', style: const TextStyle(fontSize: 18))],
    );
  }
}
