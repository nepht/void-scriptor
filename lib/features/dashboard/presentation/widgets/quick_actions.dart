import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../design_system/widgets/void_button.dart';
import '../../../../design_system/widgets/void_card.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key, this.onCreateCharacter});

  final VoidCallback? onCreateCharacter;

  @override
  Widget build(BuildContext context) {
    return VoidCard(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          VoidButton(
            label: 'New Novel',
            icon: Icons.add,
            onPressed: () => context.go(AppRoutes.createProject),
          ),
          VoidButton(
            label: 'Open Novel',
            icon: Icons.folder_open_outlined,
            onPressed: () => context.go(AppRoutes.projects),
          ),
          VoidButton(
            label: 'Create Character',
            icon: Icons.person_add_alt_1_outlined,
            onPressed: onCreateCharacter,
          ),
        ],
      ),
    );
  }
}
