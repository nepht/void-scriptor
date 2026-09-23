/// Test for Version, Changelog & Migration Notes (Step 113.37).
///
/// Validates the six canonical outputs — version, changelog, migration_notes,
/// compatibility_notes, recovery_notes, deprecation_notes — the
/// blocked/fail/pass state of the release documentation, the completion of
/// the version number across pubspec.yaml and the application constant, and
/// the step manifest: every source document exists at HEAD, every declared
/// item_count matches, and no item is blank.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/void_project_format.dart';
import 'package:void_scriptor/features/world_logic/domain/final_version_changelog_migration.dart';

const String _manifestPath =
    'docs/planning/v1.2/sprint_113_version_changelog_migration.json';
const String _canonicalVersion = '1.2.0-rc.1';

ReleaseDocumentation _complete() {
  return const ReleaseDocumentation(
    version: _canonicalVersion,
    changelog: <String>['Schema database project naik ke 62'],
    migrationNotes: <String>['Forward migration 55 -> 62 dengan backup'],
    compatibilityNotes: <String>['Format schema freeze di 16'],
    recoveryNotes: <String>['Emergency backup dibuat sebelum restore'],
    deprecationNotes: <String>['Tidak ada penghapusan fitur pada RC'],
  );
}

Map<String, dynamic> _readJson(String path) {
  return json.decode(File(path).readAsStringSync()) as Map<String, dynamic>;
}

void main() {
  group('113.37 Version, Changelog & Migration Notes', () {
    test('six canonical output names in ledger order', () {
      expect(ReleaseDocumentation.requiredOutputNames, <String>[
        'version',
        'changelog',
        'migration_notes',
        'compatibility_notes',
        'recovery_notes',
        'deprecation_notes',
      ]);
    });

    test('complete documentation has no missing output', () {
      expect(ReleaseDocumentation.missingOutputs(_complete()), isEmpty);
    });

    test('documentation without any recorded output is blocked', () {
      final evaluation = ReleaseDocumentation.evaluate(
        const ReleaseDocumentation(),
      );
      expect(evaluation.state, ReleaseDocumentationState.blocked);
      expect(evaluation.notes.join(' '), isNotEmpty);
    });

    test('blank version and empty changelog are reported as missing', () {
      const incomplete = ReleaseDocumentation(
        version: '  ',
        changelog: <String>[],
        migrationNotes: <String>['Forward migration 55 -> 62 dengan backup'],
        compatibilityNotes: <String>['Format schema freeze di 16'],
        recoveryNotes: <String>['Emergency backup dibuat sebelum restore'],
        deprecationNotes: <String>[],
      );
      expect(ReleaseDocumentation.missingOutputs(incomplete), <String>[
        'version',
        'changelog',
      ]);

      final evaluation = ReleaseDocumentation.evaluate(incomplete);
      expect(evaluation.state, ReleaseDocumentationState.fail);
      final notes = evaluation.notes.join(' ');
      expect(notes, contains('documentation incomplete'));
      expect(notes, contains('version'));
      expect(notes, contains('changelog'));
    });

    test('blank item is reported as a missing output', () {
      const blankItem = ReleaseDocumentation(
        version: _canonicalVersion,
        changelog: <String>['  '],
        migrationNotes: <String>['Forward migration 55 -> 62 dengan backup'],
        compatibilityNotes: <String>['Format schema freeze di 16'],
        recoveryNotes: <String>['Emergency backup dibuat sebelum restore'],
        deprecationNotes: <String>[],
      );
      expect(ReleaseDocumentation.missingOutputs(blankItem), <String>[
        'changelog',
      ]);
    });

    test('empty deprecation_notes is a recorded answer', () {
      const noDeprecation = ReleaseDocumentation(
        version: _canonicalVersion,
        changelog: <String>['Schema database project naik ke 62'],
        migrationNotes: <String>['Forward migration 55 -> 62 dengan backup'],
        compatibilityNotes: <String>['Format schema freeze di 16'],
        recoveryNotes: <String>['Emergency backup dibuat sebelum restore'],
        deprecationNotes: <String>[],
      );
      expect(ReleaseDocumentation.missingOutputs(noDeprecation), isEmpty);
      final evaluation = ReleaseDocumentation.evaluate(noDeprecation);
      expect(evaluation.state, ReleaseDocumentationState.pass);
    });

    test('complete documentation passes and retains its version', () {
      final evaluation = ReleaseDocumentation.evaluate(_complete());
      expect(evaluation.state, ReleaseDocumentationState.pass);
      final notes = evaluation.notes.join(' ');
      expect(notes, contains(_canonicalVersion));
      expect(notes, contains('migration_notes'));
    });

    test('version number is completed as $_canonicalVersion across pubspec '
        'and the application constant', () {
      final pubspecVersion = File('pubspec.yaml')
          .readAsLinesSync()
          .firstWhere((line) => line.startsWith('version:'))
          .substring('version:'.length)
          .trim()
          .split('+')
          .first;
      expect(
        pubspecVersion,
        _canonicalVersion,
        reason: 'pubspec.yaml must carry the completed version number',
      );
      expect(
        VoidProjectFormat.applicationVersion,
        _canonicalVersion,
        reason: 'single-source lockstep with pubspec.yaml',
      );
    });

    test('manifest records all six outputs with live status and matching '
        'item counts', () {
      final manifest = _readJson(_manifestPath);
      expect(manifest['canonical_step'], '113.37');

      final outputs = manifest['outputs'] as Map<String, dynamic>;
      expect(outputs.keys.toSet(), <String>{
        'version',
        'changelog',
        'migration_notes',
        'compatibility_notes',
        'recovery_notes',
        'deprecation_notes',
      });

      final version = outputs['version'] as Map<String, dynamic>;
      expect(version['value'], _canonicalVersion);
      expect(version['description'], isNotEmpty);
      expect(version['status'], isNotEmpty);
      final versionSource = version['source_doc'] as String;
      expect(
        File(versionSource).existsSync(),
        isTrue,
        reason: 'version source doc missing: $versionSource',
      );

      for (final name in ReleaseDocumentation.requiredOutputNames) {
        if (name == 'version') continue;
        final output = outputs[name] as Map<String, dynamic>;
        expect(output['description'], isNotEmpty, reason: name);
        expect(output['status'], isNotEmpty, reason: name);
        final sourceDoc = output['source_doc'] as String;
        expect(
          File(sourceDoc).existsSync(),
          isTrue,
          reason: '$name source doc missing: $sourceDoc',
        );
        final items = (output['items'] as List<dynamic>).cast<String>();
        expect(items, isNotEmpty, reason: '$name must record real items');
        expect(
          items.every((item) => item.trim().isNotEmpty),
          isTrue,
          reason: '$name has a blank item',
        );
        expect(output['item_count'], items.length, reason: name);
      }

      expect(manifest['version'], _canonicalVersion);
      expect(manifest['limits'], isNotEmpty);
      expect(manifest['decision'], isNotEmpty);

      final sources = manifest['sources'] as Map<String, dynamic>;
      for (final path in sources.values.cast<String>()) {
        expect(
          File(path).existsSync(),
          isTrue,
          reason: 'source missing at HEAD: $path',
        );
      }
    });

    test('version change is recorded as a changelog entry', () {
      final manifest = _readJson(_manifestPath);
      final changelog =
          (manifest['outputs']['changelog']['items'] as List<dynamic>)
              .cast<String>();
      expect(
        changelog.any((item) => item.contains('1.2.0-rc.1')),
        isTrue,
        reason: 'the version completion itself must appear in the changelog',
      );
    });
  });
}
