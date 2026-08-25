# 108.8 — Unmet-Need Map

> Sprint 108 · disusun 2026-08-25 · kanonik requirements:
> `problem_before_solution: true`, `evidence_required: true`
> Aturan entri: rumusan MASALAH saja (tanpa solusi), tiap entri wajib bawa bukti.
> Keinginan tanpa bukti (mis. "tambah fitur X") sengaja TIDAK didaftarkan.

| id | Masalah (sebelum solusi) | Bukti | Status kebutuhan |
|---|---|---|---|
| UN-01 | Pengguna tunggal belum menunjukkan pemakaian berkelanjutan — nilai harian produk belum terbukti bagi dirinya sendiri | aktivitas "Test Novel" berhenti 23 Agu 20:48; nol sesi sejak itu (mtime + pgrep watch) | TERBUKA — **diperbarui E-1 25 Agu**: aktivitas itu ternyata uji coba; belum ada percobaan menulis harian sungguhan untuk gagal/b |
| UN-02 | 152 dari 157 subsistem data tidak pernah tersentuh pemakaian nyata; tak diketahui apakah itu kebutuhan tak terpenuhi, kesadaran/onboarding, atau memang tak relevan | COUNT(*) DB "Test Novel": stories/chapters/scenes/assets/metadata saja | TERBUKA — butuh pemetaan penyebab |
| UN-03 | Produk hanya dapat dijalankan dalam WSL Linux x64; OS tujuan resmi lain belum punya jalur pakai nyata | KI-03; kontrak C5; nol jejak eksekusi native lain | TERBUKA |
| UN-04 | Keputusan arah produk dibuat tanpa sinyal pemakaian apa pun (buta pemakaian) | kebutuhan forensik mtime untuk seluruh observasi 108.6; KI-03/KI-04 | TERBUKA |
| UN-05 | Tidak ada jalur menjangkau penulis kedua (distribusi & instalasi end-user belum lengkap), sehingga hipotesis segmen S2 tak bisa diuji | KI-04 PARTIAL (portable ZIP saja); A-01 masih OPEN | TERBUKA |
| UN-06 | Stabilitas jangka panjang pada beban karya nyata (VCS penuh: ratusan karakter, timeline panjang, aset banyak) belum pernah diukur | benchmark profil dev-only; proyek nyata terbesar = 1 story/1 chapter/1 scene | TERBUKA — uji via A-06 |

## Yang sengaja TIDAK didaftarkan

- Kebutuhan AI/LLM: charter Q3 tetap pertanyaan, bukan kebutuhan terverifikasi;
  akan dinilai di langkah 108.14 dengan eksperimen 108.25–27 bila layak.
- Fitur kolaborasi/plugin marketplace/dll.: nol bukti permintaan; masuk kandidat
  evaluasi strategis (108.13) sebagai pertanyaan, bukan kebutuhan.

## Kaitan

UN-01/UN-02 adalah inti Friction F-01/F-03; UN-03↔F-04; UN-04↔F-02; UN-05
menutup rantai ke A-01. Registry peluang (108.17) hanya boleh mengubah entri
TERBUKA ini menjadi peluang SETELAH penyebabnya dipahami (108.9–108.11, 108.15).
