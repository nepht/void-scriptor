/// Test for Final Scope & Known Issues (Step 113.36).
///
/// Validates the six canonical outputs — release_scope, deferred_scope,
/// known_issues, workarounds, residual_risks, support_notes — the
/// blocked/fail/pass state of the scope document, and the step manifest:
/// every output carries a real source document that exists at HEAD, its
/// declared item_count matches the recorded items, and no item is blank.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/final_scope_known_issues.dart';

const String _manifestPath =
    'docs/planning/v1.2/sprint_113_final_scope_known_issues.json';

const String _releaseNotesPath = 'docs/release/v1.2.0-rc.1-release-notes.md';
const String _knownLimitsPath = 'docs/release/v1.2.0-rc.1-known-limits.md';
const String _recoveryGuidePath = 'docs/release/v1.2.0-rc.1-recovery-guide.md';
const String _supportPlaybookPath =
    'docs/release/v1.2.0-rc.1-support-playbook.md';

FinalScopeDocument _complete() {
  return const FinalScopeDocument(
    releaseScope: <String>['Worldbuilding integration F1-F29'],
    deferredScope: <String>['Hosted CI'],
    knownIssues: <String>['REC-01 matrix flag ids'],
    workarounds: <String>['Backup before upgrade'],
    residualRisks: <String>['Hardware power loss unverified'],
    supportNotes: <String>['P0 response target 2h'],
  );
}

Map<String, dynamic> _readJson(String path) {
  return json.decode(File(path).readAsStringSync()) as Map<String, dynamic>;
}

void main() {
  group('113.36 Final Scope & Known Issues', () {
    test('six canonical output names in ledger order', () {
      expect(FinalScopeDocument.requiredOutputNames, <String>[
        'release_scope',
        'deferred_scope',
        'known_issues',
        'workarounds',
        'residual_risks',
        'support_notes',
      ]);
    });

    test('complete document has no missing output', () {
      expect(FinalScopeDocument.missingOutputs(_complete()), isEmpty);
    });

    test('document without any recorded output is blocked', () {
      final evaluation = FinalScopeDocument.evaluate(
        const FinalScopeDocument(),
      );
      expect(evaluation.state, FinalScopeState.blocked);
      expect(evaluation.notes.join(' '), isNotEmpty);
    });

    test('partial document fails naming every missing output in order', () {
      const partial = FinalScopeDocument(
        releaseScope: <String>['Worldbuilding integration F1-F29'],
      );
      expect(FinalScopeDocument.missingOutputs(partial), <String>[
        'deferred_scope',
        'known_issues',
        'workarounds',
        'residual_risks',
        'support_notes',
      ]);

      final evaluation = FinalScopeDocument.evaluate(partial);
      expect(evaluation.state, FinalScopeState.fail);
      expect(evaluation.notes.join(' '), contains('scope incomplete'));
      expect(evaluation.notes.join(' '), contains('support_notes'));
    });

    test('blank item is reported as a missing output', () {
      const blankItem = FinalScopeDocument(
        releaseScope: <String>['  '],
        deferredScope: <String>['Hosted CI'],
        knownIssues: <String>['REC-01 matrix flag ids'],
        workarounds: <String>['Backup before upgrade'],
        residualRisks: <String>['Hardware power loss unverified'],
        supportNotes: <String>['P0 response target 2h'],
      );
      expect(FinalScopeDocument.missingOutputs(blankItem), <String>[
        'release_scope',
      ]);

      final evaluation = FinalScopeDocument.evaluate(blankItem);
      expect(evaluation.state, FinalScopeState.fail);
      expect(evaluation.notes.join(' '), contains('release_scope'));
    });

    test('empty release_scope is missing, empty known_issues is a recorded '
        'answer', () {
      const emptyRelease = FinalScopeDocument(
        releaseScope: <String>[],
        deferredScope: <String>['Hosted CI'],
        knownIssues: <String>['REC-01 matrix flag ids'],
        workarounds: <String>['Backup before upgrade'],
        residualRisks: <String>['Hardware power loss unverified'],
        supportNotes: <String>['P0 response target 2h'],
      );
      expect(FinalScopeDocument.missingOutputs(emptyRelease), <String>[
        'release_scope',
      ]);

      const emptyKnown = FinalScopeDocument(
        releaseScope: <String>['Worldbuilding integration F1-F29'],
        deferredScope: <String>[],
        knownIssues: <String>[],
        workarounds: <String>[],
        residualRisks: <String>[],
        supportNotes: <String>['P0 response target 2h'],
      );
      expect(FinalScopeDocument.missingOutputs(emptyKnown), isEmpty);
    });

    test('complete document passes and retains its support notes', () {
      final evaluation = FinalScopeDocument.evaluate(_complete());
      expect(evaluation.state, FinalScopeState.pass);
      final notes = evaluation.notes.join(' ');
      expect(notes, contains('release_scope'));
      expect(notes, contains('support_notes'));
      expect(notes, contains('P0 response target 2h'));
    });

    test('manifest records all six outputs with live status and matching '
        'item counts', () {
      final manifest = _readJson(_manifestPath);
      expect(manifest['canonical_step'], '113.36');

      final outputs = manifest['outputs'] as Map<String, dynamic>;
      expect(outputs.keys.toSet(), <String>{
        'release_scope',
        'deferred_scope',
        'known_issues',
        'workarounds',
        'residual_risks',
        'support_notes',
      });

      for (final name in FinalScopeDocument.requiredOutputNames) {
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

      expect(manifest['limits'], isNotEmpty);
      expect(manifest['decision'], isNotEmpty);

      final sources = manifest['sources'] as Map<String, dynamic>;
      expect(
        sources['feature_reconciliation'],
        'docs/planning/v1.2/sprint_113_final_feature_evidence_reconciliation.json',
      );
      for (final path in sources.values.cast<String>()) {
        expect(
          File(path).existsSync(),
          isTrue,
          reason: 'source missing at HEAD: $path',
        );
      }
    });

    test('grounding documents carry their canonical sections at HEAD', () {
      final releaseNotes = File(_releaseNotesPath).readAsStringSync();
      expect(releaseNotes, contains('## Known limitations'));
      expect(releaseNotes, contains('29 fitur unik F1'));

      final knownLimits = File(_knownLimitsPath).readAsStringSync();
      expect(knownLimits, contains('## Release boundary'));

      expect(File(_recoveryGuidePath).readAsStringSync(), isNotEmpty);
      expect(
        File(_supportPlaybookPath).readAsStringSync(),
        contains('Support'),
      );
    });

    test('known_issues output carries the open REC-01 finding', () {
      final manifest = _readJson(_manifestPath);
      final knownIssues =
          (manifest['outputs']['known_issues']['items'] as List<dynamic>)
              .cast<String>();
      expect(
        knownIssues.any((item) => item.contains('REC-01')),
        isTrue,
        reason: 'open Gap REC-01 from 113.35 must stay recorded',
      );
    });
  });
}
