# 108.26 — Prototype Boundaries

> Sprint 108 · disusun 2026-08-25 · kanonik requirements:
> production_data_allowed=false, default_feature_flag=OFF,
> security_limits_documented=true, disposable=true

Aturan ini mengikat SEMUA eksperimen E-1…E-5 dan prototipe apa pun pasca-gate.

## B1 — Data produksi tidak menyentuh kode prototipe

- Prototipe (mis. jurnal E-4) HANYA dijalankan pada salinan proyek atau fixture
  sintetis di direktori temp — TIDAK PERNAH pada `~/VoidScriptor` langsung.
- Pengecualian tegas: sesi usability (E-1) pada BINER RILIS v1.1.0 bukan
  prototipe — biner rilis adalah artefak produksi yang telah melewati gerbang;
  data nyata sah dipakai di sana karena tak ada kode baru yang berjalan.
- Sesi E-1 tetap mencatat temuan, bukan isi cerita (etika discovery sama).

## B2 — Feature flag default OFF

Setiap prototipe berflag (`vs_experimental_journal`, dst.) lahir OFF; tidak ada
jalur UI yang menyalakannya secara default; ON hanya via settings eksplisit.

## B3 — Batas keamanan terdokumentasi per eksperimen

- E-2: daftar persis data yang keluar (potongan prompt final ditampilkan lebih
  dulu), provider tujuan, estimasi biaya maksimal — ditulis SEBELUM eksekusi;
  API key via env/config milik pengguna, tidak pernah masuk repo/db/log.
- E-4: whitelist field jurnal tertutup; test anti-leakage wajib ada SEBELUM
  prototipe dianggap berhasil.
- E-3: tanpa network egress selain melayani file statis lokal.

## B4 — Sekali pakai

Prototipe tinggal di branch/workdir terpisah dan BOLEH dibuang total; tidak ada
prototipe yang di-commit ke `lib/` tanpa melewati gerbang TDD penuh (RED→GREEN
→analyze→suite). Kegagalan eksperimen adalah HASIL yang sah — dicatat, bukan
dipaksa jadi fitur.

## Konsekuensi pelanggaran

Pelanggaran salah satu B1–B4 membatalkan status eksperimen: hasilnya TIDAK
boleh dikutip di gate 108.31.
