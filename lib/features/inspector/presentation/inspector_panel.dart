import 'package:flutter/material.dart';

import 'inspector_resolver.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class InspectorPanel extends StatelessWidget {
  const InspectorPanel({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: 310,
    decoration: BoxDecoration(
      color: context.palette.panel,
      border: Border(left: BorderSide(color: context.palette.borderSoft)),
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
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Text(
            'INSPECTOR',
            style: TextStyle(
              color: context.palette.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const Spacer(),
          Icon(Icons.more_horiz, size: 17, color: context.palette.textMuted),
        ],
      ),
    ),
  );
}
