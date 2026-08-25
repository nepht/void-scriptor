# 108.9 — Support & Incident Analysis

> Sprint 108 · disusun 2026-08-25 · kanonik group_by:
> workflow, component, severity, frequency, platform, root_cause
> Sumber: register `docs/release/v1.1.0-known-issues.md` (4 entri),
> checkpoint watch (`v1.1.0-watch-checkpoints.md`, 8 titik), dan bukti
> pemakaian nyata. Kanal support eksternal belum ada (KI-04: distribusi
> terbatas) ⇒ populasi insiden = register internal + watch.

## Temuan utama

**NOL insiden produk terverifikasi** sejak rilis v1.1.0 (13:52 WIB, 25 Agu).
Semua entri di bawah adalah gap infrastruktur/proses, bukan cacat aplikasi.

| id | workflow | component | severity | frequency | platform | root_cause |
|---|---|---|---|---|---|---|
| SI-01 | distribusi/validasi | matriks platform | sedang | persisten sejak era v1.0 | Win/macOS/Web/Mobile | tidak ada mesin target untuk validasi lintas platform (KI-03) |
| SI-02 | instalasi end-user | installer/updater | sedang | persisten | semua (kritis di Windows) | builder MSI/deb tidak tersedia di lingkungan (KI-04 sisa gap) |
| SI-03 | monitoring pasca-rilis | telemetri produksi | sedang | permanen sejauh ini | semua | tidak ada hosting untuk endpoint telemetri (warisan KI-05) |
| SI-04 | proses rilis/watch | prosedur verifikasi (bukan produk) | tinggi-sebagai-alarm, nol dampak produk | 1× (25 Agu 19:46 WIB) | WSL Linux | verifikator meng-hash bundel `release/` usang alih-alih anchor debug; ditutup BUKAN insiden, pelajaran tertanam di 3 tempat |
| SI-05 | eksekusi pengujian | lingkungan uji (bukan produk) | rendah | 1× | WSLg | keterbatasan lingkungan (ledger 107.24 PARTIAL); tidak masuk intake insiden |

## Pola root_cause yang bisa dikurangi lewat perubahan produk

1. **Ketergantungan tunggal pada WSL Linux x64** (SI-01+SI-02): satu akar —
   tidak ada jalur pakai native di OS lain; terpetakan ke UN-03/UN-05.
2. **Buta pemakaian** (SI-03): tanpa telemetri, "nol laporan" ≠ bukti aman;
   terpetakan ke UN-04. Proxy filesystem satu-satunya yang tersisa.
3. SI-04/SI-05 bukan pola produk — keduanya proses/lingkungan dan sudah punya
   mitigasi terdokumentasi (catatan verifikator, pelajaran anchor path).
