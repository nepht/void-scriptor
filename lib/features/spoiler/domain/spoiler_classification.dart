/// Kontrak Spoiler Classification Model (Step 109.30).
///
/// Model klasifikasi spoiler sebagai domain murni (tanpa DB/UI).
/// Lima kemampuan kanonik sprint_109.json:
/// 1. **spoiler_levels** — level eksplisit per data (clean/mild/major);
/// 2. **reveal_point** — tersembunyi sebelum adegan reveal;
/// 3. **audience_policy** — matriks audience(level maks) vs data(level);
/// 4. **inheritance_rules** — anggota mewarisi grup kecuali ada
///    klasifikasi eksplisit;
/// 5. **safe_default** — data tanpa klasifikasi dianggap major.
library;

/// Tingkat sensitivitas spoiler sebuah data.
enum SpoilerLevel {
  /// Bebas spoiler.
  clean,

  /// Spoiler ringan.
  mild,

  /// Spoiler besar (kematian, twist, ending).
  major,
}

/// Satu audiens dengan batas level tertinggi yang boleh dilihat.
class SpoilerAudience {
  const SpoilerAudience(this.id, this.maxLevel);

  final String id;

  /// Level tertinggi yang masih boleh tampak untuk audiens ini.
  final SpoilerLevel maxLevel;
}

/// Registri klasifikasi spoiler; murni domain.
class SpoilerRegistry {
  final Map<String, SpoilerLevel> _explicit = <String, SpoilerLevel>{};
  final Map<String, String> _groupOf = <String, String>{};
  final Map<String, SpoilerLevel> _groups = <String, SpoilerLevel>{};
  final Map<String, String> _revealPoints = <String, String>{};
  final Map<String, SpoilerAudience> _audiences = <String, SpoilerAudience>{};

  void _requireAudience(String audienceId) {
    if (!_audiences.containsKey(audienceId)) {
      throw StateError('unknown audience: $audienceId');
    }
  }

  /// Mendaftarkan audiens; id duplikat ditolak [StateError].
  void addAudience(SpoilerAudience audience) {
    if (_audiences.containsKey(audience.id)) {
      throw StateError('duplicate audience: ${audience.id}');
    }
    _audiences[audience.id] = audience;
  }

  /// Klasifikasi eksplisit satu data (mengalahkan warisan grup).
  void classify(String itemId, SpoilerLevel level) => _explicit[itemId] = level;

  /// Membuat grup berlevel; id duplikat ditolak [StateError].
  void createGroup(String groupId, SpoilerLevel level) {
    if (_groups.containsKey(groupId)) {
      throw StateError('duplicate group: $groupId');
    }
    _groups[groupId] = level;
  }

  /// Mengaitkan anggota ke grup; grup tak dikenal [StateError].
  void assignToGroup(String itemId, String groupId) {
    if (!_groups.containsKey(groupId)) {
      throw StateError('unknown group: $groupId');
    }
    _groupOf[itemId] = groupId;
  }

  /// Titik reveal: sebelum adegan ini data tetap tersembunyi meski
  /// lolos matriks level.
  void setRevealPoint(String itemId, String sceneId) =>
      _revealPoints[itemId] = sceneId;

  /// Level efektif satu data: eksplisit > warisan grup >
  /// default aman major.
  SpoilerLevel effectiveLevel(String itemId) {
    final explicit = _explicit[itemId];
    if (explicit != null) return explicit;
    final group = _groupOf[itemId];
    if (group != null) return _groups[group]!;
    return SpoilerLevel.major;
  }

  /// True bila data boleh tampil bagi audiens pada adegan tersebut:
  /// level efektif <= batas audiens DAN adegan kini sudah mencapai
  /// titik reveal (bila ditetapkan).
  bool isVisible({
    required String itemId,
    required String audience,
    required String currentScene,
  }) {
    _requireAudience(audience);
    final maxLevel = _audiences[audience]!.maxLevel.index;
    if (effectiveLevel(itemId).index > maxLevel) return false;
    final revealAt = _revealPoints[itemId];
    if (revealAt != null && currentScene.compareTo(revealAt) < 0) {
      return false;
    }
    return true;
  }
}
