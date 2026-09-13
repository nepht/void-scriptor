# Parent verification vs-hunt-20260914-export (run299)

Verifikasi independen nephthys atas satu-satunya verdict REAL BUG Referee
(EXP-BUG-04) SEBELUM patch, dan koreksi minor atas suggested fix-nya.

## Reproduksi mekanismenya (bacaan kode + test)

- `ExportPreflightValidator._preview` memotong dengan `text.substring(0, limit - 1)`
  atas code unit UTF-16. Bila unit terakhir yang disertakan adalah high surrogate
  (0xD800–0xDBFF) dan low pasangannya tepat di indeks `limit-1` (tidak ikut),
  preview berakhir dengan surrogate yatim — teks malformed bagi consumer
  (clipboard/encoder/Text widget) dan melanggar intent test lama
  "truncates at a character boundary" (export_preflight_test.dart:106).
- `previewCharacterLimit` divalidasi > 0 di `validate()` (baris 149–153),
  sehingga guard `end > 0` tidak pernah bertemu limit <= 1 secara tak terdefinisi.
- RED tereksekusi (bukan dikarang): dua test surrogate FAIL sebelum patch
  dengan reason `body [..., 55357] berakhir high surrogate yatim` (0xD800=55296,
  55357 = high surrogate U+1F600). Exit terdokumentasi di transcript run299.

## Koreksi atas suggested fix Referee

Referee menyarankan `Characters(text)` (paket `characters`). Salah untuk repo ini:
`characters` bukan dependency langsung (grep pubspec.yaml = nol), dan truncation
berbasis grapheme cluster TETAP bisa menghasilkan rune non-BMP utuh yang terpotong
di batas (satu cluster emoji = 2 unit; `take(limit-1)` atas runes pun bisa
mendarat di tengah pasangan bila dihitung per-unit). Fix yang dipakai:
mundurkan `end` satu unit bila unit terakhir yang disertakan adalah high
surrogate — presisi pada level encoding, panjang ≤ limit, tanpa dependency baru.
Kasus low-surrogate-yatim di awal string tidak mungkin terjadi (substring selalu
mulai indeks 0).

## Temuan dismissed (01/02/03) — dicek ulang induk, setuju Referee

- BUG-01/02: tidak ada kontrak validasi nama/pas marker blank di doc, test,
  maupun caller; `_requireMarker` secara eksplisit mendokumentasikan isEmpty.
- BUG-03: `contentFingerprint` hanya dibandingkan internal deterministik
  (test manifest); tidak ada interoperabilitas byte eksternal yang menuntut UTF-8.

## Antrean

EXP-BUG-04: CLOSED oleh slice ini. Region features/export selesai.
Kandidan region hunt berikutnya (belum ada vs-hunt): pembulatan daftar
lib/features tanpa bukti hunt — lihat ledger next action.
