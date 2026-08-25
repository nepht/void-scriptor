# 108.4 — Assumption Register

> Sprint 108 · disusun 2026-08-25 · kanonik required_fields per entri:
> assumption_id, statement, risk, evidence_needed, test_method, status
> Semua entri lahir OPEN — tidak ada asumsi yang dianggap fakta sebelum ujinya.

| assumption_id | statement | risk | evidence_needed | test_method | status |
|---|---|---|---|---|---|
| A-01 | Pengguna tunggal (Choirudin) merepresentasikan kebutuhan pengguna inti produk | Produk diasah untuk selera satu orang; kebutuhan penulis lain terlewat | Paparan pengguna kedua/ketiga lewat tahap rollout-2 (undangan manual) | Umpan balik terstruktur dari 1–3 penulis eksternal saat kanal distribusi tersedia | OPEN |
| A-02 | Fitur workflow/automation v1.1 benar-benar dipakai dalam penulisan nyata, bukan hanya lolos test | Fitur kaya rekayasa tapi miskin pemakaian (engineering-driven, bukan usage-driven) | Observasi pemakaian pada sesi kerja Void Cube Saga yang sesungguhnya | 108.6 Workflow Observation: catat fitur automation/workflow yang BENAR-BENAR dipanggil selama sesi nyata | OPEN |
| A-03 | AI provider remote memberi nilai dengan biaya/privasi yang dapat diterima | Biaya merayap; naskah belum-publikasi terkirim ke gateway pihak ketiga | Data kualitas/biaya/latency pada prompt nyata + batas policy privasi | Eksperimen berbatas (108.25–27): prompt non-sensitif, bandingkan provider, ukur hasil | OPEN |
| A-04 | KI-03/KI-04 (platform & distribusi) menghambat nilai lebih besar daripada fitur baru apa pun | Investasi infrastruktur yang belum dibutuhkan, atau sebaliknya: blocker sesungguhnya terlewat | Pengalaman pemakaian native Windows/Web oleh pengguna nyata | Spike kecil bertanda prototype: jalankan build/flutter di host Windows utk merasakan gap-nya | OPEN |
| A-05 | Keputusan v1.2 tetap dapat dibuat tanpa telemetry, hanya dari bukti lokal | Blind spot berlanjut ke arsitektur v1.2 | Audit kelengkapan: tiap keputusan gate 108.31 ditanya "bukti apa yang mendukung?" | Checklist eksplisit di 108.31; keputusan tanpa bukti = ditunda/dicatat risiko | OPEN |
| A-06 | Kinerja saat ini cukup untuk skala proyek nyata (Void Cube Saga penuh) | Benchmark synthetic dev-only tidak mewakili bottleneck proyek nyata (aset banyak, timeline panjang) | Benchmark runner dijalankan pada profil data skala-VCS | Seed profil benchmark dgn jumlah record realistis dari outline VCS, jalankan runner eksisting | OPEN |
