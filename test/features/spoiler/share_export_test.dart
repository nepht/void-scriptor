// Kontrak Spoiler-Safe Share Export (Step 109.32) — RED pertama.
//
// Acceptance kanonik sprint_109.json: preflight_report,
// audience_manifest, sanitized_export, share_expiry, revoke.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/spoiler/domain/share_export.dart';
import 'package:void_scriptor/features/spoiler/domain/spoiler_classification.dart';

SpoilerRegistry _registry() => SpoilerRegistry()
  ..addAudience(const SpoilerAudience('beta', SpoilerLevel.mild))
  ..addAudience(const SpoilerAudience('editor', SpoilerLevel.major))
  ..classify('twist-mira', SpoilerLevel.major)
  ..classify('bekas-luka', SpoilerLevel.clean);

SharePackageBuilder _builder() =>
    SharePackageBuilder(registry: _registry())..setDocument(
      title: 'Bab 12',
      blocks: const <ShareBlock>[
        ShareBlock(id: 'b-1', text: 'Kael memeriksa lorong timur.'),
        ShareBlock(
          id: 'b-2',
          text: 'Terungkalah bahwa Mira pengkhianat.',
          spoilerItemId: 'twist-mira',
        ),
      ],
      metadata: const {'internalNote': 'jangan-bocor'},
    );

void main() {
  group('preflight_report', () {
    test('laporan pra-unduh menghitung blok yang akan disensor', () {
      final builder = _builder();
      final report = builder.preflight(audience: 'beta');
      expect(report.audience, 'beta');
      expect(report.totalBlocks, 2);
      expect(report.redactedCount, 1);
      expect(report.metadataDropped, isTrue);
      final editorReport = builder.preflight(audience: 'editor');
      expect(editorReport.redactedCount, 0);
    });
  });

  group('audience_manifest', () {
    test('manifest mencatat audiens dan batas levelnya', () {
      final builder = _builder();
      final manifest = builder.manifestFor('beta');
      expect(manifest.audienceId, 'beta');
      expect(manifest.maxLevel, SpoilerLevel.mild);
      expect(manifest.containsHiddenContent, isTrue);
    });
  });

  group('sanitized_export', () {
    test('paket ekspor bebas teks tersensor dan metadata internal', () {
      final builder = _builder();
      final pkg = builder.export(audience: 'beta', replacement: '[X]');
      final json = pkg.toJson().toString();
      expect(json, isNot(contains('pengkhianat')));
      expect(json, isNot(contains('jangan-bocor')));
      expect(pkg.blocks[0].text, contains('lorong timur'));
      expect(pkg.blocks[1].text, '[X]');
    });
  });

  group('share_expiry', () {
    test('paket kedaluwarsa setelah tenggat dan tak bisa diunduh', () {
      var now = DateTime(2026, 8, 26, 10);
      final builder = _builder().withClock(() => now);
      final pkg = builder.export(
        audience: 'beta',
        ttl: const Duration(hours: 24),
      );
      expect(pkg.isExpiredAt(now.add(const Duration(hours: 23))), isFalse);
      now = now.add(const Duration(hours: 25));
      expect(pkg.isExpiredAt(now), isTrue);
      expect(() => pkg.downloadAt(now), throwsStateError);
      expect(pkg.downloadAt(DateTime(2026, 8, 26, 11)), isNotNull);
    });
  });

  group('revoke', () {
    test(
      'pencabutan token mematikan paket permanen meski belum kedaluwarsa',
      () {
        var now = DateTime(2026, 8, 26, 10);
        final builder = _builder().withClock(() => now);
        final pkg = builder.export(audience: 'beta');
        pkg.revokeAt(now.add(const Duration(minutes: 5)));
        expect(
          () => pkg.downloadAt(now.add(const Duration(minutes: 6))),
          throwsStateError,
        );
      },
    );
  });
}
