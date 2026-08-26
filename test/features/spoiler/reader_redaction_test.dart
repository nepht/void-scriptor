// Kontrak Reader Clearance & Redaction (Step 109.31) — RED pertama.
//
// Acceptance kanonik sprint_109.json: preview_as_reader, redaction,
// hidden_links, no_metadata_leak, revocable_access.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/spoiler/domain/reader_redaction.dart';
import 'package:void_scriptor/features/spoiler/domain/spoiler_classification.dart';

SpoilerRegistry _registry() => SpoilerRegistry()
  ..addAudience(const SpoilerAudience('beta', SpoilerLevel.mild))
  ..addAudience(const SpoilerAudience('editor', SpoilerLevel.major))
  ..classify('twist-mira', SpoilerLevel.major)
  ..classify('bekas-luka', SpoilerLevel.clean);

void main() {
  group('preview_as_reader', () {
    test('dokumen dirender sesuai clearance pembaca', () {
      final redactor = ReaderRedactor(registry: _registry())
        ..grant(readerId: 'r-1', audience: 'beta');
      const doc = ReaderDocument(
        id: 'd-1',
        title: 'Bab 12',
        blocks: <ReaderBlock>[
          ReaderBlock(id: 'b-1', text: 'Kael memeriksa lorong timur.'),
          ReaderBlock(
            id: 'b-2',
            text: 'Terungkalah bahwa Mira sang pengkhianat.',
            spoilerItemId: 'twist-mira',
          ),
        ],
      );
      final preview = redactor.previewAsReader(
        doc: doc,
        readerId: 'r-1',
        currentScene: 'sc-05',
      );
      expect(preview.blocks[0].kind, PreviewKind.visible);
      expect(preview.blocks[0].text, contains('Kael'));
      expect(preview.blocks[1].kind, PreviewKind.redacted);
      expect(preview.blocks[1].text, isNot(contains('Mira')));
      // Editor dengan clearance major melihat blok yang sama utuh.
      final redactorEditor = ReaderRedactor(registry: _registry())
        ..grant(readerId: 'r-2', audience: 'editor');
      final editorView = redactorEditor.previewAsReader(
        doc: doc,
        readerId: 'r-2',
        currentScene: 'sc-05',
      );
      expect(editorView.blocks[1].kind, PreviewKind.visible);
    });
  });

  group('redaction', () {
    test('blok tersensor memakai penanda tanpa menyimpan teks asli', () {
      final redactor = ReaderRedactor(registry: _registry())
        ..grant(readerId: 'r-1', audience: 'beta');
      const doc = ReaderDocument(
        id: 'd-1',
        title: 'Bab 12',
        blocks: <ReaderBlock>[
          ReaderBlock(
            id: 'b-1',
            text: 'Rahasia besar: Mira pengkhianat.',
            spoilerItemId: 'twist-mira',
          ),
        ],
      );
      final preview = redactor.previewAsReader(
        doc: doc,
        readerId: 'r-1',
        currentScene: 'sc-01',
        replacement: '[disensor]',
      );
      expect(preview.blocks.single.text, '[disensor]');
      expect(preview.toJson().toString(), isNot(contains('pengkhianat')));
    });
  });

  group('hidden_links', () {
    test('tautan internal ke data tersembunyi dihilangkan', () {
      final redactor = ReaderRedactor(registry: _registry())
        ..grant(readerId: 'r-1', audience: 'beta');
      const doc = ReaderDocument(
        id: 'd-1',
        title: 'Bab 12',
        blocks: <ReaderBlock>[
          ReaderBlock(
            id: 'b-1',
            text: 'Lihat catatan bekas luka dan twist akhir.',
            links: <InternalLink>[
              InternalLink(label: 'bekas luka', targetItemId: 'bekas-luka'),
              InternalLink(label: 'twist akhir', targetItemId: 'twist-mira'),
            ],
          ),
        ],
      );
      final preview = redactor.previewAsReader(
        doc: doc,
        readerId: 'r-1',
        currentScene: 'sc-02',
      );
      final labels = preview.blocks.single.links.map((l) => l.label).toList();
      expect(labels, <String>['bekas luka']);
      expect(labels, isNot(contains('twist akhir')));
    });
  });

  group('no_metadata_leak', () {
    test('metadata internal tidak muncul di keluaran pratinjau', () {
      final redactor = ReaderRedactor(registry: _registry())
        ..grant(readerId: 'r-1', audience: 'beta');
      const doc = ReaderDocument(
        id: 'd-1',
        title: 'Bab 12',
        blocks: <ReaderBlock>[ReaderBlock(id: 'b-1', text: 'Narasi pembuka.')],
        metadata: <String, String>{
          'internalNote': 'catatan-rahasia-editor',
          'authorEmail': 'penulis@example.com',
        },
      );
      final preview = redactor.previewAsReader(
        doc: doc,
        readerId: 'r-1',
        currentScene: 'sc-01',
      );
      final json = preview.toJson().toString();
      expect(json, isNot(contains('catatan-rahasia-editor')));
      expect(json, isNot(contains('penulis@example.com')));
      expect(json, isNot(contains('internalNote')));
    });
  });

  group('revocable_access', () {
    test('pencabutan akses langsung mengunci pratinjau berikutnya', () {
      final redactor = ReaderRedactor(registry: _registry())
        ..grant(readerId: 'r-1', audience: 'beta');
      const doc = ReaderDocument(
        id: 'd-1',
        title: 'Bab 12',
        blocks: <ReaderBlock>[ReaderBlock(id: 'b-1', text: 'Narasi pembuka.')],
      );
      redactor.previewAsReader(
        doc: doc,
        readerId: 'r-1',
        currentScene: 'sc-01',
      );
      redactor.revoke('r-1');
      expect(
        () => redactor.previewAsReader(
          doc: doc,
          readerId: 'r-1',
          currentScene: 'sc-01',
        ),
        throwsStateError,
      );
      expect(() => redactor.revoke('hantu'), throwsStateError);
      expect(
        () => redactor.grant(readerId: 'r-9', audience: 'tak-dikenal'),
        throwsStateError,
      );
    });
  });
}
