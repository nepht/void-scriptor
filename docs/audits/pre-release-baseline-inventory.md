# Pre-release baseline inventory (G6)

Tanggal: 2026-08-23 · Sumber: live repo `~/Projects/void_scriptor_multiplatform` @ `4298284`
("Add creature closeout and simulation contracts"). Dokumen ini adalah inventaris
fakta sebagai bahan keputusan; tidak ada butir di sini yang merupakan keputusan.

## 1. Repository & branch

| Fakta | Nilai |
|---|---|
| Branch | `master`, upstream `origin/master` (`github.com/nepht/void-scriptor`) |
| Commit belum ter-push | **92** — CI belum pernah melihat kode pada HEAD saat ini |
| Tag rilis | Tidak ada |
| Worktree | 483 entri berubah (termasuk 13 file baru milik batch G4/G5) |

Implikasi jujur: sampai push dilakukan, semua bukti hijau bersifat lokal saja
(development-ready), bukan integration-ready.

## 2. Versi & metadata

| Fakta | Nilai |
|---|---|
| `pubspec.yaml` | `version: 0.1.0+1` |
| Hardcode kedua | `VoidProjectFormat.applicationVersion = '0.1.0'` (`lib/core/project_package/void_project_format.dart`), dipakai oleh `project_package_service.dart` dan `project_recovery_services.dart` |
| Embed packaging (Windows/Linux resource) | Tidak ditemukan |
| CHANGELOG.md | Keep-a-Changelog 1.1.0, hanya `[Unreleased]` — klaimnya jujur |

Risiko yang harus diputuskan: dua sumber versi bisa saling tertinggal saat naik
versi (belum ada mekanisme sinkron atau pengujian kesamaannya).

## 3. CI & kontrol keamanan

- `.github/workflows/ci.yml` "Multiplatform CI" (ubuntu-latest): verifikasi
  hardening repo, resolve deps + lockfile tak berubah, format, analyze, full
  test, tooling tests, generate SBOM CycloneDX + third-party notices (artefak
  `release-metadata`), build Linux debug, build Web release.
- `.github/workflows/security.yml`: Gitleaks history scan (jadwal mingguan + PR).
- Dependabot (Pub + Actions) terkonfigurasi.
- Bukti run pada SHA saat ini: **tidak ada** (karena 92 commit belum ter-push).

## 4. Aset rilis: ada vs absen

| Aset | Status |
|---|---|
| Installer/packaging Windows (MSIX/Inno) | ABSEN |
| Signing (keystore/key.properties) | ABSEN |
| Update channel / auto-update | ABSEN |
| Rollback procedure terdokumentasi | ABSEN |
| Release checklist | Ada (dirujuk CHANGELOG; lokasi perlu dikonfirmasi saat penyusunan kontrak) |
| `docs/releases/` | KOSONG |

Konsekuensi kontrak: selama aset di atas absen, kontrak `1.0.0` **tidak boleh**
memuat klaim installer/signing/update/rollback — atau butir-butir itu harus
dinyatakan eksplisit di luar cakupan v1.

## 5. Kontrak dorman vs aktif

`lib/features/platform/domain/release_final.dart` (Sprint 50, step 50.116–50.142)
berisi kelas domain Beta/Metrics/Safety/ReleasePlan/PatchBranch — murni data +
logika murni, teruji (`release_final_test.dart`), **tidak dipanggil runtime mana
pun**. Status jujur: kontrak dorman, bukan kapabilitas rilis. Tidak memenuhi
syarat apa pun untuk klaim release-readiness.

## 6. Butir keputusan yang menunggu otoritas

1. Definisi acceptance contract `1.0.0` — kandidat basis: fitur inti
   novel/character/story + workspace separation (ADR-WS-001) + persistence;
   installer/signing/update/rollback keluar cakupan selama asetnya absen.
2. Pemetaan branch — opsi: tetap `master`; atau mapping formal `master`→`main`.
   Prasyarat keduanya: 92 commit lokal harus di-push agar CI bermakna.
3. Sumber versi tunggal — pubspec sebagai sumber dan `applicationVersion`
   mengikuti (perlu mekanisme + test kesesuaian), atau biarkan dua sumber
   dengan risiko drift.
4. Batas release candidate — definisi snapshot bersih/reviewable dari worktree
   483-perubahan saat ini (apa yang masuk RC, apa yang ditunda).
5. Cakupan installer/signing/update/rollback — pertahankan sebagai target pasca-v1
   atau hapus dari kontrak (rekomendasi konsisten dengan #1).
6. Otoritas rilis eksplisit — siapa/yang mana yang boleh membuat tag/branch rilis
   dan mengubah metadata versi.

Tanpa keenam keputusan itu, G6 tetap tidak bisa ditutup dan Sprint 101 tetap
DEFERRED sesuai advancement rule.
