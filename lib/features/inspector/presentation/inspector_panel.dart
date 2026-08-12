import 'package:flutter/material.dart';

import '../../../design_system/colors/void_colors.dart';

class InspectorPanel extends StatelessWidget {
  const InspectorPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 310,
      decoration: const BoxDecoration(
        color: VoidColors.panel,
        border: Border(left: BorderSide(color: VoidColors.borderSoft)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InspectorHeader(),
          Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _InspectorSection(title: 'Properties'),
                  _InspectorSection(title: 'Tags'),
                  _InspectorSection(title: 'Quick Notes'),
                  _InspectorSection(title: 'AI Prompt'),
                  _InspectorSection(title: 'Linked Assets'),
                  _InspectorSection(title: 'Actions'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectorHeader extends StatelessWidget {
  const _InspectorHeader();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 44,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Text(
              'INSPECTOR',
              style: TextStyle(
                color: VoidColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            Spacer(),
            Icon(Icons.more_horiz, size: 17, color: VoidColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _InspectorSection extends StatelessWidget {
  const _InspectorSection({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: true,
      title: Text(
        title,
        style: const TextStyle(
          color: VoidColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: const Text(
            'No selection',
            style: TextStyle(color: VoidColors.textMuted, fontSize: 11),
          ),
        ),
      ],
    );
  }
}
