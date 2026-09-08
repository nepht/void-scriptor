import 'dart:io';

import 'package:path/path.dart' as p;

/// Kekuatan pencocokan folder -> aset. Makin tinggi, makin spesifik.
enum AssetFolderMatchStrength { prefix, tokenSet, exact }

/// Matcher folder-ke-aset yang dipakai bersama oleh bulk thumbnail dan bulk
/// reference import agar kedua alur mengenali folder yang sama dengan cara
/// yang sama: exact (case-insensitive) > kesamaan himpunan token (urutan kata
/// bebas) > prefix terpanjang. Deterministik: nama kandidat diurut, jadi
/// kandidat pertama yang cocok menang.
class AssetFolderMatcher {
  const AssetFolderMatcher();

  /// assetName (sudah lowercase-trim) -> assetId.
  (String, AssetFolderMatchStrength)? match(
    String folderName,
    Map<String, String> assetsByName,
  ) {
    final sortedNames = assetsByName.keys.toList()..sort();
    final needle = _normalize(folderName);

    final exact = assetsByName[needle];
    if (exact != null) return (exact, AssetFolderMatchStrength.exact);

    final needleTokens = needle.split(_whitespace);
    for (final name in sortedNames) {
      if (_sameTokenSet(name, needleTokens)) {
        return (assetsByName[name]!, AssetFolderMatchStrength.tokenSet);
      }
    }
    for (final name in sortedNames) {
      if (needle.startsWith('${_normalize(name)} ')) {
        return (assetsByName[name]!, AssetFolderMatchStrength.prefix);
      }
    }
    return null;
  }

  String _normalize(String value) => value.toLowerCase().trim();
  RegExp get _whitespace => RegExp(r'\s+');

  bool _sameTokenSet(String assetName, List<String> folderTokens) {
    final assetTokens = _normalize(assetName).split(_whitespace);
    if (assetTokens.length != folderTokens.length) return false;
    final remaining = [...folderTokens];
    for (final token in assetTokens) {
      if (!remaining.remove(token)) return false;
    }
    return true;
  }
}

/// Nama file gambar di dalam folder referensi, urut byte-name untuk
/// deterministik "gambar pertama".
Future<List<String>> sortedImageFiles(
  Directory dir,
  Set<String> allowedExtensions,
) async {
  final files =
      (await dir.list().toList())
          .whereType<File>()
          .where(
            (file) => allowedExtensions.contains(
              p.extension(file.path).toLowerCase(),
            ),
          )
          .map((file) => p.basename(file.path))
          .toList()
        ..sort();
  return files;
}
