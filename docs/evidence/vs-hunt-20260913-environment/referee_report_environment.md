# Adversarial Bug Hunt Referee Report: Region `lib/features/environment`
- **Target Repo:** D:\VoidScriptor\void_scriptor_multiplatform
- **Branch:** master | **HEAD scanned:** 902bc57 | **Tanggal:** 2026-09-13 (cron run271)
- **Rantai:** Hunter delegate LULUS (4 temuan, skor 16) -> Skeptic delegate LULUS (3 CONFIRMED / 1 DISPROVED) -> Referee delegate GAGAL HTTP 429 quota (gemini flash-lite) SETELAH membaca seluruh kode (transkrip deleg_7dfa63e5); verdict final = AUDIT INDEPENDEN INDUK (preseden run262/267/270, label PARTIAL jujur).
- **Bukti induk:** baca ulang create_environment_service.dart, environment_repository_impl.dart, environment_model.dart, environment_workspace_screen.dart penuh + grep importers + tabel Drift + DAO.

## Verdict

**ENV-BUG-001 (Hunter Medium, Skeptic DISPROVE) -> NOT A BUG.**
Transaksi DB commit lalu paket folder dengan try/catch delete-rethrow adalah KONVENSI Sprint 14 yang didokumentasikan repo ("create service as a database transaction followed by UUID-based filesystem folders; remove the folder on failure"). Kontrak tidak mensyaratkan rollback baris DB saat pembuatan folder gagal; baris DB tanpa folder tetap berfungsi penuh (workspace/inspector hanya baca DB; folder dipakai pipeline thumbnail/referensi yang punya guard sendiri). Catatan batas (bukan defect): kegagalan folder meninggalkan paket kosong parsial tanpa jalur retry — documented limitation, tidak di-escalate.

**ENV-BUG-002 -> REAL BUG, Medium, confidence 95%.**
`environment_workspace_screen.dart` L167-217: kartu LIGHTING (`'Noon'`,`'Fog','0.0'`), WEATHER (`'Clear'`,`'1.0'`), ZONES (`'No zones yet'`), CONTINUITY (`'Normal'`) adalah `const` stub murni tanpa parameter — padahal create service MEN-SEED profil default nyata ke DB (`EnvironmentWeatherProfiles` preset clear + intensity 1.0 + visibility 1.0 isDefault; `EnvironmentLightingProfiles` timePreset noon + fog 0.0; physics) dan `EnvironmentDao` sudah punya reader `getWeatherProfiles/getLightingProfiles/getZones/getContinuityStates`. Nilai stub kebetulan identik dengan seed default sehingga data palsu terlihat seperti data nyata — pelanggaran kontrak anti-fake-data repo pada permukaan Core Locations (acceptance 145.27). Arah fix: wire kartu ke detail repository-backed melalui provider keluarga (konvensi skill: durable data access di belakang repository), render nilai persisten nyata; state kosong jujur ('—' / 'No zones yet' HANYA saat DB kosong).

**ENV-BUG-003 (Hunter Medium, Skeptic CONFIRMED) -> NOT A BUG (design debt Low).**
K_collision domain `SceneEnvironmentContext` vs Drift generated class memang ada namanya, TAPI grep importers file domain = NOL di lib/ dan test/ — file mati; tidak ada satu pun file yang mengimpor keduanya, jadi tabrakan murni hipotetis. Preseden repo (Sprint 21): collision Drift/domain ditangani dengan alias eksplisit saat dipakai, bukan rename preventif. Item nyata = dead code (file domain tak berkcaller) -> catatan housekeeping, bukan defect pada jalur reachable.

**ENV-BUG-004 -> REAL BUG, Low, confidence 90%.**
`_EnvironmentInfoCard` L157-161 memakai `model?.field ?? '—'` sementara `EnvironmentModel` men-default string `''` (bukan null) dan kolom DB denganDefault(''). Lokasi kosong me-render baris kosong, bukan fallback dash. Arah fix: helper `_orDash` (null ATAU empty -> '—').

**REF tambahan:** header `More environment actions (deferred)` dengan `onPressed: null` adalah marker deferred eksplisit sesuai kontrak deferred-control — bukan defect.

## Tally
- REAL: 2 (ENV-BUG-002 Medium, ENV-BUG-004 Low) — satu boundary file presentation, diperbaiki sebagai satu slice TDD.
- Dismissed: 2 (ENV-BUG-001 documented-design; ENV-BUG-003 hypothetical/dead-code).
- Skeptic akurasi: benar pada 001/002/004; klaim 003 diterima tanpa verifikasi reachability -> dikoreksi induk.
- Fix owner: agen utama (bukan child), sesuai otorisasi 2026-09-07.
