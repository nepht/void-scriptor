import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/documentation_transparency.dart';

void main() {
  group('Sprint 110.48 Documentation Model Transparency', () {
    group('TransparencyEntry validation', () {
      test('rejects empty id', () {
        expect(
          () => TransparencyEntry(
            id: '',
            kind: TransparencyEntryKind.modelCard,
            title: 'World Clock',
            subjectId: 'world_clock',
            summary: 'deterministic clock',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
      test('rejects empty title', () {
        expect(
          () => TransparencyEntry(
            id: 'm.wc',
            kind: TransparencyEntryKind.modelCard,
            title: '',
            subjectId: 'world_clock',
            summary: 'deterministic clock',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
      test('rejects empty subjectId', () {
        expect(
          () => TransparencyEntry(
            id: 'm.wc',
            kind: TransparencyEntryKind.modelCard,
            title: 'World Clock',
            subjectId: '',
            summary: 'deterministic clock',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
      test('rejects empty summary', () {
        expect(
          () => TransparencyEntry(
            id: 'm.wc',
            kind: TransparencyEntryKind.modelCard,
            title: 'World Clock',
            subjectId: 'world_clock',
            summary: '',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
      test('rejects uncertainty outside [0,1]', () {
        expect(
          () => TransparencyEntry(
            id: 'm.wc',
            kind: TransparencyEntryKind.modelCard,
            title: 'World Clock',
            subjectId: 'world_clock',
            summary: 's',
            uncertainty: 1.5,
          ),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => TransparencyEntry(
            id: 'm.wc',
            kind: TransparencyEntryKind.modelCard,
            title: 'World Clock',
            subjectId: 'world_clock',
            summary: 's',
            uncertainty: -0.1,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
      test('accepts valid entry with all optional fields', () {
        final entry = TransparencyEntry(
          id: 'm.wc',
          kind: TransparencyEntryKind.modelCard,
          title: 'World Clock',
          subjectId: 'world_clock',
          summary: 'Deterministic monotonic clock authority.',
          inputs: const ['absolute_tick', 'epoch'],
          assumptions: const ['tick is non-negative'],
          units: const {'tick': 'integer', 'duration': 'ticks'},
          uncertainty: 0.1,
          overridePath: 'doc/override_guide.md#world-clock',
          recoveryPath: 'doc/recovery_guide.md#world-clock',
          limits: const ['no wall-clock conversion'],
          sources: const ['sprint_110.json:110.3'],
        );
        expect(entry.id, 'm.wc');
        expect(entry.kind, TransparencyEntryKind.modelCard);
        expect(entry.uncertainty, 0.1);
        expect(entry.units['tick'], 'integer');
      });
    });
    group('TransparencyCatalog queries', () {
      late TransparencyCatalog catalog;
      setUp(() {
        catalog = TransparencyCatalogBuilder()
            .add(
              TransparencyEntry(
                id: 'feat.world_clock',
                kind: TransparencyEntryKind.featureGuide,
                title: 'World Clock',
                subjectId: 'world_clock',
                summary: 'Authoritative clock.',
              ),
            )
            .add(
              TransparencyEntry(
                id: 'm.world_clock',
                kind: TransparencyEntryKind.modelCard,
                title: 'World Clock Model',
                subjectId: 'world_clock',
                summary: 'Deterministic monotonic clock.',
                uncertainty: 0.1,
              ),
            )
            .add(
              TransparencyEntry(
                id: 'a.world_clock',
                kind: TransparencyEntryKind.assumptionGuide,
                title: 'World Clock Assumptions',
                subjectId: 'world_clock',
                summary: 'Tick is integer and non-negative.',
              ),
            )
            .add(
              TransparencyEntry(
                id: 'o.world_clock',
                kind: TransparencyEntryKind.overrideGuide,
                title: 'World Clock Override',
                subjectId: 'world_clock',
                summary: 'Editor may pin a tick with reason.',
              ),
            )
            .add(
              TransparencyEntry(
                id: 'r.world_clock',
                kind: TransparencyEntryKind.recoveryGuide,
                title: 'World Clock Recovery',
                subjectId: 'world_clock',
                summary: 'Restore last persisted tick.',
              ),
            )
            .add(
              TransparencyEntry(
                id: 'l.world_clock',
                kind: TransparencyEntryKind.knownLimit,
                title: 'World Clock Limits',
                subjectId: 'world_clock',
                summary: 'No real-time sync.',
              ),
            )
            .add(
              TransparencyEntry(
                id: 'm.route_network',
                kind: TransparencyEntryKind.modelCard,
                title: 'Route Network Model',
                subjectId: 'route_network',
                summary: 'Deterministic graph with terrain costs.',
              ),
            )
            .build();
      });
      test('entriesByKind groups by kind', () {
        final groups = catalog.entriesByKind;
        expect(groups[TransparencyEntryKind.featureGuide]!.length, 1);
        expect(groups[TransparencyEntryKind.modelCard]!.length, 2);
        expect(groups[TransparencyEntryKind.knownLimit]!.length, 1);
      });
      test('bySubject returns all entries for that subject', () {
        final entries = catalog.bySubject('world_clock');
        expect(entries.length, 6);
        expect(entries.map((e) => e.kind).toSet(), {
          TransparencyEntryKind.featureGuide,
          TransparencyEntryKind.modelCard,
          TransparencyEntryKind.assumptionGuide,
          TransparencyEntryKind.overrideGuide,
          TransparencyEntryKind.recoveryGuide,
          TransparencyEntryKind.knownLimit,
        });
      });
      test('byKind filters by kind', () {
        final guides = catalog.byKind(TransparencyEntryKind.featureGuide);
        expect(guides.length, 1);
        expect(guides.first.subjectId, 'world_clock');
      });
      test('allKindsCovered returns true for canonical 6 kinds', () {
        expect(
          catalog.allKindsCovered(
            subjectId: 'world_clock',
            kinds: TransparencyEntryKind.canonicalKinds,
          ),
          isTrue,
        );
      });
      test('allKindsCovered returns false when missing one kind', () {
        final sparse = TransparencyCatalogBuilder()
            .add(
              TransparencyEntry(
                id: 'feat.x',
                kind: TransparencyEntryKind.featureGuide,
                title: 'X',
                subjectId: 'x',
                summary: 'x',
              ),
            )
            .build();
        expect(
          sparse.allKindsCovered(
            subjectId: 'x',
            kinds: TransparencyEntryKind.canonicalKinds,
          ),
          isFalse,
        );
      });
      test('catalog length matches entries', () {
        expect(catalog.length, 7);
      });
    });

    group('TransparencyReport', () {
      test('explain() is byte-stable and deterministic', () {
        final catalog = TransparencyCatalogBuilder()
            .add(
              TransparencyEntry(
                id: 'm.world_clock',
                kind: TransparencyEntryKind.modelCard,
                title: 'World Clock',
                subjectId: 'world_clock',
                summary: 'Deterministic clock.',
                uncertainty: 0.1,
              ),
            )
            .build();
        final report = TransparencyReport.fromCatalog(catalog);
        expect(report.explain(), report.explain());
      });
      test('explain() orders entries by kind then id', () {
        final catalog = TransparencyCatalogBuilder()
            .add(
              TransparencyEntry(
                id: 'm.z',
                kind: TransparencyEntryKind.modelCard,
                title: 'Z',
                subjectId: 'z',
                summary: 'z',
              ),
            )
            .add(
              TransparencyEntry(
                id: 'm.a',
                kind: TransparencyEntryKind.modelCard,
                title: 'A',
                subjectId: 'a',
                summary: 'a',
              ),
            )
            .build();
        final report = TransparencyReport.fromCatalog(catalog);
        final text = report.explain();
        final aIdx = text.indexOf('m.a');
        final zIdx = text.indexOf('m.z');
        expect(aIdx, isNonNegative);
        expect(zIdx, greaterThan(aIdx));
      });
      test('missingKinds reports missing kinds for a subject', () {
        final catalog = TransparencyCatalogBuilder()
            .add(
              TransparencyEntry(
                id: 'm.world_clock',
                kind: TransparencyEntryKind.modelCard,
                title: 'World Clock',
                subjectId: 'world_clock',
                summary: 'Deterministic clock.',
              ),
            )
            .build();
        final report = TransparencyReport.fromCatalog(catalog);
        expect(
          report.missingKinds(
            subjectId: 'world_clock',
            kinds: TransparencyEntryKind.canonicalKinds,
          ),
          contains(TransparencyEntryKind.featureGuide),
        );
        expect(
          report.missingKinds(
            subjectId: 'world_clock',
            kinds: TransparencyEntryKind.canonicalKinds,
          ),
          contains(TransparencyEntryKind.knownLimit),
        );
      });
    });
    group('Wave-2 documentation snapshot', () {
      test('covers all canonical kinds for every subject', () {
        final catalog = Wave2TransparencySnapshot.build();
        for (final subjectId in Wave2TransparencySnapshot.subjectIds) {
          expect(
            catalog.allKindsCovered(
              subjectId: subjectId,
              kinds: TransparencyEntryKind.canonicalKinds,
            ),
            isTrue,
            reason: 'subject $subjectId missing some kinds',
          );
        }
        expect(catalog.length, greaterThanOrEqualTo(60));
      });
      test('subjectIds returns the 10 canonical Wave-2 modules', () {
        expect(Wave2TransparencySnapshot.subjectIds.length, 10);
      });
      test(
        'snapshot exposes rationale fields for inputs, assumptions, units, override, recovery, limits',
        () {
          final catalog = Wave2TransparencySnapshot.build();
          final wc = catalog.bySubject('world_clock');
          final modelCard = wc.firstWhere(
            (e) => e.kind == TransparencyEntryKind.modelCard,
          );
          expect(modelCard.units, isNotEmpty);
          expect(modelCard.inputs, isNotEmpty);
          final recovery = wc.firstWhere(
            (e) => e.kind == TransparencyEntryKind.recoveryGuide,
          );
          expect(recovery.recoveryPath, isNotEmpty);
          final override = wc.firstWhere(
            (e) => e.kind == TransparencyEntryKind.overrideGuide,
          );
          expect(override.overridePath, isNotEmpty);
        },
      );
    });
  });
}
