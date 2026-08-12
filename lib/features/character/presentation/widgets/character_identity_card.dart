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
  });
  final String name, alias, height, hair, eyes, age;
  @override
  Widget build(BuildContext context) => VoidCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Character Identity', style: VoidTypography.headingMedium),
        const SizedBox(height: 18),
        for (final row in [
          ('Name', name),
          ('Alias', alias),
          ('Age', age),
          ('Height', height),
          ('Hair', hair),
          ('Eyes', eyes),
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
