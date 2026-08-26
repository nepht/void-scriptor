// Kontrak Scene POV Lock (Step 109.33) — RED pertama.
//
// Acceptance kanonik sprint_109.json: scene_pov, section_override,
// tense, narration_mode, visible_status.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/pov/domain/pov_lock.dart';

void main() {
  group('scene_pov', () {
    test('POV karakter pertama terkunci per adegan', () {
      final ledger = PovLedger()
        ..lockScene(
          sceneId: 'sc-01',
          povCharacterId: 'n-kael',
          mode: PovMode.firstPerson,
        );
      expect(ledger.povOf('sc-01')!.povCharacterId, 'n-kael');
      expect(ledger.povOf('sc-01')!.mode, PovMode.firstPerson);
      // Kunci ulang POV berbeda pada adegan sama ditolak.
      expect(
        () => ledger.lockScene(
          sceneId: 'sc-01',
          povCharacterId: 'n-mira',
          mode: PovMode.thirdLimited,
        ),
        throwsStateError,
      );
    });
  });

  group('section_override', () {
    test('bagian mewarisi kunci adegan kecuali di-override', () {
      final ledger = PovLedger()
        ..lockScene(
          sceneId: 'sc-01',
          povCharacterId: 'n-kael',
          mode: PovMode.thirdLimited,
        )
        ..lockScene(
          sceneId: 'sc-02',
          povCharacterId: 'n-mira',
          mode: PovMode.thirdLimited,
        )
        ..defineSection(
          sectionId: 'sec-1',
          sceneIds: const <String>['sc-01', 'sc-02'],
        );
      // Override satu bagian mengubah seluruh adegan anggotanya.
      ledger.overrideSection(
        sectionId: 'sec-1',
        povCharacterId: 'n-mira',
        mode: PovMode.firstPerson,
        tense: NarrativeTense.past,
      );
      expect(ledger.effectivePovOf('sc-01')!.povCharacterId, 'n-mira');
      expect(ledger.effectivePovOf('sc-02')!.povCharacterId, 'n-mira');
      // Adegan tanpa bagian tetap memakai kunci adegannya sendiri.
      final ledger2 = PovLedger()
        ..lockScene(
          sceneId: 'sc-09',
          povCharacterId: 'n-kael',
          mode: PovMode.thirdLimited,
        );
      expect(ledger2.effectivePovOf('sc-09')!.povCharacterId, 'n-kael');
    });
  });

  group('tense', () {
    test('tense narasi terekam dan bisa berbeda antaradegan', () {
      final ledger = PovLedger()
        ..lockScene(
          sceneId: 'sc-01',
          povCharacterId: 'n-kael',
          mode: PovMode.thirdLimited,
          tense: NarrativeTense.past,
        )
        ..lockScene(
          sceneId: 'sc-02',
          povCharacterId: 'n-mira',
          mode: PovMode.firstPerson,
          tense: NarrativeTense.present,
        );
      expect(ledger.povOf('sc-01')!.tense, NarrativeTense.past);
      expect(ledger.povOf('sc-02')!.tense, NarrativeTense.present);
    });
  });

  group('narration_mode', () {
    test('mode narasi tersedia dan tervalidasi', () {
      final ledger = PovLedger()
        ..lockScene(
          sceneId: 'sc-01',
          povCharacterId: 'n-kael',
          mode: PovMode.thirdOmniscient,
          tense: NarrativeTense.past,
        );
      expect(ledger.povOf('sc-01')!.mode, PovMode.thirdOmniscient);
      // firstPerson tanpa nama tokoh jelas tetap sah; tapi mode wajib
      // eksplisit — tidak ada default diam-diam.
      expect(
        () => ledger.lockScene(sceneId: 'sc-05', povCharacterId: 'n-mira'),
        throwsArgumentError,
      );
    });
  });

  group('visible_status', () {
    test('status kunci terlihat dan dilaporkan per adegan', () {
      final ledger = PovLedger()
        ..lockScene(
          sceneId: 'sc-01',
          povCharacterId: 'n-kael',
          mode: PovMode.firstPerson,
        )
        ..markUnlocked('sc-01');
      expect(ledger.statusOf('sc-01'), PovStatus.unlocked);
      expect(ledger.statusOf('hantu'), PovStatus.unset);
      ledger.lockScene(
        sceneId: 'sc-01',
        povCharacterId: 'n-kael',
        mode: PovMode.firstPerson,
      );
      expect(ledger.statusOf('sc-01'), PovStatus.locked);
      // Ringkasan seluruh adegan untuk panel status.
      ledger.lockScene(
        sceneId: 'sc-02',
        povCharacterId: 'n-mira',
        mode: PovMode.thirdLimited,
      );
      final statuses = ledger.allStatuses();
      expect(statuses['sc-01'], PovStatus.locked);
      expect(statuses['sc-02'], PovStatus.locked);
    });
  });
}
