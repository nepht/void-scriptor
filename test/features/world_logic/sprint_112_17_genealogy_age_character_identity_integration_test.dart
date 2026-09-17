import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/genealogy_age_character_identity_integration.dart';

void main() {
  const integration = GenealogyAgeCharacterIdentityIntegration();

  GenealogyAgeCharacterIdentityScenario scenario() {
    return const GenealogyAgeCharacterIdentityScenario(
      lifespans: <String, CharacterLifespan>{
        'queen': CharacterLifespan(birthTick: 0, deathTick: 100),
        'heir': CharacterLifespan(birthTick: 20),
      },
      familyRelations: <FamilyRelation>[
        FamilyRelation(
          parentId: 'queen',
          childId: 'heir',
          kind: FamilyRelationKind.biological,
        ),
      ],
      names: <String, List<HistoricalCharacterName>>{
        'heir': <HistoricalCharacterName>[
          HistoricalCharacterName(name: 'Aren', validFrom: 0, validUntil: 29),
          HistoricalCharacterName(name: 'Aren the Heir', validFrom: 30),
        ],
      },
      inheritance: <String, List<String>>{
        'queen': <String>['heir'],
      },
      identityLinks: <IdentityLink>[
        IdentityLink(
          sourceId: 'heir',
          targetId: 'heir-profile',
          kind: IdentityLinkKind.alias,
        ),
      ],
    );
  }

  test(
    'birth_death_dates exposes lifespan and validates death after birth',
    () {
      final result = integration.evaluate(scenario(), atTick: 50);
      expect(result.lifespan('queen')?.isAlive, isTrue);
      expect(result.lifespan('queen')?.birthTick, 0);
    },
  );

  test('age_at_scene calculates age at the selected world tick', () {
    expect(integration.evaluate(scenario(), atTick: 35).ageOf('heir'), 15);
  });

  test('family_rules rejects parent-child cycles and returns family links', () {
    final result = integration.evaluate(scenario(), atTick: 35);
    expect(result.parentsOf('heir'), <String>['queen']);
    expect(
      () => integration.validateRelations(const <FamilyRelation>[
        FamilyRelation(
          parentId: 'a',
          childId: 'b',
          kind: FamilyRelationKind.biological,
        ),
        FamilyRelation(
          parentId: 'b',
          childId: 'a',
          kind: FamilyRelationKind.biological,
        ),
      ]),
      throwsA(isA<FamilyRuleViolation>()),
    );
  });

  test('historical_names resolves the name valid at the scene tick', () {
    final result = integration.evaluate(scenario(), atTick: 35);
    expect(result.nameOf('heir'), 'Aren the Heir');
  });

  test('inheritance_order preserves the explicit deterministic order', () {
    final result = integration.evaluate(scenario(), atTick: 35);
    expect(result.inheritanceOrderFor('queen'), <String>['heir']);
  });

  test(
    'identity_links resolves only links active for the selected identity',
    () {
      final result = integration.evaluate(scenario(), atTick: 35);
      expect(result.linksFor('heir').single.targetId, 'heir-profile');
    },
  );
}
