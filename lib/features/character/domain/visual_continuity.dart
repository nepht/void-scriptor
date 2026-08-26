/// Kontrak Visual Description Continuity (Step 109.29).
///
/// Pembanding deskripsi karakter dengan atribut visual canon dan
/// riwayat adegan sebagai domain murni (tanpa DB/UI). Lima kemampuan
/// kanonik sprint_109.json:
/// 1. **attribute_registry** — atribut canon per tokoh; nilai yang
///    sudah ada tidak ditimpa diam-diam;
/// 2. **scene_comparison** — deskripsi adegan dicocokkan dengan nilai
///    canon efektif;
/// 3. **explain_warning** — mismatch diberi penjelasan deterministik
///    yang menyebut nilai canon;
/// 4. **timeline_awareness** — titik ubah canon berlaku setelah adegan
///    tertentu;
/// 5. **user_override** — override pengguna mengalahkan canon untuk
///    satu pasangan tokoh+adegan saja.
library;

/// Registri atribut visual canon lintas tokoh; murni domain.
class VisualCanon {
  final Map<String, Map<String, String>> _attributes =
      <String, Map<String, String>>{};

  /// Titik ubah kronologis: setelah [afterScene], nilai atribut menjadi
  /// [value].
  final List<VisualChangePoint> _changePoints = <VisualChangePoint>[];

  /// Mendaftarkan nilai canon; menimpa nilai berbeda ([StateError])
  /// dilarang agar canon tidak berubah diam-diam.
  void setAttribute(String characterId, String attribute, String value) {
    final bucket = _attributes.putIfAbsent(
      characterId,
      () => <String, String>{},
    );
    final existing = bucket[attribute];
    if (existing != null && existing != value) {
      throw StateError(
        'canon $characterId.$attribute sudah $existing; '
        'gunakan addChangePoint untuk mengubah',
      );
    }
    bucket[attribute] = value;
  }

  /// Nilai canon dasar; null bila belum terdaftar.
  String? attributeOf(String characterId, String attribute) =>
      _attributes[characterId]?[attribute];

  /// Menambah titik ubah canon.
  void addChangePoint({
    required String characterId,
    required String attribute,
    required String afterScene,
    required String value,
  }) {
    _changePoints.add(
      VisualChangePoint(
        characterId: characterId,
        attribute: attribute,
        afterScene: afterScene,
        value: value,
      ),
    );
  }

  /// Nilai canon efektif pada suatu adegan, memperhitungkan titik ubah
  /// yang sudah lewat (terbaru menang).
  String? effectiveValue(String characterId, String attribute, String sceneId) {
    var value = attributeOf(characterId, attribute);
    var bestScene = '';
    for (final point in _changePoints) {
      if (point.characterId != characterId || point.attribute != attribute) {
        continue;
      }
      if (sceneId.compareTo(point.afterScene) > 0 &&
          point.afterScene.compareTo(bestScene) >= 0) {
        value = point.value;
        bestScene = point.afterScene;
      }
    }
    return value;
  }

  bool hasAttribute(String characterId, String attribute) =>
      (_attributes[characterId]?.containsKey(attribute)) ?? false;

  Iterable<String> attributesOf(String characterId) =>
      (_attributes[characterId] ?? const <String, String>{}).keys;
}

/// Satu titik ubah canon.
class VisualChangePoint {
  const VisualChangePoint({
    required this.characterId,
    required this.attribute,
    required this.afterScene,
    required this.value,
  });

  final String characterId;
  final String attribute;

  /// Adegan terakhir tempat nilai LAMA masih sah.
  final String afterScene;
  final String value;
}

/// Laporan perbandingan satu adegan.
class VisualContinuityReport {
  const VisualContinuityReport({
    required this.characterId,
    required this.sceneId,
    required this.matches,
    required this.mismatches,
    required this.explanations,
  });

  final String characterId;
  final String sceneId;

  /// Atribut -> nilai yang cocok dengan canon efektif.
  final Map<String, String> matches;

  /// Atribut -> kutipan deskripsi yang bertentangan dengan canon.
  final Map<String, String> mismatches;

  final Map<String, String> explanations;

  /// Penjelasan deterministik untuk satu atribut; null bila tak ada
  /// temuan untuk atribut tersebut.
  String? explanationFor(String attribute) => explanations[attribute];
}

/// Pemeriksa kontinuitas visual; murni domain.
class VisualContinuityChecker {
  VisualContinuityChecker({required this.canon});

  /// Registri canon yang dirujuk.
  final VisualCanon canon;

  final Map<String, Map<String, String>> _overridesByScene =
      <String, Map<String, String>>{};

  /// Override pengguna untuk SATU pasangan tokoh+adegen.
  void override({
    required String characterId,
    required String sceneId,
    required String attribute,
    required String expectedValue,
  }) {
    _overridesByScene.putIfAbsent(
      '$characterId@$sceneId',
      () => <String, String>{},
    )[attribute] = expectedValue;
  }

  /// Membandingkan deskripsi bebas dengan canon efektif.
  ///
  /// Deskripsi dianggap membahas sebuah atribut bila memuat nama
  /// atributnya; cocok bila juga memuat nilai canon efektifnya.
  VisualContinuityReport compare({
    required String characterId,
    required String sceneId,
    required List<String> descriptions,
  }) {
    final matches = <String, String>{};
    final mismatches = <String, String>{};
    final explanations = <String, String>{};
    final overrides =
        _overridesByScene['$characterId@$sceneId'] ?? const <String, String>{};
    final lowered = [for (final d in descriptions) d.toLowerCase()];
    for (final attribute in canon.attributesOf(characterId)) {
      final expected =
          overrides[attribute] ??
          canon.effectiveValue(characterId, attribute, sceneId);
      if (expected == null) continue;
      final attrLower = attribute.toLowerCase();
      final expLower = expected.toLowerCase();
      for (var i = 0; i < lowered.length; i++) {
        final text = lowered[i];
        if (!text.contains(attrLower)) continue;
        if (text.contains(expLower)) {
          matches[attribute] = expected;
        } else {
          mismatches[attribute] = descriptions[i];
          explanations[attribute] =
              'Adegan $sceneId: deskripsi "${descriptions[i]}" untuk '
              '$attribute tidak cocok; canon $characterId.$attribute = '
              '$expected'
              '${overrides.containsKey(attribute) ? " (override pengguna)" : ""}.';
        }
        break;
      }
    }
    return VisualContinuityReport(
      characterId: characterId,
      sceneId: sceneId,
      matches: Map.unmodifiable(matches),
      mismatches: Map.unmodifiable(mismatches),
      explanations: Map.unmodifiable(explanations),
    );
  }
}
