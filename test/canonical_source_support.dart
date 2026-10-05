import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Kanonik sprint/spec JSON disimpan di ARSIP DI LUAR repo
/// (`ROADMAP_STATE.json` -> `hermes_reference_root` / `canonical_archive_root`).
/// Konstanta `lib/` menunjuk ke path itu dan di-pin sha256, sehingga file ini
/// memang tidak pernah ikut ter-commit. Di mesin tanpa arsip (mis. runner CI
/// Linux), test yang membacanya melewati berkas ini dengan skip yang terlihat,
/// bukan gagal — sama seperti golden yang di-skip di luar Windows.
const externalCanonicalSources = <String>[
  'C:/Users/nepht/AppData/Local/hermes/references/void_scriptor/sprint_115.json',
  'C:/Users/nepht/AppData/Local/hermes/references/void_scriptor/sprint_116.json',
  'C:/Users/nepht/Documents/Codex/2026-08-22/'
      'referenced-chatgpt-conversation-this-is-an-2/outputs/'
      'account_cloud_center_spec.json',
  'C:/Users/nepht/Documents/Codex/2026-08-22/'
      'referenced-chatgpt-conversation-this-is-an-2/outputs/'
      'connector_sdk_spec.json',
];

bool get externalCanonicalSourcesPresent =>
    externalCanonicalSources.every((path) => File(path).existsSync());

/// Panggil sebagai baris pertama badan test yang membaca arsip kanonik.
/// Mengembalikan `true` bila test sudah di-skip dan badan harus `return;`.
bool skipUnlessExternalCanonical(String what) {
  if (externalCanonicalSourcesPresent) {
    return false;
  }
  markTestSkipped('arsip kanonik eksternal absen di mesin ini ($what)');
  return true;
}
