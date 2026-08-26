# 109.43 — Unresolved Subplot & Consequence Alerts

**Acceptance kanonik:** `unresolved_report`, `deadline_or_story_point`,
`failure_consequence`, `dismissal_reason`, `closure_history`.

`lib/features/subplot/domain/subplot_alerts.dart` menyediakan scanner dan
report domain murni di atas `StoryQuest`:

- quest terminal tidak menghasilkan alert unresolved;
- quest non-terminal menghasilkan alert unresolved, story-point overdue, atau
deadline overdue dengan trigger eksplisit;
- failure consequence diambil dari outcome gagal dan dibawa ke alert;
- dismissal/resolution membutuhkan alasan atau note nonblank;
- closure history append-only, immutable antar report, dan menyimpan timestamp,
kind, reason, serta alert ID;
- report mengembalikan instance baru saat menutup alert, tanpa memutasi sumber.

Batas scope: tidak ada persistence/UI/clock service. `now` dapat diinjeksi untuk
scan deterministik; default clock hanya fallback produksi.

## Bukti TDD

| Acceptance | Bukti |
|---|---|
| `unresolved_report` | active/available terlapor; completed tidak. |
| `deadline_or_story_point` | trigger story point dan deadline dibedakan. |
| `failure_consequence` | outcome gagal masuk ke alert. |
| `dismissal_reason` | blank reason ditolak; dismiss menghapus active dan mencatat history. |
| `closure_history` | resolve+dismiss append-only dan ordered; report awal tetap kosong. |

## Iterasi jujur

Analyzer menemukan tiga `curly_braces_in_flow_control_structures` dan tiga
`prefer_const_constructors`; semua diperbaiki pada file owned tanpa mengubah
perilaku. Focused suite tetap 5/5 dan suite subplot 19/19.

109.43 tidak menambah tabel Drift; D-SCHEMA-01 tetap OPEN hingga gate 109.51.
