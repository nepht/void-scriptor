# FAST-THINKING.md — Void Scriptor

Aturan mikro untuk keputusan cepat (System 1) saat mengerjakan Void Scriptor: heuristik satu-baris, red flag, dan syarat berhenti berpikir cepat -> beralih ke kerja lambat (TDD penuh, audit, kontrak).
Dokumen pendamping `AGENTS.md` (kontrak keras) dan `ARCHITECTURE.md` (peta). Saat fast-thinking dan kontrak bertabrakan -> **kontrak menang**.

## 1. Kapan boleh cepat

Heuristik ini sah hanya jika syaratnya terpenuhi:

- **Gerbang sudah hijau sebelumnya dan tidak ada yang berubah di wilayah itu** -> lanjut, jangan re-run paket penuh untuk *feeling* aman. Verifikasi ulang cukup setelah ada mutasi kode.
- **Satu file docs/ledger, satu baris status** -> tulis langsung; asalkan angka diambil dari output yang barusan terbaca, bukan dari ingatan.
- **Commits sebelumnya identik polanya** (message scope, path, ukuran diff) -> ikuti pola itu; jangan buat format baru untuk hal rutin.
- **Guard/skrip sudah ada** -> jalankan, jangan menulis ulang logikanya dengan tangan.
- **Error sudah pernah dilihat di file ini dengan akar sama** -> pakai fix yang sama; lewati diagnosis panjang.

## 2. Red flag — STOP, ini kerja lambat

Sebuah heuristik cepat GAGAL dan wajib turun ke kerja lambat kalau muncul salah satu:

- **Sentuh schema/migrasi, kredensial, keputusan push/merge, atau hapus file** -> tidak ada jalan pintas; kontrak + bukti eksplisit.
- **Dua bukti saling bertentangan** (ledger bilang X, output bilang Y) -> berhenti; percayakan output, rekonsiliasi baris ledger — jangan pilih yang enak.
- **Angka test/commit/URL tidak berasal dari terminal yang baru selesai** -> STOP. Angka dari ingatan = fabrikasi; re-run untuk dapat angka.
- **Worker/cron lain sedang menulis di wilayah yang sama** (`git status` menunjukkan WIP asing) -> audit dulu, jangan overwrite; scope terpisah atau laporkan.
- **Fix kedua kalinya dengan hipotesis yang sama gagal** -> ganti hipotesis/alat, bukan ulang perintah identik.
- **"Selesai" hanya karena file/model/tes ada** -> itu belum bukti; butuh output eksekusi nyata.

## 3. Checklist 10 detik sebelum commit

```text
[ ] staged list = hanya path yang kumiliki (git diff --cached --name-only)
[ ] tidak ada `git add -A`
[ ] angka di pesan commit berasal dari output yang kubaca sendiri
[ ] tidak ada rahasia di diff (key/token = [REDACTED])
[ ] WIP orang lain tidak tersentuh (git status sebelum & sesudah)
```

## 4. Perintah fast-check (repo ini)

```bash
git status --short --branch            # siapa yang menulis, apa yang kotor
dart run tool/roadmap_guard.dart       # pointer & policy konsisten?
git diff --cached --name-only          # isi commit
flutter analyze --no-pub               # kesehatan statis
flutter test --no-pub <focused>        # gerbang perilaku tersasar
```

Order: **status -> guard -> staged -> gerbang fokus**. Jangan lompati; setiap baris menjawab pertanyaan yang berbeda.

## 5. Eskalasi ke kerja lambat (kapan memikirkan penuh)

- Desain domain baru / bentuk interface yang akan dipakai banyak fitur -> tulis kontrak + RED dulu, bukan implementasi lalu tes.
- Audit atau review "apa yang belum beres" -> baca sumber kanonik, bukan ringkasan riwayat.
- Keputusan yang sulit dibalik (hapus data, publikasi eksternal, ganti pin model/pointer roadmap) -> menu keputusan ke Choirudin dengan rekomendasi + bukti.

## 6. Satu kalimat penutup

Cepat untuk mengikuti pola yang sudah terbukti; lambat untuk membentuk pola baru; **berhenti sama sekali** ketika bukti yang dipegang berasal dari ingatan, bukan dari layar.
