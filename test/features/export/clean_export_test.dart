import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/export/domain/clean_export.dart';

void main() {
  group('strip_internal_links', () {
    test('keeps labels while stripping scene links and lore-link syntax', () {
      const source =
          '[Mira](scene:sc-01) menemui [[Menara Utara]] lalu scene:sc-02.';

      final result = const CleanExportTransformer().transform(source);

      expect(result.text, 'Mira menemui Menara Utara lalu .');
      expect(result.removedInternalLinks, 3);
    });

    test('does not strip ordinary external markdown links', () {
      const source = '[Sumber](https://example.test)';

      final result = const CleanExportTransformer().transform(source);

      expect(result.text, source);
      expect(result.removedInternalLinks, 0);
    });
  });

  group('strip_private_notes', () {
    test('removes inline and multiline private notes completely', () {
      const source =
          'Awal [[PRIVATE:catatan inline]] tengah\n'
          '[[PRIVATE:\nrahasia editor\nbaris dua\n]]\n'
          'Akhir';

      final result = const CleanExportTransformer().transform(source);

      expect(result.text, 'Awal  tengah\n\nAkhir');
      expect(result.removedPrivateNotes, 2);
      expect(result.text, isNot(contains('rahasia')));
    });
  });

  group('preserve_formatting', () {
    test('preserves all surrounding whitespace and line structure exactly', () {
      const source =
          '# Bab 1\r\n\r\n'
          '    Indent [[PRIVATE:x]] tetap\r\n'
          '\t[Mira](scene:sc-1)\r\n\r\n\r\n'
          'Penutup  ';

      final result = const CleanExportTransformer().transform(source);

      expect(
        result.text,
        '# Bab 1\r\n\r\n    Indent  tetap\r\n\tMira\r\n\r\n\r\nPenutup  ',
      );
    });
  });

  group('deterministic_output', () {
    test(
      'same input produces value-identical results and stable fingerprint',
      () {
        const source = '[A](scene:s-1) dan [[PRIVATE:x]] [[Lore]]';
        const transformer = CleanExportTransformer();

        final first = transformer.transform(source);
        final second = transformer.transform(source);

        expect(second, first);
        expect(second.fingerprint, first.fingerprint);
        expect(first.fingerprint, isNotEmpty);
      },
    );

    test('different cleaned text produces a different fingerprint', () {
      const transformer = CleanExportTransformer();

      expect(
        transformer.transform('Satu').fingerprint,
        isNot(transformer.transform('Dua').fingerprint),
      );
    });
  });

  group('no_source_mutation', () {
    test(
      'transform returns a new immutable result without changing source',
      () {
        const source = '[A](scene:s-1) [[PRIVATE:z]]';
        const transformer = CleanExportTransformer();

        final result = transformer.transform(source);

        expect(source, '[A](scene:s-1) [[PRIVATE:z]]');
        expect(result.sourceText, same(source));
        expect(result.text, 'A ');
        expect(result.wasChanged, isTrue);
      },
    );

    test('unchanged source is reported without manufacturing a mutation', () {
      const source = 'Teks biasa\n\nTetap utuh.';

      final result = const CleanExportTransformer().transform(source);

      expect(result.sourceText, source);
      expect(result.text, source);
      expect(result.wasChanged, isFalse);
      expect(result.removedInternalLinks, 0);
      expect(result.removedPrivateNotes, 0);
    });
  });
}
