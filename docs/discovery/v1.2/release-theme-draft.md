# 108.29 — v1.2 Release Theme (DRAFT untuk gate 108.31)

> Status: **DISETUJUI sebagai arah resmi v1.2** — GO oleh Choirudin di
> Direction Approval Gate (108.31), 2026-08-25 ±21:45 WIB.
> Kanonik required_fields: theme, problem, target_users, expected_outcome,
> non_goals, evidence

- **theme**: *"Kembali ke Alur" — memulihkan dan memperdalam jalur naratif
  harian penulis.*
- **problem**: satu-satunya pengguna aktif berhenti total sejak 23 Agu 20:48,
  dan hanya 5 dari 157 subsistem data pernah tersentuh pemakaian nyata — nilai
  produk belum terrealisasi melebihi smoke-test meski kapabilitasnya teruji.
- **target_users**: S1 — penulis-tunggal teknis (terbukti); S2 tetap hipotesis
  dan TIDAK menjadi sasaran utama v1.2 sampai teruji.
- **expected_outcome**: ≥3 hari-menulis aktif per minggu bertahan 4 minggu
  (window 28 hari, metrik 108.24), dengan alur masuk-edit-pertama < 60 detik.
- **non_goals**: bukan menambah subsistem baru; bukan installer/updater; bukan
  telemetri hosting; bukan ekspansi Plugin API; bukan platform baru.
- **evidence**: F-01/F-03 + UN-01/UN-02 (DB read-only 5/157 tabel, timeline
  mtime), watch record 8 checkpoint NO_PROCESS, sizing 108.18, fit 108.19,
  feasibility 108.20–108.23, E-3 terlaksana.

Alternatif yang ditolak beserta alasannya ada di 108.28 (skor OPP lain lebih
rendah pada bukti nilai, bukan pada kemampuan teknis).
