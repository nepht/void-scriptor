# REFEREE REPORT — vs-hunt-20260913-projects
- stage: referee LULUS penuh (rantai 3-tahap bersih: Hunter 52s, Skeptic 39s, Referee 25s; gemini flash-lite sehat era ini)
- repo: D:\VoidScriptor\void_scriptor_multiplatform, master, HEAD masuk 648d9bff; fingerprint scope di scope_hashes.txt
- commands (read-only): read_file 10 file scope + create_project_screen.dart + project_flow_test.dart + project_web_guard_test.dart; grep callsites (relocateProject/closeProject/moveProject/createProject/currentProjectProvider/resolvePackageRoot/projectSessionProvider); git log --oneline -- project_controller.dart

## Verdict
- PRJ-BUG-01 NOT A BUG — close-session-before-relocate prasyarat Windows lock; dokumentasi baris 62-65 + commit a8072b8; kegagalan relocate melempr ke pemanggil dan paket tetap di lokasi awal.
- PRJ-BUG-02 REAL BUG — Low. `localPath` required tetapi tidak dirujuk di body; `ProjectPackageService` selalu memakai `paths.root()`. Referee independen membaca create_project_screen.dart:75-81: layar hanya MENERUSKAN root terkelola sebagai teks kosong-ekivalen sehingga TIDAK ada pemborosan pilihan pengguna saat ini — defect-nya adalah contract trap (parameter yang berjanji menentukan lokasi, diam-diam diabaikan; preseden kelas BUG-7 wiring). Fix direction: hormati localPath non-kosong, kosong = default paths.root().
- PRJ-BUG-03 NOT A BUG — serialization mutex; pemanggil asli menerima error dari await miliknya sendiri.
- PRJ-BUG-04 NOT A BUG — resolver murni; penanganan missing-dir downstream (project_open_path_registry_resolution_test.cs already pins).

Stats: dilaporkan 4, REAL 1 (Low), dismissed 3, Critical 0.
REPAIR QUEUE: PRJ-BUG-02.

## Eksekusi (oleh eksekutor utama, bukan anak)
- RED: test/features/projects/project_create_localpath_test.dart — `createProject honors a non-empty localPath as the package root` gagal persis gejala (paket jatuh ke managed root, bukan chosen root).
- GREEN: project_controller.dart — rootDirectory = localPath.isEmpty ? paths.root() : Directory(localPath). Two tests PASS.
- Regresi: test/features/projects SELURUHNYA 25 PASS / 0 FAIL (setelah `dart format` menstabilkan file tes baru; gate format exit 0). Konsumen luar-region yang memanggil controller.createProject dengan localPath nyata: test/core/persistence/project_creation_marker_delete_failure_test.dart (root terkelola == root yang diteruskan, paket tetap ada & terdaftar) + test/features/dashboard/recent_projects_test.dart — keduanya PASS (7/7).
- dart analyze lib/features/projects test/features/projects: No issues found. git diff --check exit 0. flutter build windows --debug: PASS 25,3s (working tree memuat WIP sibling autosave/character — dirty-scope, build bukan bukti atas region itu).
- Catatan perilaku: satu-satunya pemanggil produksi (create_project_screen) meneruskan `paths.root()` yang SAMA, sehingga perubahan ini netral bagi UI hari-hari; hanya pemanggil mendatang yang mengeksploitasi pemilihan lokasi yang berubah perilaku — sesuai desain.
