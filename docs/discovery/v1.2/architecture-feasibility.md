# 108.20 — Architecture Feasibility

> Sprint 108 · disusun 2026-08-25 · kanonik review_scope:
> modules, runtime, persistence, events, plugins, workflow, platforms
> Peta live: 24 modul `lib/core/` + 46 fitur `lib/features/`; Riverpod +
> GoRouter; Drift project.db v56; repository-layer di depan DB.

## Penilaian per scope

- **modules**: OPP-02 menyentuh modul naratif yang SUDAH ADA
  (`features/story`, `timeline`, `cinema`) — fokus & poles, tanpa modul baru.
  OPP-05 butuh SATU titik instrumentasi di bootstrap/session (pola sudah ada:
  crash_diagnostics). Tidak ada OPP yang menuntut modul core baru.
- **runtime**: semua peluang berjalan di runtime desktop terbukti; OPP-03
  menuntut runtime Web divalidasi (bukan perubahan arsitektur).
- **persistence**: OPP-05 sengaja FILE-based (jurnal JSONL per mesin) agar
  NOL migrasi skema; OPP-06 memakai tabel `ai_generation_jobs` yang SUDAH ada
  (0 baris). DB v56 bisa tetap beku sepanjang v1.2 discovery-scope ini.
- **events**: OPP-05 dapat mengambil event bus yang sudah ada (pola bridge
  104.8); tanpa topologi event baru.
- **plugins**: Plugin API v1 TIDAK disentuh oleh peluang mana pun — konsisten
  dengan verdikt 108.13 (pelihara, jangan ganggu).
- **workflow**: subsistem automation/approval tidak diubah oleh peluang utama;
  OPP-01/02 justru memberi dia kesempatan pertama dipakai nyata.
- **platforms**: OPP-03 = validasi target yang sudah di-scaffold; tidak ada
  porting arsitektural baru.

## Verdikt

**Semua enam peluang feasible tanpa merusak boundary/ownership.**
Tidak ada yang melintasi batas layer (UI→repository→DB), tidak ada yang
menuntut migrasi skema, dan tidak ada yang mengambil kepemilikan modul agen
lain. Risiko arsitektur terbesar bukan pada peluang, melainkan pada godaan
menambah modul baru sebelum OPP-01 terjawab — disiplin fokus OPP-02 adalah
penangkalnya.
