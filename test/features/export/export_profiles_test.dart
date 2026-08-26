// Kontrak Manuscript Export Profiles (Step 109.38) — RED pertama.
//
// Acceptance kanonik sprint_109.json: profile_settings, chapter_rules,
// scene_break_rules, front_matter, saved_presets.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/export/domain/export_profiles.dart';

void main() {
  group('profile_settings', () {
    test('profil format bawaan tersedia dan tervalidasi', () {
      final docx = ExportProfile.docx();
      expect(docx.format, ExportFormat.docx);
      expect(docx.sceneBreakMarker, isNotEmpty);
      final txt = ExportProfile.plainText();
      expect(txt.format, ExportFormat.plainText);
      // Marker adegan kosong ditolak.
      expect(
        () =>
            ExportProfile(format: ExportFormat.webNovel, sceneBreakMarker: ''),
        throwsArgumentError,
      );
    });
  });

  group('chapter_rules', () {
    test('aturan bab: penomoran, awalan, dan halaman baru', () {
      final profile = ExportProfile.docx()
        ..setChapterRules(
          numberingStart: 1,
          titlePrefix: 'Bab',
          pageBreakBefore: true,
        );
      expect(profile.chapterRules!.title(1), 'Bab 1');
      expect(profile.chapterRules!.title(12), 'Bab 12');
      expect(profile.chapterRules!.pageBreakBefore, isTrue);
      // Awalan kosong sah (judul angka saja).
      profile.setChapterRules(
        numberingStart: 0,
        titlePrefix: '',
        pageBreakBefore: false,
      );
      expect(profile.chapterRules!.title(5), '5');
    });
  });

  group('scene_break_rules', () {
    test('aturan pemisah adegan: marker dan blank lines', () {
      final web = ExportProfile.webNovel()
        ..setSceneBreakRules(blankLinesBetween: 2);
      // Web novel memakai marker bawaan sendiri.
      expect(web.sceneBreakMarker, contains('* * *'));
      expect(web.sceneBreakRules!.blankLinesAroundBreak, 2);
      // Blank line negatif ditolak.
      expect(
        () => web.setSceneBreakRules(blankLinesBetween: -1),
        throwsArgumentError,
      );
    });
  });

  group('front_matter', () {
    test('halaman muka terekam dan ikut render dokumen', () {
      final profile = ExportProfile.docx()
        ..setFrontMatter(title: 'Void Cube Saga', author: 'Choirudin');
      expect(profile.frontMatter!.title, 'Void Cube Saga');
      expect(profile.frontMatter!.author, 'Choirudin');
      final rendered = profile.renderFrontMatter();
      expect(rendered, contains('Void Cube Saga'));
      expect(rendered, contains('Choirudin'));
    });
  });

  group('saved_presets', () {
    test('preset profil bisa disimpan, dipanggil, dan dihapus', () {
      final book = ExportPresetBook();
      final profile = ExportProfile.docx()
        ..setChapterRules(
          numberingStart: 1,
          titlePrefix: 'Bab',
          pageBreakBefore: true,
        )
        ..setFrontMatter(title: 'Naskah Utama', author: 'Choirudin');
      book.save(name: 'standar', profile: profile);
      final loaded = book.load('standar');
      expect(loaded.format, ExportFormat.docx);
      expect(loaded.frontMatter!.title, 'Naskah Utama');
      // Simpan ulang nama sama menimpa (preset milik pengguna).
      book.save(name: 'standar', profile: ExportProfile.plainText());
      expect(book.load('standar').format, ExportFormat.plainText);
      // Muat nama tak dikenal ditolak; hapus lalu muat gagal.
      expect(() => book.load('hantu'), throwsStateError);
      book.delete('standar');
      expect(() => book.load('standar'), throwsStateError);
      // Daftar nama preset terurut untuk UI pilih-preset.
      book
        ..save(name: 'beta', profile: ExportProfile.webNovel())
        ..save(name: 'alpha', profile: ExportProfile.plainText());
      expect(book.names(), <String>['alpha', 'beta']);
    });
  });
}
