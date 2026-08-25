# Discovery Charter — VOID SCRIPTOR v1.2

> Langkah **108.1** Sprint 108 · dibuka 2026-08-25 · kanonik: `sprint_108.json`
> (required_fields: decision, questions, scope, non_goals, owners, deadline)

## Decision (keputusan yang harus dihasilkan)

Satu tema rilis **v1.2** berbasis bukti, beserta scope Must/Should/Could/Won't,
disetujui Choirudin melalui **Direction Approval Gate (langkah 108.31)**. Jika
bukti belum cukup untuk memilih tema, keputusan sah yang dihasilkan adalah
**penundaan yang didokumentasikan** (lihat 108.32).

## Questions (pertanyaan discovery)

1. Q1 — Friction: bagian mana dari workflow penulisan/pembangunan universe
   (pengguna utama saat ini: Choirudin sendiri sebagai first user) yang paling
   sering menghambat pekerjaan nyata, dengan dampak yang bisa dinilai?
2. Q2 — Nilai fitur v1.1: fitur workflow/automation/plugin/AI mana yang terbukti
   dipakai dan berhasil, dan mana yang belum memberi nilai terukur?
3. Q3 — Arah AI & compute: strategi AI apa yang realistis untuk hardware lokal
   (AMD RX 590 GME 8GB — tanpa LLM lokal; lihat keputusan 25 Agu) versus
   provider remote, ditinjau dari biaya, privasi, kualitas, latency?
4. Q4 — Platform: platform mana (Linux/Windows/Web/Mobile) yang paling memengaruhi
   nilai produk berikutnya, dengan bukti dari pengalaman pemakaian nyata?
5. Q5 — Peluang vs biaya: peluang perbaikan mana yang memberi nilai terbesar per
   risiko/biaya, dan mana yang harus ditunda (non-goal v1.2)?

## Scope (cakupan discovery)

- Seluruh permukaan produk yang sudah ada di `1.1.0` stable: editor, story bible,
  timeline/cinematic, environment, plugin SDK v1, AI provider architecture,
  automation/workflow engine, persistence & project package.
- Sumber bukti lokal yang benar-benar ada: rekaman watch rilis (checkpoint),
  `docs/release/v1.1.0-known-issues.md`, suite regresi (+1713/+58/+41), catatan
  arsitektur, observasi workflow Choirudin, keputusan arsitek terdokumentasi.
- Eksperimen kecil diperbolehkan HANYA sesuai batas langkah 108.25–108.26
  (prototype ≠ implementasi produksi).

## Non-goals (di luar cakupan sprint ini)

- Tidak ada implementasi fitur produksi, tanpa perubahan `lib/`, tanpa bump versi.
- Bukan redesign UI menyeluruh dan bukan janji penutupan KI-03 (telemetry) /
  KI-04 (installer/updater distribusi publik) — keduanya tetap carry-over terbuka.
- Tidak mengklaim data pemakaian publik: belum ada telemetry maupun kanal
  distribusi publik, sehingga discovery bersandar pada bukti lokal dan dinyatakan
  demikian di tiap langkah.

## Owners

- **nephthys** — eksekusi investigasi, dokumentasi per langkah, bukti & ledger.
- **Choirudin** — otoritas keputusan: gate 108.31 (persetujuan arah v1.2) dan
  segala penyimpangan dari charter ini.

## Deadline

Draft lengkap langkah 108.2–108.30 ditargetkan selesai **2026-08-29** (±3,5 hari
kalender kerja otonom-aman). Gate 108.31 dijalankan kapan pun Choirudin siap;
sprint tidak menyatakan selesai sebelum keputusannya terekam.
