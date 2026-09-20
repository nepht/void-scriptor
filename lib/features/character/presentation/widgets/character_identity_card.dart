import 'package:flutter/material.dart';
import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';

class CharacterIdentityCard extends StatelessWidget {
  const CharacterIdentityCard({
    super.key,
    required this.name,
    required this.alias,
    required this.height,
    required this.hair,
    required this.eyes,
    required this.age,
    this.voice = '',
    this.compact = false,
  });
  final String name, alias, height, hair, eyes, age, voice;
  final bool compact;
  @override
  Widget build(BuildContext context) => VoidCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('CHARACTER CONCEPT', style: VoidTypography.headingMedium),
        const SizedBox(height: 6),
        Text(
          name.isEmpty ? '—' : name,
          style: VoidTypography.headingLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (alias.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(alias, style: VoidTypography.caption),
        ],
        SizedBox(height: compact ? 8 : 18),
        if (compact)
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              for (final row in [
                ('Name', name),
                ('Alias', alias),
                ('Age', age),
                ('Height', height),
                ('Hair', hair),
                ('Eyes', eyes),
              ])
                SizedBox(
                  width: 130,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(row.$1, style: VoidTypography.caption),
                      Text(
                        row.$2.isEmpty ? '—' : row.$2,
                        style: VoidTypography.body,
                      ),
                    ],
                  ),
                ),
            ],
          )
        else
          for (final row in [
            ('Name', name),
            ('Alias', alias),
            ('Age', age),
            ('Height', height),
            ('Hair', hair),
            ('Eyes', eyes),
            ('Voice', voice),
          ])
            _IdentityRow(label: row.$1, value: row.$2),
      ],
    ),
  );
}

class _IdentityRow extends StatelessWidget {
  const _IdentityRow({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 90, child: Text(label, style: VoidTypography.caption)),
        Expanded(
          child: Text(value.isEmpty ? '—' : value, style: VoidTypography.body),
        ),
      ],
    ),
  );
}
