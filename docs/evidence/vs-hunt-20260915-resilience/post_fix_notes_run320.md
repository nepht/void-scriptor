# Post-fix notes — vs-hunt-20260915-resilience (run320)

- HEAD saat hunt: 762ed7f (scope 18 file, SHA-256 di scope_hashes.txt).
- BUG-3 (Critical) FIXED di 03f4cad: marker sesi kini memuat identitas
  start-time proses; `_recoverDeadOwnerMarker` membandingkan CreationDate
  holder PID (CIM, via probe terinjeksi) dengan `openedAt` marker + grace
  60 detik. Reuse terbukti -> recovery sah (snapshot diarsipkan seperti
  sebelumnya). Null/gagal/skew/grace -> fail-closed persis perilaku lama.
  Konsumsi token: probe start-time HANYA dipanggil ketika PID terbukti hidup
  (jalur recovery), jadi acquire normal tanpa biaya tambahan.
- Perubahan perilaku terisolasi pada bukti kuat saja: holder yang mulai
  SEBELUM marker ditulis (atau waktu tak diketahui / dalam grace) tetap
  dilindungi persis perilaku lama. Holder yang mulai SETELAH marker =
  mustahil penulisnya -> reuse terbukti -> dipulihkan. Konsekuensinya,
  fixture lama yang men-stamp openedAt lampau dengan pid proses test
  sendiri kini SALAH PREMIS (proses test mulai setelah stamp itu) ->
  diadaptasi dinamis (lihat commit) karena premis tersebut tidak mungkin
  terjadi pada pemilik sah di produksi.
- ANTREAN (verdict Referee on-disk = otoritas; angka BUG = namespace
  vs-hunt-20260915-resilience-*):
  - BUG-4 Medium: setelah competing-create gagal pada create kedua,
    re-read marker dan bedakan 'owner baru sah' vs 'stale' sebelum
    melempar StateError.
  - BUG-6 Medium: `ProjectIntegrityReport.portable` (project_resilience_
    repository.dart:37) += `orphanFiles == 0`; satu-satunya konsumen
    project_resilience_center_screen.dart:209; tambahkan regresi
    presentasi 'needs attention'.
  - BUG-7 Medium: `Available backups` (controller scan backupItems) harus
    dihitung dari baris record backup (termasuk root eksternal), bukan
    hanya direktori internal paket.
  - BUG-8 Medium: `_enforceBackupRetention` — balik urutan jadi
    tandai-pending -> hapus baris -> sweep, atau rekonsiliasi direktori
    hilang vs baris saat scan.
  - BUG-9 Low: `ProjectVersionControlService.compare` pakai perbandingan
    JSON struktural (bukan `!=` dangkal).
- BUG-1/2/5/10 NOT A BUG per Referee (guard resolve/kepemilikan sudah
  benar) — JANGAN re-fix.
