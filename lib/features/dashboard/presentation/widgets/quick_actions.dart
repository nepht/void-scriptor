import 'package:flutter/material.dart';

import '../../../../design_system/widgets/void_button.dart';
import '../../../../design_system/widgets/void_card.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key, required this.onOpenStudio});

  final VoidCallback onOpenStudio;

  @override
  Widget build(BuildContext context) {
    return VoidCard(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          VoidButton(label: 'New Project', icon: Icons.add, onPressed: () {}),
          VoidButton(
            label: 'Open Project',
            icon: Icons.folder_open_outlined,
            onPressed: onOpenStudio,
          ),
          VoidButton(
            label: 'Create Character',
            icon: Icons.person_add_alt_1_outlined,
            onPressed: () {},
          ),
          VoidButton(
            label: 'Import Asset',
            icon: Icons.upload_file_outlined,
            onPressed: () {},
          ),
          VoidButton(
            label: 'AI Studio',
            icon: Icons.auto_awesome_outlined,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
