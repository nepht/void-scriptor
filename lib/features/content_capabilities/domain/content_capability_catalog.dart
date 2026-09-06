import 'dart:collection';

import 'content_capability.dart';

/// Audited product-integration baseline.
///
/// A source file alone does not make a capability available. A workflow is
/// marked available only when the repository currently exposes a usable
/// product path for it; partial and missing cells remain visible as work.
abstract final class ContentCapabilityCatalog {
  static final List<ContentModuleCapability> modules = List.unmodifiable([
    _module(
      id: 'story',
      label: 'Novel & Scene',
      description: 'Penulisan manuskrip, bab, adegan, snapshot, dan ekspor.',
      maturity: ContentModuleMaturity.partial,
      available: {
        ContentWorkflowCapability.browse,
        ContentWorkflowCapability.createEdit,
        ContentWorkflowCapability.persistence,
        ContentWorkflowCapability.importExport,
      },
      partial: {
        ContentWorkflowCapability.searchFilter,
        ContentWorkflowCapability.relations,
        ContentWorkflowCapability.validation,
        ContentWorkflowCapability.media,
        ContentWorkflowCapability.revisionHistory,
        ContentWorkflowCapability.collaboration,
      },
      nextAction: 'Satukan revisi, komentar, dan status validasi pada editor.',
      evidence: ['features/story', 'features/export'],
    ),
    _module(
      id: 'character',
      label: 'Character',
      description: 'Profil tokoh, mode karakter, relasi, dan moodboard.',
      maturity: ContentModuleMaturity.partial,
      available: {
        ContentWorkflowCapability.browse,
        ContentWorkflowCapability.createEdit,
        ContentWorkflowCapability.persistence,
        ContentWorkflowCapability.relations,
      },
      partial: {
        ContentWorkflowCapability.searchFilter,
        ContentWorkflowCapability.validation,
        ContentWorkflowCapability.media,
        ContentWorkflowCapability.revisionHistory,
        ContentWorkflowCapability.importExport,
      },
      nextAction: 'Hubungkan moodboard, lokasi, usia, dan histori canon ke UI.',
      evidence: ['features/character', 'features/character_mode'],
    ),
    _module(
      id: 'world',
      label: 'World & Locations',
      description:
          'Lokasi, lingkungan, simulasi dunia, dan perubahan temporal.',
      maturity: ContentModuleMaturity.partial,
      available: {
        ContentWorkflowCapability.browse,
        ContentWorkflowCapability.createEdit,
        ContentWorkflowCapability.persistence,
        ContentWorkflowCapability.relations,
        ContentWorkflowCapability.validation,
      },
      partial: {
        ContentWorkflowCapability.searchFilter,
        ContentWorkflowCapability.media,
        ContentWorkflowCapability.revisionHistory,
        ContentWorkflowCapability.importExport,
      },
      nextAction:
          'Satukan editor lokasi dengan temporal map dan simulation feed.',
      evidence: [
        'features/world',
        'features/environment',
        'features/world_logic',
      ],
    ),
    _module(
      id: 'bible',
      label: 'Project Bible & Lore',
      description:
          'Canon, lore, faction, timeline, backlink, dan konflik fakta.',
      maturity: ContentModuleMaturity.partial,
      available: {
        ContentWorkflowCapability.browse,
        ContentWorkflowCapability.createEdit,
        ContentWorkflowCapability.persistence,
        ContentWorkflowCapability.searchFilter,
        ContentWorkflowCapability.relations,
        ContentWorkflowCapability.validation,
      },
      partial: {
        ContentWorkflowCapability.media,
        ContentWorkflowCapability.revisionHistory,
        ContentWorkflowCapability.importExport,
        ContentWorkflowCapability.collaboration,
      },
      nextAction:
          'Tampilkan provenance, confidence, dan resolusi konflik canon.',
      evidence: ['features/bible', 'features/lore'],
    ),
    _module(
      id: 'timeline',
      label: 'Timeline & Events',
      description: 'Track waktu, event cerita, dan sinkronisasi urutan plot.',
      maturity: ContentModuleMaturity.partial,
      available: {
        ContentWorkflowCapability.browse,
        ContentWorkflowCapability.createEdit,
        ContentWorkflowCapability.persistence,
      },
      partial: {
        ContentWorkflowCapability.searchFilter,
        ContentWorkflowCapability.relations,
        ContentWorkflowCapability.validation,
        ContentWorkflowCapability.revisionHistory,
        ContentWorkflowCapability.importExport,
      },
      nextAction: 'Hubungkan event dengan karakter, lokasi, dan cabang dunia.',
      evidence: ['features/timeline', 'features/plot'],
    ),
    _module(
      id: 'assets',
      label: 'Assets & References',
      description:
          'Aset proyek, referensi visual, perbandingan, dan relasi file.',
      maturity: ContentModuleMaturity.partial,
      available: {
        ContentWorkflowCapability.browse,
        ContentWorkflowCapability.persistence,
        ContentWorkflowCapability.searchFilter,
        ContentWorkflowCapability.relations,
        ContentWorkflowCapability.media,
        ContentWorkflowCapability.importExport,
      },
      partial: {
        ContentWorkflowCapability.createEdit,
        ContentWorkflowCapability.validation,
        ContentWorkflowCapability.revisionHistory,
        ContentWorkflowCapability.collaboration,
      },
      nextAction:
          'Tambahkan versioning aset dan pemeriksaan file hilang terpadu.',
      evidence: ['features/assets', 'features/references'],
    ),
    _module(
      id: 'cinema',
      label: 'Cinema & Shots',
      description:
          'Shot, animatic, continuity, preview, dan production status.',
      maturity: ContentModuleMaturity.partial,
      available: {
        ContentWorkflowCapability.browse,
        ContentWorkflowCapability.createEdit,
        ContentWorkflowCapability.validation,
        ContentWorkflowCapability.media,
      },
      partial: {
        ContentWorkflowCapability.persistence,
        ContentWorkflowCapability.searchFilter,
        ContentWorkflowCapability.relations,
        ContentWorkflowCapability.revisionHistory,
        ContentWorkflowCapability.importExport,
        ContentWorkflowCapability.collaboration,
      },
      nextAction: 'Lengkapi persistence produksi dan relasi shot-ke-scene.',
      evidence: ['features/cinema', 'features/cinematic_production'],
    ),
    _module(
      id: 'audio',
      label: 'Audio, Music & SFX',
      description: 'Aset audio, import, timeline audio, dan metering.',
      maturity: ContentModuleMaturity.partial,
      available: {
        ContentWorkflowCapability.browse,
        ContentWorkflowCapability.persistence,
        ContentWorkflowCapability.media,
        ContentWorkflowCapability.importExport,
      },
      partial: {
        ContentWorkflowCapability.createEdit,
        ContentWorkflowCapability.searchFilter,
        ContentWorkflowCapability.relations,
        ContentWorkflowCapability.validation,
      },
      nextAction:
          'Satukan library, timeline, metadata lisensi, dan scene binding.',
      evidence: [
        'features/audio',
        'features/audio_import',
        'features/audio_timeline',
      ],
    ),
    _module(
      id: 'ai-output',
      label: 'AI Generation Outputs',
      description: 'Queue generasi, gallery, provider, dan hasil tersimpan.',
      maturity: ContentModuleMaturity.partial,
      available: {
        ContentWorkflowCapability.browse,
        ContentWorkflowCapability.createEdit,
        ContentWorkflowCapability.persistence,
        ContentWorkflowCapability.media,
      },
      partial: {
        ContentWorkflowCapability.searchFilter,
        ContentWorkflowCapability.relations,
        ContentWorkflowCapability.validation,
        ContentWorkflowCapability.revisionHistory,
        ContentWorkflowCapability.importExport,
      },
      nextAction:
          'Hubungkan provenance hasil AI dengan konten sumber dan lisensi.',
      evidence: ['features/ai'],
    ),
    _module(
      id: 'dialogue',
      label: 'Dialogue',
      description: 'Aturan suara, konsistensi dialog, dan repository dialog.',
      maturity: ContentModuleMaturity.domainOnly,
      available: {
        ContentWorkflowCapability.persistence,
        ContentWorkflowCapability.validation,
      },
      partial: {ContentWorkflowCapability.relations},
      nextAction: 'Bangun dialogue bank dan editor suara per karakter.',
      evidence: ['features/dialogue'],
    ),
    _module(
      id: 'plot-subplot',
      label: 'Plot, Subplot & Quest',
      description: 'Urutan plot, subplot, misi, dan konsekuensi cerita.',
      maturity: ContentModuleMaturity.domainOnly,
      available: {ContentWorkflowCapability.validation},
      partial: {
        ContentWorkflowCapability.browse,
        ContentWorkflowCapability.createEdit,
        ContentWorkflowCapability.relations,
      },
      nextAction:
          'Bangun board terpadu dengan dependency dan dangling-thread check.',
      evidence: [
        'features/plot',
        'features/subplot',
        'features/game/domain/quests.dart',
      ],
    ),
    _module(
      id: 'pacing-pov',
      label: 'Pacing & POV',
      description:
          'Analisis tensi, sudut pandang, dan batas pengetahuan tokoh.',
      maturity: ContentModuleMaturity.domainOnly,
      available: {ContentWorkflowCapability.validation},
      partial: {
        ContentWorkflowCapability.browse,
        ContentWorkflowCapability.relations,
      },
      nextAction:
          'Tambahkan heatmap pacing dan pemeriksaan POV di Writing Room.',
      evidence: ['features/pacing', 'features/pov'],
    ),
    _module(
      id: 'herbology-alchemy',
      label: 'Herbology & Alchemy',
      description: 'Ingredient, resep, efek, substitusi, dan konsistensi zat.',
      maturity: ContentModuleMaturity.domainOnly,
      available: {
        ContentWorkflowCapability.searchFilter,
        ContentWorkflowCapability.relations,
        ContentWorkflowCapability.validation,
      },
      partial: {
        ContentWorkflowCapability.persistence,
        ContentWorkflowCapability.revisionHistory,
      },
      nextAction: 'Bangun encyclopedia editor untuk bahan, efek, dan resep.',
      evidence: ['features/world_logic/domain/encyclopedia_alchemy.dart'],
    ),
    _module(
      id: 'economy-travel',
      label: 'Economy & Travel',
      description: 'Harga, inflasi, jarak, moda perjalanan, dan persediaan.',
      maturity: ContentModuleMaturity.domainOnly,
      available: {ContentWorkflowCapability.validation},
      partial: {
        ContentWorkflowCapability.searchFilter,
        ContentWorkflowCapability.relations,
      },
      nextAction:
          'Bangun kalkulator interaktif yang terhubung ke timeline dunia.',
      evidence: ['features/world_logic/domain/writer_economy_calculator.dart'],
    ),
    _module(
      id: 'culture-language',
      label: 'Culture, Language & Idioms',
      description: 'Conlang, grammar, nama budaya, kutipan, dan idiom lokal.',
      maturity: ContentModuleMaturity.domainOnly,
      available: {
        ContentWorkflowCapability.searchFilter,
        ContentWorkflowCapability.relations,
        ContentWorkflowCapability.validation,
      },
      partial: {
        ContentWorkflowCapability.persistence,
        ContentWorkflowCapability.revisionHistory,
      },
      nextAction:
          'Bangun kamus, idiom bank, dan generator nama berbasis budaya.',
      evidence: ['features/world/domain/conlang_grammar.dart'],
    ),
    _module(
      id: 'production-cards',
      label: 'Creature, Vehicle & Prop Cards',
      description:
          'Workspace presentasi generik untuk tiga jenis aset produksi.',
      maturity: ContentModuleMaturity.uiOnly,
      available: {
        ContentWorkflowCapability.browse,
        ContentWorkflowCapability.media,
      },
      partial: {ContentWorkflowCapability.createEdit},
      nextAction:
          'Ganti fallback statis dengan repository dan form per jenis aset.',
      evidence: ['features/production_assets/presentation'],
    ),
    _module(
      id: 'reader-annotations',
      label: 'Reader Annotations',
      description:
          'Catatan pembaca, highlight, dan diskusi yang disetujui penulis.',
      maturity: ContentModuleMaturity.planned,
      available: const {},
      partial: {
        ContentWorkflowCapability.relations,
        ContentWorkflowCapability.collaboration,
      },
      nextAction:
          'Definisikan consent penulis, moderation, dan ownership catatan.',
      evidence: ['Roadmap reader/creator boundary'],
    ),
  ]);

  static Map<ContentModuleMaturity, List<ContentModuleCapability>>
  get byMaturity {
    final result = <ContentModuleMaturity, List<ContentModuleCapability>>{
      for (final maturity in ContentModuleMaturity.values) maturity: [],
    };
    for (final module in modules) {
      result[module.maturity]!.add(module);
    }
    return UnmodifiableMapView({
      for (final entry in result.entries)
        entry.key: List.unmodifiable(entry.value),
    });
  }

  static List<ContentModuleCapability> search(String query) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) return modules;
    return modules
        .where((module) {
          final haystack = _normalize(
            [
              module.label,
              module.description,
              module.maturity.label,
              module.nextAction,
              ...module.workflowStates.keys.map((item) => item.label),
            ].join(' '),
          );
          return haystack.contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(' +'), ' ');
}

ContentModuleCapability _module({
  required String id,
  required String label,
  required String description,
  required ContentModuleMaturity maturity,
  required Set<ContentWorkflowCapability> available,
  required Set<ContentWorkflowCapability> partial,
  required String nextAction,
  required List<String> evidence,
}) {
  assert(available.intersection(partial).isEmpty);
  return ContentModuleCapability(
    id: id,
    label: label,
    description: description,
    maturity: maturity,
    workflowStates: UnmodifiableMapView({
      for (final capability in ContentWorkflowCapability.values)
        capability: available.contains(capability)
            ? ContentCapabilityState.available
            : partial.contains(capability)
            ? ContentCapabilityState.partial
            : ContentCapabilityState.missing,
    }),
    nextAction: nextAction,
    evidence: List.unmodifiable(evidence),
  );
}
