# Void Scriptor Roadmap Governance

Roadmap tidak bergantung pada satu file:

1. Kontrak kebutuhan berada di arsip JSON eksternal `outputs/sprint_NNN.json`.
2. Kebijakan prioritas berada di `ROADMAP_POLICY.json`.
3. Bukti implementasi berada di ledger per sprint dalam `docs/sprints/`.
4. `.hermes/ROADMAP_STATE.json` hanya cache runtime dan dapat direkonstruksi.
5. `tool/roadmap_guard.dart` memeriksa konsensus keempat lapisan sebelum perubahan.
6. File tanpa nomor sprint dikendalikan oleh `DOCUMENT_REGISTRY.json`; file
   yang tidak terdaftar bersifat `NON_BINDING` dan tidak boleh menciptakan scope.

## Aturan utama

- Hanya satu mutation stream boleh `ACTIVE`.
- Corrective Sprint 145 menahan ekspansi Sprint 111 sampai Core MVP dan data
  safety gate selesai.
- File JSON sprint tidak boleh diedit oleh eksekutor; Hermes memakai salinan
  byte-identik dan guard memeriksa SHA-256.
- Status `PARTIAL`, `BLOCKED`, `MISSING`, dan `DEFERRED` bukan `VERIFIED`.
- Modul baru masuk sebagai backlog/deferred sampai dependency, data ownership,
  migration, UI path, dan acceptance test didefinisikan.
- Root otoritas yang ketat tidak menerima dokumen baru sebelum dokumen itu
  didaftarkan dengan role, authority, owner, status, hubungan sprint, dan
  kebijakan integritas yang valid.
- `POLICY` dan `EXECUTOR_POLICY` boleh membatasi eksekusi, tetapi tidak boleh
  menambah fitur di luar kontrak sprint. `EVIDENCE` hanya membuktikan status;
  `REFERENCE`, `BACKLOG`, `GENERATED`, dan file tak terdaftar tidak mengikat.

## File tanpa sprint

`docs/roadmap/DOCUMENT_REGISTRY.json` adalah allowlist otoritas, bukan backlog.
Setiap entry memiliki:

- `role` dan `authority` untuk menentukan cara Hermes membacanya;
- `may_create_scope: false` sebagai invariant global;
- `linked_sprints` untuk konteks, bukan izin eksekusi;
- `IMMUTABLE` + SHA-256 untuk kebijakan terkunci, atau `MUTABLE` untuk ledger
  turunan yang memang diperbarui;
- `owner` dan `status` untuk provenance.

Dokumen di luar strict authority roots boleh tetap ada, tetapi default-nya
`NON_BINDING`. Hermes tidak boleh menjadikannya sumber langkah baru kecuali
kemudian dipetakan ke kontrak sprint kanonis.

## Pemeriksaan

```text
dart run tool/roadmap_guard.dart
```

Jika runtime pointer rusak atau hilang, pause scheduler lebih dahulu lalu:

```text
dart run tool/roadmap_guard.dart --repair
```

Repair hanya menyalin kontrak aktif, menghitung langkah unresolved pertama dari
ledger, dan menandai quality gate `RECHECK_REQUIRED`. Repair tidak menandai tes
atau implementasi sebagai lulus.
