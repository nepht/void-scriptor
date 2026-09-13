// Regression test vs-hunt-20260914-export EXP-BUG-04 (Low).
// Kontrak: preview preflight harus terpotong pada batas kode UTF-16 yang utuh —
// pasangan surrogate (karakter non-BMP) tidak boleh dibelah. High/low surrogate
// yatim di ujung string = teks malformed bagi consumer (clipboard, encoder UI)
// dan melanggar intent test lama "truncates at a character boundary".
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/export/domain/export_preflight.dart';
import 'package:void_scriptor/features/export/domain/export_profiles.dart';

void main() {
  ExportPreflightRequest request({
    required String source,
    int previewLimit = 40,
  }) => ExportPreflightRequest(
    documentId: 'doc-preview-surrogate',
    sourceText: source,
    profile: ExportProfile.plainText(),
    previewCharacterLimit: previewLimit,
  );

  const validator = ExportPreflightValidator();

  bool endsWithLoneHighSurrogate(String s) {
    if (s.isEmpty) return false;
    final last = s.codeUnits.last;
    if (last < 0xD800 || last > 0xDBFF) return false;
    // high surrogate di posisi terakhir = yatim
    return true;
  }

  test('preview tidak berakhir dengan high surrogate yatim', () {
    // 'abcdefghijklmnop' = 16 BMP char; emoji 😀 non-BMP (2 code unit)
    // menempati indeks 16-17. limit 18 -> substring(0,17) -> high yatim.
    const source = 'abcdefghijklmnop\u{1F600}qrstuvwxyz';
    final report = validator.validate(
      request(source: source, previewLimit: 18),
    );
    final body = report.preview.endsWith('…')
        ? report.preview.substring(0, report.preview.length - 1)
        : report.preview;
    expect(
      endsWithLoneHighSurrogate(body),
      isFalse,
      reason: 'body ${body.codeUnits} berakhir high surrogate yatim',
    );
  });

  test('preview tidak menyisipkan low surrogate tanpa high pendamping', () {
    // Emoji di indeks 15-16; limit 17 -> substring(0,16) memuat high@15...
    const source = 'abcdefghijklmno\u{1F600}pqrstuvwxyz0123456789';
    final report = validator.validate(
      request(source: source, previewLimit: 17),
    );
    final units = report.preview.codeUnits;
    for (var i = 0; i < units.length; i++) {
      final u = units[i];
      if (u >= 0xDC00 && u <= 0xDFFF) {
        // low surrogate wajib didahului high surrogate pada indeks i-1
        expect(
          i > 0 && units[i - 1] >= 0xD800 && units[i - 1] <= 0xDBFF,
          isTrue,
          reason: 'low surrogate yatim pada indeks $i: $units',
        );
      } else if (u >= 0xD800 && u <= 0xDBFF) {
        // high surrogate wajib punya pasangan low pada indeks i+1
        expect(
          i + 1 < units.length &&
              units[i + 1] >= 0xDC00 &&
              units[i + 1] <= 0xDFFF,
          isTrue,
          reason: 'high surrogate yatim pada indeks $i: $units',
        );
      }
    }
  });

  test('kontrak lama: teks BMP tetap terpotong persis sama', () {
    final report = validator.validate(
      request(source: 'abc def ghi jkl mno pqr', previewLimit: 10),
    );
    expect(report.preview, 'abc def g…');
    expect(report.preview.length, 10);
  });

  test(
    'teks seluruhnya emoji: potong genap sebelum ellipsis, panjang <= limit',
    () {
      final source = '\u{1F600}' * 10; // 20 code unit
      final report = validator.validate(
        request(source: source, previewLimit: 5),
      );
      expect(report.preview.endsWith('…'), isTrue);
      expect(report.preview.length, lessThanOrEqualTo(5));
      // body harus kelipatan pasangan surrogate (genap)
      expect((report.preview.length - 1) % 2, 0);
      expect(endsWithLoneHighSurrogate(report.preview), isFalse);
    },
  );
}
