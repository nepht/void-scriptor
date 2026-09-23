# COLLABORATION.md — Void Scriptor

Panduan kerja sama antara agent/assistant dan Choirudin (pemilik produksi).
Sumber kebenaran: `AGENTS.md`, `ARCHITECTURE.md`, `DESIGN-SYSTEM.md`, `roadmap_guard`, `.hermes/ROADMAP_STATE.json`, `docs/sprints/*.md`, `docs/roadmap/*.json`.

---

## 1. Status role

| Peran | Otoritas | Catatan |
|---|---|---|
| **nephthys (agent)** | Implementasi, inspeksi live, verifikasi output, commit scoped, laporan verdad. | Bukan keputusan arsitektur final; push hanya setelah gate hijau & path milik sendiri. |
| **Choirudin (pemilik)** | Keputusan produk, kriteria rilis, model/pointer roadmap, signing CA, distribusi publik, dependabot/security settings. | Segala perubahan policy/model/pointer wajib diverifikasi langsung dari source (repo live, not summary). |

---

## 2. Urutan kerja (workflow) per item

Setiap tugas atau fitur mengikuti urutan wajib ini; lompat langkah = blokir gate dan dilaporkan BLOCKED.

### A. Inspeksi repo live (read-only, *awal*)

1. `git status --short --branch` — siapa yang menulis, apa yang kotor, berapa commit ahead.
2. `git log --oneline -3` — commit terbaru apa, apakah ada WIP concurrent.
3. `dart run tool/roadmap_guard.dart` — canonical/pointer & policy konsisten.
4. Baca `docs/sprints/sprint-*.md` baris terlengkap untuk sprint terkait.
5. `hermes cron list` — status worker, model, schedule.

*Jika langkah 3-5 menunjukkan FAIL/SUSPENDED/PAUSED → hentikan dan laporkan sebelum melanjutkan.*

### B. Pekerjaan (implementation, test, evidence)

1. Tulis kode/modifikasi di path milik sendiri (tidak menyentuh WIP sibling, WIP concurrent, file liar di root).
2. Teskop `RED` minimal, lalu implementasi `GREEN`, lalu `REGRESI wilayah` (test/features/core).
3. `flutter analyze --no-pub` → bersih (tanpa warning baru).
4. `git diff --check` → tidak ada whitespace error.
5. Commit **scoped**: `git add -- <path>` eksplisit; *larangan* `git add -A` ketika ada file tidak terkait.
6. Pesan commit: angka/ status diambil dari output terminal yang baru selesai, bukan dari ingatan.

### C. Verifikasi & push (gate hijau)

1. `git diff --cached --name-only` — hanya path yang disenggara.
2. `flutter test --no-pub <focused>` — gerbang perilaku tersasar.
3. `roadmap_guard` PASS (pointer & policy).
4. Jika **semuanya hijau** → `git push origin master` dan `git push gitlab master`.
5. Jika **ada merah** → hentikan; laporkan BLOCKED dengan evidence detail; jangan push.

*Catatan:* Hosted CI merah sejak 14 Sep 2026 (billing block, 0-step) → gate resmi = suite lokal (langkah C.2). Jika singergin perlu handal Choirudin.

---

## 3. Safety & Anti-Slop Rules (dari `AGENTS.md` + antislop-ui skill)

- **Jangan pernah** menimpa file yang sudah ada tanpa laporan verifikasi (`git diff`, `git status` sebelum & sesudah).
- **Jangan** pakai `git add -A` ketika ada file tidak terkait atau protected.
- **Jangan** mengklaim fitur/sprint selesai hanya karena file/abstraksi/placeholder ada.
- **Jangan** menyimpan atau mempertahankan kredensial, token, API key di file, commit, log, atau laporan. → `[REDACTED]`.
- **Jangan** menciptakan progress file di `.hermes/` (kecuali `docs/SPRINT_PROGRESS.md` yang diotorisasi).
- **Jangan** merubah acceptance criteria untuk membuat progress tampak "complete".
- **Jangan** fabrikan test count, build result, URL, file content, commit, atau respons eksternal.
- **Jangan** paksa pointer roadmap melampaui sprint yang belum tertutup (112.51–112.54 → 113 hanyalah setelah 112.54).
- **Jangan** push tanpa izin eksplisit dari Choirudin *kecuali* standing otorisasi `"Setelah ini commit dan push setelah itu lanjut ke sprint berikutnya jika sudah"` — dalam kasus ini push tetap hanya setelah gate hijau.

---

## 4. Konstitusi path & file

| Kategori | Lokasi kanonik | Catatan |
|---|---|---|
| **Root repo** | `D:\VoidScriptoroid_scriptor_multiplatform` | `git status` di sini selalu. |
| **Docs sprint** | `docs/sprints/*.md` | Setiap sprint punya ledger baris status + kriteria penerimaan. |
| **Roadmap** | `docs/roadmap/ROADMAP_POLICY.json`, `.hermes/ROADMAP_STATE.json`, `docs/planning/v1.2/*.json` | Policy JSON adalah sumber kebenaran stream/guard; SHA pin harus selalu match. |
| **Evidence** | `docs/evidence/sprint-112-39-*.meta`, `docs/planning/v1.2/*.json` | File meta per-test/per-run; bawaan dari output terminal, bukan dibuat. |
| **WIP concurrent** | *TIDAK diadopsi/ditimpa* — `test/release/sprint_112_*`, `macos/Flutter/GeneratedPluginRegistrant.swift`, `lib/features/world_logic/domain/end_to_end_simulation_workflow.dart`, dll. | Jika worker lain sedang menulis → audit dulu; jangan overwrite. |
| **File liar di root** | `NUL`, `analyze_sprints.py`, `check_state.py`, `cron_report.md` — hapus atau ignore saat commit. | Mencegah `git status` kotor. |

---

## 5. Commit & push standar (verbatim dari standing Choirudin)

> *"Setelah ini commit dan push setelah itu lanjut ke sprint berikutnya jika sudah."*

Artinya:
1. Commit bersifat **scoped** (hanya path milik sendiri).
2. Push dilakukan **langsung setelah gate hijau** (flutter test + roadmap_guard + git diff --check).
3. Push **bukan** melompati sprint: 112.51–112.54 harus ditutup dulu sebelum transisi ke 113.
4. Jika worker cron sedang menulis WIP di area sama → commit WIP-nya tidak ikut (scoped hanya path milik task ini).

*Satuan pengecekan sebelum push:*
```
git status --short --branch           # siapa yang menulis, apa yang kotor
dart run tool/roadmap_guard.dart      # pointer & policy konsisten
git diff --cached --name-only         # isi commit
flutter analyze --no-pub              # kesehatan statis
flutter test --no-pub <focused>       # gerbang perilaku
```

Jika **semuanya hijau** → push. Jika ada merah → hentikan; laporkan BLOCKED dengan evidence.

---

## 6. Kolaborasi konkret (peran nephthys)

- **Inspeksi live** sebelum setiap langkah berikutnya — tidak boleh mengandalkan riwayat atau summary.
- **Laporan verdad** per task: VERIFIED-LOCAL, PARTIAL, BLOCKED, DEFERRED dengan path konkret + output tools.
- **Push hanya** setelah gate hijau & standing otorisasi terbaca dari chat ini.
- **Jika blocked** → catat `BLOCKED` dengan alasan konkret + path + command yang gagal, lalu hentikan.
- **Jika deferred** → catat `DEFERRED` dengan alasan (hardware-bound, external gate, CI billing) + pointer tetap.
- **Jika model berubah** → verifikasi via `cron/jobs.json`; Reporter tidak diubah otomatis (no-agent).
- **Jika roadmap pointer bergeser** → baca ulang `ROADMAP_STATE.json` + `ROADMAP_POLICY.json` + ledger baris terkait; jangan angkat asumsi.

---

## 7. Penanganan kondisi khusus

| Kondisi | Aksi nephthys | Catatan |
|---|---|---|
| **Worker cron aktif, menulis WIP** | Audit `git status`; jangan overwrite; catat status; lanjutkan pekerjaan milik sendiri di worktree terisolasi. | Tidak ikut commit WIP lain. |
| **CI merah (billing block)** | Laporkan `steps: 0` + run terakhir hijau; jangan fix sendirian; butuh tangan Choirudin di `github.com/settings/billing`. | Gate resmi = suite lokal. |
| **Roadmap guard FAIL** | Baca `ROADMAP_POLICY.json` + `ROADMAP_STATE.json` + ledger baris yang keliru; patch baris lalu re-run guard; commit policy+state dalam satu scoped commit. | Policy JSON adalah sumber kebenaran multi-stream. |
| **Sprint belum tertutup (112.51–112.54)** | Hentikan transisi ke sprint berikutnya; tetap lanjutkan sprint yang dibutuhkan; jangan push yang melompati. | Guard menolak loncat sprint. |
| **Model Cron berubah** | Verifikasi via `cron/jobs.json`; reporter `no-agent` tetap; job tetap aktif mulai run selanjutnya. | Reporter tidak diubah otomatis. |
| **File duplikat/fixture** | Patch tes (bukan implementasi); guard fail-closed; lalu ulangi RED→GREEN→regression. | Duplicate `locationId` digugurkan, bukan kode. |

---

## 8. Tinjauan & pembaruan

- Dokumen ini *hidup* di `COLLABORATION.md` root repo; setiap perubahan harus melalui commit scoped.
- pembaruan berkala (setiap sprint berakhir atau pointer roadmap bergeser): verifikasi `git status`, `roadmap_guard`, dan `cron list`.
- Korban slip: lapor langsung ke Choirudin dengan evidence detail (command + output + path).

--- 

## 9. Kontak & otorisasi

- **Asisten:** nephthys (implementasi, verifikasi, laporan).
- **Pemilik:** Choirudin (keputusan produk, model, pointer, signing, dependabot/security).
- **Otorisasi push:** `"Setelah ini commit dan push setelah itu lanjut ke sprint berikutnya jika sudah"` → push setelah gate hijau, tidak sebelum.

---

*Dokumen ini ikut versi: `9c3f33f` (commit bersama PRD, DESIGN-SYSTEM, ARCHITECTURE, FAST-THINKING). Setiap perubahan wajib melalui `git add -- <path>` scoped, `git commit -m "..."`, `git push origin master` setelah gate hijau.*
