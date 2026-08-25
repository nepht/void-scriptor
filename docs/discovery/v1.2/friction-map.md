# 108.7 — Friction Map

> Sprint 108 · disusun 2026-08-25 · kanonik required_fields per entri:
> friction_id, workflow, frequency, severity, affected_users,
> current_workaround, evidence
> Skala severity: rendah/sedang/tinggi — dinilai dari dampak terhadap alur kerja
> nyata segmen S1 (satu-satunya segmen berbukti). Semua entri WAJIB punya bukti;
> dugaan tanpa bukti tidak boleh masuk peta ini.

| friction_id | workflow | frequency | severity | affected_users | current_workaround | evidence |
|---|---|---|---|---|---|---|
| F-01 | adopsi subsistem di luar alur naratif inti | setiap sesi pemakaian nyata sejauh ada (2/2 proyek hanya menyentuh ≤5 tabel) | sedang→tinggi (nilai produk tidak terrealisasi melebihi smoke-test) | S1 | tidak ada — subsistem sekadar tidak dipakai | hitung baris DB "Test Novel": 5/157 tabel terisi; proyek "jj": 0 aktivitas pasca-pembuatan |
| F-02 | evaluasi & pengambilan keputusan produk oleh arsitek/nephthys | setiap siklus discovery/watch | sedang | S1 (peran ganda sbg pembangun) | forensik mtime/filesystem manual seperti di 108.6 | ketiadaan telemetri (KI-03/KI-04); dokumen workflow-observation.md |
| F-03 | retensi pemakaian harian | 1 kejadian (n=1): aktivitas berhenti total setelah 23 Agu 20:48, termasuk sepanjang watch rilis | tinggi bila polanya berulang; belum dapat digeneralisasi | S1 | tidak ada | timeline mtime vs rilis 25 Agu 13:52; pgrep NO_PROCESS di semua checkpoint |
| F-04 | menjalankan aplikasi di OS sehari-hari (Windows host) tanpa lapisan WSL | setiap kali native diinginkan (tidak pernah terjadi — inferensi, bukan keluhan) | sedang (inferensi) | S1 | menjalankan dari WSL | KI-03; nol jejak sesi aplikasi native Windows di mesin ber-Windows |
| F-05 | kepercayaan pada dokumen rilis | sekali (ditemukan saat review 108.2) | rendah | S1 | cek silang ke register known-issues | kolom Signature/SBOM STALE di v1.1.0-stable-manifest.md |

## Catatan jujur

F-03 adalah sinyal terpenting SEKALIGUS paling rapuh: n=1 dan konteksnya
(keputusan sadar menunda vs hambatan nyata) belum diketahui — konfirmasi ke
Choirudin tentang ALUAN berhentinya adalah eksperimen termurah yang membuka
maknanya (masuk rencana 108.25). F-04 ditandai inferensi: tidak ada pernyataan
friksi langsung dari pengguna; ia tetap terdaftar karena KI-03 membuat
kemungkinannya tak terbantahkan.

## RESOLUSI E-1 (2026-08-25 ±21:45 WIB, jawaban langsung Choirudin)

F-03 **TERPECAHKAN — bukan friksi produk**: sesi 22–23 Agu adalah *uji coba*;
tidak ada penulisan harian yang benar-benar berjalan lalu terhenti. Konsekuensi
jujur: bukti pemakaian produktif S1 semakin tipis (satu-satunya "penggunaan
aktif" pun uji coba), dan permintaan turunan arsitek adalah pembersihan data
uji (tereksekusi 21:50 WIB, backup ganda terverifikasi SHA-256). F-03 tetap
bersejarah di tabel di atas; baca bersama resolusi ini.
