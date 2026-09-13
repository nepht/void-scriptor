# Referee Report — vs-hunt-20260913-loadout (run272)

- target: `lib/features/character_mode` (15 files, ~1.6k LOC)
- repo: D:\VoidScriptor\void_scriptor_multiplatform, branch master, HEAD saat scan: `058d7963049efb75675ba16ba71d711fb47448bc`
- rantai: Hunter (delegasi, 5 temuan / score 21) → Skeptic+Referee inline oleh parent (delegasi anak gagal 429 upstream dua kali; preseden run262/267/270; status rantai jujur: PARTIAL delegate, verdict diverifikasi penuh terhadap kode live oleh parent)
- method referee: setiap claim dibaca ulang terhadap file live di HEAD yang sama; verdict di bawah adalah otoritas nomor dan status temuan ini.

## VONIS (nomor otoritatif = tabel ini, mengikat konsumen BUG-ID sebagai `vs-hunt-20260913-loadout-BUG-N`)

| ID | Claim ringkas | Verdict | Severity sejati | Alasan |
|----|---------------|---------|-----------------|--------|
| LDT-BUG-01 | `ref.invalidate(characterModesProvider)` tanpa arg family gagal/error | NOT A BUG | - | flutter_riverpod ^2.6.1 mendukung invalidasi seluruh family via objek family; jalur rebuild FutureBuilder editor terverifikasi di section:63/:91. Skeptic benar. |
| LDT-BUG-02 | invalidate `projectAssetsProvider` tidak menyegarkan kartu referensi mode | REAL BUG | Low | Staleness UI nyata: kartu dimuat dari `repository.getReferences(modeId)` (FutureBuilder lokal), consumer lain tidak rebuild kartu ini. Tidak ada kehilangan data. |
| LDT-BUG-03 | slot multiple hanya menyimpan/mengedit satu aset; replace = tambah baris kedua senyap | REAL BUG | Medium | Mekanik terkonfirmasi: dialog map slot→entri pertama; Save memanggil `setSlot` saja; `character_loadout_repository_impl.dart` hanya delete-before-insert untuk `multiplicity == single` → replace pada accessory/carried_item meninggalkan ikatan lama + baris baru. Akumulasi senyap = defect integritas data. |
| LDT-BUG-04 | `removeSlot` cek `stillUsed` lintas karakter (global by assetId) | REAL BUG | Low | Query filter assetId saja tanpa join ke character mode milik karakter ini → relasi turunan 'uses'/'wears' ghost bertahan untuk karakter ini saat karakter lain masih memakai aset yang sama. Cleanup di bawahnya sudah benar ter-scope. |
| LDT-BUG-05 | `selectedCharacterModeProvider` default null memaksa konsumen handle null | NOT A BUG | - | Idiom Riverpod standar; `_resolveMode` punya fallback chain eksplisit (selectedId ?? lastUsedId). Skeptic benar. |

Ringkasan: **3 REAL / 2 NOT A BUG.**

## TINDAK LANJUT (diputuskan dan dieksekusi run272)
- **LDT-BUG-03 diperbaiki** via `test/features/character_mode/loadout_slot_replace_semantics_test.dart` (RED missing-symbol → GREEN 4/4): `setSlot` menjadi operasi SET per (modeId, slot) untuk SEMUA multiplicity (clean-then-insert), sesuai semantik yang sudah dikunci kontrak 'replace' dialog + updateQuantity. Satu panggilan `setSlot(quantity:5)` untuk konsolidasi baris duplikat warisan.
- **LDT-BUG-03b** (temuan turunan saat menulis RED, satu kontrak dengan -03): helper `loadoutSlotSupportsQuantity` (sumber kebenaran tunggal = `validateLoadoutQuantity`) menggantikan gerbang UI longgar → '+' stepper tidak lagi muncul pada accessory (kapasitas 1) yang sebelumnya berujung `ArgumentError` saat Save.
- **Regression terpro-duksi di HEAD, diperbaiki di run ini (di luar 5 temuan):** `VoidButton` overflow RenderFlex pada label panjang di viewport 390px — penyebab kegagalan deterministik `character_section_ownership_test.dart` dan exception `narrative_card_terminal_failure_test.dart` di HEAD `058d796`. Fix design-system: `Flexible` + `TextOverflow.ellipsis`; RED+GREEN di `test/design_system/widgets/void_button_test.dart`. **Atribusi commit:** pilot paralel mendaratkan fix setara lebih dulu sebagai `d41dc20` (2026-09-13 12:09); fix run272 digantikan (superseded) oleh commit itu — diverifikasi hijau pasca-pull: `character_section_ownership_test.dart` 4/4 PASS, `void_button_test.dart` 3/3 PASS.
- **LDT-BUG-02 dan LDT-BUG-04 masih TERBUKA** (Low; dicatat di ledger untuk remediasi berjadwal).

## PERBAIKAN KONSUMEN
Konsumen verdict WAJIB mem-scope BUG-ID penuh (`vs-hunt-20260913-loadout-BUG-03`) dan memeriksa HEAD yang tertera sebelum bertindak — rantai paralel lain di repo ini punya penomoran BUG-nya sendiri.
