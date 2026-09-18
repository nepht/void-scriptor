/// Kontrak Reader Clearance & Redaction (Step 109.31).
///
/// Pratinjau dokumen sesuai clearance pembaca beta sebagai domain
/// murni (tanpa DB/UI), mengikat SpoilerRegistry 109.30. Lima
/// kemampuan kanonik sprint_109.json:
/// 1. **preview_as_reader** — render dokumen dari mata satu pembaca;
/// 2. **redaction** — blok ber-spoiler diganti penanda tanpa teks asli;
/// 3. **hidden_links** — tautan internal ke data tersembunyi dihapus;
/// 4. **no_metadata_leak** — metadata internal tak pernah ikut keluaran;
/// 5. **revocable_access** — akses dapat dicabut kapan pun.
library;

import 'package:void_scriptor/features/spoiler/domain/spoiler_classification.dart';

/// Tautan internal dalam blok.
class InternalLink {
  const InternalLink({required this.label, required this.targetItemId});

  final String label;

  /// Id data lore/spoiler yang dirujuk tautan.
  final String targetItemId;
}

/// Satu blok dokumen sumber.
class ReaderBlock {
  const ReaderBlock({
    required this.id,
    required this.text,
    this.spoilerItemId,
    this.links = const <InternalLink>[],
  });

  final String id;
  final String text;

  /// Bila terisi, visibilitas blok ditentukan registry spoiler.
  final String? spoilerItemId;
  final List<InternalLink> links;
}

/// Dokumen sumber lengkap dengan metadata internal (tidak pernah
/// bocor ke pratinjau).
class ReaderDocument {
  const ReaderDocument({
    required this.id,
    required this.title,
    required this.blocks,
    this.metadata = const <String, String>{},
  });

  final String id;
  final String title;
  final List<ReaderBlock> blocks;

  /// Metadata internal untuk penulis/editor saja.
  final Map<String, String> metadata;
}

/// Jenis render blok pratinjau.
enum PreviewKind { visible, redacted }

/// Satu blok hasil pratinjau; tidak memuat data internal.
class PreviewBlock {
  const PreviewBlock({
    required this.id,
    required this.kind,
    required this.text,
    this.links = const <InternalLink>[],
  });

  final String id;
  final PreviewKind kind;
  final String text;
  final List<InternalLink> links;
}

/// Hasil pratinjau satu pembaca; serialisasi aman tanpa metadata.
class ReaderPreview {
  const ReaderPreview({
    required this.documentId,
    required this.title,
    required this.readerId,
    required this.blocks,
  });

  final String documentId;
  final String title;
  final String readerId;
  final List<PreviewBlock> blocks;

  Map<String, Object?> toJson() => <String, Object?>{
    'documentId': documentId,
    'title': title,
    'readerId': readerId,
    'blocks': <Object?>[
      for (final b in blocks)
        <String, Object?>{
          'id': b.id,
          'kind': b.kind.name,
          'text': b.text,
          'links': <Object?>[
            for (final l in b.links) <String, Object?>{'label': l.label},
          ],
        },
    ],
  };
}

/// Perender pratinjau sesuai clearance; murni domain.
class ReaderRedactor {
  ReaderRedactor({required this.registry});

  /// Registry spoiler 109.30 yang menjadi sumber kebenaran level.
  final SpoilerRegistry registry;

  final Map<String, String> _grants = <String, String>{};

  /// True bila pembaca masih memiliki grant aktif.
  bool hasAccess(String readerId) => _grants.containsKey(readerId);

  /// Memberi (atau memperbarui) akses satu pembaca; audiens harus
  /// terdaftar ([StateError]).
  void grant({required String readerId, required String audience}) {
    if (!registry.hasAudience(audience)) {
      throw StateError('unknown audience: $audience');
    }
    _grants[readerId] = audience;
  }

  /// Mencabut akses; pembaca tak dikenal [StateError].
  void revoke(String readerId) {
    if (!_grants.containsKey(readerId)) {
      throw StateError('unknown reader: $readerId');
    }
    _grants.remove(readerId);
  }

  /// Merender [doc] dari mata pembaca: blok ber-spoiler yang belum
  /// tampak diganti [replacement], tautan ke data tersembunyi
  /// dihilangkan, metadata internal dibuang total.
  ReaderPreview previewAsReader({
    required ReaderDocument doc,
    required String readerId,
    required String currentScene,
    String replacement = '[disensor]',
  }) {
    final audience = _grants[readerId];
    if (audience == null) {
      throw StateError('reader has no access: $readerId');
    }
    bool visibleItem(String itemId) => registry.isVisible(
      itemId: itemId,
      audience: audience,
      currentScene: currentScene,
    );
    final blocks = <PreviewBlock>[];
    for (final block in doc.blocks) {
      final shown =
          block.spoilerItemId == null || visibleItem(block.spoilerItemId!);
      final links = <InternalLink>[
        for (final link in block.links)
          if (visibleItem(link.targetItemId)) link,
      ];
      blocks.add(
        PreviewBlock(
          id: block.id,
          kind: shown ? PreviewKind.visible : PreviewKind.redacted,
          text: shown ? block.text : replacement,
          links: List.unmodifiable(links),
        ),
      );
    }
    return ReaderPreview(
      documentId: doc.id,
      title: doc.title,
      readerId: readerId,
      blocks: List.unmodifiable(blocks),
    );
  }
}
