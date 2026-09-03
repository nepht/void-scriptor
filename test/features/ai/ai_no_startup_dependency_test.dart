import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/domain/ai_policy.dart';
import 'package:void_scriptor/features/ai/domain/ai_provider.dart';

/// Sprint 145.36 — AI Optional Boundary, gap "dedicated no-startup-dependency
/// proof".
///
/// Dua lapis bukti bahwa Core startup tidak bergantung pada layanan AI:
///
/// 1. Struktural: file bootstrap inti (main + app/bootstrap + void_app)
///    tidak mengimpor modul AI sama sekali. Router (app_router.dart) boleh
///    mereferensikan screen AI — itu komposisi UI, bukan inisialisasi
///    runtime; route gating adalah urusan 145.37.
/// 2. Perilaku: ketika AI tidak tersedia (byokReady false / external
///    transfer tanpa consent), [AiPolicy] menolak (fail-closed) sehingga
///    alur Core tetap berjalan tanpa pernah memanggil provider.
void main() {
  group('Core startup AI-free source boundary', () {
    const coreStartupFiles = <String>[
      'lib/main.dart',
      'lib/app/bootstrap/app_bootstrap.dart',
      'lib/app/bootstrap/bootstrap_gate.dart',
      'lib/app/bootstrap/app_diagnostics.dart',
      'lib/app/bootstrap/startup_recovery_policy.dart',
      'lib/app/void_app.dart',
      'lib/app/void_scriptor_app.dart',
    ];

    test('bootstrap core files never import AI feature modules', () {
      final offenders = <String>[];
      for (final file in coreStartupFiles) {
        final source = File(file).readAsStringSync();
        final aiImports = source
            .split('\n')
            .where(
              (line) =>
                  line.trimLeft().startsWith('import ') &&
                  (line.contains('features/ai') || line.contains('core/ai')),
            )
            .toList();
        if (aiImports.isNotEmpty) {
          offenders.add('$file -> ${aiImports.join(' | ')}');
        }
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'bootstrap Core tidak boleh bergantung statis pada AI: '
            '${offenders.join('; ')}',
      );
    });
  });

  group('AiPolicy fail-closed when AI is unavailable', () {
    test('unavailable AI (no credential) denies without exception', () {
      const policy = AiPolicy.byDefault();
      final result = policy.check(
        const AiPolicyCheckRequest(
          target: PromptTarget.story,
          contextSummary: 'ctx',
          byokReady: false,
        ),
      );
      expect(result, isA<PolicyResultDenied>());
      expect((result as PolicyResultDenied).reason, contains('credential'));
    });

    test('unavailable AI never reaches external provider without consent', () {
      const policy = AiPolicy.byDefault();
      final result = policy.check(
        const AiPolicyCheckRequest(
          target: PromptTarget.image,
          contextSummary: 'ctx',
          byokReady: false,
          externalTransfer: true,
        ),
      );
      expect(result, isA<PolicyResultDenied>());
    });

    test('policy is a pure contract usable without any runtime', () {
      // No AiGenerationRuntime, no CredentialStore, no network: the policy
      // still answers deterministically, which is what the Core flow needs.
      const policy = AiPolicy.byDefault();
      final result = policy.check(
        const AiPolicyCheckRequest(
          target: PromptTarget.story,
          contextSummary: 'draft context',
          byokReady: true,
        ),
      );
      expect(result, isA<PolicyResultAllowed>());
      expect((result as PolicyResultAllowed).requiredContext, 'draft context');
    });
  });
}
