import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key, this.onCreateCharacter});

  final VoidCallback? onCreateCharacter;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          label: const Text('New Novel'),
          icon: const Icon(Icons.add),
          onPressed: () => context.go(AppRoutes.createProject),
        ),
        OutlinedButton.icon(
          label: const Text('Open Novel'),
          icon: const Icon(Icons.folder_open_outlined),
          onPressed: () => context.go(AppRoutes.projects),
        ),
        TextButton.icon(
          label: const Text('Create Character'),
          icon: const Icon(Icons.person_add_alt_1_outlined),
          onPressed: onCreateCharacter,
        ),
      ],
    );
  }
}
