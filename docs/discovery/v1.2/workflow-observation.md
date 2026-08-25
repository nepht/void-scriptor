# 108.6 — Workflow Observation

> Sprint 108 · direkam 2026-08-25 · kanonik capture fields: goal, steps, tools,
> handoffs, delays, errors, workarounds, outcome
> **Metode & batas jujur:** observasi direkonstruksi dari jejak filesystem &
> metadata DB (mtime, ukuran, hitung baris read-only) atas proyek nyata
> "Test Novel" (`778f5427…voidproject`) — BUKAN shadowing sesi langsung. Isi
> cerita tidak dibuka. Tidak ada instrumentasi in-app sehingga beberapa field
> hanya dapat diisi "tidak teramati".

## Observasi: sesi kerja nyata 22–23 Agustus 2026

| Field | Hasil | Bukti |
|---|---|---|
| goal | memvalidasi alur proyek-novel pada build RC (proyek bernama "Test Novel", dibuat 22 Agu 22:07) | registry `projects.json` createdAt |
| steps | (1) buat proyek → manifest/project.json lahir 22:07; (2) isi struktur naratif → stories/story_chapters/story_scenes masing-masing 1 baris; (3) siklus backup → `backups/` terisi 6 file (terakhir 23 Agu 12:47); (4) sesi lanjutan 23 Agu hingga 20:48 (database/project.db mtime) | mtime direktori + hitung baris DB (mode=ro) |
| tools | sistem proyek + subsistem naratif + backup; SEMUA subsistem lain (characters, environment, timeline, mode/loadout, reference, bible/canon, automation, plugin, AI) NOL baris — tidak pernah dipakai sampai tersimpan | COUNT(*) per tabel, 5/157 terisi |
| handoffs | tidak teramati (tanpa instrumentasi) | — |
| delays | tidak teramati; jeda antar-sentuhan terlihat (22 Agu malam → 23 Agu tengah hari → 23 Agu malam) tapi maknanya tak bisa ditafsirkan tanpa konteks | mtime |
| errors | tidak ada artefak error/crash; lock file `.project.lock`/`session.lock` tertinggal dari sesi terakhir (normal saat tutup) | daftar file proyek |
| workarounds | satu-satunya "workaround" yang terdokumentasi justru di sisi nephthys: analisis pakai forensik mtime karena tidak ada telemetri pemakaian (dipakai ulang di 108.7 F-02) | dokumen ini sendiri |
| outcome | pemakaian sedalam smoke-test: kerangka naratif berdiri, lalu AKTIVITAS BERHENTI TOTAL — tidak ada sesi setelah 23 Agu 20:48, termasuk sejak rilis v1.1.0 25 Agu (konsisten pgrep NO_PROCESS di semua checkpoint watch) | mtime vs timeline rilis |

## Makna untuk pertanyaan charter

- Q2 (nilai fitur v1.1): jawaban awal berbasis bukti — nilai terbukti ada pada
  project system, alur naratif, dan backup; sisanya BELUM TERUJI NILAI.
- Q1/Q5: penghentian pemakaian pasca-sesi uji adalah sinyal retensi terpenting
  yang tersedia; harus masuk Friction Map & Opportunity Registry.
- Batas: satu proyek, satu pengguna, kedalaman smoke — kesimpulan lintas
  pengguna/lintaskarya TIDAK BOLEH ditarik dari sini.
