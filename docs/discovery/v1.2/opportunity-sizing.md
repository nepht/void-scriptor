# 108.18 — Opportunity Sizing

> Sprint 108 · disusun 2026-08-25 · kanonik dimensions:
> reach, frequency, impact, confidence, effort, risk
> Skala dinilai pada populasi NYATA saat ini: 1 pengguna terbukti (S1);
> S2 masih hipotesis. Menilai "reach besar" sekarang berarti mendustakan data.

| peluang | reach | frequency | impact | confidence | effort | risk |
|---|---|---|---|---|---|---|
| OPP-01 retensi pengguna inti | 1 pengguna (seluruh populasi) | harian bila berhasil | tinggi — tanpa ini tak ada produk | penyebab belum diketahui | sangat kecil (jawaban Choi) / kecil (perbaikan) | rendah |
| OPP-02 fokus jalur naratif | 1 nyata + basis calon S2 | tiap sesi menulis | tinggi — alur satu-satunya yang terbukti bernilai | tinggi | sedang (fokus, bukan fitur baru) | sedang — risiko mengabaikan subsistem lain harus disadari |
| OPP-03 validasi Web | 1 nyata; membuka akses non-WSL | sekali validasi + tiap rilis | sedang — klaim platform kedua jujur | sedang | sedang (profil performa + siklus penuh) | sedang — performa Web belum diprofil |
| OPP-04 uji distribusi eksternal | 1–n sukarelawan | sekali uji | sedang-tinggi — menguji hipotesis S2 | sedang-rendah | kecil-sedang (manual, tanpa installer) | sedang — ketergantungan orang luar |
| OPP-05 jurnal pemakaian lokal | 1 nyata | tiap sesi | sedang — akhirkan kebutaan keputusan | sedang | kecil (log lokal opt-in, tanpa server) | rendah — wajib bebas konten cerita |
| OPP-06 eksperimen AI remote | 1 nyata | eksperimen sekali | sedang — buka nilai AI atau tutup pertanyaannya dengan bukti | sedang | kecil (satu prompt end-to-end) | biaya token keluar kantong + privasi konten |

## Bacaan sizing yang jujur

Dengan populasi n=1, semua "reach" adalah mikro secara definisi — nilai
peluang di sini adalah **membeli kepastian arah**, bukan skala pasar.
OPP-01 mendominasi: usahanya paling murah dan membuka makna hampir semua
temuan lain (F-03, UN-01, A-register). Urutan kasar berdasarkan
impact-per-effort: OPP-01 → OPP-02 → OPP-05 → OPP-06 → OPP-03 → OPP-04.
