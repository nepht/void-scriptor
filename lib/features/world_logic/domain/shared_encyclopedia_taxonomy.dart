// Sprint 111.3 - Shared Encyclopedia Taxonomy.
//
// Domain-only contract covering controlled categories, free-form tags,
// aliases, localized names, cross-domain links, and taxonomy versioning.
// No persistence, UI, locale, network, wall clock, or random input.

library;

/// Controlled category for a Wave 3 encyclopedia domain.
class EncyclopediaCategory {
  const EncyclopediaCategory._({required this.id, required this.label});

  factory EncyclopediaCategory.validated({
    required String id,
    required String label,
  }) {
    final normalizedId = _normalizeId(id);
    final trimmedLabel = label.trim();
    if (normalizedId.isEmpty) {
      throw ArgumentError.value(id, 'id', 'category id cannot be empty');
    }
    if (trimmedLabel.isEmpty) {
      throw ArgumentError.value(
        label,
        'label',
        'category label cannot be empty',
      );
    }
    return EncyclopediaCategory._(id: normalizedId, label: trimmedLabel);
  }

  final String id;
  final String label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EncyclopediaCategory && other.id == id && other.label == label);

  @override
  int get hashCode => Object.hash(id, label);

  @override
  String toString() => 'EncyclopediaCategory($id, $label)';
}

/// Free-form tag attached to any encyclopedia record.
class EncyclopediaTag {
  const EncyclopediaTag._(this.value);

  factory EncyclopediaTag.validated(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) {
      throw ArgumentError.value(raw, 'raw', 'tag cannot be empty');
    }
    return EncyclopediaTag._(normalized);
  }

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EncyclopediaTag && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'EncyclopediaTag($value)';
}

/// Alias for a category-scoped label (common name, scientific name, etc.).
class EncyclopediaAlias {
  const EncyclopediaAlias._({required this.alias, required this.categoryId});

  factory EncyclopediaAlias.validated({
    required String alias,
    required String categoryId,
  }) {
    final trimmedAlias = alias.trim();
    final normalizedCategoryId = _normalizeId(categoryId);
    if (trimmedAlias.isEmpty) {
      throw ArgumentError.value(alias, 'alias', 'alias cannot be empty');
    }
    if (normalizedCategoryId.isEmpty) {
      throw ArgumentError.value(
        categoryId,
        'categoryId',
        'categoryId cannot be empty',
      );
    }
    return EncyclopediaAlias._(
      alias: trimmedAlias,
      categoryId: normalizedCategoryId,
    );
  }

  final String alias;
  final String categoryId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EncyclopediaAlias &&
          other.alias == alias &&
          other.categoryId == categoryId);

  @override
  int get hashCode => Object.hash(alias, categoryId);

  @override
  String toString() => 'EncyclopediaAlias($alias -> $categoryId)';
}

/// Locale-scoped display name with optional original-script notation.
class LocalizedName {
  const LocalizedName._({
    required this.locale,
    required this.displayName,
    this.originalScript,
  });

  factory LocalizedName.validated({
    required String locale,
    required String displayName,
    String? originalScript,
  }) {
    final trimmedLocale = locale.trim();
    final trimmedName = displayName.trim();
    if (trimmedLocale.isEmpty) {
      throw ArgumentError.value(locale, 'locale', 'locale cannot be empty');
    }
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(
        displayName,
        'displayName',
        'displayName cannot be empty',
      );
    }
    final script = originalScript?.trim();
    if (script != null && script.isEmpty) {
      throw ArgumentError.value(
        originalScript,
        'originalScript',
        'originalScript cannot be empty when provided',
      );
    }
    return LocalizedName._(
      locale: trimmedLocale,
      displayName: trimmedName,
      originalScript: script,
    );
  }

  final String locale;
  final String displayName;
  final String? originalScript;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalizedName &&
          other.locale == locale &&
          other.displayName == displayName &&
          other.originalScript == originalScript);

  @override
  int get hashCode => Object.hash(locale, displayName, originalScript);

  @override
  String toString() =>
      'LocalizedName($locale: $displayName${originalScript == null ? '' : ' ($originalScript)'})';
}

/// Kind of relationship that can connect two entries in different domains.
enum CrossDomainLinkKind {
  symbiotic,
  derivedFrom,
  antagonist,
  references,
  composes,
  custom,
}

/// Cross-domain link between two entries in different categories.
class EncyclopediaCrossDomainLink {
  const EncyclopediaCrossDomainLink._({
    required this.fromCategoryId,
    required this.fromEntryId,
    required this.toCategoryId,
    required this.toEntryId,
    required this.linkKind,
  });

  factory EncyclopediaCrossDomainLink.validated({
    required String fromCategoryId,
    required String fromEntryId,
    required String toCategoryId,
    required String toEntryId,
    required CrossDomainLinkKind linkKind,
  }) {
    final fromCat = _normalizeId(fromCategoryId);
    final fromId = fromEntryId.trim();
    final toCat = _normalizeId(toCategoryId);
    final toId = toEntryId.trim();
    if (fromCat.isEmpty) {
      throw ArgumentError.value(
        fromCategoryId,
        'fromCategoryId',
        'fromCategoryId cannot be empty',
      );
    }
    if (fromId.isEmpty) {
      throw ArgumentError.value(
        fromEntryId,
        'fromEntryId',
        'fromEntryId cannot be empty',
      );
    }
    if (toCat.isEmpty) {
      throw ArgumentError.value(
        toCategoryId,
        'toCategoryId',
        'toCategoryId cannot be empty',
      );
    }
    if (toId.isEmpty) {
      throw ArgumentError.value(
        toEntryId,
        'toEntryId',
        'toEntryId cannot be empty',
      );
    }
    if (fromCat == toCat) {
      throw ArgumentError(
        "cross-domain link requires different categories (got \"$fromCat\")",
      );
    }
    return EncyclopediaCrossDomainLink._(
      fromCategoryId: fromCat,
      fromEntryId: fromId,
      toCategoryId: toCat,
      toEntryId: toId,
      linkKind: linkKind,
    );
  }

  final String fromCategoryId;
  final String fromEntryId;
  final String toCategoryId;
  final String toEntryId;
  final CrossDomainLinkKind linkKind;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EncyclopediaCrossDomainLink &&
          other.fromCategoryId == fromCategoryId &&
          other.fromEntryId == fromEntryId &&
          other.toCategoryId == toCategoryId &&
          other.toEntryId == toEntryId &&
          other.linkKind == linkKind);

  @override
  int get hashCode => Object.hash(
    fromCategoryId,
    fromEntryId,
    toCategoryId,
    toEntryId,
    linkKind,
  );

  @override
  String toString() =>
      'EncyclopediaCrossDomainLink($fromCategoryId:$fromEntryId -> $toCategoryId:$toEntryId [$linkKind])';
}

/// Semantic version for the Wave 3 encyclopedia taxonomy.
class TaxonomyVersion {
  const TaxonomyVersion({required this.major, required this.minor});

  const TaxonomyVersion.initial() : major = 1, minor = 0;

  final int major;
  final int minor;

  TaxonomyVersion bumpMinor() =>
      TaxonomyVersion(major: major, minor: minor + 1);

  TaxonomyVersion bumpMajor() => TaxonomyVersion(major: major + 1, minor: 0);

  bool isAtLeast(TaxonomyVersion other) {
    if (major != other.major) return major > other.major;
    return minor >= other.minor;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaxonomyVersion &&
          other.major == major &&
          other.minor == minor);

  @override
  int get hashCode => Object.hash(major, minor);

  @override
  String toString() => 'TaxonomyVersion($major.$minor)';
}

/// Entry within a controlled encyclopedia category.
class EncyclopediaEntry {
  const EncyclopediaEntry._({
    required this.id,
    required this.categoryId,
    required this.displayName,
  });

  factory EncyclopediaEntry.validated({
    required String id,
    required String categoryId,
    required String displayName,
  }) {
    final normalizedId = _normalizeId(id);
    final normalizedCategoryId = _normalizeId(categoryId);
    final trimmedName = displayName.trim();
    if (normalizedId.isEmpty) {
      throw ArgumentError.value(id, 'id', 'entry id cannot be empty');
    }
    if (normalizedCategoryId.isEmpty) {
      throw ArgumentError.value(
        categoryId,
        'categoryId',
        'categoryId cannot be empty',
      );
    }
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(
        displayName,
        'displayName',
        'displayName cannot be empty',
      );
    }
    return EncyclopediaEntry._(
      id: normalizedId,
      categoryId: normalizedCategoryId,
      displayName: trimmedName,
    );
  }

  final String id;
  final String categoryId;
  final String displayName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EncyclopediaEntry &&
          other.id == id &&
          other.categoryId == categoryId &&
          other.displayName == displayName);

  @override
  int get hashCode => Object.hash(id, categoryId, displayName);

  @override
  String toString() => 'EncyclopediaEntry($id in $categoryId, $displayName)';
}

/// Registry aggregating categories, tags, entries, aliases, and links
/// under a versioned taxonomy. Mutations track every version bump so
/// projects can attribute taxonomy changes to canonical contracts.
class EncyclopediaTaxonomy {
  EncyclopediaTaxonomy()
    : _categories = <String, EncyclopediaCategory>{},
      _tags = <String, EncyclopediaTag>{},
      _aliases = <EncyclopediaAlias, bool>{},
      _entries = <String, EncyclopediaEntry>{},
      _links = <EncyclopediaCrossDomainLink, bool>{},
      _currentVersion = const TaxonomyVersion.initial(),
      _history = <TaxonomyVersion>[const TaxonomyVersion.initial()];

  final Map<String, EncyclopediaCategory> _categories;
  final Map<String, EncyclopediaTag> _tags;
  final Map<EncyclopediaAlias, bool> _aliases;
  final Map<String, EncyclopediaEntry> _entries;
  final Map<EncyclopediaCrossDomainLink, bool> _links;
  TaxonomyVersion _currentVersion;
  final List<TaxonomyVersion> _history;

  TaxonomyVersion get currentVersion => _currentVersion;
  List<TaxonomyVersion> get history => List.unmodifiable(_history);
  Iterable<EncyclopediaCategory> get categories => _categories.values;
  Iterable<EncyclopediaTag> get tags => _tags.values;
  Iterable<EncyclopediaAlias> get aliases => _aliases.keys;
  Iterable<EncyclopediaEntry> get entries => _entries.values;
  Iterable<EncyclopediaCrossDomainLink> get links => _links.keys;

  void addCategory(EncyclopediaCategory category) {
    if (_categories.containsKey(category.id)) {
      throw StateError('category id already registered: ${category.id}');
    }
    _categories[category.id] = category;
  }

  void addTag(EncyclopediaTag tag) {
    if (_tags.containsKey(tag.value)) return;
    _tags[tag.value] = tag;
  }

  void addAlias(EncyclopediaAlias alias) {
    if (!_categories.containsKey(alias.categoryId)) {
      throw StateError(
        'alias references unknown category: ${alias.categoryId}',
      );
    }
    _aliases[alias] = true;
  }

  void addEntry(EncyclopediaEntry entry) {
    if (!_categories.containsKey(entry.categoryId)) {
      throw StateError(
        'entry references unknown category: ${entry.categoryId}',
      );
    }
    _entries['${entry.categoryId}::${entry.id}'] = entry;
  }

  void addLink(EncyclopediaCrossDomainLink link) {
    if (!_categories.containsKey(link.fromCategoryId)) {
      throw StateError(
        'link references unknown fromCategory: ${link.fromCategoryId}',
      );
    }
    if (!_categories.containsKey(link.toCategoryId)) {
      throw StateError(
        'link references unknown toCategory: ${link.toCategoryId}',
      );
    }
    final fromKey = '${link.fromCategoryId}::${link.fromEntryId}';
    final toKey = '${link.toCategoryId}::${link.toEntryId}';
    if (!_entries.containsKey(fromKey)) {
      throw StateError('link references unknown fromEntry: $fromKey');
    }
    if (!_entries.containsKey(toKey)) {
      throw StateError('link references unknown toEntry: $toKey');
    }
    _links[link] = true;
  }

  void bumpMinor() {
    _currentVersion = _currentVersion.bumpMinor();
    _history.add(_currentVersion);
  }

  void bumpMajor() {
    _currentVersion = _currentVersion.bumpMajor();
    _history.add(_currentVersion);
  }
}

String _normalizeId(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  return trimmed.toLowerCase();
}
