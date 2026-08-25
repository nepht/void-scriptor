# 108.23 — Accessibility & Localization Feasibility

> Sprint 108 · disusun 2026-08-25 · kanonik review_scope:
> keyboard, screen_reader, scaling, contrast, motion, text_expansion,
> locale_coverage — dinilai SEBELUM prioritisasi solusi.

## Bukti langsung (grep repo live, 2026-08-25)

| area | temuan | penilaian |
|---|---|---|
| keyboard | 3 file uji memakai `LogicalKeyboardKey`; shortcut inti (Ctrl+S/Z/Y dsb.) teruji sejak era awal | parsial — alur keyboard hidup untuk power-user |
| screen_reader | `Semantics(` di seluruh `lib/` = **0 kemunculan** | praktis tidak dilayani saat ini |
| scaling | `MediaQuery`/`textScaler` hanya 2 file | minim — uji overflow per-sprint melindungi layout sempit, bukan font besar |
| contrast | tema 6 mode (termasuk AMOLED) ada; tanpa uji kontras otomatis | belum diukur sistematis |
| motion | tidak ditemukan penanganan reduced-motion | belum dikaji |
| text_expansion | tidak ada uji teks panjang per-lokale | belum dikaji |
| locale_coverage | **`lib/l10n/app_en.arb` + `app_id.arb` + app_localizations.dart ADA** | kekuatan nyata: bahasa pengguna utama (Indonesia) didukung infrastruktur resmi |

## Implikasi ke prioritisasi

1. Lokalisasi EN/ID adalah modal yang jarang disadari — untuk segmen penulis
   Indonesia ini pembeda nyata dan murah dipelihara (jaga parity kedua .arb).
2. Gap a11y terkonsentrasi di screen_reader/scaling/motion. Peluang terpilih
   (OPP-01/02/05/06) tidak memperburuknya, tapi ATURAN MINIMAL berlaku:
   setiap permukaan UI baru wajib tooltip/label semantik (pola 23 file yang
   sudah ada) dan uji layout desktop+narrow — standar sprint sebelumnya.
3. Perbaikan a11y menyeluruh BUKAN peluang v1.2 (tidak ada bukti permintaan
   dari n=1) — dicatat sebagai utang terukur, bukan dianggap nol.
