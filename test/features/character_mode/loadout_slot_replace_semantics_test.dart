// vs-hunt-20260913-loadout LDT-BUG-03 (run272).
//
// REFILL: setSlot adalah API 'set' satu-satunya untuk editor loadout
// (satu-satunya caller produksi: CharacterModeActions.setSlot -> tombol
// Save Loadout di character_mode_section.dart). Untuk slot multiplicity
// 'multiple' (accessory, carried_item) implementasi lama hanya menghapus
// entri lama bila multiplicity == single, sehingga MENGGANTI aset pada
// accessory/carried_item menyisakan baris lama + baris baru: dua aset
// terikat pada satu slot meski dialog hanya menyimpan satu pilihan —
// pengikatan lama menumpuk senyap dan relasi derived 'uses'/'wears' lama
// tidak pernah copot.
//
// Kontrak yang ditegakkan di sini:
// 1. setSlot eksklusif per (modeId, slot) untuk SEMUA multiplicity:
//    persis satu baris tersisa setelah set (clean-then-insert, sama seperti
//    jalur single yang sudah ada).
// 2. setSlot aset yang sama dua kali tetap idempoten (satu baris, bukan dua).
// 3. Baris pengganti memakai assetId & quantity baru; validasi tipe/quantity
//    lama tidak berubah.
// 4. (LDT-BUG-03b) Stepper quantity di dialog hanya boleh muncul untuk slot
//    yang validator-nya menerima quantity > 1. validateLoadoutQuantity
//    menolak quantity != 1 untuk accessory/companion/vehicle/armor/hair —
//    jadi loadoutSlotSupportsQuantity(accessory) HARUS false: selama ini
//    _slotSupportsQuantity longgar pada semua slot 'multiple', sehingga
//    pengguna bisa menekan '+' pada accessory lalu Save memicu
//    ArgumentError 'accessory supports quantity 1 only' dari repository.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/character_mode/data/character_loadout_repository_impl.dart';
import 'package:void_scriptor/features/character_mode/domain/loadout_slot.dart';
import 'package:void_scriptor/features/character_mode/presentation/widgets/character_mode_section.dart';

void main() {
  late ProjectDatabase database;

  setUp(() async {
    database = ProjectDatabase(NativeDatabase.memory());
    await database.initialize();
    await database
        .into(database.assets)
        .insert(
          AssetsCompanion.insert(
            id: 'char-1',
            projectId: 'project-1',
            name: 'Qowner',
            type: 'character',
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
        );
    for (final id in ['acc-old', 'acc-new', 'prop-old', 'prop-new']) {
      await database
          .into(database.assets)
          .insert(
            AssetsCompanion.insert(
              id: id,
              projectId: 'project-1',
              name: id,
              type: id.startsWith('acc') ? 'accessory' : 'prop',
              createdAt: DateTime(2026),
              updatedAt: DateTime(2026),
            ),
          );
    }
    await database.characterModeDao.insertMode(
      CharacterModesCompanion.insert(
        id: 'mode-1',
        projectId: 'project-1',
        characterId: 'char-1',
        name: 'Base Mode',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
  });

  tearDown(() => database.close());

  test(
    'replacing an accessory slot leaves exactly the new binding (LDT-BUG-03)',
    () async {
      final repository = CharacterLoadoutRepositoryImpl(database);
      await repository.setSlot(
        modeId: 'mode-1',
        slot: LoadoutSlot.accessory,
        assetId: 'acc-old',
      );

      await repository.setSlot(
        modeId: 'mode-1',
        slot: LoadoutSlot.accessory,
        assetId: 'acc-new',
      );

      final rows = await database.characterModeDao.getLoadout('mode-1');
      expect(
        rows.map((row) => row.assetId),
        ['acc-new'],
        reason:
            'slot accessory hanya boleh menyimpan satu ikatan; replace lama '
            'menyisakan baris lama + baru (penumpukan senyap)',
      );
    },
  );

  test(
    'setting the same accessory twice is idempotent (no duplicate rows)',
    () async {
      final repository = CharacterLoadoutRepositoryImpl(database);
      await repository.setSlot(
        modeId: 'mode-1',
        slot: LoadoutSlot.accessory,
        assetId: 'acc-old',
      );
      await repository.setSlot(
        modeId: 'mode-1',
        slot: LoadoutSlot.accessory,
        assetId: 'acc-old',
      );

      final rows = await database.characterModeDao.getLoadout('mode-1');
      expect(rows, hasLength(1));
    },
  );

  test(
    'replacing a carried_item slot keeps only the new row and its quantity',
    () async {
      final repository = CharacterLoadoutRepositoryImpl(database);
      await repository.setSlot(
        modeId: 'mode-1',
        slot: LoadoutSlot.carriedItem,
        assetId: 'prop-old',
        quantity: 2,
      );
      await repository.setSlot(
        modeId: 'mode-1',
        slot: LoadoutSlot.carriedItem,
        assetId: 'prop-new',
        quantity: 3,
      );

      final rows = await database.characterModeDao.getLoadout('mode-1');
      expect(rows, hasLength(1));
      expect(rows.single.assetId, 'prop-new');
      expect(rows.single.quantity, 3);
    },
  );

  test('quantity stepper gating mirrors the validator: accessory is false, '
      'carried_item and weapons are true (LDT-BUG-03b)', () {
    // Helper publik baru: satu sumber kebenaran = validator repository.
    expect(
      loadoutSlotSupportsQuantity(LoadoutSlot.accessory),
      isFalse,
      reason:
          'validateLoadoutQuantity(accessory, 2) menolak — stepper tidak '
          'boleh menawarkannya (Save akan melempar ArgumentError)',
    );
    expect(loadoutSlotSupportsQuantity(LoadoutSlot.companion), isFalse);
    expect(loadoutSlotSupportsQuantity(LoadoutSlot.armor), isFalse);
    expect(loadoutSlotSupportsQuantity(LoadoutSlot.carriedItem), isTrue);
    expect(loadoutSlotSupportsQuantity(LoadoutSlot.primaryWeapon), isTrue);
    expect(loadoutSlotSupportsQuantity(LoadoutSlot.secondaryWeapon), isTrue);
    // Konsistensi: helper == keputusan validator untuk SEMUA slot.
    for (final slot in LoadoutSlot.values) {
      expect(
        loadoutSlotSupportsQuantity(slot),
        validateLoadoutQuantity(slot, 2) == null,
        reason: 'gating stepper must equal validator for ${slot.value}',
      );
    }
    // Sentinel Value agar import drift terpakai bila tak dipakai tidak
    // mengganggu; tidak ada assertion tambahan.
    expect(const Value(1).value, 1);
  });
}
