// Regresi vs-hunt-20260914-content CT-BUG-05 (PovLedger.markUnlocked).
//
// Doc-mark: membuka kunci "hanya sah dari status locked". Guard lama
// hanya memeriksa ada-tidaknya entri kunci, sehingga unlock KEDUA pada
// adegan yang sudah unlocked lolos diam-diam (status tak berubah) —
// transisi state tidak sah yang dijanjikan ditolak tidak ditolak.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/pov/domain/pov_lock.dart';

void main() {
  group('markUnlocked state machine (CT-BUG-05)', () {
    test('unlock pertama sah; unlock ulang ditolak StateError', () {
      final ledger = PovLedger()
        ..lockScene(
          sceneId: 'sc-01',
          povCharacterId: 'n-kael',
          mode: PovMode.firstPerson,
        )
        ..markUnlocked('sc-01');
      expect(ledger.statusOf('sc-01'), PovStatus.unlocked);
      expect(() => ledger.markUnlocked('sc-01'), throwsStateError);
      // Status tetap unlocked setelah percobaan ganda.
      expect(ledger.statusOf('sc-01'), PovStatus.unlocked);
    });

    test('unlock setelah relock kembali sah', () {
      final ledger = PovLedger()
        ..lockScene(
          sceneId: 'sc-02',
          povCharacterId: 'n-mira',
          mode: PovMode.thirdLimited,
        )
        ..markUnlocked('sc-02')
        ..lockScene(
          sceneId: 'sc-02',
          povCharacterId: 'n-mira',
          mode: PovMode.thirdLimited,
        );
      expect(ledger.statusOf('sc-02'), PovStatus.locked);
      ledger.markUnlocked('sc-02');
      expect(ledger.statusOf('sc-02'), PovStatus.unlocked);
    });

    test('adegan tak dikenal tetap ditolak (kontrak lama)', () {
      expect(() => PovLedger().markUnlocked('hantu'), throwsStateError);
    });
  });
}
