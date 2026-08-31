// Sprint 111.5 - Temporal, Regional & Cultural Scope.
//
// Tests the domain contract for EncyclopediaScope covering validity_ranges,
// locations, cultures, factions (with role), languages, and world_branches,
// plus the registry's integrity guards and deterministic query helpers.
//

// Library is pure Dart, deterministic, and free of persistence, UI, locale,
// network, wall clock, and random input.

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_scope.dart';

void main() {
  group('validity_range', () {
    test('containsTick returns true inside open-ended and bounded ranges', () {
      final open = ValidityRange.validated(validFrom: 0, validUntil: null);
      final bounded = ValidityRange.validated(validFrom: 10, validUntil: 25);

      expect(open.containsTick(0), isTrue);
      expect(open.containsTick(99999), isTrue);
      expect(bounded.containsTick(10), isTrue);
      expect(bounded.containsTick(25), isTrue);
      expect(bounded.containsTick(9), isFalse);
      expect(bounded.containsTick(26), isFalse);
    });

    test(
      'factory rejects negative validFrom and validUntil before validFrom',
      () {
        expect(
          () => ValidityRange.validated(validFrom: -1, validUntil: null),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => ValidityRange.validated(validFrom: 10, validUntil: 5),
          throwsA(isA<ArgumentError>()),
        );
      },
    );
  });

  group('scope refs', () {
    test('location/culture/language ref rejects empty id', () {
      expect(
        () => ScopeLocationRef.validated(locationId: '', kind: 'city'),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => ScopeCultureRef.validated(cultureId: '   '),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => ScopeLanguageRef.validated(languageId: ''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('faction ref carries role and rejects empty id', () {
      const owning = ScopeFactionRole.owning;
      final ref = ScopeFactionRef.validated(
        factionId: 'merchant-guild',
        role: owning,
      );
      expect(ref.factionId, 'merchant-guild');
      expect(ref.role, owning);

      expect(
        () => ScopeFactionRef.validated(factionId: '', role: owning),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('branch ref distinguishes prime from variant', () {
      final prime = ScopeBranchRef.validated(branchId: 'prime', isPrime: true);
      final variant = ScopeBranchRef.validated(
        branchId: 'age-of-ash',
        isPrime: false,
      );

      expect(prime.isPrime, isTrue);
      expect(variant.isPrime, isFalse);

      expect(
        () => ScopeBranchRef.validated(branchId: '', isPrime: true),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('encyclopedia scope', () {
    test('default scope has no facets and isAlwaysApplicable', () {
      const empty = EncyclopediaScope.empty;
      expect(empty.isAlwaysApplicable, isTrue);
      expect(empty.hasAnyFacet, isFalse);
      expect(empty.activeAt(0), isTrue);
      expect(empty.forBranch('prime'), isTrue);
    });

    test('scope with only locations does not claim cultural coverage', () {
      final scope = EncyclopediaScope(
        locations: [
          ScopeLocationRef.validated(locationId: 'havens-rest', kind: 'city'),
        ],
      );

      expect(scope.hasAnyFacet, isTrue);
      expect(scope.isAlwaysApplicable, isFalse);
      expect(scope.cultures, isEmpty);
      expect(scope.forLocation('havens-rest'), isTrue);
      expect(scope.forLocation('other'), isFalse);
    });
  });

  group('scope registry', () {
    test('rejects duplicate scope ids', () {
      final registry = ScopeRegistry();
      registry.register(EncyclopediaScope.empty, id: 'sp:cosmology:prime');
      expect(
        () => registry.register(
          EncyclopediaScope.empty,
          id: 'sp:cosmology:prime',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects empty scope id', () {
      final registry = ScopeRegistry();
      expect(
        () => registry.register(EncyclopediaScope.empty, id: ''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('scope returns the registered scope or null', () {
      final factionScope = EncyclopediaScope(
        factions: [
          ScopeFactionRef.validated(
            factionId: 'merchant-guild',
            role: ScopeFactionRole.owning,
          ),
        ],
      );

      final registry = ScopeRegistry();
      registry.register(factionScope, id: 'sp:bank:prime');

      expect(registry.scopeFor('sp:bank:prime'), equals(factionScope));
      expect(registry.scopeFor('missing'), isNull);
    });
  });

  group('scope query', () {
    EncyclopediaScope buildSample() {
      return EncyclopediaScope(
        validity: ValidityRange.validated(validFrom: 5, validUntil: 20),
        locations: [
          ScopeLocationRef.validated(locationId: 'havens-rest', kind: 'city'),
          ScopeLocationRef.validated(locationId: 'thornwood', kind: 'forest'),
        ],
        cultures: [ScopeCultureRef.validated(cultureId: 'aelyr')],
        factions: [
          ScopeFactionRef.validated(
            factionId: 'merchant-guild',
            role: ScopeFactionRole.owning,
          ),
          ScopeFactionRef.validated(
            factionId: 'thorn-court',
            role: ScopeFactionRole.opposedTo,
          ),
        ],

        languages: [
          ScopeLanguageRef.validated(languageId: 'common'),
          ScopeLanguageRef.validated(languageId: 'aelyri'),
        ],
        branches: [
          ScopeBranchRef.validated(branchId: 'prime', isPrime: true),
          ScopeBranchRef.validated(branchId: 'age-of-ash', isPrime: false),
        ],
      );
    }

    test('activeAt respects validity range', () {
      final scope = EncyclopediaScope(
        validity: ValidityRange.validated(validFrom: 5, validUntil: 20),
      );
      expect(scope.activeAt(4), isFalse);
      expect(scope.activeAt(5), isTrue);
      expect(scope.activeAt(20), isTrue);
      expect(scope.activeAt(21), isFalse);
    });

    test('forBranch matches when no branch facet is declared', () {
      final scope = EncyclopediaScope(
        cultures: [ScopeCultureRef.validated(cultureId: 'aelyr')],
      );
      expect(scope.forBranch('prime'), isTrue);
      expect(scope.forBranch('age-of-ash'), isTrue);
    });

    test('forBranch narrows to declared branches', () {
      final scope = buildSample();
      expect(scope.forBranch('prime'), isTrue);
      expect(scope.forBranch('age-of-ash'), isTrue);
      expect(scope.forBranch('unmapped'), isFalse);
    });

    test('forLocation / forCulture / forLanguage / forFaction filter ids', () {
      final scope = buildSample();
      expect(scope.forLocation('havens-rest'), isTrue);
      expect(scope.forLocation('skyhold'), isFalse);
      expect(scope.forCulture('aelyr'), isTrue);
      expect(scope.forCulture('highland'), isFalse);
      expect(scope.forLanguage('common'), isTrue);
      expect(scope.forLanguage('klingon'), isFalse);
      expect(scope.forFaction('merchant-guild'), isTrue);
      expect(scope.forFaction('skyhold-wardens'), isFalse);
    });

    test('explain summarizes facets and validity for diagnostics', () {
      final scope = buildSample();
      final summary = scope.explain();

      expect(summary, contains('validity=5..20'));
      expect(summary, contains('locations=2'));
      expect(summary, contains('cultures=1'));
      expect(summary, contains('factions=2'));
      expect(summary, contains('languages=2'));
      expect(summary, contains('branches=2'));
    });
  });
}
