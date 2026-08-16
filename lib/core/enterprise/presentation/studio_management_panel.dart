import 'package:flutter/material.dart';

/// Studio management overview panel (Step 37.16).
class StudioManagementPanel extends StatelessWidget {
  const StudioManagementPanel({
    super.key,
    required this.studioName,
    required this.plan,
    required this.usedSeats,
    required this.maxSeats,
  });

  final String studioName;
  final String plan;
  final int usedSeats;
  final int maxSeats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(studioName, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 12),
        Text('Plan: $plan'),
        Text('Seats: $usedSeats / $maxSeats'),
      ],
    );
  }
}
