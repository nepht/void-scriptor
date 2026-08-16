import 'package:flutter/material.dart';

/// Team member list (Step 37.17).
class TeamMemberList extends StatelessWidget {
  const TeamMemberList({super.key, required this.members});

  final List<String> members;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final member in members)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(member),
          ),
      ],
    );
  }
}
