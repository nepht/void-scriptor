// Sprint 111.9 - Ingredient and Substance Catalog.
//
// Domain-only contract for ingredient/substance records: typed ingredient
// categories, parts used from a source, local variants, aliases, media
// attachments, and source links.
//
// No persistence, UI, locale, network, wall clock, or random input.
library;

/// Category of an ingredient or substance. Flora, fauna, and mineral cover
/// harvested natural sources; `zat` covers purified chemical substances;
/// `synthetic` covers manufactured compounds; `other` is the escape hatch
/// for any future category without breaking existing records.
enum IngredientType {
  flora('Flora'),
  fauna('Fauna'),
  mineral('Mineral'),
  zat('Zat'),
  synthetic('Synthetic'),
  other('Other');

  const IngredientType(this.label);

  final String label;
}

String _requireTrimmed(String value, String fieldName) {
  if (value.trim().isEmpty) {
    throw ArgumentError('$fieldName must be non-empty');
  }
  return value.trim();
}

/// A part of a source organism or material used as an ingredient, for
/// example petal, root, scale, ore, or distilled essence.
class IngredientPart {
  const IngredientPart._({required this.partId, required this.name});

  factory IngredientPart.validated({
    required String partId,
    required String name,
  }) {
    return IngredientPart._(
      partId: _requireTrimmed(partId, 'partId'),
      name: _requireTrimmed(name, 'name'),
    );
  }

  final String partId;
  final String name;
}

/// A regional or local variant of an ingredient with a distinct description.
class LocalVariant {
  const LocalVariant._({
    required this.variantId,
    required this.region,
    required this.description,
  });

  factory LocalVariant.validated({
    required String variantId,
    required String region,
    required String description,
  }) {
    return LocalVariant._(
      variantId: _requireTrimmed(variantId, 'variantId'),
      region: _requireTrimmed(region, 'region'),
      description: _requireTrimmed(description, 'description'),
    );
  }

  final String variantId;
  final String region;
  final String description;
}

/// An alternate name for an ingredient, optionally scoped to a language or
/// culture.
class IngredientAlias {
  const IngredientAlias._({required this.alias, this.language});

  factory IngredientAlias.validated({required String alias, String? language}) {
    final trimmed = _requireTrimmed(alias, 'alias');
    final trimmedLanguage = language?.trim();
    if (trimmedLanguage != null && trimmedLanguage.isEmpty) {
      throw ArgumentError('language must be non-empty when provided');
    }
    return IngredientAlias._(alias: trimmed, language: trimmedLanguage);
  }

  final String alias;
  final String? language;
}

/// A reference to a media asset attached to an ingredient record.
class IngredientMediaLink {
  const IngredientMediaLink._({required this.mediaId, this.caption});

  factory IngredientMediaLink.validated({
    required String mediaId,
    String? caption,
  }) {
    final trimmedCaption = caption?.trim();
    if (trimmedCaption != null && trimmedCaption.isEmpty) {
      throw ArgumentError('caption must be non-empty when provided');
    }
    return IngredientMediaLink._(
      mediaId: _requireTrimmed(mediaId, 'mediaId'),
      caption: trimmedCaption,
    );
  }

  final String mediaId;
  final String? caption;
}

/// A reference to an external or in-project source for an ingredient record.
class IngredientSourceLink {
  const IngredientSourceLink._({required this.sourceId, this.note});

  factory IngredientSourceLink.validated({
    required String sourceId,
    String? note,
  }) {
    final trimmedNote = note?.trim();
    if (trimmedNote != null && trimmedNote.isEmpty) {
      throw ArgumentError('note must be non-empty when provided');
    }
    return IngredientSourceLink._(
      sourceId: _requireTrimmed(sourceId, 'sourceId'),
      note: trimmedNote,
    );
  }

  final String sourceId;
  final String? note;
}

/// An immutable ingredient/substance catalog record. Optional collections
/// are guarded against duplicate identity keys so a record stays clean for
/// downstream persistence and search.
class IngredientRecord {
  const IngredientRecord._({
    required this.ingredientId,
    required this.name,
    required this.type,
    required this.parts,
    required this.variants,
    required this.aliases,
    required this.mediaLinks,
    required this.sourceLinks,
  });

  factory IngredientRecord.validated({
    required String ingredientId,
    required String name,
    required IngredientType type,
    List<IngredientPart> parts = const [],
    List<LocalVariant> variants = const [],
    List<IngredientAlias> aliases = const [],
    List<IngredientMediaLink> mediaLinks = const [],
    List<IngredientSourceLink> sourceLinks = const [],
  }) {
    final ids = <String, String>{};
    for (final part in parts) {
      if (ids.containsKey(part.partId)) {
        throw ArgumentError('duplicate partId: ${part.partId}');
      }
      ids[part.partId] = part.partId;
    }
    final variantIds = <String, String>{};
    for (final variant in variants) {
      if (variantIds.containsKey(variant.variantId)) {
        throw ArgumentError('duplicate variantId: ${variant.variantId}');
      }
      variantIds[variant.variantId] = variant.variantId;
    }
    final aliasValues = <String, String>{};
    for (final alias in aliases) {
      if (aliasValues.containsKey(alias.alias)) {
        throw ArgumentError('duplicate alias: ${alias.alias}');
      }
      aliasValues[alias.alias] = alias.alias;
    }
    final mediaIds = <String, String>{};
    for (final media in mediaLinks) {
      if (mediaIds.containsKey(media.mediaId)) {
        throw ArgumentError('duplicate mediaId: ${media.mediaId}');
      }
      mediaIds[media.mediaId] = media.mediaId;
    }
    final sourceIds = <String, String>{};
    for (final source in sourceLinks) {
      if (sourceIds.containsKey(source.sourceId)) {
        throw ArgumentError('duplicate sourceId: ${source.sourceId}');
      }
      sourceIds[source.sourceId] = source.sourceId;
    }
    return IngredientRecord._(
      ingredientId: _requireTrimmed(ingredientId, 'ingredientId'),
      name: _requireTrimmed(name, 'name'),
      type: type,
      parts: List.unmodifiable(parts),
      variants: List.unmodifiable(variants),
      aliases: List.unmodifiable(aliases),
      mediaLinks: List.unmodifiable(mediaLinks),
      sourceLinks: List.unmodifiable(sourceLinks),
    );
  }

  final String ingredientId;
  final String name;
  final IngredientType type;
  final List<IngredientPart> parts;
  final List<LocalVariant> variants;
  final List<IngredientAlias> aliases;
  final List<IngredientMediaLink> mediaLinks;
  final List<IngredientSourceLink> sourceLinks;
}
