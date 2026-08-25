# 109.7 — Accessibility & Localization Baseline

> Kanonik 109.7: "Menetapkan standar keyboard, screen reader, scaling, contrast,
> motion, locale, dan text expansion." Disusun nephthys 2026-08-26.
> Baseline diukur live pada repo saat ini; standar mengikat semua fitur Wave 1 dan
> menjadi pembanding verifikasi 109.48.

## B1 — Baseline terukur (2026-08-26, bukan klaim historis)

| Metrik | Nilai live | Sumber |
|---|---|---|
| Widget `Semantics(` eksplisit di `lib/` | **0** | grep seluruh lib |
| Tooltip/`semanticsLabel` | **42** penggunaan | grep seluruh lib |
| Kunci lokalisasi | **4 kunci**, paritas en↔id PENUH | `app_en.arb` / `app_id.arb` |
| Locale terpasang | ID + EN (`AppLocalizations`, dipakai main/void_app/welcome_screen) | `lib/l10n/` |
| Tes scaling teks | **1 file** (`workflow/automation_a11y_test.dart`) | grep textScaler di test |
| Suite a11y/keyboard historis | +14 tes hijau (S107 batch 2, 2026-08-25) | ledger S107 |

Interpretasi jujur: fondasi ada (tooltip, l10n generator, satu suite a11y), tetapi
cakupan semantik screen reader masih kosong. Sprint ini TIDAK menjanjikan remediasi
retroaktif seluruh modul lama (NG-6) — standar berikut mengikat FITUR BARU.

## B2 — Standar aksesibilitas Wave 1 (mengikat)

| ID | Standar |
|---|---|
| A11Y-01 Keyboard | Setiap alur inti fitur dapat diselesaikan penuh via keyboard; shortcut tidak menimpa binding teks (pola SingleActivator dengan modifier). Acceptance kanonik per fitur (keyboard_navigation, keyboard_reorder, keyboard_exit) adalah minimum, bukan target. |
| A11Y-02 Screen reader | Kontrol ikon tanpa teks wajib tooltip ATAU Semantics label; daftar/kartu dinamis (inbox, board, heatmap) menyediakan label ringkas per item; pengumuman perubahan state penting (mis. reorder board) via semantics announcement sesuai acceptance kanonik. |
| A11Y-03 Scaling | Widget test fitur mencakup lebar desktop + sempit dengan `tester.takeException()` null (pola mapan), plus minimal satu tes textScaler besar per layar fitur baru. |
| A11Y-04 Contrast & warna | Hanya token tema (SemanticColors/desain sistem); warna literal di luar design system ditolak review; status tak boleh disampaikan warna saja (selalu ada teks/ikon). |
| A11Y-05 Motion | Transisi baru menghormati preferensi reduce-motion bila media query tersedia; tanpa animasi wajib untuk operasi data. |

## B3 — Standar lokalisasi Wave 1 (mengikat)

| ID | Standar |
|---|---|
| L10N-01 | String user-facing fitur baru masuk ARB (`app_en.arb` + `app_id.arb`), paritas kunci dijaga tes; string literal hard-coded di widget fitur baru = temuan review 109.48. |
| L10N-02 | Text expansion: layout memakai ellipsis/wrap/isExpanded (pitfall DropdownButton/toolbar mapan); tes lebar sempit memverifikasi id-string terpanjang. |
| L10N-03 | Format angka/tanggal via intl sesuai locale aktif (target kata, durasi sesi, tanggal snapshot). |
| L10N-04 | Terminologi konsisten: istilah kanonik v1.2 (Novel Workspace, Character Workspace, lore link, dsb.) punya padanan Indonesia tetap di ARB, tidak diterjemahkan bergantian. |

## B4 — Cara verifikasi

Per langkah fitur: kriterianya sendiri membuktikan diri via test (B2/B3 masuk RED test
saat relevan). Langkah 109.48 kemudian menjalankan verifikasi lintas-workflow penuh
(keyboard/screen-reader/scaling/contrast/locale results + fix_status) dan membandingkan
dengan angka B1 sebagai delta nyata.
