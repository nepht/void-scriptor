import 'package:flutter/material.dart';
import '../../../../design_system/typography/void_typography.dart';

class InspectorBody extends StatelessWidget {
  const InspectorBody({
    super.key,
    required this.name,
    required this.type,
    required this.sections,
  });
  final String name, type;
  final List<String> sections;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(name, style: VoidTypography.title),
      const SizedBox(height: 4),
      Text(type, style: VoidTypography.caption),
      const SizedBox(height: 22),
      for (final section in sections)
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(section, style: VoidTypography.title),
              const SizedBox(height: 8),
              Text(
                section == 'Relations' ? 'No relations yet' : '—',
                style: VoidTypography.caption,
              ),
            ],
          ),
        ),
    ],
  );
}
