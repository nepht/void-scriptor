# PRD — Void Scriptor

**Produk:** Void Scriptor — Flutter creative-universe database studio untuk penulis dan worldbuilder.
**Versi live:** `1.2.0-rc.1` (`pubspec.yaml`).
**Deskripsi resmi (pubspec):** "Multiplatform creative studio for characters, worlds, and stories."
**Otoritas produk:** Choirudin (architect & decision owner). Dokumen ini adalah ringkasan requirement dari bukti repo; sumber kanonik tetap roadmap JSON di `Documents/Codex/.../referenced-chatgpt-conversation-*` + ledger `docs/sprints/`.

## 1. Masalah & tujuan

Penulis serial/fiksi ilmiah-fantasi menyimpan kanon (karakter, dunia, lore, artefak) tersebar di dokumen teks; tidak ada yang menjaga konsistensi silang, tidak ada tooling simulasi/kebetulan untuk menguji dunia, dan tidak ada jalur terstruktur dari kanon → naskah → ekspor.

Void Scriptor menyediakan satu studio berbasis proyek: setiap proyek = satu database SQLite + workspace filesystem, kanon hidup di struktur data yang divalidasi, dan seluruh alur kerja penulis (draft → link → validasi → snapshot → ekspor) berjalan lokal (local-first).

## 2. Pengguna

- **Primary:** penulis novel/web-novel yang membangun dunia panjang (target: Choirudin & pilot reader).
- **Secondary:** worldbuilder/kreator konten yang butuh katalog aset visual (karakter, wardrobe, weapon, environment).
- **Platform target:** Windows desktop (primary), Linux, Web, Android (rehearsal builds), macOS/iOS simulator (CI).

## 3. Requirement inti (Product)

| # | Requirement | Bukti live | Status |
|---|---|---|---|
| P1 | Proyek lokal dengan database & workspace sendiri per proyek | `lib/features/projects`, `lib/database/project/` (Drift, per-project `project.db`) | VERIFIED |
| P2 | Auth local/guest/offline tanpa server wajib | `lib/features/authentication`, `test/app/auth` | VERIFIED |
| P3 | Keluarga aset: Character, Wardrobe, Weapon, Environment, Story/Scene, Timeline | `README.md`, `lib/features/{character,wardrobe,weapon,environment,story,timeline}` | VERIFIED |
| P4 | Selection Engine generik → Workspace/Inspector per tipe aset | `lib/core/selection`, `test/core/selection` | VERIFIED |
| P5 | World Logic: budaya, bahasa, peta, kalender, faksi, makhluk, artefak, lore saling terhubung + simulasi | `lib/features/world_logic` (Sprint 110–111) | VERIFIED-LOCAL |
| P6 | Alur tulis end-to-end: planning → drafting → linking → validasi → snapshot → ekspor spoiler-safe | `EndToEndWriterWorkflow` & family (Sprint 112.32–112.35) | VERIFIED-LOCAL |
| P7 | Ekspor multi-format (DOCX, plain text, web novel) tanpa metadata internal | `lib/features/export` | VERIFIED-LOCAL |
| P8 | Theme/personalisasi: 6 aksen × light/dark, default Void Purple | `lib/design_system/theme/void_theme_variant.dart` | VERIFIED |
| P9 | Local-first: tanpa telemetry wajib, consent eksplisit untuk AI/fitur opsional | `permission_privacy_model.md`, feature flags default OFF | VERIFIED-LOCAL |
| P10 | Resilience: backup dua-fase, corruption detection, rollback/downgrade, crash recovery | Sprint 112.27–112.50 evidence | VERIFIED-LOCAL |

## 4. Non-requirements (explicit scope, Sprint 145 reset)

Ditutup/ditunda agar MVP tetap terukur:

- Cloud sync & kolaborasi multi-pengguna (fitur `collaboration` bertahan sebagai seam, aktivasinya milestone terpisah).
- Public release publication, signing CA publik, installer distribusi — **DEFERRED_EXTERNAL_GATES** (keputusan 112.53/112.54).
- Hosted CI green — runner diblokir billing sejak 14 Sep 2026; gate resmi = suite lokal.
- Native GUI certification, hardware power-loss/USB cold-eject — butuh tangan Choirudin.
- Wave 1–3 capabilities tetap default OFF (`vs12_world_logic_shared` kill switch).

## 5. Kriteria penerimaan rilis (Sprint 112/113)

1. Seluruh 29 fitur unik F1–F29 terpetakan ke evidence executable (`docs/planning/v1.2/*.json`).
2. Suite lokal penuh hijau (benchmark saat 112.39: **5635 PASS, 0 fail**).
3. Analyzer bersih, `git diff --check` bersih, `roadmap_guard PASS`.
4. RC artifact Windows ber-signing lokal + manifest checksum/provenance (112.52).
5. Sprint closure `DEFERRED_EXTERNAL_GATES` tercatat jujur (112.54) — tanpa klaim production-ready.
6. Sprint 113 (GA) tetap mensyaratkan gate eksternal yang masih tertunda.

## 6. Posisi saat ini (23 Sep 2026)

- Sprint 112 **ditutup** (VERIFIED-LOCAL), Sprint 113 (GA release validation) berjalan, frontier `113.30`.
- Development-ready & integration-ready: **ya** (suite lokal + build).
- Production-ready: **belum** — lihat §5 butir 4–6.

## 7. Risiko terbuka

- Hosted CI merah karena billing (known-issue, job 0-step); akun owner harus clear.
- Signing sertifikat lokal CurrentUser tanpa timestamp — tidak sah untuk distribusi publik.
- Worktree shared dengan cron v4 — kontribusi wajib mengikuti `AGENTS.md` (scoped commit, TDD, evidence).
