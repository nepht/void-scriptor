import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/story/domain/inline_lore_links.dart';

void main() {
  const parser = InlineLoreLinkParser();
  const renderer = InlineLoreLinkRenderer();
  const editor = InlineLoreLinkEditor();

  LoreTextSegment textOf(InlineLoreSegment segment) {
    expect(segment, isA<LoreTextSegment>());
    return segment as LoreTextSegment;
  }

  LoreLinkSegment linkOf(InlineLoreSegment segment) {
    expect(segment, isA<LoreLinkSegment>());
    return segment as LoreLinkSegment;
  }

  group('parse_valid_links', () {
    test('parses a single link embedded between plain text', () {
      final segments = parser.parse('Kisah [[Ratu Angin]] bermula di pesisir.');

      expect(segments.length, 3);
      expect(textOf(segments[0]).text, 'Kisah ');
      expect(linkOf(segments[1]).target, 'Ratu Angin');
      expect(textOf(segments[2]).text, ' bermula di pesisir.');
    });

    test('parses several links in one passage', () {
      final segments = parser.parse(
        '[[Api]] bertemu [[Air]] di [[Pulau Karang]].',
      );

      expect(segments.length, 6);
      expect(linkOf(segments[0]).target, 'Api');
      expect(textOf(segments[1]).text, ' bertemu ');
      expect(linkOf(segments[2]).target, 'Air');
      expect(textOf(segments[3]).text, ' di ');
      expect(linkOf(segments[4]).target, 'Pulau Karang');
      expect(textOf(segments[5]).text, '.');
    });

    test('exposes trimmed display name for entity lookup', () {
      final segments = parser.parse('[[  Laut Selatan  ]]');

      final link = linkOf(segments.single);
      expect(link.target, '  Laut Selatan  ');
      expect(link.displayName, 'Laut Selatan');
    });

    test('parses an entirely linked passage', () {
      final segments = parser.parse('[[Void Cube]]');

      expect(segments.length, 1);
      expect(linkOf(segments.single).target, 'Void Cube');
    });
  });

  group('preserve_plain_text', () {
    test('keeps plain prose verbatim including spacing and newlines', () {
      const source = 'Baris pertama.\nBaris  kedua   tetap utuh.';

      final segments = parser.parse(source);

      expect(segments.length, 1);
      expect(textOf(segments.single).text, source);
    });

    test('keeps an unbalanced opening as literal text', () {
      const source = 'Ia menulis [[Ratu Angin lalu hujan turun.';

      final segments = parser.parse(source);

      expect(segments.length, 1);
      expect(textOf(segments.single).text, source);
    });

    test('keeps empty and blank bracket bodies as literal text', () {
      for (final source in <String>[
        'sebuah [[]] kotak',
        'isi [[   ]] kosong',
      ]) {
        final segments = parser.parse(source);

        expect(segments.length, 1, reason: source);
        expect(textOf(segments.single).text, source, reason: source);
      }
    });

    test('never links across line breaks', () {
      const source = 'awal [[Ratu\nAngin]] akhir';

      final segments = parser.parse(source);

      expect(segments.length, 1);
      expect(textOf(segments.single).text, source);
    });
  });

  group('escape_syntax', () {
    test('backslash before the opening bracket prevents linkification', () {
      const source = r'Ini bukan tautan: \[[Ratu Angin]].';

      final segments = parser.parse(source);

      expect(segments.length, 1);
      expect(textOf(segments.single).text, source);
    });

    test('escaped text coexists with a real link afterwards', () {
      const source = r'\[[Bukan]] tetapi [[Asli]] ya.';

      final segments = parser.parse(source);

      expect(segments.length, 3);
      expect(textOf(segments[0]).text, r'\[[Bukan]] tetapi ');
      expect(linkOf(segments[1]).target, 'Asli');
      expect(textOf(segments[2]).text, ' ya.');
    });
  });

  group('round_trip', () {
    const corpus = <String>[
      '',
      'Naskah polos tanpa tautan.',
      'Spasi  ganda\ndan baris baru.',
      '[[Api]]',
      '[[Ratu Angin]] memanggil [[Budi]] ke [[Pulau Karang]].',
      r'Huruf wajar \[[bukan tautan]] di tengah kalimat.',
      'Tautan tak tertutup [[Api di ujung.',
      'Penutup liar ]] sebelum apapun.',
      r'Campuran [[Api]] dengan \[[Bayangan]] dan [[Batal',
      'Emoji 🌊 menuju [[Laut Selatan]] lalu 🌋.',
      '[[  Laut Selatan  ]] dengan spasi dalam kurung.',
      'tanda \\ biasa sebelum [[Api]].',
    ];

    test('every corpus entry survives parse then render unchanged', () {
      for (final source in corpus) {
        final rendered = renderer.render(parser.parse(source));

        expect(rendered, source, reason: 'round trip gagal untuk: $source');
      }
    });
  });

  group('handle_rename', () {
    test('renames only the link segment', () {
      const source = 'Kisah [[Ratu Angin]] dimulai.';

      final renamed = editor.renameTarget(
        source,
        from: 'Ratu Angin',
        to: 'Ratu Timur',
      );

      expect(renamed, 'Kisah [[Ratu Timur]] dimulai.');
    });

    test('leaves plain-text mentions of the same name untouched', () {
      const source = 'Ratu Angin berbicara tentang [[Ratu Angin]] sendiri.';

      final renamed = editor.renameTarget(
        source,
        from: 'Ratu Angin',
        to: 'Ratu Timur',
      );

      expect(renamed, 'Ratu Angin berbicara tentang [[Ratu Timur]] sendiri.');
    });

    test('leaves escaped mentions untouched', () {
      const source = r'\[[Ratu Angin]] contoh; [[Ratu Angin]] nyata.';

      final renamed = editor.renameTarget(
        source,
        from: 'Ratu Angin',
        to: 'Ratu Timur',
      );

      expect(renamed, r'\[[Ratu Angin]] contoh; [[Ratu Timur]] nyata.');
    });

    test(
      'matches padded links by display name and writes canonical target',
      () {
        const source = 'jejak [[  Ratu Angin  ]] purba.';

        final renamed = editor.renameTarget(
          source,
          from: 'Ratu Angin',
          to: 'Ratu Timur',
        );

        expect(renamed, 'jejak [[Ratu Timur]] purba.');
      },
    );

    test('matching is case sensitive', () {
      const source = '[[ratu angin]] tetap.';

      final renamed = editor.renameTarget(
        source,
        from: 'Ratu Angin',
        to: 'Ratu Timur',
      );

      expect(renamed, source);
    });

    test('returns the identical source when nothing matches', () {
      const source = 'tidak ada [[Entitas Lain]] di sini.';

      final renamed = editor.renameTarget(
        source,
        from: 'Ratu Angin',
        to: 'Ratu Timur',
      );

      expect(identical(renamed, source), isTrue);
    });

    test('renamed result still round trips', () {
      const source = 'prolog [[Ratu Angin]] epilog.';

      final renamed = editor.renameTarget(
        source,
        from: 'Ratu Angin',
        to: 'Ratu Timur',
      );

      expect(renderer.render(parser.parse(renamed)), renamed);
    });
  });
}
