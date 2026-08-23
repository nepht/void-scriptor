# Hotfix Runbook v1.0.1 — Void Scriptor

Sprint 101 — Post-Release Stabilization & Hotfix.
Kontrak induk: `docs/audits/release-contract-v1.md`. Sumber langkah:
`sprint_101.json` (arsip resmi). Otoritas rilis tetap D6: hanya Choirudin
yang membuat tag atau menaikkan nomor versi.

## Alur laporan (101.4)

Satu pintu masuk: GitHub Issues dengan template:

| Template | Dipakai untuk | Langkah |
|---|---|---|
| Bug Report | perilaku salah umum | 101.4, 101.6 |
| Crash Report | aplikasi berhenti/error fatal | 101.4, 101.6, 101.8 |

Input lain (diagnostic bundle, installation/data-integrity issue) dilaporkan
lewat Bug Report dengan label sesuai. Laporan tanpa data reproduksi tetap
diterima, tetapi tidak naik status sampai 101.6 lengkap.

## Klasifikasi severity (101.5, 101.7)

| Level | Definisi | Contoh |
|---|---|---|
| P0 | kehilangan/rusaknya data proyek pengguna, atau app tak bisa dibuka sama sekali | save gagal senyap; DB korup saat upgrade |
| P1 | alur inti terblokir tanpa workaround | tidak bisa membuat scene; import novel gagal selalu |
| P2 | alur inti terganggu tapi ada workaround | UI overflow pada lebar tertentu |
| P3 | kosmetik/minor | teks terpotong, typo |

**Data-Loss Gate**: setiap isu dengan risiko kehilangan/rusaknya data
default P0 dan merupakan *release blocker* — patch v1.0.1 tidak boleh rilis
selama ada P0 terbuka (lihat 101.26 DoD).

## Rekaman reproduksi (101.6)

Template issue meminta semua field wajib: `issue_id` (otomatis dari issue
number), versi (`version`), build id, platform, arsitektur, langkah
reproduksi, hasil diharapkan, hasil aktual, log, lampiran, severity usulan.
Field log/lampiran opsional di form tetapi wajib lengkap sebelum fix mulai.

## Analisis crash (101.8)

Crash runtime otomatis tertangkap oleh bootstrap diagnostics
(`lib/app/bootstrap/crash_diagnostics.dart`, Sprint 101.3/101.9):
satu berkas JSON per kejadian di `<support>/VoidScriptor/diagnostics/crash/`
dengan `signature` (tipe error + baris pertama pesan) sebagai kunci grup.
Triage mengelompokkan berdasar signature, lalu affected version, platform,
frekuensi, workflow terdampak, komponen tersangka.

## Recovery startup (101.9)

Kegagalan boot berturut-turut die skalasi oleh
`StartupRecoveryPolicy`: normal → safe (kegagalan ke-2) → recovery
(kegagalan ke-3+), dengan saran diagnostic mode sejak kegagalan ke-4.
Streak dibersihkan ketika frame pertama berhasil ter-render
(`recordHealthyShutdown`). Reset konfigurasi menghapus state
(`state/startup.json`).

## Review keamanan & privasi tiap hotfix (101.16, 101.17)

Checklist wajib sebelum merge patch:

- [ ] Validasi input & path tidak melemah (path traversal, injeksi nama file)
- [ ] Tidak ada secret baru di kode/konfig/log
- [ ] Perubahan plugin permission tidak memperluas akses
- [ ] Verifikasi update/artefak tetap hash-terkunci
- [ ] Perilaku lokal-saja tidak berubah (tidak ada transfer cloud baru)
- [ ] Redaksi diagnostic bundle tetap menyaring konten cerita

## Regresi otomatis per fix (101.20)

Aturan: **satu bug fix = satu test regresi** di commit yang sama
(test-first bila memungkinkan). CI (`analyze` + `test`) menegakkan hijau;
PR tanpa test regresi untuk fix P0/P1 ditolak kecuali fix-nya murni dokumen.

## Scope lock hotfix (101.21)

Boleh: bug fix, security fix, data-integrity fix, perf-regression fix,
koreksi dokumentasi.
Terlarang: fitur mayor, breaking API, redesign format proyek/database,
redesign UI besar. Ragu → diskusi dulu, bukan commit dulu.

## Promosi versi (101.22–101.25) — otoritas D6

Draft urutan (eksekusi hanya oleh Choirudin):

1. `release/1.0` dibuat dari master pada SHA stabil; `hotfix/1.0.1` bekerja
   di atasnya (101.1).
2. Bump `pubspec.yaml` + `VoidProjectFormat.applicationVersion` bersamaan
   (dijaga `test/version_single_source_test.dart`).
3. RC: tag `v1.0.1-rc.1` → jalankan gate final (101.23): regression,
   install/upgrade/rollback/recovery tests, security checks, artifact
   verification. Saat ini install/update/rollback produksi eksplisit DI LUAR
   v1 (release-contract-v1.md); gate tersebut dijalankan sebatas yang
   tersedia dan sisanya dicatat BLOCKED/DEFERRED — jangan direkayasa diam-diam.
4. Artifact lock (101.24): catat build id, commit, checksum, manifest di
   evidence release.
5. Patch release (101.25): tag `v1.0.1` + release notes + known issues.

## Definition of Done sprint (101.26)

Sprint 101 boleh ditutup hanya jika semua terbukti: no open P0; P1 blocking
selesai; upgrade path teruji (atau DEFERRED eksplisit karena installer di
luar v1); kompatibilitas proyek terverifikasi; recovery/rollback lulus;
artefak final terverifikasi; release notes + known issues tersedia.
