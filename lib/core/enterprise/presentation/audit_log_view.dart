import 'package:flutter/material.dart';

/// Audit log view (Step 37.18).
class AuditLogView extends StatelessWidget {
  const AuditLogView({super.key, required this.events});

  final List<String> events;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final event in events)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(event),
          ),
      ],
    );
  }
}
