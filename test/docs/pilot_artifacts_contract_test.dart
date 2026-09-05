import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Kontrak artefak persiapan pilot 145.45/145.46 (doc-only, tanpa keputusan produk).
///
/// 145.45 objective: "Recruit 5-20 relevant novelists ... informed expectations,
/// privacy, support path, and no coercive incentives."
/// 145.46 objective: "Observe create novel/character, write/reopen, lore finding,
/// export, backup/restore without leading; record task friction, errors,
/// confidence, terminology, and context."
void main() {
  group('pilot artifacts contract (input 145.45/145.46)', () {
    test(
      'recruitment brief exists with informed-expectation and privacy contracts',
      () async {
        final f = File('docs/user/pilot-recruitment-brief.md');
        expect(
          f.existsSync(),
          isTrue,
          reason: 'docs/user/pilot-recruitment-brief.md belum ada (RED)',
        );
        final text = await f.readAsString();
        expect(
          text.toLowerCase(),
          contains('informed'),
          reason:
              'harus memuat harapan yang diberitahukan (informed expectations)',
        );
        expect(
          text.toLowerCase(),
          contains('privasi'),
          reason: 'harus memuat privasi',
        );
        final support = text.toLowerCase();
        expect(
          support.contains('support path') ||
              support.contains('jalur dukungan'),
          isTrue,
          reason: 'harus memuat jalur dukungan/support path',
        );
        final lower = text.toLowerCase();
        expect(
          lower.contains('no coercive') ||
              lower.contains('tanpa paksaan') ||
              lower.contains('bukan insentif paksaan'),
          isTrue,
          reason: 'harus menyatakan larangan insentif paksaan',
        );
        final nMatch = RegExp(r'5\s*[-–]\s*20').firstMatch(text);
        expect(
          nMatch,
          isNotNull,
          reason: 'harus menyebut rentang 5-20 novelis',
        );
      },
    );

    test(
      'task validation script exists covering all five canonical task groups',
      () async {
        final f = File('docs/user/task-validation-script.md');
        expect(
          f.existsSync(),
          isTrue,
          reason: 'docs/user/task-validation-script.md dokumen belum ada (RED)',
        );
        final text = await f.readAsString();
        const required = [
          'create novel',
          'create character',
          'write',
          'lore',
          'export',
          'backup',
          'restore',
        ];
        for (final k in required) {
          expect(
            text.toLowerCase(),
            contains(k),
            reason: 'skrip validasi wajib mencakup $k',
          );
        }
        expect(
          text.toLowerCase().contains('friction') ||
              text.toLowerCase().contains('friksi'),
          isTrue,
          reason: 'wajib mencatat friksi',
        );
        expect(
          text.toLowerCase().contains('tanpa memandu') ||
              text.toLowerCase().contains('without leading'),
          isTrue,
          reason: 'observasi wajib tanpa memandu (without leading)',
        );
        for (final k in ['confidence', 'terminology', 'context']) {
          expect(text.toLowerCase(), contains(k), reason: 'harus mencatat $k');
        }
      },
    );
  });
}
