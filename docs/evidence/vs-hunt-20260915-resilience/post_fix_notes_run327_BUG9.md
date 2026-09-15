# Post-fix notes — vs-hunt-20260915-resilience BUG-9 (run327, 2026-09-15)

- Verdict Referee on-disk (otoritas numbering): REAL BUG, Low, Confidence High.
  `project_version_control_service.dart:95-111` — `compare` membandingkan
  nilai JSON hasil decode dengan `!=` dangkal; snapshot dibaca dari file JSON
  terpisah sehingga map/list nested tidak pernah share identity meski isinya
  identik => data nested yang sama dilaporkan `changed` (false diff).
- Mekanisme terverifikasi di HEAD sebelum fix (9b8c353): RED fokus
  mereproduksi persis klaim Referee — `Expected: ['name'] Actual:
  ['name','traits']` (nested map identik ikut masuk `changed`).
- Fix (3793e5c): helper `_jsonEquals` rekursif — Map dibandingkan per key
  (insensitif urutan insert), List per posisi, nilai lain lewat `==` biasa;
  `identical()` short-circuit lebih dulu. Sesuai arah perbaikan Referee
  (structural/recursive equality).
- Konsumen diverifikasi: `CharacterVersionService.compare` delegasi tipis ke
  service ini; satu-satunya test region lama
  (`project_version_control_service_test.dart`) tetap lulus tanpa perubahan
  — kontrak diff skalar tak tersentuh.
- Bukti gate: fokus 2/2 PASS; regresi `flutter test --no-pub
  test/features/project_resilience test/features/character` = 354 PASS /
  1 platform-skip / 0 FAIL exit 0 (~3m35d); `flutter analyze --no-pub`
  No issues found (13,9 s); gate format CI
  `dart format --output=none --set-exit-if-changed` pada 2 file slice exit 0;
  `git diff --check` exit 0; `flutter build windows --debug --no-pub` PASS
  (√ void_scriptor.exe); guard pra- dan pasca-kerja PASS
  recommended_step 145.30, canonical sha 86af6a53.
- Batas jujur: baris diff versi di GUI native tidak direproduksi lewat
  computer-use pada run ini (UNVERIFIABLE, tidak diklaim). Bukti = level
  service/JSON struktural + seluruh region hijau. Tidak ada data pengguna
  disentuh (fixture temporer).
- Konsekuensi status: antrean hunt run320 yang aman-cron HABIS (BUG-8 run323,
  BUG-6 run324, BUG-7 run325, BUG-4 run326, BUG-9 run327). 145.30 tetap
  PARTIAL hardware-bound (power-loss nyata + USB cold-eject butuh tangan
  Choi) — JANGAN fabrikasi slice palsu; JANGAN ulang scan region
  project_resilience (hunt 15 Sep masih hangat).
- Push: TIDAK (keputusan push milik Choi; ahead 17 setelah run ini).
