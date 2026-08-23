# Sprint 101.16 — Security Review (penerapan pertama)

Penerapan pertama checklist "Review keamanan & privasi tiap hotfix"
(`docs/release/hotfix-runbook-v1.0.1.md`) atas diff nyata sprint ini:
`origin/master...HEAD` pada cabang `sprint101` — 13 file, +1414/−1,
seluruhnya di area proses/docs dan lapisan bootstrap (`lib/app/bootstrap/`,
`lib/main.dart`, `test/app/bootstrap/`). Tanggal: 2026-08-23.

## Hasil per butir

| # | Butir | Status | Bukti |
|---|---|---|---|
| 1 | Validasi input & path tidak melemah | **VERIFIED** | Diff tidak menambahkan penguraian input eksternal apa pun. Nama file diagnostik disusun hanya dari `kind` internal (`replaceAll('_','-')`), `DateTime.now().microsecondsSinceEpoch`, dan counter sekuens integer (`crash_diagnostics.dart` ~157) — tidak ada data eksternal dalam komposisi nama file. Direktori penyimpanan berasal dari resolusi platform (`getApplicationSupportDirectory()` dengan fallback `Directory.systemTemp`, `app_diagnostics.dart`), bukan input pengguna. |
| 2 | Tidak ada secret baru di kode/konfig/log | **VERIFIED** | Pemindaian regex secret atas seluruh diff menghasilkan satu hit: fixture uji `token=supersecret42` (`crash_diagnostics_test.dart`) — nilai palsu yang sengaja dibuat untuk membuktikan redaksi bekerja. Lapisan `_redactSecrets()` justru menambah proteksi: Bearer header, assignment berlabel, dan token berpola provider diganti `[REDACTED]` sebelum menyentuh disk (101.17). |
| 3 | Perubahan plugin permission tidak memperluas akses | **VERIFIED (N/A)** | `git diff origin/master...HEAD --name-only` tidak menyentuh `pubspec.yaml`, AndroidManifest, Info.plist, Gradle, atau entitlement — permukaan izin platform tak berubah. |
| 4 | Verifikasi update/artefak tetap hash-terkunci | **VERIFIED (N/A)** | Subsistem installer/update eksplisit di luar kontrak v1 (`docs/audits/release-contract-v1.md`); tidak ada jalur verifikasi artefak yang bisa melemah karena belum ada. |
| 5 | Perilaku lokal-saja tidak berubah | **VERIFIED** | Diff hanya mengimpor `dart:convert`, `dart:io`, Flutter/Riverpod — nol paket jaringan. Guard otomatis `privacy_regression_test.dart` (8 test) mengunci: artefak lahir hanya di direktori diagnostics yang diinjeksikan, skema JSON tanpa field telemetri, tanpa marker endpoint/provider remote, permukaan dependensi bootstrap bebas jaringan. |
| 6 | Redaksi diagnostic bundle tetap menyaring konten cerita | **PARTIAL** | Redaksi secret terbukti otomatis (butir 2). Penyaringan konten cerita secara eksplisit belum diimplementasikan; risikonya dibatasi desain lokal-saja — artefak crash/startup tidak pernah meninggalkan mesin (tanpa telemetri), tetap di direktori aplikasi, dan `CrashDiagnostics.purge()` tersedia untuk penghapusan penuh. Dicatat sebagai utang penyempurnaan, bukan regresi. |

## Kesimpulan

Tidak ditemukan pelemahan keamanan pada diff sprint ini. Seluruh perubahan
aditif pada lapisan diagnostik yang berjalan lokal-saja; dua butir bernilai
N/A struktural (izin platform, jalur update). Satu utang dicatat pada butir 6
(penyaringan konten cerita dalam artefak diagnostik) — berstatus aman oleh
kontainmen lokal, layak dievaluasi ulang saat subsistem berbagi/telemetri
(mungkin) muncul pasca-v1.
