// Kontrak Voice Profile & Dialogue Consistency (Step 109.16) — RED pertama.
//
// Acceptance kanonik sprint_109.json: editable_voice_rules,
// dialogue_comparison, explain_warning, disable_rule, no_auto_rewrite.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/dialogue/domain/voice_consistency.dart';

DialogueVoiceRule tabooRule() => const DialogueVoiceRule(
  id: 'vr-taboo',
  characterId: 'c-marek',
  kind: DialogueVoiceRuleKind.taboo,
  mode: DialogueVoiceRuleMode.avoid,
  terms: <String>['sialan', 'ampun'],
  explanation: 'Marek tidak pernah bersumpah kasar.',
);

DialogueVoiceRule patternRule() => const DialogueVoiceRule(
  id: 'vr-pattern',
  characterId: 'c-marek',
  kind: DialogueVoiceRuleKind.speechPattern,
  mode: DialogueVoiceRuleMode.require,
  terms: <String>['Komandan'],
  contextMarkers: <String>['menyerang', 'mundur'],
  explanation: 'Dalam perintah tempur Marek selalu menyebut jabatan.',
);

void main() {
  group('editable_voice_rules', () {
    test('aturan sah lolos validasi; masalah dilaporkan deterministik', () {
      expect(tabooRule().validateSchema(), isEmpty);
      const broken = DialogueVoiceRule(
        id: '',
        characterId: ' ',
        kind: DialogueVoiceRuleKind.diction,
        mode: DialogueVoiceRuleMode.avoid,
        terms: <String>[],
      );
      expect(broken.validateSchema(), <String>[
        'id must not be blank',
        'characterId must not be blank',
        'terms must not be empty',
      ]);
    });

    test('profil dapat diedit: tambah, ubah, hapus, aktif/nonaktif', () {
      final profile = DialogueVoiceProfile(characterId: 'c-marek')
        ..upsert(tabooRule());
      expect(profile.rules.single.id, 'vr-taboo');
      profile.upsert(
        const DialogueVoiceRule(
          id: 'vr-taboo',
          characterId: 'c-marek',
          kind: DialogueVoiceRuleKind.taboo,
          mode: DialogueVoiceRuleMode.avoid,
          terms: <String>['sialan'],
          explanation: 'Versi revisi.',
        ),
      );
      expect(profile.rules.single.terms, <String>['sialan']);
      profile.toggleEnabled('vr-taboo');
      expect(profile.rules.single.enabled, isFalse);
      profile.toggleEnabled('vr-taboo');
      expect(profile.rules.single.enabled, isTrue);
      profile.remove('vr-taboo');
      expect(profile.rules, isEmpty);
      expect(() => profile.toggleEnabled('tidak-ada'), throwsArgumentError);
    });
  });

  group('dialogue_comparison', () {
    test('avoid: istilah terlarang terdeteksi tak peduli kapitalisasi', () {
      final analyzer = DialogueVoiceConsistencyAnalyzer();
      final dirty = analyzer.checkLine(
        rules: <DialogueVoiceRule>[tabooRule()],
        characterId: 'c-marek',
        text: 'SIALAN, kapal kita bocor!',
      );
      expect(dirty.warnings.length, 1);
      expect(dirty.warnings.single.matchedTerm, 'sialan');
      expect(dirty.clean, isFalse);
      final clean = analyzer.checkLine(
        rules: <DialogueVoiceRule>[tabooRule()],
        characterId: 'c-marek',
        text: 'Kita perbaiki di pelabuhan berikutnya.',
      );
      expect(clean.clean, isTrue);
    });

    test('require: penanda konteks tanpa istilah wajib memicu peringatan', () {
      final analyzer = DialogueVoiceConsistencyAnalyzer();
      final violating = analyzer.checkLine(
        rules: <DialogueVoiceRule>[patternRule()],
        characterId: 'c-marek',
        text: 'Kita menyerang saat gelap.',
      );
      expect(violating.warnings.single.missingTerms, <String>['Komandan']);
      final compliant = analyzer.checkLine(
        rules: <DialogueVoiceRule>[patternRule()],
        characterId: 'c-marek',
        text: 'Komandan, kita menyerang saat gelap.',
      );
      expect(compliant.clean, isTrue);
      final outOfContext = analyzer.checkLine(
        rules: <DialogueVoiceRule>[patternRule()],
        characterId: 'c-marek',
        text: 'Sarapan pagi ini hangat.',
      );
      expect(outOfContext.clean, isTrue);
    });
  });

  group('explain_warning', () {
    test('render penjelasan deterministik dan identik antar-analisis', () {
      final analyzer = DialogueVoiceConsistencyAnalyzer();
      final a = analyzer.checkLine(
        rules: <DialogueVoiceRule>[tabooRule()],
        characterId: 'c-marek',
        text: 'Ampun, dia kuat sekali.',
      );
      final b = analyzer.checkLine(
        rules: <DialogueVoiceRule>[tabooRule()],
        characterId: 'c-marek',
        text: 'Ampun, dia kuat sekali.',
      );
      expect(a.warnings.single.render(), b.warnings.single.render());
      expect(
        a.warnings.single.render(),
        '[taboo] Marek tidak pernah bersumpah kasar.\n'
        'Istilah terlarang ditemukan: "ampun".\n'
        'Saran: tinjau ulang kalimat ini secara manual.',
      );
    });
  });

  group('disable_rule', () {
    test('aturan nonaktif dilewati sampai diaktifkan kembali', () {
      final analyzer = DialogueVoiceConsistencyAnalyzer();
      var rule = tabooRule();
      final before = analyzer.checkLine(
        rules: <DialogueVoiceRule>[rule],
        characterId: 'c-marek',
        text: 'Sialan, dia lolos.',
      );
      expect(before.warnings.length, 1);
      rule = rule.withEnabled(false);
      final during = analyzer.checkLine(
        rules: <DialogueVoiceRule>[rule],
        characterId: 'c-marek',
        text: 'Sialan, dia lolos.',
      );
      expect(during.clean, isTrue);
      rule = rule.withEnabled(true);
      final after = analyzer.checkLine(
        rules: <DialogueVoiceRule>[rule],
        characterId: 'c-marek',
        text: 'Sialan, dia lolos.',
      );
      expect(after.warnings.length, 1);
    });
  });

  group('no_auto_rewrite', () {
    test('teks asli dipertahankan verbatim dan analisis idempoten', () {
      final analyzer = DialogueVoiceConsistencyAnalyzer();
      const raw = '  SIALAN,   kapal kita bocor!\n';
      final first = analyzer.checkLine(
        rules: <DialogueVoiceRule>[tabooRule()],
        characterId: 'c-marek',
        text: raw,
      );
      expect(first.originalText, raw);
      expect(first.suggestedRewrite, isNull);
      final second = analyzer.checkLine(
        rules: <DialogueVoiceRule>[tabooRule()],
        characterId: 'c-marek',
        text: raw,
      );
      expect(second.warnings.single.render(), first.warnings.single.render());
    });

    test('batch multi-baris menjaga urutan dan teks asli tiap baris', () {
      final analyzer = DialogueVoiceConsistencyAnalyzer();
      final lines = <String>[
        'Ampun, dia kuat.',
        'Bersiaplah, Komandan.',
        'Sialan, badai datang.',
      ];
      final results = analyzer.checkAll(
        rules: <DialogueVoiceRule>[tabooRule()],
        characterId: 'c-marek',
        texts: lines,
      );
      expect(results.map((r) => r.originalText), lines);
      expect(results.where((r) => !r.clean).length, 2);
    });
  });
}
