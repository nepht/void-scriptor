// Sprint 111.22 - Activation, Cost, Curse & Limitation Rules.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_activation_rules.dart';

void main() {
  group('CostResource', () {
    test('has a defined set of resources with labels', () {
      expect(CostResource.values.length, greaterThanOrEqualTo(6));
      for (final r in CostResource.values) {
        expect(r.label, isNotEmpty);
      }
    });

    test('covers life, stamina, mana, memory, luck and bond', () {
      final names = CostResource.values.map((r) => r.name).toSet();
      expect(
        names,
        containsAll(['life', 'stamina', 'mana', 'memory', 'luck', 'bond']),
      );
    });
  });

  group('CurseSeverity', () {
    test('ladder carries strictly increasing weight', () {
      for (var i = 1; i < CurseSeverity.values.length; i++) {
        expect(
          CurseSeverity.values[i].weight,
          greaterThan(CurseSeverity.values[i - 1].weight),
        );
      }
    });

    test('every severity carries a label', () {
      for (final s in CurseSeverity.values) {
        expect(s.label, isNotEmpty);
      }
    });
  });

  group('ActivationRequirement', () {
    test('rejects empty requirement id', () {
      expect(
        () => ActivationRequirement.validated(
          requirementId: '',
          description: 'Speak the true name aloud',
        ),
        throwsArgumentError,
      );
    });

    test('rejects empty description', () {
      expect(
        () => ActivationRequirement.validated(
          requirementId: 'r1',
          description: '  ',
        ),
        throwsArgumentError,
      );
    });

    test('rejects blank optional fields', () {
      expect(
        () => ActivationRequirement.validated(
          requirementId: 'r1',
          description: 'ok',
          condition: ' ',
        ),
        throwsArgumentError,
      );
      expect(
        () => ActivationRequirement.validated(
          requirementId: 'r1',
          description: 'ok',
          note: '',
        ),
        throwsArgumentError,
      );
    });

    test('trims fields and keeps optional condition', () {
      final req = ActivationRequirement.validated(
        requirementId: ' r1 ',
        description: ' Under a full moon ',
        condition: 'night',
      );
      expect(req.requirementId, 'r1');
      expect(req.description, 'Under a full moon');
      expect(req.condition, 'night');
    });

    test('isConditional true only when a condition is present', () {
      final plain = ActivationRequirement.validated(
        requirementId: 'r1',
        description: 'Hold the hilt',
      );
      final conditional = ActivationRequirement.validated(
        requirementId: 'r2',
        description: 'Speak the name',
        condition: 'willing speaker',
      );
      expect(plain.isConditional, isFalse);
      expect(conditional.isConditional, isTrue);
    });
  });

  group('AbilityRule', () {
    test('rejects empty ability id or name', () {
      expect(
        () => AbilityRule.validated(abilityId: '', name: 'Fireward'),
        throwsArgumentError,
      );
      expect(
        () => AbilityRule.validated(abilityId: 'a1', name: ' '),
        throwsArgumentError,
      );
    });

    test('keeps trimmed optional description', () {
      final a = AbilityRule.validated(
        abilityId: ' a1 ',
        name: ' Fireward ',
        description: ' Blocks flame for one scene ',
      );
      expect(a.abilityId, 'a1');
      expect(a.name, 'Fireward');
      expect(a.description, 'Blocks flame for one scene');
    });

    test('rejects blank description when provided', () {
      expect(
        () => AbilityRule.validated(
          abilityId: 'a1',
          name: 'Fireward',
          description: '  ',
        ),
        throwsArgumentError,
      );
    });
  });

  group('CostEntry', () {
    test('rejects empty cost id or resource name', () {
      expect(
        () => CostEntry.validated(
          costId: '',
          resource: CostResource.mana,
          amount: 3,
        ),
        throwsArgumentError,
      );
      expect(
        () => CostEntry.validated(
          costId: 'c1',
          resource: null,
          resourceName: ' ',
          amount: 3,
        ),
        throwsArgumentError,
      );
    });

    test('rejects non-positive amount', () {
      expect(
        () => CostEntry.validated(
          costId: 'c1',
          resource: CostResource.life,
          amount: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => CostEntry.validated(
          costId: 'c2',
          resource: CostResource.life,
          amount: -1,
        ),
        throwsArgumentError,
      );
    });

    test('custom resource name is kept trimmed when enum absent', () {
      final c = CostEntry.validated(
        costId: ' c1 ',
        resource: null,
        resourceName: ' starlight ',
        amount: 2,
      );
      expect(c.resource, isNull);
      expect(c.resourceName, 'starlight');
    });

    test('resourceLabel prefers enum label', () {
      final known = CostEntry.validated(
        costId: 'c1',
        resource: CostResource.mana,
        amount: 2,
      );
      final custom = CostEntry.validated(
        costId: 'c2',
        resource: null,
        resourceName: 'starlight',
        amount: 2,
      );
      expect(known.resourceLabel, CostResource.mana.label);
      expect(custom.resourceLabel, 'starlight');
    });

    test('rejects blank note when provided', () {
      expect(
        () => CostEntry.validated(
          costId: 'c1',
          resource: CostResource.mana,
          amount: 2,
          note: ' ',
        ),
        throwsArgumentError,
      );
    });
  });

  group('CurseRule', () {
    test('rejects empty curse id or description', () {
      expect(
        () => CurseRule.validated(curseId: '', description: 'drains warmth'),
        throwsArgumentError,
      );
      expect(
        () => CurseRule.validated(curseId: 'k1', description: ''),
        throwsArgumentError,
      );
    });

    test('rejects severity out of 1..5 when provided', () {
      expect(
        () =>
            CurseRule.validated(curseId: 'k1', description: 'ok', severity: 0),
        throwsArgumentError,
      );
      expect(
        () =>
            CurseRule.validated(curseId: 'k2', description: 'ok', severity: 6),
        throwsArgumentError,
      );
    });

    test('keeps trimmed fields and optional bearer hint', () {
      final k = CurseRule.validated(
        curseId: ' k1 ',
        description: ' The blade drinks warmth ',
        severity: 3,
        bearerHint: 'first wielder only',
      );
      expect(k.curseId, 'k1');
      expect(k.description, 'The blade drinks warmth');
      expect(k.severity, 3);
      expect(k.bearerHint, 'first wielder only');
    });

    test('rejects blank optional fields', () {
      expect(
        () => CurseRule.validated(
          curseId: 'k1',
          description: 'ok',
          bearerHint: ' ',
        ),
        throwsArgumentError,
      );
    });
  });

  group('CooldownRule', () {
    test('rejects empty cooldown id', () {
      expect(
        () => CooldownRule.validated(cooldownId: '', durationTicks: 10),
        throwsArgumentError,
      );
    });

    test('rejects negative duration', () {
      expect(
        () => CooldownRule.validated(cooldownId: 'd1', durationTicks: -1),
        throwsArgumentError,
      );
    });

    test('zero duration is allowed (instant re-use)', () {
      final d = CooldownRule.validated(cooldownId: 'd1', durationTicks: 0);
      expect(d.durationTicks, 0);
      expect(d.isImmediate, isTrue);
    });

    test('isReadyAt uses half-open window end = start + duration', () {
      final d = CooldownRule.validated(
        cooldownId: 'd1',
        durationTicks: 10,
        label: 'One night',
      );
      expect(d.isImmediate, isFalse);
      expect(d.isReadyAt(lastUseTick: 100, currentTick: 109), isFalse);
      expect(d.isReadyAt(lastUseTick: 100, currentTick: 110), isTrue);
      expect(d.isReadyAt(lastUseTick: 100, currentTick: 250), isTrue);
    });

    test('rejects blank label and note when provided', () {
      expect(
        () => CooldownRule.validated(
          cooldownId: 'd1',
          durationTicks: 1,
          label: ' ',
        ),
        throwsArgumentError,
      );
      expect(
        () => CooldownRule.validated(
          cooldownId: 'd1',
          durationTicks: 1,
          note: '',
        ),
        throwsArgumentError,
      );
    });
  });

  group('LimitationRule', () {
    test('rejects empty limitation id or description', () {
      expect(
        () => LimitationRule.validated(limitationId: '', description: 'x'),
        throwsArgumentError,
      );
      expect(
        () => LimitationRule.validated(limitationId: 'l1', description: ''),
        throwsArgumentError,
      );
    });

    test('rejects non-positive maxUses when provided', () {
      expect(
        () => LimitationRule.validated(
          limitationId: 'l1',
          description: 'ok',
          maxUses: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => LimitationRule.validated(
          limitationId: 'l2',
          description: 'ok',
          maxUses: -3,
        ),
        throwsArgumentError,
      );
    });

    test('allowsAnyUseCount true when maxUses absent', () {
      final l = LimitationRule.validated(
        limitationId: 'l1',
        description: 'Only outside homeland',
      );
      expect(l.allowsAnyUseCount, isTrue);
      expect(l.hasUseCap, isFalse);
      expect(l.remainingUses(usedCount: 3), isNull);
      expect(l.isExhausted(usedCount: 999), isFalse);
    });

    test('remainingUses counts against cap and floors at zero', () {
      final l = LimitationRule.validated(
        limitationId: 'l1',
        description: 'Seven times only',
        maxUses: 7,
      );
      expect(l.hasUseCap, isTrue);
      expect(l.remainingUses(usedCount: 2), 5);
      expect(l.remainingUses(usedCount: 7), 0);
      expect(l.remainingUses(usedCount: 9), 0);
      expect(l.isExhausted(usedCount: 7), isTrue);
      expect(l.isExhausted(usedCount: 6), isFalse);
    });

    test('rejects blank optional fields', () {
      expect(
        () => LimitationRule.validated(
          limitationId: 'l1',
          description: 'ok',
          context: ' ',
        ),
        throwsArgumentError,
      );
    });
  });

  group('PowerSystemLink', () {
    test('rejects empty system id', () {
      expect(
        () => PowerSystemLink.validated(systemId: ''),
        throwsArgumentError,
      );
    });

    test('keeps trimmed system id and optional role/note', () {
      final link = PowerSystemLink.validated(
        systemId: ' ps1 ',
        systemName: ' Aurean Resonance ',
        role: 'anchor',
        note: 'requires attunement',
      );
      expect(link.systemId, 'ps1');
      expect(link.systemName, 'Aurean Resonance');
      expect(link.role, 'anchor');
      expect(link.note, 'requires attunement');
    });

    test('rejects blank optional fields', () {
      expect(
        () => PowerSystemLink.validated(systemId: 'ps1', systemName: ' '),
        throwsArgumentError,
      );
      expect(
        () => PowerSystemLink.validated(systemId: 'ps1', role: ''),
        throwsArgumentError,
      );
      expect(
        () => PowerSystemLink.validated(systemId: 'ps1', note: ' '),
        throwsArgumentError,
      );
    });
  });

  group('ArtifactRules', () {
    test('rejects empty artifact id', () {
      expect(
        () => ArtifactRules.validated(artifactId: ''),
        throwsArgumentError,
      );
    });

    test('accepts minimal record with only artifact id', () {
      final r = ArtifactRules.validated(artifactId: 'art-1');
      expect(r.artifactId, 'art-1');
      expect(r.requirementCount, 0);
      expect(r.abilityCount, 0);
      expect(r.costCount, 0);
      expect(r.curseCount, 0);
      expect(r.cooldownCount, 0);
      expect(r.limitationCount, 0);
      expect(r.linkCount, 0);
      expect(r.isActiveRulesEmpty, isTrue);
    });

    test('rejects duplicate ids within each collection', () {
      expect(
        () => ArtifactRules.validated(
          artifactId: 'art-1',
          requirements: [
            ActivationRequirement.validated(
              requirementId: 'r1',
              description: 'a',
            ),
            ActivationRequirement.validated(
              requirementId: 'r1',
              description: 'b',
            ),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => ArtifactRules.validated(
          artifactId: 'art-1',
          abilities: [
            AbilityRule.validated(abilityId: 'a1', name: 'x'),
            AbilityRule.validated(abilityId: 'a1', name: 'y'),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => ArtifactRules.validated(
          artifactId: 'art-1',
          costs: [
            CostEntry.validated(
              costId: 'c1',
              resource: CostResource.mana,
              amount: 1,
            ),
            CostEntry.validated(
              costId: 'c1',
              resource: CostResource.life,
              amount: 2,
            ),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => ArtifactRules.validated(
          artifactId: 'art-1',
          curses: [
            CurseRule.validated(curseId: 'k1', description: 'a'),
            CurseRule.validated(curseId: 'k1', description: 'b'),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => ArtifactRules.validated(
          artifactId: 'art-1',
          cooldowns: [
            CooldownRule.validated(cooldownId: 'd1', durationTicks: 1),
            CooldownRule.validated(cooldownId: 'd1', durationTicks: 2),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => ArtifactRules.validated(
          artifactId: 'art-1',
          limitations: [
            LimitationRule.validated(limitationId: 'l1', description: 'a'),
            LimitationRule.validated(limitationId: 'l1', description: 'b'),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => ArtifactRules.validated(
          artifactId: 'art-1',
          powerSystemLinks: [
            PowerSystemLink.validated(systemId: 'ps1'),
            PowerSystemLink.validated(systemId: 'ps1'),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('collections are immutable', () {
      final r = ArtifactRules.validated(
        artifactId: 'art-1',
        requirements: [
          ActivationRequirement.validated(
            requirementId: 'r1',
            description: 'a',
          ),
        ],
        costs: [
          CostEntry.validated(
            costId: 'c1',
            resource: CostResource.mana,
            amount: 1,
          ),
        ],
      );
      expect(
        () => r.requirements.add(
          ActivationRequirement.validated(
            requirementId: 'r2',
            description: 'b',
          ),
        ),
        throwsUnsupportedError,
      );
      expect(() => r.costs.clear(), throwsUnsupportedError);
    });

    test('requiresActivation and hasAbility lookups', () {
      final r = ArtifactRules.validated(
        artifactId: 'art-1',
        requirements: [
          ActivationRequirement.validated(
            requirementId: 'r1',
            description: 'a',
          ),
        ],
        abilities: [AbilityRule.validated(abilityId: 'a1', name: 'Fireward')],
      );
      expect(r.requiresActivation, isTrue);
      expect(r.hasAbility('a1'), isTrue);
      expect(r.hasAbility('a9'), isFalse);
      expect(r.abilityNameFor('a1'), 'Fireward');
      expect(r.abilityNameFor('missing'), isNull);
    });

    test('totalCostFor sums per resource including custom names', () {
      final r = ArtifactRules.validated(
        artifactId: 'art-1',
        costs: [
          CostEntry.validated(
            costId: 'c1',
            resource: CostResource.mana,
            amount: 3,
          ),
          CostEntry.validated(
            costId: 'c2',
            resource: CostResource.mana,
            amount: 4,
          ),
          CostEntry.validated(
            costId: 'c3',
            resource: null,
            resourceName: 'starlight',
            amount: 2,
          ),
        ],
      );
      expect(r.totalCostFor(resource: CostResource.mana), 7);
      expect(r.totalCostFor(resourceName: 'Starlight'), 2);
      expect(r.totalCostFor(resource: CostResource.life), 0);
    });

    test('maxCurseSeverity reports ladder value and zero without curses', () {
      final empty = ArtifactRules.validated(artifactId: 'art-1');
      expect(empty.maxCurseSeverity, 0);
      final r = ArtifactRules.validated(
        artifactId: 'art-1',
        curses: [
          CurseRule.validated(curseId: 'k1', description: 'a', severity: 2),
          CurseRule.validated(curseId: 'k2', description: 'b', severity: 4),
          CurseRule.validated(curseId: 'k3', description: 'c'),
        ],
      );
      expect(r.maxCurseSeverity, 4);
    });

    test('isCursedAtLeast compares severity ladder', () {
      final r = ArtifactRules.validated(
        artifactId: 'art-1',
        curses: [
          CurseRule.validated(curseId: 'k1', description: 'a', severity: 3),
        ],
      );
      expect(r.isCursedAtLeast(3), isTrue);
      expect(r.isCursedAtLeast(4), isFalse);
    });

    test('linksToSystem finds declared power system links', () {
      final r = ArtifactRules.validated(
        artifactId: 'art-1',
        powerSystemLinks: [
          PowerSystemLink.validated(systemId: 'ps1', role: 'anchor'),
        ],
      );
      expect(r.linksToSystem('ps1'), isTrue);
      expect(r.linksToSystem('ps2'), isFalse);
    });

    test('systemIds is sorted and deduplicated view of links', () {
      final r = ArtifactRules.validated(
        artifactId: 'art-1',
        powerSystemLinks: [
          PowerSystemLink.validated(systemId: 'ps-b'),
          PowerSystemLink.validated(systemId: 'ps-a'),
        ],
      );
      expect(r.systemIds, ['ps-a', 'ps-b']);
    });

    test('cooldownsReadyAt reports every cooldown ready at tick', () {
      final r = ArtifactRules.validated(
        artifactId: 'art-1',
        cooldowns: [
          CooldownRule.validated(cooldownId: 'd1', durationTicks: 5),
          CooldownRule.validated(cooldownId: 'd2', durationTicks: 10),
        ],
      );
      final lastUse = {'d1': 100, 'd2': 100};
      expect(
        r.cooldownsReadyAt(lastUseTickByCooldown: lastUse, currentTick: 104),
        isFalse,
      );
      expect(
        r.cooldownsReadyAt(lastUseTickByCooldown: lastUse, currentTick: 110),
        isTrue,
      );
      // unknown cooldown id counts as ready (no history yet)
      expect(
        r.cooldownsReadyAt(lastUseTickByCooldown: {}, currentTick: 0),
        isTrue,
      );
    });
  });

  group('ArtifactRulesCatalog', () {
    test('empty catalog', () {
      final c = ArtifactRulesCatalog.empty();
      expect(c.count, 0);
      expect(c.artifactIds, isEmpty);
      expect(c.mostCursedArtifactId, isNull);
    });

    test('rejects duplicate artifact ids', () {
      expect(
        () => ArtifactRulesCatalog.withRecords([
          ArtifactRules.validated(artifactId: 'a'),
          ArtifactRules.validated(artifactId: 'a'),
        ]),
        throwsArgumentError,
      );
    });

    test('records sorted by artifact id and lookup works', () {
      final c = ArtifactRulesCatalog.withRecords([
        ArtifactRules.validated(artifactId: 'zeta'),
        ArtifactRules.validated(artifactId: 'alpha'),
      ]);
      expect(c.artifactIds, ['alpha', 'zeta']);
      expect(c.rulesFor('alpha')?.artifactId, 'alpha');
      expect(c.rulesFor('nope'), isNull);
    });

    test('artifactsUsingPowerSystem deterministic sorted list', () {
      final c = ArtifactRulesCatalog.withRecords([
        ArtifactRules.validated(
          artifactId: 'b',
          powerSystemLinks: [PowerSystemLink.validated(systemId: 'ps1')],
        ),
        ArtifactRules.validated(artifactId: 'a'),
        ArtifactRules.validated(
          artifactId: 'c',
          powerSystemLinks: [PowerSystemLink.validated(systemId: 'ps1')],
        ),
      ]);
      expect(c.artifactsUsingPowerSystem('ps1'), ['b', 'c']);
      expect(c.artifactsUsingPowerSystem('ps9'), isEmpty);
    });

    test('mostCursedArtifactId picks highest severity, null when none', () {
      final c = ArtifactRulesCatalog.withRecords([
        ArtifactRules.validated(
          artifactId: 'a',
          curses: [
            CurseRule.validated(curseId: 'k1', description: 'x', severity: 2),
          ],
        ),
        ArtifactRules.validated(
          artifactId: 'b',
          curses: [
            CurseRule.validated(curseId: 'k2', description: 'y', severity: 5),
          ],
        ),
        ArtifactRules.validated(artifactId: 'c'),
      ]);
      expect(c.mostCursedArtifactId, 'b');
    });

    test('totalCostAcross sums one resource over catalog', () {
      final c = ArtifactRulesCatalog.withRecords([
        ArtifactRules.validated(
          artifactId: 'a',
          costs: [
            CostEntry.validated(
              costId: 'c1',
              resource: CostResource.mana,
              amount: 3,
            ),
          ],
        ),
        ArtifactRules.validated(
          artifactId: 'b',
          costs: [
            CostEntry.validated(
              costId: 'c2',
              resource: CostResource.mana,
              amount: 4,
            ),
          ],
        ),
      ]);
      expect(c.totalCostAcross(resource: CostResource.mana), 7);
      expect(c.totalCostAcross(resource: CostResource.life), 0);
    });
  });
}
