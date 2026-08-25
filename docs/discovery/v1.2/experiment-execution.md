# 108.27 — Experiment Execution

> Sprint 108 · dieksekusi 2026-08-25 · kanonik required_outputs per eksperimen:
> method, observations, results, limitations, decision_impact

## E-3 — performance_spike jalur Web (DIEKSEKUSI ✅ otonom)

- **method**: `flutter build web --release` di WSL Ubuntu (toolchain kanonik),
  lalu audit artefak `build/web/` dan sajikan via `python3 -m http.server`
  lokal (127.0.0.1) diuji `curl -I`.
- **observations**: kompilasi lib/main.dart selesai **83,2 detik**;
  `Wasm dry run succeeded`; dua font tree-shaken (lucide 99,7%, MaterialIcons
  98,6%); satu catatan non-fatal: font cupertino_icons tak ditemukan (paket
  direferensikan tapi tak dipakai di assets).
- **results**: **`✓ Built build/web`** — artefak total ±59 MB (termasuk
  canvaskit + assets); `main.dart.js` = 5.062.125 byte; `index.html` 1.514 B.
  Penyajian statis lokal: `index.html` → **HTTP 200 OK**, `main.dart.js` →
  **HTTP 200 OK**.
- **limitations**: ini spike build+sajikan — BUKAN validasi interaksi runtime,
  performa render, atau persistence di browser; klasifikasi Web naik dari
  LIMITED ke **LIMITED-plus (buildable & servable)**, belum PRODUCTION_READY.
- **decision_impact**: OPP-03 turun risikonya (jalur teknis terbukti hidup);
  namun tetap tidak diprioritaskan pada putaran ini (lihat 108.28) karena nilai
  langsungnya bagi S1 masih di bawah OPP-01/02/05.

## E-1 — usability pengguna inti (DIEKSEKUSI ✅ 25 Agu ±21:45 WIB)

method/usaha sudah disiapkan (satu kalimat alasan berhenti + sesi terpandu).
**Hasil**: Choi menjawab langsung — proyek "Test Novel" hanyalah *uji coba*;
tidak ada penulisan nyata yang berhenti. Turunan permintaan arsitek: bersihkan
isi project uji + statistik agar tampilan mulai bersih → dieksekusi 21:50 WIB
(kedua `.voidproject` dihapus, registry dikosongkan valid, 6 laporan crash era
uji dihapus; backup data + app-state terverifikasi SHA-256
`aaf66b86…` / `3f22289d…`). limitations: jawaban verbal satu-kalimat, tanpa
sesi terpandu; decision_impact: F-03 tertutup sebagai non-friksi, tema v1.2
beralih dari "pulihkan retensi" ke "mulai siklus menulis harian pertama".

## E-2 — spike AI remote (BLOKIR — butuh izin privasi + biaya)

Gerbang persetujuan per-konten (108.22-B3) wajib lebih dulu: konten apa,
provider apa, biaya maksimal. Tidak dieksekusi tanpa otorisasi.

## E-4 — prototipe jurnal anti-leakage (DEFERRED)

Menuntut menulis kode baru → melanggar batas mode otonom-aman (tanpa sentuh
`lib/`). Masuk sprint implementasi pasca-gate bila OPP-05 terpilih.

## E-5 — uji distribusi sukarelawan (BLOKIR — butuh orang eksternal)

Paket portable siap; menunggu sukarelawan yang disetujui Choi.
