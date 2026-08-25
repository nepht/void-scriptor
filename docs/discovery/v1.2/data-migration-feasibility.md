# 108.21 — Data & Migration Feasibility

> Sprint 108 · disusun 2026-08-25 · kanonik required_outputs:
> data_changes, migration_risk, rollback_limits, compatibility_impact

## data_changes

| peluang | perubahan data |
|---|---|
| OPP-01 | nol — percakapan + observasi ulang |
| OPP-02 | nol skema — pemakaian tabel naratif existing lebih intensif |
| OPP-03 | nol — artefak build/profil saja |
| OPP-04 | nol — paket portable existing |
| OPP-05 | file BARU di luar project.db (JSONL per mesin, opt-in) — desainnya anti-migrasi |
| OPP-06 | baris BARU di `ai_generation_jobs` (tabel existing, kini 0 baris) — nol skema baru |

## migration_risk

**RENDAH dan dapat dibuat NOL untuk cakupan v1.2 ini**: tidak ada peluang
yang menuntut schema v57. DB v56 beku sejak rilis; jejak migrasi era-v1.0.x
tersimulasi di suite; pola pre-migration backup sudah ada
(`references/project-resilience-hardening.md`).

## rollback_limits

- Migrasi+rollback terbukti **byte-for-byte** saat RC (105.10–105.11) — batas
  mekanismenya teruji untuk skenario skema.
- OPP-05/OPP-06 punya rollback trivial: hapus file jurnal / hapus baris job;
  keduanya additive, tak pernah menyentuh data naratif pengguna.
- Batas jujur: backup harian hanya di D:\ (mesin tunggal) — disaster recovery
  lintas-mesin belum ada dan BUKAN bagian peluang manapun (tercatat terbuka).

## compatibility_impact

Kontrak C1–C5 dijaga: tidak ada peluang yang mengubah kontrak publik,
Plugin API, format `.voidproject`, atau semantik lock/session. Regresi
kontrak tetap gerbang wajib tiap implementasi pasca-discovery.
