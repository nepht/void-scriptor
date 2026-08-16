import 'package:flutter/material.dart';

/// Universe validation view (Step 38.18).
class UniverseValidationView extends StatelessWidget {
  const UniverseValidationView({super.key, required this.violations});

  final List<String> violations;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final violation in violations)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(violation),
          ),
      ],
    );
  }
}
