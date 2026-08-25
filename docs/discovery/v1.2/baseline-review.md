# 108.2 — Stable Baseline Review (baseline aktual: v1.1.0)

> Sprint 108 · dievaluasi 2026-08-25 ±20:45 WIB · kanonik inputs:
> release_health, support_backlog, known_issues, performance_baseline,
> security_posture, compatibility_matrix
> **Deviasi tercatat:** kanonik menyebut "kondisi v1.1.1"; keputusan arsitek opsi A
> membuat rilis `1.1.1` tidak ada — baseline yang dinilai adalah `1.1.0` stable.

## 1. release_health — SEHAT

Rilis 2026-08-25 13:52 WIB via metadata promotion (`promote_exact_tested_artifact`);
biner rc-1 @`696a667`, SHA256 `e87e6580…788d44c`. Watch pasca-rilis berjalan:
7 checkpoint + 1 catatan verifikator, **nol insiden terverifikasi**; integritas
biner re-verified berkala (terakhir 20:29 WIB). Suite penuh **+1713 All tests
passed!** saat rilis (`vs_full_suite_105.log`), regresi terfokus **+41 hijau**
@HEAD 19:04 WIB. Portable ZIP lolos uji end-to-end (ekstraksi → checksum →
signature Verified OK → eksekusi proses hidup). Auto-close window ≥24 jam
dijadwalkan 2026-08-26 ±13:57 WIB. Catatan: verifikasi visual GUI tetap DEFERRED
(render WSLg hitam tanpa GPU — batas lingkungan, bukan cacat aplikasi).

## 2. support_backlog — VAKUM YANG JUJUR

Tidak ada kanal distribusi publik maupun telemetry (KI-03/KI-04), sehingga belum
ada laporan pengguna masuk — ketiadaan laporan BUKAN bukti tidak ada masalah.
Backlog nyata yang terbuka berasal dari register internal:

| Item | Sifat |
|---|---|
| KI-03 | validasi platform Windows/macOS/Web/Mobile belum dieksekusi |
| KI-04 sisa | installer MSI/deb (clean-install/upgrade/repair/uninstall) + updater |
| Telemetry (KI-05 lama) | butuh hosting; observabilitas produksi nol |

Kanal support lokal = `v1.1.0-troubleshooting.md` + register known-issues.

## 3. known_issues — 2 CLOSED, 1 OPEN, 1 PARTIAL

KI-01 (signing RSA-3072 detached) CLOSED; KI-02 (SBOM CycloneDX 125 komponen)
CLOSED; KI-03 OPEN; KI-04 PARTIAL (portable ZIP mengisi sebagian).
**Temuan review:** `v1.1.0-stable-manifest.md` masih menulis
`Signature: NOT AVAILABLE (KI-01)` dan `SBOM: NOT AVAILABLE (KI-02)` — kedua
kolom itu STALE, karena hardening offline terjadi SETELAH manifest digenerate.
Manifest rilis tidak disentuh diam-diam (rekaman rilis); koreksi faktual ini
dicatat sebagai kandidat aksi dokumentasi untuk Opportunity Registry (108.17).

## 4. performance_baseline — PUSAT SEHAT, TANPA REGRESI TERUKUR

`test/core/performance` **+58 All tests passed** (`~/vs_perf_107.log`):
FTS5 search 20k dokumen tetap interaktif; startup metrics berfase;
pagination/lazy-loading/image-prefetch terkontrak; benchmark dataset
deterministik (dev-only profile). Belum ada profil pemakaian dunia-nyata
jangka panjang (single-user lokal saja) — dicatat sebagai keterbatasan.

## 5. security_posture — DASAR AKTIF, GAP TERDEFINISI

Aktif: detached signature (self-signed, trust-on-first-use via fingerprint —
tanpa RFC3161 timestamping); SBOM pub-dependencies (komponen native GTK/dsb.
belum terinventarisasi); review keamanan/privasi S107 bersih (nol secret,
nol jalur keluar baru, fakta automation identifiers-only).
Gap struktural: tidak ada telemetry = juga berarti tidak ada sinyal keamanan
produksi; update mechanism belum ada (KI-04) sehingga jalur patch keamanan
belum teruji end-to-end.

## 6. compatibility_matrix — TERKONTRAK DAN DIKUNCI TEST

C1 project format major 1 / schema 16, versi tak-dikenal ditolak aman;
C2 DB schema v56, migrasi 53→56 ter-guard, rollback = restore byte-for-byte
(tanpa downgrade in-place); C3 Plugin API major 1 beku — terverifikasi di kode
(`plugin_host.dart`: `hostApiVersion = PluginApiVersion(1, 0)`; regresi batch-2
mengunci penolakan major≠1); C4 workflow/automation schemas generasi 1;
C5 platform tervalidasi hanya Linux x64 (KI-03).

## Implikasi untuk pertanyaan discovery (charter Q1–Q5)

- **Q2/Q4:** satu-satunya platform teruji adalah Linux x64; klaim lintas platform
  harus diperlakukan sebagai hipotesis, bukan aset.
- **Q3:** tanpa LLM lokal (RX 590) dan tanpa telemetry, arah AI harus dinilai dari
  biaya/privasi/latency provider remote vs kemampuan lokal non-LLM.
- **Q5:** gap terbesar yang terukur hari ini = KI-03 (platform), KI-04 sisa
  (distribusi/updater), telemetry — semuanya infrastruktural, bukan fitur cerita;
  discovery harus menguji apakah itu benar-benar bernilai bagi pengguna tunggal
  saat ini sebelum diprioritaskan.
- Batas metode: semua penilaian bertumpu pada bukti lokal single-user; setiap
  langkah lanjutan wajib menyebut keterbatasan ini alih-alih menggeneralisasi.
