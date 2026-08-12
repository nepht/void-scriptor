import 'package:flutter/material.dart';

import '../../../design_system/colors/void_colors.dart';
import 'inspector_resolver.dart';

class InspectorPanel extends StatelessWidget {
  const InspectorPanel({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: 310,
    decoration: const BoxDecoration(
      color: VoidColors.panel,
      border: Border(left: BorderSide(color: VoidColors.borderSoft)),
    ),
    child: const Column(
      children: [
        _InspectorHeader(),
        Divider(height: 1),
        Expanded(child: InspectorResolver()),
      ],
    ),
  );
}

class _InspectorHeader extends StatelessWidget {
  const _InspectorHeader();
  @override
  Widget build(BuildContext context) => const SizedBox(
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
