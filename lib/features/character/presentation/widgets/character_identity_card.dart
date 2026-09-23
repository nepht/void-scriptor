import 'package:flutter/material.dart';
import '../../../../design_system/theme/void_theme_context.dart';
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
    this.biography = '',
    this.personality = '',
    this.gender = '',
    this.compact = false,
    this.designSheet = false,
  });
  final String name;
  final String alias;
  final String height;
  final String hair;
  final String eyes;
  final String age;
  final String voice;
  final String biography;
  final String personality;
  final String gender;
  final bool compact;
  final bool designSheet;

  @override
  Widget build(BuildContext context) => designSheet
      ? _DesignSheetIdentity(
          name: name,
          alias: alias,
          age: age,
          height: height,
          gender: gender,
          voice: voice,
          biography: biography,
          personality: personality,
        )
      : VoidCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CHARACTER CONCEPT',
                style: VoidTypography.headingMedium,
              ),
              const Text('Character Identity', style: VoidTypography.caption),
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

class _DesignSheetIdentity extends StatelessWidget {
  const _DesignSheetIdentity({
    required this.name,
    required this.alias,
    required this.age,
    required this.height,
    required this.gender,
    required this.voice,
    required this.biography,
    required this.personality,
  });

  final String name;
  final String alias;
  final String age;
  final String height;
  final String gender;
  final String voice;
  final String biography;
  final String personality;

  String get concept {
    if (biography.trim().isNotEmpty) return biography.trim();
    if (personality.trim().isNotEmpty) return personality.trim();
    return 'Add a biography or personality note to define this character concept.';
  }

  @override
  Widget build(BuildContext context) => VoidCard(
    padding: const EdgeInsets.all(12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 24,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? '—' : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: VoidTypography.characterName,
              ),
              const SizedBox(height: 3),
              Text(
                alias.isEmpty ? 'Character' : alias,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: VoidTypography.characterSubtitle.copyWith(
                  color: context.palette.primaryBright,
                ),
              ),
            ],
          ),
        ),
        _ConceptDivider(color: context.palette.borderSoft),
        Expanded(
          flex: 28,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _DesignFact(label: 'AGE', value: age),
                _DesignFact(label: 'HEIGHT', value: height),
                _DesignFact(label: 'GENDER', value: gender),
                _DesignFact(label: 'Voice', value: voice),
              ],
            ),
          ),
        ),
        _ConceptDivider(color: context.palette.borderSoft),
        Expanded(
          flex: 48,
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CHARACTER CONCEPT', style: VoidTypography.caption),
                const SizedBox(height: 5),
                Text(
                  concept,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: VoidTypography.caption.copyWith(height: 1.35),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _ConceptDivider extends StatelessWidget {
  const _ConceptDivider({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 84, color: color);
}

class _DesignFact extends StatelessWidget {
  const _DesignFact({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        SizedBox(
          width: 54,
          child: Text(
            label,
            style: VoidTypography.caption.copyWith(
              color: context.palette.primaryBright,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: VoidTypography.caption,
          ),
        ),
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
