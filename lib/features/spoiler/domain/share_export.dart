/// Kontrak Spoiler-Safe Share Export (Step 109.32).
///
/// Pembuat paket berbagi yang diperiksa kebocoran spoiler sebagai
/// domain murni (tanpa DB/UI), mengikat SpoilerRegistry 109.30.
/// Lima kemampuan kanonik sprint_109.json:
/// 1. **preflight_report** — laporan pra-unduh: berapa blok akan
///    disensor dan apakah metadata dibuang;
/// 2. **audience_manifest** — manifest audiens beserta batas level
///    dan penanda konten tersembunyi;
/// 3. **sanitized_export** — paket ekspor bebas teks tersensor dan
///    metadata internal;
/// 4. **share_expiry** — paket kedaluwarsa setelah tenggat;
/// 5. **revoke** — pencabutan mematikan paket permanen.
library;

import 'package:void_scriptor/features/spoiler/domain/spoiler_classification.dart';

/// Satu blok dokumen sumber untuk dibagikan.
class ShareBlock {
  const ShareBlock({required this.id, required this.text, this.spoilerItemId});

  final String id;
  final String text;

  /// Bila terisi, visibilitas blok ditentukan registry spoiler.
  final String? spoilerItemId;
}

/// Dokumen sumber lengkap dengan metadata internal (tidak pernah
/// ikut paket).
class ShareDocument {
  const ShareDocument({
    required this.title,
    required this.blocks,
    this.metadata = const <String, String>{},
  });

  final String title;
  final List<ShareBlock> blocks;
  final Map<String, String> metadata;
}

/// Laporan pra-unduh untuk satu audiens.
class PreflightReport {
  const PreflightReport({
    required this.audience,
    required this.totalBlocks,
    required this.redactedCount,
    required this.metadataDropped,
  });

  final String audience;
  final int totalBlocks;

  /// Banyaknya blok yang AKAN disensor untuk audiens ini.
  final int redactedCount;

  /// True bila ada metadata internal yang dibuang.
  final bool metadataDropped;

  /// Paket aman diunduh hanya bila tidak ada blok tersensor DAN tak
  /// ada metadata; selain itu unduhan tetap boleh tapi laporan wajib
  /// ditinjau (keputusan tetap di tangan penulis).
  bool get fullyClean => redactedCount == 0 && !metadataDropped;
}

/// Manifest audiens pada sebuah paket.
class AudienceManifest {
  const AudienceManifest({
    required this.audienceId,
    required this.maxLevel,
    required this.containsHiddenContent,
  });

  final String audienceId;
  final SpoilerLevel maxLevel;

  /// True bila minimal satu blok disensor untuk audiens ini.
  final bool containsHiddenContent;
}

/// Blok hasil sanitasi.
class SanitizedBlock {
  const SanitizedBlock({
    required this.id,
    required this.text,
    required this.wasRedacted,
  });

  final String id;
  final String text;
  final bool wasRedacted;
}

/// Paket berbagi hasil ekspor; kedaluwarsa dan dapat dicabut.
class SharePackage {
  SharePackage({
    required this.token,
    required this.audienceId,
    required this.title,
    required List<SanitizedBlock> blocks,
    required this.expiresAt,
  }) : _blocks = List.unmodifiable(blocks),
       _revokedAt = null;

  /// Token publik paket (tidak mengandung data internal).
  final String token;
  final String audienceId;
  final String title;
  final DateTime expiresAt;

  final List<SanitizedBlock> _blocks;
  DateTime? _revokedAt;

  /// Blok ter-sanitasi urut aslinya.
  List<SanitizedBlock> get blocks => _blocks;

  /// True bila paket sudah kedaluwarsa pada [at].
  bool isExpiredAt(DateTime at) => at.isAfter(expiresAt);

  /// Mencabut paket permanen pada [at]; panggilan ulang [StateError].
  void revokeAt(DateTime at) {
    if (_revokedAt != null) {
      throw StateError('package already revoked');
    }
    _revokedAt = at;
  }

  bool get isRevoked => _revokedAt != null;

  /// Mengunduh isi paket pada [at]; [StateError] bila kedaluwarsa
  /// atau sudah dicabut.
  List<SanitizedBlock> downloadAt(DateTime at) {
    if (isExpiredAt(at)) {
      throw StateError('package expired');
    }
    if (_revokedAt != null) {
      throw StateError('package revoked');
    }
    return _blocks;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'token': token,
    'audienceId': audienceId,
    'title': title,
    'expiresAt': expiresAt.toIso8601String(),
    'blocks': <Object?>[
      for (final b in _blocks)
        <String, Object?>{
          'id': b.id,
          'text': b.text,
          'redacted': b.wasRedacted,
        },
    ],
  };
}

/// Pembangun paket berbagi anti-bocor; murni domain.
class SharePackageBuilder {
  SharePackageBuilder({
    required this.registry,
    DateTime Function()? clock,
    String Function()? tokens,
  }) : _clock = clock ?? DateTime.now,
       _tokens = tokens ?? _defaultToken;

  static int _counter = 0;

  static String _defaultToken() {
    _counter += 1;
    return 'share-$_counter';
  }

  /// Registry spoiler 109.30 sumber kebenaran level.
  final SpoilerRegistry registry;

  final DateTime Function() _clock;
  final String Function() _tokens;
  ShareDocument? _document;

  DateTime Function() get clockForTest => _clock;

  /// Mengikat dokumen sumber.
  void setDocument({
    required String title,
    required List<ShareBlock> blocks,
    Map<String, String> metadata = const <String, String>{},
  }) {
    _document = ShareDocument(title: title, blocks: blocks, metadata: metadata);
  }

  /// Menyuntik jam (untuk uji kedaluwarsa).
  SharePackageBuilder withClock(DateTime Function() clock) {
    return SharePackageBuilder(
      registry: registry,
      clock: clock,
      tokens: _tokens,
    ).._document = _document;
  }

  void _requireDocument() {
    if (_document == null) {
      throw StateError('document not set');
    }
  }

  /// Menghitung laporan pra-unduh tanpa membuat paket.
  PreflightReport preflight({required String audience}) {
    _requireDocument();
    var redacted = 0;
    for (final block in _document!.blocks) {
      if (block.spoilerItemId != null &&
          !registry.isVisible(
            itemId: block.spoilerItemId!,
            audience: audience,
            currentScene: 'zzz-latest',
          )) {
        redacted += 1;
      }
    }
    return PreflightReport(
      audience: audience,
      totalBlocks: _document!.blocks.length,
      redactedCount: redacted,
      metadataDropped: _document!.metadata.isNotEmpty,
    );
  }

  /// Manifest audiens untuk paket yang akan dibuat.
  AudienceManifest manifestFor(String audience) {
    _requireDocument();
    final report = preflight(audience: audience);
    return AudienceManifest(
      audienceId: audience,
      maxLevel: registry.maxLevelOf(audience),
      containsHiddenContent: report.redactedCount > 0,
    );
  }

  /// Membuat paket ter-sanitasi untuk audiens; [ttl] opsional
  /// menetapkan kedaluwarsa relatif dari jam saat ini.
  ///
  /// Adegan pemeriksa visibilitas memakai 'zzz-latest': paket berbagi
  /// dinilai pada keadaan reveal TERAKHIR sehingga konten yang sudah
  /// ter-reveal bagi audiens tidak ikut disensor.
  SharePackage export({
    required String audience,
    Duration? ttl,
    String replacement = '[disensor]',
  }) {
    _requireDocument();
    final now = _clock();
    final blocks = <SanitizedBlock>[];
    for (final block in _document!.blocks) {
      final shown =
          block.spoilerItemId == null ||
          registry.isVisible(
            itemId: block.spoilerItemId!,
            audience: audience,
            currentScene: 'zzz-latest',
          );
      blocks.add(
        SanitizedBlock(
          id: block.id,
          text: shown ? block.text : replacement,
          wasRedacted: !shown,
        ),
      );
    }
    return SharePackage(
      token: _tokens(),
      audienceId: audience,
      title: _document!.title,
      blocks: blocks,
      expiresAt: ttl == null
          ? now.add(const Duration(days: 3650))
          : now.add(ttl),
    );
  }
}
