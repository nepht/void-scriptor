/// Test for Documentation & Guidance Corrections (Step 113.33).
/// Validates the six canonical outputs — corrected_guides, ui_copy,
/// error_guidance, recovery_steps, known_limits, accessibility_notes —
/// and the blocked/fail/pass state of the corrections log.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/documentation_guidance_corrections.dart';

void main() {
  final log = DocumentationCorrectionLog();

  group('113.33 Documentation & Guidance Corrections', () {
    test('complete correction carries all six canonical outputs', () {
      const correction = DocumentationCorrection(
        issueId: 'DOC-301',
        correctedGuides: <String>['docs/guides/recovery.md'],
        uiCopy: <String>['Pilih proyek untuk melanjutkan menulis.'],
        errorGuidance: 'File tidak ditemukan — pulihkan dari backup terbaru.',
        recoverySteps: <String>[
          'Buka Project Backups',
          'Restore backup terkonfirmasi',
        ],
        knownLimits: <String>['Undo dibatasi 50 operasi terakhir.'],
        accessibilityNotes: 'Semua shortcut utama memiliki tooltip terbaca.',
      );

      expect(DocumentationCorrection.requiredOutputNames, <String>[
        'corrected_guides',
        'ui_copy',
        'error_guidance',
        'recovery_steps',
        'known_limits',
        'accessibility_notes',
      ]);
      expect(log.missingOutputs(correction), isEmpty);
    });

    test('missing outputs are reported by canonical name', () {
      const bare = DocumentationCorrection(
        issueId: 'DOC-302',
        correctedGuides: <String>[],
        uiCopy: <String>[],
        errorGuidance: '',
        recoverySteps: <String>[],
        knownLimits: <String>[],
        accessibilityNotes: '',
      );

      expect(log.missingOutputs(bare), <String>[
        'corrected_guides',
        'ui_copy',
        'error_guidance',
        'recovery_steps',
        'known_limits',
        'accessibility_notes',
      ]);
    });

    test('blank issue_id is reported as issue_id', () {
      const noId = DocumentationCorrection(
        issueId: ' ',
        correctedGuides: <String>['docs/a.md'],
        uiCopy: <String>['copy'],
        errorGuidance: 'guidance',
        recoverySteps: <String>['step'],
        knownLimits: <String>['limit'],
        accessibilityNotes: 'note',
      );
      expect(log.missingOutputs(noId), <String>['issue_id']);
    });

    test('empty log is blocked pending a correction attempt', () {
      final state = log.evaluate();
      expect(state.state, DocumentationCorrectionState.blocked);
      expect(state.correctionCount, 0);
      expect(state.notes.join(' '), isNotEmpty);
    });

    test('complete correction passes and retains its error guidance', () {
      final complete = DocumentationCorrectionLog()
        ..add(
          const DocumentationCorrection(
            issueId: 'DOC-303',
            correctedGuides: <String>[
              'docs/architecture/07_development_guide.md',
            ],
            uiCopy: <String>['Coba lagi'],
            errorGuidance:
                'Koneksi terputus — pekerjaan tetap tersimpan lokal.',
            recoverySteps: <String>['Buka ulang proyek'],
            knownLimits: <String>['Mode offline tidak menyinkronkan AI.'],
            accessibilityNotes: 'Kontras teks error memenuhi WCAG AA.',
          ),
        );

      final state = complete.evaluate();
      expect(state.state, DocumentationCorrectionState.pass);
      expect(state.correctionCount, 1);
      expect(
        state.notes.join(' '),
        contains('pekerjaan tetap tersimpan lokal'),
      );
    });

    test('incomplete correction fails naming the issue and every missing '
        'output', () {
      final incomplete = DocumentationCorrectionLog()
        ..add(
          const DocumentationCorrection(
            issueId: 'DOC-304',
            correctedGuides: <String>['docs/a.md'],
            uiCopy: <String>[],
            errorGuidance: '',
            recoverySteps: <String>[],
            knownLimits: <String>[],
            accessibilityNotes: '',
          ),
        );

      final state = incomplete.evaluate();
      expect(state.state, DocumentationCorrectionState.fail);
      final notes = state.notes.join(' ');
      expect(notes, contains('DOC-304'));
      expect(notes, contains('ui_copy'));
      expect(notes, contains('error_guidance'));
      expect(notes, contains('recovery_steps'));
      expect(notes, contains('known_limits'));
      expect(notes, contains('accessibility_notes'));
    });

    test('multiple corrections fail the log when any one is incomplete', () {
      final mixed = DocumentationCorrectionLog()
        ..add(
          const DocumentationCorrection(
            issueId: 'DOC-305',
            correctedGuides: <String>['docs/b.md'],
            uiCopy: <String>['copy ok'],
            errorGuidance: 'ok',
            recoverySteps: <String>['step ok'],
            knownLimits: <String>['limit ok'],
            accessibilityNotes: 'ok',
          ),
        )
        ..add(
          const DocumentationCorrection(
            issueId: 'DOC-306',
            correctedGuides: <String>[],
            uiCopy: <String>['copy'],
            errorGuidance: 'ok',
            recoverySteps: <String>['step'],
            knownLimits: <String>['limit'],
            accessibilityNotes: 'ok',
          ),
        );

      final state = mixed.evaluate();
      expect(state.state, DocumentationCorrectionState.fail);
      expect(state.correctionCount, 2);
      expect(state.notes.join(' '), contains('DOC-306'));
      expect(state.notes.join(' '), contains('corrected_guides'));
    });

    test('manifest records all six outputs with live status', () {
      final manifest =
          json.decode(
                File(
                  'docs/planning/v1.2/sprint_113_documentation_guidance_corrections.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;

      expect(manifest['canonical_step'], '113.33');
      final outputs = manifest['outputs'] as Map<String, dynamic>;
      expect(outputs.keys.toSet(), <String>{
        'corrected_guides',
        'ui_copy',
        'error_guidance',
        'recovery_steps',
        'known_limits',
        'accessibility_notes',
      });
      for (final value in outputs.values) {
        final entry = value as Map<String, dynamic>;
        expect(entry['description'], isNotEmpty);
        expect(entry['status'], isNotEmpty);
      }
      expect(manifest['limits'], isNotEmpty);
      expect(manifest['decision'], isNotEmpty);
    });
  });
}
