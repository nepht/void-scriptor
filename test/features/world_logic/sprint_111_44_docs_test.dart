// Sprint 111.44 - Documentation & Worldbuilding Guidance.
//
// Enam keluaran kanonik objective (sprint_111.json step 111.44):
//   feature_guides, taxonomy_guide, canon_guide, generator_guide,
//   portability_guide, known_limits
// diverifikasi sebagai katalog panduan ter-audit di atas manifest modul
// Wave 3 nyata (census 111.40) + 10 subjek wajib objective.
//
// Batas jujur: dokumentasi domain-only; D-SCHEMA-01 tetap OPEN; native GUI
// tidak diklaim.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_wave3_docs.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_wave3_test_matrix.dart';

void main() {
  final report = Wave3GuideCoverageReport.of(Wave3DocsCatalog.canonical);

  group('111.44 canonical catalog contract', () {
    test(
      'coverage COMPLETE: 6 output kinds, 10 required topics, census audit',
      () {
        expect(report.isComplete, isTrue, reason: report.describe());
        expect(report.kindsMissing, isEmpty);
        expect(report.topicsMissing, isEmpty);
        expect(report.modulesUncovered, isEmpty);
        expect(report.modulesMappedMoreThanOnce, isEmpty);
        expect(report.unknownModuleReferences, isEmpty);
      },
    );

    test('each canonical output kind has a non-empty entry set', () {
      for (final kind in Wave3GuideKind.canonicalKinds) {
        final entries = Wave3DocsCatalog.canonical.entriesOfKind(kind);
        expect(entries, isNotEmpty, reason: '${kind.outputLabel} kosong');
        expect(
          entries.map((e) => e.kind).toSet(),
          {kind},
          reason: '${kind.outputLabel} tercampur jenis lain',
        );
      }
    });

    test('entry ids carry their kind prefix (unambiguous kind from id)', () {
      for (final entry in Wave3DocsCatalog.canonical.entries) {
        expect(
          entry.id.startsWith(entry.kind.idPrefix),
          isTrue,
          reason: '${entry.id} tidak ber-prefix ${entry.kind.idPrefix}',
        );
      }
    });

    test('entries sorted by id, immutable, no duplicates', () {
      final entries = Wave3DocsCatalog.canonical.entries;
      final ids = entries.map((e) => e.id).toList();
      expect(ids, [...ids]..sort());
      expect(ids.toSet().length, ids.length);
      expect(() => entries.add(entries.first), throwsUnsupportedError);
    });

    test('entry validation rejects empty fields and wrong prefixes', () {
      expect(
        () => Wave3GuideEntry.validated(
          id: '',
          kind: Wave3GuideKind.featureGuide,
          title: 't',
          summary: 's',
          topics: ['schema'],
          sources: ['111.3'],
        ),
        throwsArgumentError,
      );
      expect(
        () => Wave3GuideEntry.validated(
          id: 'wrong.prefix',
          kind: Wave3GuideKind.canonGuide,
          title: 't',
          summary: 's',
          topics: ['canon'],
          sources: ['111.4'],
        ),
        throwsArgumentError,
      );
      expect(
        () => Wave3GuideEntry.validated(
          id: 'lim.x',
          kind: Wave3GuideKind.knownLimit,
          title: 't',
          summary: 's',
          topics: ['   '],
          sources: ['111.4'],
        ),
        throwsArgumentError,
      );
      expect(
        () => Wave3GuideEntry.validated(
          id: 'lim.x',
          kind: Wave3GuideKind.knownLimit,
          title: 't',
          summary: 's',
          topics: ['backup'],
          sources: <String>[],
        ),
        throwsArgumentError,
      );
    });

    test('duplicate entry id rejected by catalog builder', () {
      final base = Wave3DocsCatalog.canonical.entries.first;
      expect(
        () => Wave3DocsCatalog.withEntries([base, base]),
        throwsStateError,
      );
    });

    test('catalog builder does not mutate caller-owned input list', () {
      final base = Wave3DocsCatalog.canonical.entries.first;
      final other = Wave3DocsCatalog.canonical.entries.last;
      final input = [base, other];
      Wave3DocsCatalog.withEntries(input);
      expect(input.length, 2);
      expect(input.first.id, base.id);
      expect(input.last.id, other.id);
    });
  });

  group('111.44 required topics coverage', () {
    test('all ten objective topics covered by canonical catalog', () {
      final missing = Wave3DocsCatalog.canonical.missingRequiredTopics();
      expect(missing, isEmpty);
    });

    test('coverage report detects a missing kind on a stripped catalog', () {
      final stripped = Wave3DocsCatalog.withEntries(
        Wave3DocsCatalog.canonical.entries.where(
          (e) => e.kind != Wave3GuideKind.portabilityGuide,
        ),
      );
      final strippedReport = Wave3GuideCoverageReport.of(stripped);
      expect(strippedReport.isComplete, isFalse);
      expect(strippedReport.kindsMissing, {Wave3GuideKind.portabilityGuide});
      // Topik portability (import/export/backup) masih dibahas entri fondasi
      // dan known-limits; yang hilang adalah output kind-nya.
      expect(strippedReport.topicsMissing, isEmpty);
    });

    test('coverage report detects a missing topic when all entries covering '
        'a topic are removed', () {
      final stripped = Wave3DocsCatalog.withEntries(
        Wave3DocsCatalog.canonical.entries.where(
          (e) => !e.coversTopic('recovery'),
        ),
      );
      final strippedReport = Wave3GuideCoverageReport.of(stripped);
      expect(strippedReport.topicsMissing, contains('recovery'));
      expect(strippedReport.isComplete, isFalse);
    });

    test('coversTopic normalizes case and whitespace', () {
      final entry = Wave3DocsCatalog.canonical.entryFor(
        'feat.f23-herbology-alchemy',
      );
      expect(entry, isNotNull);
      expect(entry!.coversTopic('  SCHEMA '), isTrue);
      expect(entry.coversTopic('nonexistent-topic'), isFalse);
    });
  });

  group('111.44 capability groups vs real Wave 3 census', () {
    test('every canonical group module exists in the 111.40 census', () {
      final census = EncyclopediaWave3TestSuiteSources.wave3DomainModules();
      final censusSet = census.toSet();
      for (final group in Wave3CapabilityGroups.canonical) {
        for (final module in group.modules) {
          expect(
            censusSet.contains(module),
            isTrue,
            reason: '${group.id} merujuk modul di luar census: $module',
          );
        }
      }
    });

    test('census is partitioned exactly once across canonical groups', () {
      final census = EncyclopediaWave3TestSuiteSources.wave3DomainModules();
      final mapped = <String>{};
      for (final group in Wave3CapabilityGroups.canonical) {
        for (final module in group.modules) {
          expect(
            mapped.add(module),
            isTrue,
            reason: '$module dipetakan lebih dari sekali',
          );
        }
      }
      final uncovered = census.where((m) => !mapped.contains(m)).toList();
      expect(uncovered, isEmpty, reason: 'modul census tak terdokumentasi');
      expect(mapped.length, census.length);
    });

    test('canonical groups match scope contract ids and step ranges', () {
      final ids = Wave3CapabilityGroups.canonical.map((g) => g.id).toList();
      expect(
        ids,
        containsAll(<String>['F23', 'F24', 'F26', 'F27', 'F28', 'F29']),
      );
      expect(ids, isNot(contains('F30')), reason: 'F30 = alias F24');
      final f24 = Wave3CapabilityGroups.canonical.firstWhere(
        (g) => g.id == 'F24',
      );
      expect(f24.label, contains('F30'));
    });
  });

  group('111.44 JSON round-trip and no-mutation', () {
    test('entry toJson/fromJson is byte-identical', () {
      for (final entry in Wave3DocsCatalog.canonical.entries.take(5)) {
        final json = entry.toJson();
        final restored = Wave3GuideEntry.fromJson(json);
        expect(restored.toJson(), json);
        expect(restored.id, entry.id);
        expect(restored.kind, entry.kind);
        expect(restored.topics, entry.topics);
        expect(restored.sources, entry.sources);
      }
    });

    test('catalog JSON round-trip preserves sorted entries', () {
      final catalog = Wave3DocsCatalog.canonical;
      final json = catalog.toJson();
      final encoded = jsonEncode(json);
      final restored = Wave3DocsCatalog.fromJson(
        jsonDecode(encoded) as Map<String, Object?>,
      );
      expect(restored.toJson(), json);
      expect(restored.entries.length, catalog.entries.length);
      expect(
        restored.entries.map((e) => e.id).toList(),
        catalog.entries.map((e) => e.id).toList(),
      );
    });

    test('fromJson rejects unknown kind and non-list entries', () {
      expect(
        () => Wave3GuideEntry.fromJson(<String, Object?>{
          'id': 'lim.x',
          'kind': 'bogus',
          'title': 't',
          'summary': 's',
          'topics': ['backup'],
          'sources': ['111.4'],
        }),
        throwsArgumentError,
      );
      expect(
        () => Wave3DocsCatalog.fromJson(<String, Object?>{
          'entries': 'not-a-list',
        }),
        throwsArgumentError,
      );
    });

    test(
      'no-mutation: building coverage report leaves catalog JSON intact',
      () {
        final before = jsonEncode(Wave3DocsCatalog.canonical.toJson());
        Wave3GuideCoverageReport.of(Wave3DocsCatalog.canonical);
        final after = jsonEncode(Wave3DocsCatalog.canonical.toJson());
        expect(after, before);
      },
    );
  });

  group('111.44 guide content honesty', () {
    test('every entry cites at least one sprint-step source', () {
      for (final entry in Wave3DocsCatalog.canonical.entries) {
        expect(entry.sources, isNotEmpty, reason: '${entry.id} tanpa sumber');
        for (final source in entry.sources) {
          expect(source.trim(), isNotEmpty);
        }
      }
    });

    test(
      'canonical entries only cite steps that exist in sprint 111 ledger',
      () {
        // Sumber langkah sprint-111 wajib berformat 111.<n>; sumber lain
        // (kontrak scope / langkah lintas-sprint) diizinkan eksplisit.
        const allowedNonSprintSources = <String>{
          'sprint_111_scope_contract.md',
          '145.30',
        };
        final sprintStepPattern = RegExp(r'^111\.\d+$');
        for (final entry in Wave3DocsCatalog.canonical.entries) {
          for (final source in entry.sources) {
            final isSprintStep = sprintStepPattern.hasMatch(source);
            final isAllowedOther = allowedNonSprintSources.contains(source);
            expect(
              isSprintStep || isAllowedOther,
              isTrue,
              reason: '${entry.id} merujuk sumber tak dikenal: $source',
            );
          }
        }
      },
    );

    test('known-limits entries document D-SCHEMA-01 and native deferral', () {
      final limits = Wave3DocsCatalog.canonical
          .entriesOfKind(Wave3GuideKind.knownLimit)
          .map((e) => e.id)
          .toList();
      expect(
        limits.any((id) => id.contains('d-schema-01')),
        isTrue,
        reason: 'D-SCHEMA-01 wajib terdokumentasi sebagai known limit',
      );
      expect(
        limits.any((id) => id.contains('native')),
        isTrue,
        reason: 'deferral native wajib terdokumentasi',
      );
      expect(
        limits.any((id) => id.contains('hardware')),
        isTrue,
        reason: 'batas hardware-bound wajib terdokumentasi',
      );
    });

    test('summaries are substantive (not placeholders)', () {
      for (final entry in Wave3DocsCatalog.canonical.entries) {
        expect(
          entry.summary.length,
          greaterThanOrEqualTo(120),
          reason: '${entry.id} terlalu pendek untuk jadi panduan',
        );
        expect(entry.summary.toLowerCase().contains('todo'), isFalse);
        expect(entry.summary.toLowerCase().contains('placeholder'), isFalse);
      }
    });

    test('describe() reports COMPLETE for canonical catalog', () {
      expect(report.describe(), contains('coverage COMPLETE'));
    });
  });
}
