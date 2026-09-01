import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/character/domain/character_scope_layers.dart';

// RED test: contract items for Sprint 145.26 Character Scope Layers.
// Every assertion below references a type/function that does NOT exist yet.

void main() {
  group('CharacterScopeLayer discriminator', () {
    test('enum defines three layers', () {
      expect(CharacterScopeLayer.values.length, 3);
      expect(
        CharacterScopeLayer.values,
        containsAll([
          CharacterScopeLayer.canonical,
          CharacterScopeLayer.universeTimeline,
          CharacterScopeLayer.novelSpecific,
        ]),
      );
    });

    test('precedence order canonical -> universeTimeline -> novelSpecific', () {
      expect(CharacterScopeLayer.canonical.priority, 0);
      expect(CharacterScopeLayer.universeTimeline.priority, 1);
      expect(CharacterScopeLayer.novelSpecific.priority, 2);
    });
  });

  group('CharacterScopeField ownership', () {
    test(
      'canonical owns IDENTITY/BASE_VOICE/BASE_VISUAL_PROFILE/BASE_RELATION_REFERENCES',
      () {
        final fields = CharacterScopeFieldOwnership.fieldsFor(
          CharacterScopeLayer.canonical,
        );
        expect(fields, contains('IDENTITY'));
        expect(fields, contains('BASE_VOICE'));
        expect(fields, contains('BASE_VISUAL_PROFILE'));
        expect(fields, contains('BASE_RELATION_REFERENCES'));
      },
    );

    test(
      'universeTimeline owns ALTERNATE_HISTORY/ALTERNATE_RELATIONSHIPS/ERA_SPECIFIC_FACTS',
      () {
        final fields = CharacterScopeFieldOwnership.fieldsFor(
          CharacterScopeLayer.universeTimeline,
        );
        expect(fields, contains('ALTERNATE_HISTORY'));
        expect(fields, contains('ALTERNATE_RELATIONSHIPS'));
        expect(fields, contains('ERA_SPECIFIC_FACTS'));
      },
    );

    test('novelSpecific owns seven novel-state fields', () {
      final fields = CharacterScopeFieldOwnership.fieldsFor(
        CharacterScopeLayer.novelSpecific,
      );
      expect(fields, contains('ROLE'));
      expect(fields, contains('ARC'));
      expect(fields, contains('CURRENT_LOCATION'));
      expect(fields, contains('CURRENT_AGE'));
      expect(fields, contains('CURRENT_STATUS'));
      expect(fields, contains('SCENE_POV'));
      expect(fields, contains('NOVEL_RELATION_STATE'));
    });

    test('ownership sets are disjoint', () {
      final a = CharacterScopeFieldOwnership.fieldsFor(
        CharacterScopeLayer.canonical,
      ).toSet();
      final b = CharacterScopeFieldOwnership.fieldsFor(
        CharacterScopeLayer.universeTimeline,
      ).toSet();
      final c = CharacterScopeFieldOwnership.fieldsFor(
        CharacterScopeLayer.novelSpecific,
      ).toSet();
      expect(a.intersection(b), isEmpty);
      expect(a.intersection(c), isEmpty);
      expect(b.intersection(c), isEmpty);
    });
  });

  group('CharacterScopeState null-vs-clear semantics', () {
    test('null inherits from lower layer; lower layers untouched', () {
      final canonical = CharacterScopeState.canonical(
        identity: 'Qowner identity',
      );
      final novel = CharacterScopeState.novelSpecific(role: null);

      final effective = CharacterScopeEffectiveResolver(
        canonical: canonical,
        universeTimeline: const CharacterScopeState.empty(),
        novelSpecific: novel,
      );

      expect(effective.identity, 'Qowner identity');
      expect(effective.role, isNull);
    });

    test('explicit override at higher layer wins over lower', () {
      final canonical = CharacterScopeState.canonical(
        identity: 'base identity',
      );
      final novel = CharacterScopeState.novelSpecific(role: 'Villain');

      final effective = CharacterScopeEffectiveResolver(
        canonical: canonical,
        universeTimeline: const CharacterScopeState.empty(),
        novelSpecific: novel,
      );

      expect(effective.role, 'Villain');
      expect(effective.identity, 'base identity');
    });
  });

  group('CharacterScopePrecedence', () {
    test(
      'novelSpecific overrides universeTimeline which overrides canonical',
      () {
        final canonical = CharacterScopeState.canonical(currentStatus: 'Alive');
        final universe = CharacterScopeState.universeTimeline(
          currentStatus: 'Missing',
        );
        final novel = CharacterScopeState.novelSpecific(currentStatus: 'Dead');

        final effective = CharacterScopeEffectiveResolver(
          canonical: canonical,
          universeTimeline: universe,
          novelSpecific: novel,
        );
        expect(effective.currentStatus, 'Dead');

        final noNovel = CharacterScopeEffectiveResolver(
          canonical: canonical,
          universeTimeline: universe,
          novelSpecific: const CharacterScopeState.empty(),
        );
        expect(noNovel.currentStatus, 'Missing');

        final onlyCanonical = CharacterScopeEffectiveResolver(
          canonical: canonical,
          universeTimeline: const CharacterScopeState.empty(),
          novelSpecific: const CharacterScopeState.empty(),
        );
        expect(onlyCanonical.currentStatus, 'Alive');
      },
    );

    test('clearing an override falls back to the layer below it', () {
      final canonical = CharacterScopeState.canonical(
        currentLocation: 'Pole of Creation',
      );
      final universe = CharacterScopeState.universeTimeline(
        currentLocation: 'Void Sea',
      );

      final withUniverse = CharacterScopeEffectiveResolver(
        canonical: canonical,
        universeTimeline: universe,
        novelSpecific: const CharacterScopeState.empty(),
      );
      expect(withUniverse.currentLocation, 'Void Sea');

      final withoutUniverse = CharacterScopeEffectiveResolver(
        canonical: canonical,
        universeTimeline: const CharacterScopeState.empty(),
        novelSpecific: const CharacterScopeState.empty(),
      );
      expect(withoutUniverse.currentLocation, 'Pole of Creation');
    });
  });

  group('Scoped command contract', () {
    test('rejects a field not owned by the target scope', () async {
      final command = UpdateCharacterScopeCommand(
        id: 'scope-1',
        projectId: 'p1',
        targetLayer: CharacterScopeLayer.novelSpecific,
        field: 'ALTERNATE_HISTORY',
        value: 'rewritten history',
      );
      await expectLater(command.execute(), throwsArgumentError);
    });

    test('accepts a field owned by the target scope', () async {
      final command = UpdateCharacterScopeCommand(
        id: 'scope-2',
        projectId: 'p1',
        targetLayer: CharacterScopeLayer.novelSpecific,
        field: 'ROLE',
        value: 'Villain',
      );
      await expectLater(command.execute(), completes);
    });

    test('payload carries the explicit scope discriminator', () {
      final command = UpdateCharacterScopeCommand(
        id: 'scope-3',
        projectId: 'p1',
        targetLayer: CharacterScopeLayer.universeTimeline,
        field: 'ERA_SPECIFIC_FACTS',
        value: 'era fact',
      );
      expect(command.payload['scope'], 'universeTimeline');
      expect(command.payload['field'], 'ERA_SPECIFIC_FACTS');
      expect(command.payload['value'], 'era fact');
    });
  });

  group('Effective resolver does not mutate inputs', () {
    test('resolving leaves canonical and override states untouched', () {
      final canonical = CharacterScopeState.canonical(identity: 'Qowner');
      final novel = CharacterScopeState.novelSpecific(role: 'Villain');

      CharacterScopeEffectiveResolver(
        canonical: canonical,
        universeTimeline: const CharacterScopeState.empty(),
        novelSpecific: novel,
      );

      expect(canonical.identity, 'Qowner');
      expect(canonical.role, isNull);
      expect(novel.role, 'Villain');
      expect(novel.identity, isNull);
    });
  });
}
