# Risk Register v1.2 Discovery (paket gate 108.31)

> Konsolidasi seluruh risiko yang tersebar di dokumen discovery
> (sizing, fit, feasibility×3, boundaries, execution). Kanonik gate
> `required_evidence` memuat `risk_register` — inilah jawabannya.
> Disusun 2026-08-25 · status tiap risiko dinilai SEBELUM eksekusi v1.2.

| id | risiko | L | I | mitigasi / perlakuan |
|---|---|---|---|---|
| R-01 | Penyebab berhentinya pemakaian ternyata hambatan produk yang tak teramati → tema "Kembali ke Alur" meleset sasaran | sedang | tinggi | E-1 wajib lebih dulu (M1); tema direvisi bila jawabannya di luar alur |
| R-02 | Fokus naratif (OPP-02) mengabaikan subsistem lain yang kelak dibutuhkan | sedang | sedang | subsistem non-fokus tetap dijaga regresi penuh; WON'T eksplisit, bisa dibuka ulang lewat bukti baru |
| R-03 | Jurnal lokal (OPP-05) bocor konten cerita | rendah | tinggi | whitelist field tertutup + test anti-leakage + flag default OFF (guardrail g1, batas B3) |
| R-04 | Eksperimen AI remote mengeksfiltrasi naskah / biaya membengkak | sedang | tinggi | gerbang persetujuan per-konten, prompt ditampilkan dulu, cap biaya tertulis (B3); tanpa otorisasi tidak jalan |
| R-05 | Uji sukarelawan (E-5) gagal instalasi → sinyal palsu atas S2 | sedang | rendah | paket portable teruji + VERIFY-SIGNATURE.sh + INSTALL.txt; kegagalan dicatat sebagai HASIL sah |
| R-06 | Build Web sukses dicap "platform didukung" sebelum runtime tervalidasi | sedang | sedang | status dibekukan LIMITED-plus ("buildable & servable"); W4 melarang klaim baru |
| R-07 | Keputusan gate diambil sebelum window watch v1.1.0 auto-close (26 Agu 13:57 WIB) | rendah | sedang | watch bersih 8 checkpoint; bila insiden muncul sebelum auto-close, gate ditunda dan tema ditinjau |
| R-08 | Ketergantungan mesin tunggal: backup hanya D:, DR lintas-mesin nihil | tinggi(sebagai kondisi) | tinggi(bila gagal disk) | DI LUAR scope v1.2 (jujur tercatat); disiplin backup harian existing dilanjutkan |
| R-09 | Populasi n=1 membuat setiap generalisasi rapuh | pasti | sedang | semua klaim dibatasi populasi nyata; S2 tetap hipotesis sampai E-5 |

Prinsip pakai di gate: risiko dengan mitigasi terpasang boleh dilewati
GO_WITH_DOCUMENTED_RISK; R-01 adalah satu-satunya yang menuntut AKSI SEBELUM
implementasi (jawaban E-1), bukan sekadar dokumentasi.
