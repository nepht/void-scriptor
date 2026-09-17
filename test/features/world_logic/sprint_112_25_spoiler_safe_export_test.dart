import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/spoiler/domain/reader_redaction.dart';
import 'package:void_scriptor/features/spoiler/domain/spoiler_classification.dart';
import 'package:void_scriptor/features/world_logic/domain/spoiler_safe_manuscript_knowledge_export.dart';

void main() {
  test(
    'preflight and exports spoiler-safe manuscript without private data',
    () {
      final registry = SpoilerRegistry()
        ..addAudience(const SpoilerAudience('beta', SpoilerLevel.clean))
        ..classify('secret', SpoilerLevel.major);
      final exporter = SpoilerSafeExportService(
        redactor: ReaderRedactor(registry: registry)
          ..grant(readerId: 'reader-1', audience: 'beta'),
      );
      const request = SpoilerSafeExportRequest(
        documentId: 'novel-1',
        title: 'Ash Coast',
        readerId: 'reader-1',
        currentScene: 'chapter-1',
        format: ExportFormat.plainText,
        sections: [
          ExportSection(id: 's1', title: 'Opening', text: 'Public prose.'),
          ExportSection(
            id: 's2',
            title: 'Secret',
            text: 'Forbidden truth.',
            spoilerItemId: 'secret',
          ),
          ExportSection(
            id: 'note',
            title: 'Author note',
            text: 'Do not publish this.',
            privateNote: true,
          ),
        ],
        metadata: {'projectPath': 'D:/private/project', 'author': 'Choirudin'},
      );

      final preflight = exporter.preflight(request);
      expect(preflight.isReady, isTrue);
      expect(preflight.issues, isEmpty);

      final output = exporter.export(request);
      expect(output.content, contains('Public prose.'));
      expect(output.content, contains('[disensor]'));
      expect(output.content, isNot(contains('Forbidden truth.')));
      expect(output.content, isNot(contains('Do not publish this.')));
      expect(output.content, isNot(contains('projectPath')));
      expect(output.content, isNot(contains('reader-1')));
    },
  );

  test('encyclopedia JSON profile removes hidden links and metadata', () {
    final registry = SpoilerRegistry()
      ..addAudience(const SpoilerAudience('public', SpoilerLevel.clean))
      ..classify('secret', SpoilerLevel.major);
    final service = SpoilerSafeExportService(
      redactor: ReaderRedactor(registry: registry)
        ..grant(readerId: 'public-reader', audience: 'public'),
    );
    final output = service.export(
      const SpoilerSafeExportRequest(
        documentId: 'encyclopedia-1',
        title: 'Knowledge',
        readerId: 'public-reader',
        currentScene: 'opening',
        format: ExportFormat.encyclopediaJson,
        sections: [
          ExportSection(
            id: 'entry',
            title: 'Entry',
            text: 'Known fact.',
            links: [InternalLink(label: 'secret', targetItemId: 'secret')],
          ),
        ],
      ),
    );
    expect(output.content, contains('Known fact.'));
    expect(output.content, isNot(contains('secret')));
    expect(output.content, isNot(contains('metadata')));
  });
}
