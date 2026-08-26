# 109.42 — Mission Board & Story Links

**Acceptance kanonik:** `board_views`, `story_links`, `status_flow`,
`dependency_view`, `filters`.

## Implementasi

`lib/features/subplot/domain/mission_board.dart` memproyeksikan model
`StoryQuest` 109.41 menjadi board domain murni:

- list view terurut stabil berdasarkan quest ID;
- status view mengelompokkan seluruh quest ke setiap `StoryQuestStatus`;
- story links typed ke scene, character, location, dan arc;
- status flow eksplisit dan terminal status tidak dapat dibuka kembali;
- dependency view menunjukkan required/current status serta `isSatisfied`;
- filter kombinatif menurut status, tipe story-link, dan query case-insensitive.

Board menolak story link yang menunjuk quest tidak dikenal. Seluruh list hasil
bersifat unmodifiable dan operasi transition menghasilkan `StoryQuest` baru.

## Bukti TDD

| Acceptance | Bukti fokus |
|---|---|
| `board_views` | List stabil; grouping status mencakup setiap quest tepat sekali. |
| `story_links` | Scene/character/location/arc terproyeksi ke kartu; quest tidak dikenal ditolak. |
| `status_flow` | Draft→available→active→completed/failed sah; completed→active ditolak. |
| `dependency_view` | Status prerequisite saat ini dan syarat target ditampilkan; unlock dihitung. |
| `filters` | Status+tipe+query bisa digabung; filter kosong identik dengan list view. |

## Batas scope

Ini board model/application contract, bukan widget visual atau persistence.
Skema Drift tetap tidak berubah sampai D-SCHEMA-01 diputuskan di 109.51.
Mission-board UI dapat mengonsumsi proyeksi ini tanpa mengulang logika domain.
