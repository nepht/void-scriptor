import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/export/domain/clean_export.dart';
import 'package:void_scriptor/features/export/domain/export_preflight.dart';
import 'package:void_scriptor/features/export/domain/export_profiles.dart';

void main() {
  const clean = CleanExportTransformer();

  ExportPreflightRequest request({
    String source = '# Bab 1\n\nTeks [[Lore]].',
    ExportFormat format = ExportFormat.plainText,
    List<ExportAssetRef> assets = const [],
    List<String> unresolvedSpoilerIds = const [],
    int previewLimit = 40,
  }) => ExportPreflightRequest(
    documentId: 'doc-1',
    sourceText: source,
    profile: switch (format) {
      ExportFormat.docx => ExportProfile.docx(),
      ExportFormat.plainText => ExportProfile.plainText(),
      ExportFormat.webNovel => ExportProfile.webNovel(),
    },
    assets: assets,
    unresolvedSpoilerIds: unresolvedSpoilerIds,
    previewCharacterLimit: previewLimit,
  );

  group('preflight_report', () {
    test('reports structure, assets, spoilers, special chars and render', () {
      const assets = [
        ExportAssetRef(id: 'cover', path: 'assets/cover.png', exists: true),
      ];

      final report = const ExportPreflightValidator().validate(
        request(assets: assets),
      );

      expect(report.documentId, 'doc-1');
      expect(report.checks.map((c) => c.kind).toSet(), {
        ExportPreflightCheckKind.structure,
        ExportPreflightCheckKind.assets,
        ExportPreflightCheckKind.spoilers,
        ExportPreflightCheckKind.specialCharacters,
        ExportPreflightCheckKind.render,
      });
      expect(report.isReady, isTrue);
    });
  });

  group('blocking_errors', () {
    test('blank manuscript and missing assets block export', () {
      const missing = ExportAssetRef(
        id: 'cover',
        path: 'assets/missing.png',
        exists: false,
      );

      final report = const ExportPreflightValidator().validate(
        request(source: '   \n', assets: const [missing]),
      );

      expect(report.isReady, isFalse);
      expect(
        report.blockingErrors.map((e) => e.code),
        containsAll(['empty_document', 'missing_asset']),
      );
      expect(report.blockingErrors.every((e) => e.isBlocking), isTrue);
    });

    test('render failure is blocking and carries a named code', () {
      final report = const ExportPreflightValidator().validate(
        request(source: '[[PRIVATE:seluruh naskah]]'),
      );

      expect(
        report.blockingErrors.map((e) => e.code),
        contains('empty_render'),
      );
      expect(report.isReady, isFalse);
    });
  });

  group('warnings', () {
    test(
      'unresolved spoilers and control characters warn without blocking',
      () {
        final report = const ExportPreflightValidator().validate(
          request(
            source: '# Bab\nTeks\u0007 akhir',
            unresolvedSpoilerIds: const ['sp-2', 'sp-1'],
          ),
        );

        expect(report.isReady, isTrue);
        expect(
          report.warnings.map((e) => e.code),
          containsAll(['unresolved_spoiler', 'control_character']),
        );
        expect(report.warnings.every((e) => !e.isBlocking), isTrue);
      },
    );
  });

  group('sample_preview', () {
    test(
      'preview uses cleaned render and truncates at a character boundary',
      () {
        final report = const ExportPreflightValidator().validate(
          request(
            source: '# Bab\n[Mira](scene:s-1) [[PRIVATE:x]] menemui [[Naga]].',
            previewLimit: 18,
          ),
        );

        // Limit 18 mencakup ellipsis: 17 karakter sumber + `…`.
        expect(report.preview, '# Bab\nMira  menem…');
        expect(report.preview, isNot(contains('scene:')));
        expect(report.preview, isNot(contains('PRIVATE')));
        expect(report.preview.length, 18);
      },
    );

    test('short render is returned verbatim without ellipsis', () {
      final report = const ExportPreflightValidator().validate(
        request(source: 'Pendek', previewLimit: 20),
      );

      expect(report.preview, 'Pendek');
    });
  });

  group('export_manifest', () {
    test('manifest is deterministic and contains format, hash and assets', () {
      const assets = [
        ExportAssetRef(id: 'z', path: 'z.png', exists: true),
        ExportAssetRef(id: 'a', path: 'a.png', exists: true),
      ];
      const validator = ExportPreflightValidator();
      final input = request(format: ExportFormat.docx, assets: assets);

      final first = validator.validate(input);
      final second = validator.validate(input);

      expect(second.manifest, first.manifest);
      expect(first.manifest.documentId, 'doc-1');
      expect(first.manifest.format, ExportFormat.docx);
      expect(
        first.manifest.contentFingerprint,
        clean.transform(input.sourceText).fingerprint,
      );
      expect(first.manifest.assetPaths, ['a.png', 'z.png']);
      expect(first.manifest.toJson(), second.manifest.toJson());
    });
  });
}
