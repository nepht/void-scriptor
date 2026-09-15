// Sprint 111.37 — Unified Encyclopedia Search.
//
// Domain-only contract that searches every Wave 3 encyclopedia domain by
// name, alias, category, culture, region, time (tick), canon status, and
// spoiler clearance. Cross-domain query, deterministic OR/AND text
// semantics, aggregate facets, permission filtering (SpoilerPolicy 111.8 +
// canon allowlist), a keyboard navigation driver over the standard
// KeyboardNavigationMap (111.8), and an in-memory saved-search registry
// with a JSON round-trip contract.
//
// Consumes without duplicating: EncyclopediaRecord / EncyclopediaDomain /
// CanonStatus (111.6 shared_encyclopedia_schema.dart), ValidityRange
// (111.5 encyclopedia_scope.dart), SpoilerPolicy / SpoilerLevel /
// KeyboardShortcut / KeyboardNavigationMap (111.8
// encyclopedia_spoiler_accessibility.dart).
//
// No persistence, UI, locale, network, wall clock, or random input.
// saved_search is deliberately in-memory + JSON contract only: D-SCHEMA-01
// remains OPEN, so no Drift table is introduced here.

import 'package:void_scriptor/features/world_logic/domain/encyclopedia_scope.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_spoiler_accessibility.dart';
import 'package:void_scriptor/features/world_logic/domain/shared_encyclopedia_schema.dart';

/// Uncategorised bucket key used by facets when a record carries no
/// taxonomy category.
const String kUncategorizedFacetKey = 'uncategorized';

/// trim + lowercase + collapse internal whitespace runs to single spaces.
String _normalizeText(String raw) => raw
    .trim()
    .toLowerCase()
    .split(RegExp(r'\s+'))
    .where((t) => t.isNotEmpty)
    .join(' ');

String _normalizedToken(String raw, String field) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(raw, field, '$field cannot be empty');
  }
  return trimmed.toLowerCase();
}

Set<String> _normalizedIdSet(Iterable<String> raw, String field) {
  final out = <String>{};
  for (final value in raw) {
    out.add(_normalizedToken(value, field));
  }
  return out;
}

/// One searchable encyclopedia document: the canonical 111.6 record plus
/// the alias, culture, and spoiler facets the unified index needs to match
/// cross-domain queries. Aliases are normalized (trim + lowercase) and
/// deduplicated; empty aliases are rejected individually.
class EncyclopediaSearchDocument {
  EncyclopediaSearchDocument._({
    required this.record,
    required this.aliases,
    required this.cultureIds,
    required this.spoilerLevel,
    this.validity,
  });

  factory EncyclopediaSearchDocument.validated({
    required EncyclopediaRecord record,
    List<String> aliases = const [],
    List<String> cultureIds = const [],
    ValidityRange? validity,
    SpoilerLevel spoilerLevel = SpoilerLevel.safe,
  }) {
    final normalizedAliases = <String>[];
    for (final raw in aliases) {
      final token = _normalizedToken(raw, 'alias');
      if (!normalizedAliases.contains(token)) {
        normalizedAliases.add(token);
      }
    }
    final normalizedCultures = <String>[];
    for (final raw in cultureIds) {
      final token = _normalizedToken(raw, 'cultureId');
      if (!normalizedCultures.contains(token)) {
        normalizedCultures.add(token);
      }
    }
    final cleanedRegions = <String>[];
    for (final raw in record.scopeLocationIds) {
      final token = raw.trim().toLowerCase();
      if (token.isNotEmpty && !cleanedRegions.contains(token)) {
        cleanedRegions.add(token);
      }
    }
    final normalizedRecord = _listEq(record.scopeLocationIds, cleanedRegions)
        ? record
        : EncyclopediaRecord.validated(
            recordId: record.recordId,
            domain: record.domain,
            title: record.title,
            taxonomyCategoryId: record.taxonomyCategoryId,
            canonStatus: record.canonStatus,
            scopeLocations: cleanedRegions,
          );
    return EncyclopediaSearchDocument._(
      record: normalizedRecord,
      aliases: List.unmodifiable(normalizedAliases),
      cultureIds: List.unmodifiable(normalizedCultures),
      validity: validity,
      spoilerLevel: spoilerLevel,
    );
  }

  factory EncyclopediaSearchDocument.fromJson(Map<String, Object?> json) {
    final recordId = json['recordId'];
    if (recordId is! String) {
      throw ArgumentError.value(recordId, 'recordId', 'must be a string');
    }
    final title = json['title'];
    if (title is! String) {
      throw ArgumentError.value(title, 'title', 'must be a string');
    }
    final validityRaw = json['validity'];
    ValidityRange? validity;
    if (validityRaw is Map<Object?, Object?>) {
      final from = validityRaw['validFrom'];
      if (from is! int) {
        throw ArgumentError.value(from, 'validFrom', 'must be an int');
      }
      final until = validityRaw['validUntil'];
      if (until != null && until is! int) {
        throw ArgumentError.value(until, 'validUntil', 'must be an int');
      }
      validity = ValidityRange.validated(
        validFrom: from,
        validUntil: until as int?,
      );
    } else if (validityRaw != null) {
      throw ArgumentError.value(validityRaw, 'validity', 'must be an object');
    }
    return EncyclopediaSearchDocument.validated(
      record: EncyclopediaRecord.validated(
        recordId: recordId,
        domain: domainFromId(json['domainId']),
        title: title,
        taxonomyCategoryId: _optionalString(json['taxonomyCategoryId']),
        canonStatus: canonFromName(json['canonStatus']),
        scopeLocations: _stringList(
          json['scopeLocationIds'],
          'scopeLocationIds',
        ),
      ),
      aliases: _stringList(json['aliases'], 'aliases'),
      cultureIds: _stringList(json['cultureIds'], 'cultureIds'),
      validity: validity,
      spoilerLevel: spoilerFromName(json['spoilerLevel']),
    );
  }

  final EncyclopediaRecord record;
  final List<String> aliases;
  final List<String> cultureIds;
  final ValidityRange? validity;
  final SpoilerLevel spoilerLevel;

  String get recordId => record.recordId;
  String get title => record.title;
  EncyclopediaDomain get domain => record.domain;
  CanonStatus get canonStatus => record.canonStatus;
  String? get taxonomyCategoryId => record.taxonomyCategoryId;
  List<String> get regionIds => record.scopeLocationIds;

  bool get hasValidity => validity != null;

  Map<String, Object?> toJson() => <String, Object?>{
    'recordId': record.recordId,
    'domainId': record.domain.id,
    'title': record.title,
    'taxonomyCategoryId': record.taxonomyCategoryId,
    'canonStatus': record.canonStatus.name,
    'scopeLocationIds': List<String>.from(record.scopeLocationIds),
    'aliases': List<String>.from(aliases),
    'cultureIds': List<String>.from(cultureIds),
    'spoilerLevel': spoilerLevel.name,
    'validity': validity == null
        ? null
        : <String, Object?>{
            'validFrom': validity!.validFrom,
            'validUntil': validity!.validUntil,
          },
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EncyclopediaSearchDocument &&
          other.record == record &&
          _listEq(other.aliases, aliases) &&
          _listEq(other.cultureIds, cultureIds) &&
          other.validity == validity &&
          other.spoilerLevel == spoilerLevel);

  @override
  int get hashCode => Object.hash(
    record,
    Object.hashAll(aliases),
    Object.hashAll(cultureIds),
    validity,
    spoilerLevel,
  );

  @override
  String toString() =>
      'EncyclopediaSearchDocument($recordId, ${domain.id}, $title)';
}

bool _listEq(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

List<String> _stringList(Object? raw, String field) {
  if (raw == null) return const [];
  if (raw is! List) {
    throw ArgumentError.value(raw, field, 'must be a list');
  }
  return raw.map((e) {
    if (e is! String) {
      throw ArgumentError.value(e, field, 'entries must be strings');
    }
    return e;
  }).toList();
}

String? _optionalString(Object? raw) {
  if (raw == null) return null;
  if (raw is! String) {
    throw ArgumentError.value(raw, 'value', 'must be a string');
  }
  final trimmed = raw.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Reverse lookup for [EncyclopediaDomain.id]; throws [ArgumentError].
EncyclopediaDomain domainFromId(Object? raw) {
  final value = (raw ?? '').toString().trim().toLowerCase();
  for (final domain in EncyclopediaDomain.values) {
    if (domain.id == value) return domain;
  }
  throw ArgumentError.value(raw, 'domainId', 'unknown encyclopedia domain');
}

CanonStatus canonFromName(Object? raw) {
  final value = (raw ?? '').toString().trim().toLowerCase();
  for (final status in CanonStatus.values) {
    if (status.name == value) return status;
  }
  throw ArgumentError.value(raw, 'canonStatus', 'unknown canon status');
}

SpoilerLevel spoilerFromName(Object? raw) {
  final value = (raw ?? '').toString().trim().toLowerCase();
  for (final level in SpoilerLevel.values) {
    if (level.name == value) return level;
  }
  throw ArgumentError.value(raw, 'spoilerLevel', 'unknown spoiler level');
}

/// Unified search query across every domain. Set filters use
/// empty-set-means-no-restriction semantics; text matching is a
/// deterministic token scoring model (see [EncyclopediaSearchIndex]).
class EncyclopediaSearchQuery {
  EncyclopediaSearchQuery({
    String text = '',
    Set<EncyclopediaDomain> domains = const {},
    Set<String> categoryIds = const {},
    Set<String> cultureIds = const {},
    Set<String> regionIds = const {},
    Set<CanonStatus> canonStatuses = const {},
    this.atTick,
    this.requireAllTerms = false,
    this.limit = EncyclopediaSearchQuery.maxLimit,
  }) : text = _normalizeText(text),
       domains = Set.unmodifiable(domains),
       categoryIds = Set.unmodifiable(
         _normalizedIdSet(categoryIds, 'categoryId'),
       ),
       cultureIds = Set.unmodifiable(_normalizedIdSet(cultureIds, 'cultureId')),
       regionIds = Set.unmodifiable(_normalizedIdSet(regionIds, 'regionId')),
       canonStatuses = Set.unmodifiable(canonStatuses) {
    if (limit < 1 || limit > maxLimit) {
      throw ArgumentError.value(
        limit,
        'limit',
        'limit must be between 1 and $maxLimit',
      );
    }
    if (atTick != null && atTick! < 0) {
      throw ArgumentError.value(atTick, 'atTick', 'atTick must be >= 0');
    }
    if (requireAllTerms && textTokens.isEmpty) {
      throw ArgumentError.value(
        text,
        'text',
        'requireAllTerms needs at least one text token',
      );
    }
  }

  factory EncyclopediaSearchQuery.fromJson(Map<String, Object?> json) {
    final text = json['text'];
    if (text != null && text is! String) {
      throw ArgumentError.value(text, 'text', 'must be a string');
    }
    final rawDomains = json['domains'];
    if (rawDomains != null && rawDomains is! List) {
      throw ArgumentError.value(rawDomains, 'domains', 'must be a list');
    }
    final rawCanon = json['canonStatuses'];
    if (rawCanon != null && rawCanon is! List) {
      throw ArgumentError.value(rawCanon, 'canonStatuses', 'must be a list');
    }
    final atTick = json['atTick'];
    if (atTick != null && atTick is! int) {
      throw ArgumentError.value(atTick, 'atTick', 'must be an int');
    }
    final limit = json['limit'];
    if (limit != null && limit is! int) {
      throw ArgumentError.value(limit, 'limit', 'must be an int');
    }
    final requireAll = json['requireAllTerms'] ?? false;
    if (requireAll is! bool) {
      throw ArgumentError.value(
        requireAll,
        'requireAllTerms',
        'must be a bool',
      );
    }
    final query = EncyclopediaSearchQuery(
      text: (text as String?) ?? '',
      domains: {
        for (final raw in rawDomains as List<Object?>? ?? const [])
          domainFromId(raw),
      },
      categoryIds: _normalizedIdSet(
        _stringList(json['categoryIds'], 'categoryIds'),
        'categoryId',
      ),
      cultureIds: _normalizedIdSet(
        _stringList(json['cultureIds'], 'cultureIds'),
        'cultureId',
      ),
      regionIds: _normalizedIdSet(
        _stringList(json['regionIds'], 'regionIds'),
        'regionId',
      ),
      canonStatuses: {
        for (final raw in rawCanon as List<Object?>? ?? const [])
          canonFromName(raw),
      },
      atTick: atTick as int?,
      requireAllTerms: requireAll,
      limit: (limit as int?) ?? maxLimit,
    );
    return query;
  }

  static const int maxLimit = 512;

  final String text;
  final Set<EncyclopediaDomain> domains;
  final Set<String> categoryIds;
  final Set<String> cultureIds;
  final Set<String> regionIds;
  final Set<CanonStatus> canonStatuses;
  final int? atTick;
  final bool requireAllTerms;
  final int limit;

  /// Lowercased whitespace-separated tokens of [text], in order.
  List<String> get textTokens =>
      text.split(' ').where((t) => t.isNotEmpty).toList();

  bool get isEmpty => text.trim().isEmpty && !hasFilters;

  bool get hasFilters =>
      domains.isNotEmpty ||
      categoryIds.isNotEmpty ||
      cultureIds.isNotEmpty ||
      regionIds.isNotEmpty ||
      canonStatuses.isNotEmpty ||
      atTick != null;

  Map<String, Object?> toJson() => <String, Object?>{
    'text': text,
    'domains': domains.map((d) => d.id).toList()..sort(),
    'categoryIds': categoryIds.toList()..sort(),
    'cultureIds': cultureIds.toList()..sort(),
    'regionIds': regionIds.toList()..sort(),
    'canonStatuses': canonStatuses.map((c) => c.name).toList()..sort(),
    'atTick': atTick,
    'requireAllTerms': requireAllTerms,
    'limit': limit,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EncyclopediaSearchQuery &&
          other.text == text &&
          _setEq<EncyclopediaDomain>(other.domains, domains) &&
          _setEq<String>(other.categoryIds, categoryIds) &&
          _setEq<String>(other.cultureIds, cultureIds) &&
          _setEq<String>(other.regionIds, regionIds) &&
          _setEq<CanonStatus>(other.canonStatuses, canonStatuses) &&
          other.atTick == atTick &&
          other.requireAllTerms == requireAllTerms &&
          other.limit == limit);

  @override
  int get hashCode => Object.hash(
    text,
    Object.hashAllUnordered(domains),
    Object.hashAllUnordered(categoryIds),
    Object.hashAllUnordered(cultureIds),
    Object.hashAllUnordered(regionIds),
    Object.hashAllUnordered(canonStatuses),
    atTick,
    requireAllTerms,
    limit,
  );

  @override
  String toString() =>
      'EncyclopediaSearchQuery(text: "$text", filters: $hasFilters, limit: $limit)';
}

bool _setEq<T>(Set<T> a, Set<T> b) {
  if (a.length != b.length) return false;
  return a.containsAll(b);
}

/// Facet counts over a set of permission-cleared search matches. Every map
/// is sorted by key and unmodifiable; serialization is byte-stable.
class EncyclopediaSearchFacets {
  EncyclopediaSearchFacets._({
    required this.totalCount,
    required Map<String, int> byDomain,
    required Map<String, int> byCategory,
    required Map<String, int> byCanon,
    required Map<String, int> byCulture,
    required Map<String, int> byRegion,
  }) : byDomain = _sorted(byDomain),
       byCategory = _sorted(byCategory),
       byCanon = _sorted(byCanon),
       byCulture = _sorted(byCulture),
       byRegion = _sorted(byRegion);

  factory EncyclopediaSearchFacets.fromMatches(
    List<EncyclopediaSearchDocument> matches,
  ) {
    final byDomain = <String, int>{};
    final byCategory = <String, int>{};
    final byCanon = <String, int>{};
    final byCulture = <String, int>{};
    final byRegion = <String, int>{};
    for (final doc in matches) {
      byDomain.update(doc.domain.id, (v) => v + 1, ifAbsent: () => 1);
      byCategory.update(
        doc.taxonomyCategoryId ?? kUncategorizedFacetKey,
        (v) => v + 1,
        ifAbsent: () => 1,
      );
      byCanon.update(doc.canonStatus.name, (v) => v + 1, ifAbsent: () => 1);
      for (final culture in doc.cultureIds) {
        byCulture.update(culture, (v) => v + 1, ifAbsent: () => 1);
      }
      for (final region in doc.regionIds) {
        byRegion.update(region, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    return EncyclopediaSearchFacets._(
      totalCount: matches.length,
      byDomain: byDomain,
      byCategory: byCategory,
      byCanon: byCanon,
      byCulture: byCulture,
      byRegion: byRegion,
    );
  }

  factory EncyclopediaSearchFacets.fromJson(Map<String, Object?> json) {
    return EncyclopediaSearchFacets._(
      totalCount: _requireInt(json['totalCount'], 'totalCount'),
      byDomain: _countMap(json['byDomain'], 'byDomain'),
      byCategory: _countMap(json['byCategory'], 'byCategory'),
      byCanon: _countMap(json['byCanon'], 'byCanon'),
      byCulture: _countMap(json['byCulture'], 'byCulture'),
      byRegion: _countMap(json['byRegion'], 'byRegion'),
    );
  }

  final int totalCount;
  final Map<String, int> byDomain;
  final Map<String, int> byCategory;
  final Map<String, int> byCanon;
  final Map<String, int> byCulture;
  final Map<String, int> byRegion;

  bool get isEmpty => totalCount == 0;

  Map<String, Object?> toJson() => <String, Object?>{
    'totalCount': totalCount,
    'byDomain': byDomain,
    'byCategory': byCategory,
    'byCanon': byCanon,
    'byCulture': byCulture,
    'byRegion': byRegion,
  };

  String describe() {
    String facet(String label, Map<String, int> counts) {
      if (counts.isEmpty) return '$label=none';
      final entries = counts.entries
          .map((e) => '${e.key}:${e.value}')
          .join(',');
      return '$label=[$entries]';
    }

    return 'facets total=$totalCount '
        '${facet('domain', byDomain)} '
        '${facet('category', byCategory)} '
        '${facet('canon', byCanon)} '
        '${facet('culture', byCulture)} '
        '${facet('region', byRegion)}';
  }
}

int _requireInt(Object? raw, String field) {
  if (raw is! int) {
    throw ArgumentError.value(raw, field, 'must be an int');
  }
  return raw;
}

Map<String, int> _countMap(Object? raw, String field) {
  if (raw == null) return const {};
  if (raw is! Map) {
    throw ArgumentError.value(raw, field, 'must be an object');
  }
  final out = <String, int>{};
  raw.forEach((key, value) {
    if (key is! String || value is! int) {
      throw ArgumentError.value(raw, field, 'entries must be string->int');
    }
    out[key] = value;
  });
  return out;
}

Map<String, int> _sorted(Map<String, int> counts) {
  final keys = counts.keys.toList()..sort();
  return Map.unmodifiable(<String, int>{
    for (final key in keys) key: counts[key]!,
  });
}

/// One scored search hit.
class EncyclopediaSearchHit {
  EncyclopediaSearchHit._({
    required this.document,
    required this.score,
    required this.matchedFields,
  });

  final EncyclopediaSearchDocument document;
  final int score;
  final List<String> matchedFields;

  String get recordId => document.recordId;

  Map<String, Object?> toJson() => <String, Object?>{
    'document': document.toJson(),
    'score': score,
    'matchedFields': List<String>.from(matchedFields),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EncyclopediaSearchHit &&
          other.document == document &&
          other.score == score &&
          _listEq(other.matchedFields, matchedFields));

  @override
  int get hashCode =>
      Object.hash(document, score, Object.hashAll(matchedFields));

  @override
  String toString() => 'EncyclopediaSearchHit($recordId, score $score)';
}

/// The full search report: permission-cleared matches, facets, and the
/// limit-truncated page of hits.
class EncyclopediaSearchReport {
  EncyclopediaSearchReport._({
    required this.query,
    required List<EncyclopediaSearchHit> hits,
    required this.totalMatches,
    required this.facets,
    required List<String> hiddenRecordIds,
  }) : hits = List.unmodifiable(hits),
       hiddenRecordIds = List.unmodifiable(hiddenRecordIds);

  final EncyclopediaSearchQuery query;
  final List<EncyclopediaSearchHit> hits;
  final int totalMatches;
  final EncyclopediaSearchFacets facets;

  /// Ids of documents that matched text/filters but were hidden by the
  /// permission filter. Presence of this list is itself a hint; the list
  /// only reveals ids, never titles or spoiler content.
  final List<String> hiddenRecordIds;

  bool get truncated => totalMatches > hits.length;

  bool get hasHiddenMatches => hiddenRecordIds.isNotEmpty;

  Map<String, Object?> toJson() => <String, Object?>{
    'query': query.toJson(),
    'hits': hits.map((h) => h.toJson()).toList(),
    'totalMatches': totalMatches,
    'facets': facets.toJson(),
    'hiddenRecordIds': List<String>.from(hiddenRecordIds),
  };

  String describe() {
    final buffer = StringBuffer()
      ..write('query="${query.text}"')
      ..write(' matches=$totalMatches shown=${hits.length}');
    if (truncated) buffer.write(' truncated');
    if (hasHiddenMatches) {
      buffer.write(' hidden=${hiddenRecordIds.length}');
    }
    return buffer.toString();
  }
}

/// Permission filter for unified search: a spoiler audience policy (111.8)
/// and an optional canon-status allowlist. A null policy or empty canon
/// set permits everything for that dimension.
class EncyclopediaPermissionFilter {
  const EncyclopediaPermissionFilter({
    this.spoilerPolicy,
    this.allowedCanonStatuses = const {},
  });

  factory EncyclopediaPermissionFilter.allowAll() =>
      const EncyclopediaPermissionFilter();

  factory EncyclopediaPermissionFilter.fromJson(Map<String, Object?> json) {
    final defaultLevel = json['defaultSpoiler'];
    final overrides = json['spoilerOverrides'];
    SpoilerPolicy? policy;
    if (defaultLevel != null || overrides != null) {
      policy = SpoilerPolicy(
        defaultLevel: defaultLevel == null
            ? SpoilerLevel.safe
            : spoilerFromName(defaultLevel),
        overrides: {
          for (final entry
              in (overrides as Map<Object?, Object?>? ?? const {}).entries)
            _normalizedToken(entry.key.toString(), 'spoilerOverride key'):
                spoilerFromName(entry.value),
        },
      );
    }
    final rawCanon = json['allowedCanonStatuses'];
    if (rawCanon != null && rawCanon is! List) {
      throw ArgumentError.value(
        rawCanon,
        'allowedCanonStatuses',
        'must be a list',
      );
    }
    return EncyclopediaPermissionFilter(
      spoilerPolicy: policy,
      allowedCanonStatuses: Set.unmodifiable({
        for (final raw in rawCanon as List<Object?>? ?? const [])
          canonFromName(raw),
      }),
    );
  }

  final SpoilerPolicy? spoilerPolicy;
  final Set<CanonStatus> allowedCanonStatuses;

  bool permitsCanon(CanonStatus status) =>
      allowedCanonStatuses.isEmpty || allowedCanonStatuses.contains(status);

  bool permitsDocument(EncyclopediaSearchDocument document) {
    if (!permitsCanon(document.canonStatus)) return false;
    final policy = spoilerPolicy;
    if (policy == null) return true;
    return policy.allows(document.spoilerLevel, recordKey: document.recordId);
  }

  bool get allowsEverything =>
      spoilerPolicy == null && allowedCanonStatuses.isEmpty;

  Map<String, Object?> toJson() => <String, Object?>{
    'defaultSpoiler': spoilerPolicy?.defaultLevel.name,
    'spoilerOverrides': <String, String>{
      for (final entry in (spoilerPolicy?.overrides ?? const {}).entries)
        entry.key: entry.value.name,
    },
    'allowedCanonStatuses': allowedCanonStatuses.map((c) => c.name).toList()
      ..sort(),
  };

  String describe() {
    final policy = spoilerPolicy;
    final canonList = allowedCanonStatuses.isEmpty
        ? 'all'
        : (allowedCanonStatuses.map((c) => c.name).toList()..sort()).join(',');
    return 'permission default=${policy?.defaultLevel.name ?? "all"} canon=$canonList';
  }
}

/// Cross-domain, deterministic encyclopedia search index. Matching is
/// per-token scoring against title and alias fields:
/// exact == token -> 8, prefix -> 4, contains -> 2,
/// with an alias match worth half the title match (4/2/1). Documents with
/// zero-score tokens are excluded; default semantics are OR across tokens
/// (`requireAllTerms: true` switches to AND). Ordering is score desc, then
/// title length asc, then title asc, then recordId asc — never insertion
/// order or wall clock.
class EncyclopediaSearchIndex {
  EncyclopediaSearchIndex._(List<EncyclopediaSearchDocument> documents)
    : _documents = <String, EncyclopediaSearchDocument>{
        for (final doc in documents) doc.recordId: doc,
      };

  factory EncyclopediaSearchIndex.empty() =>
      EncyclopediaSearchIndex._(const []);

  factory EncyclopediaSearchIndex.withDocuments(
    List<EncyclopediaSearchDocument> documents,
  ) {
    final index = EncyclopediaSearchIndex._(const []);
    for (final doc in documents) {
      index.register(doc);
    }
    return index;
  }

  factory EncyclopediaSearchIndex.fromJson(Map<String, Object?> json) {
    final rawDocs = json['documents'];
    if (rawDocs != null && rawDocs is! List) {
      throw ArgumentError.value(rawDocs, 'documents', 'must be a list');
    }
    final index = EncyclopediaSearchIndex.empty();
    for (final raw in rawDocs as List<Object?>? ?? const []) {
      if (raw is! Map) {
        throw ArgumentError.value(raw, 'documents', 'entries must be objects');
      }
      index.register(
        EncyclopediaSearchDocument.fromJson(raw.cast<String, Object?>()),
      );
    }
    return index;
  }

  final Map<String, EncyclopediaSearchDocument> _documents;

  int get count => _documents.length;

  List<String> get recordIds => _documents.keys.toList()..sort();

  List<EncyclopediaSearchDocument> get documents =>
      List.unmodifiable(recordIds.map((id) => _documents[id]!));

  void register(EncyclopediaSearchDocument document) {
    final id = document.recordId;
    if (_documents.containsKey(id)) {
      throw StateError('duplicate recordId: $id');
    }
    _documents[id] = document;
  }

  EncyclopediaSearchDocument? documentFor(String recordId) =>
      _documents[recordId.trim()];

  Map<String, Object?> toJson() => <String, Object?>{
    'documents': documents.map((d) => d.toJson()).toList(),
  };

  /// Run [query] against every domain and apply [permission] last, so
  /// denied records never surface in hits, scores, facets, or totals.
  EncyclopediaSearchReport search(
    EncyclopediaSearchQuery query, {
    EncyclopediaPermissionFilter? permission,
  }) {
    final tokens = query.textTokens;
    if (query.requireAllTerms && tokens.isEmpty) {
      throw ArgumentError.value(
        query,
        'query',
        'requireAllTerms without text tokens cannot match',
      );
    }
    final scored = <EncyclopediaSearchHit>[];
    for (final document in documents) {
      if (!_passesFilters(document, query)) continue;
      final hit = _score(document, tokens);
      if (hit == null) continue;
      if (query.requireAllTerms) {
        final covered = hit.matchedFields.isEmpty
            ? <String>{}
            : _tokenizedUnion(document).keys.toSet();
        if (!tokens.every(covered.contains)) continue;
      }
      scored.add(hit);
    }
    final permissionFilter =
        permission ?? EncyclopediaPermissionFilter.allowAll();
    final cleared = <EncyclopediaSearchHit>[];
    final hidden = <String>[];
    for (final hit in scored) {
      if (permissionFilter.permitsDocument(hit.document)) {
        cleared.add(hit);
      } else {
        hidden.add(hit.recordId);
      }
    }
    final sorted = List<EncyclopediaSearchHit>.from(cleared)
      ..sort(_compareHits);
    final facets = EncyclopediaSearchFacets.fromMatches(
      cleared.map((h) => h.document).toList(),
    );
    return EncyclopediaSearchReport._(
      query: query,
      hits: sorted.take(query.limit).toList(),
      totalMatches: cleared.length,
      facets: facets,
      hiddenRecordIds: hidden..sort(),
    );
  }

  static int _compareHits(EncyclopediaSearchHit a, EncyclopediaSearchHit b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    final byLength = a.document.title.length.compareTo(b.document.title.length);
    if (byLength != 0) return byLength;
    final byTitle = a.document.title.compareTo(b.document.title);
    if (byTitle != 0) return byTitle;
    return a.recordId.compareTo(b.recordId);
  }

  bool _passesFilters(
    EncyclopediaSearchDocument document,
    EncyclopediaSearchQuery query,
  ) {
    if (query.domains.isNotEmpty && !query.domains.contains(document.domain)) {
      return false;
    }
    if (query.categoryIds.isNotEmpty) {
      final category = document.taxonomyCategoryId;
      if (category == null || !query.categoryIds.contains(category)) {
        return false;
      }
    }
    if (query.cultureIds.isNotEmpty &&
        !document.cultureIds.any(query.cultureIds.contains)) {
      return false;
    }
    if (query.regionIds.isNotEmpty &&
        !document.regionIds.any(query.regionIds.contains)) {
      return false;
    }
    if (query.canonStatuses.isNotEmpty &&
        !query.canonStatuses.contains(document.canonStatus)) {
      return false;
    }
    final tick = query.atTick;
    if (tick != null) {
      final validity = document.validity;
      if (validity != null && !validity.containsTick(tick)) return false;
    }
    return true;
  }

  EncyclopediaSearchHit? _score(
    EncyclopediaSearchDocument document,
    List<String> tokens,
  ) {
    if (tokens.isEmpty) {
      return EncyclopediaSearchHit._(
        document: document,
        score: 0,
        matchedFields: const [],
      );
    }
    final fields = _tokenizedUnion(document);
    var score = 0;
    final matchedFields = <String>{};
    for (final token in tokens) {
      final hit = fields[token];
      if (hit == null) continue;
      score += hit.score;
      matchedFields.add(hit.field);
    }
    if (score == 0) return null;
    return EncyclopediaSearchHit._(
      document: document,
      score: score,
      matchedFields: matchedFields.toList()..sort(),
    );
  }

  /// token -> best field match across title and aliases.
  Map<String, _FieldMatch> _tokenizedUnion(
    EncyclopediaSearchDocument document,
  ) {
    final byToken = <String, _FieldMatch>{};
    void offer(String token, _FieldMatch match) {
      final existing = byToken[token];
      if (existing == null || match.score > existing.score) {
        byToken[token] = match;
      }
    }

    for (final token in _tokensOf(document.title)) {
      offer(
        token,
        _FieldMatch(
          score: token == document.title.toLowerCase()
              ? 8
              : _prefixOrContains(token, document.title.toLowerCase()),
          field: 'title',
        ),
      );
    }
    for (final alias in document.aliases) {
      final raw = alias.toLowerCase();
      for (final token in _tokensOf(alias)) {
        final base = token == raw ? 4 : _prefixOrContains(token, raw) ~/ 2;
        offer(token, _FieldMatch(score: base < 1 ? 1 : base, field: 'alias'));
      }
    }
    return byToken;
  }

  static List<String> _tokensOf(String value) => value
      .trim()
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList();

  static int _prefixOrContains(String token, String fieldLower) {
    if (fieldLower.startsWith(token)) return 4;
    if (fieldLower.contains(token)) return 2;
    return 0;
  }
}

class _FieldMatch {
  const _FieldMatch({required this.score, required this.field});
  final int score;
  final String field;
}

/// Standard keyboard navigation contract over the 111.8
/// [KeyboardNavigationMap]. Bindings: Home=first, ArrowUp=previous,
/// ArrowDown=next, End=last. Selection clamps at both ends — no wrap —
/// so screen-reader position stays predictable.
class EncyclopediaKeyboardNavigation {
  EncyclopediaKeyboardNavigation({KeyboardNavigationMap? map})
    : map = map ?? EncyclopediaKeyboardNavigation.standardMap();

  static const String actionFirst = 'encyclopedia.search.first';
  static const String actionPrevious = 'encyclopedia.search.previous';
  static const String actionNext = 'encyclopedia.search.next';
  static const String actionLast = 'encyclopedia.search.last';

  final KeyboardNavigationMap map;

  static KeyboardNavigationMap standardMap() => KeyboardNavigationMap()
      .add(const KeyboardShortcut(action: actionFirst, key: 'Home'))
      .add(const KeyboardShortcut(action: actionPrevious, key: 'ArrowUp'))
      .add(const KeyboardShortcut(action: actionNext, key: 'ArrowDown'))
      .add(const KeyboardShortcut(action: actionLast, key: 'End'));

  /// Returns the selected index after applying [action] to a result list
  /// of [resultCount] items, or `null` when there is nothing to select.
  /// Throws [ArgumentError] for unknown actions or an out-of-range current
  /// selection, and [StateError] when the action has no binding in this
  /// map.
  int? selectedIndexFor(
    String action, {
    required int resultCount,
    required int selectedIndex,
  }) {
    if (resultCount < 0) {
      throw ArgumentError.value(
        resultCount,
        'resultCount',
        'must be non-negative',
      );
    }
    final knownActions = [actionFirst, actionPrevious, actionNext, actionLast];
    if (!knownActions.contains(action)) {
      throw ArgumentError.value(action, 'action', 'unknown navigation action');
    }
    if (map.bindingFor(action) == null) {
      throw StateError('navigation action not bound: $action');
    }
    if (resultCount == 0) return null;
    if (selectedIndex < 0 || selectedIndex >= resultCount) {
      throw ArgumentError.value(
        selectedIndex,
        'selectedIndex',
        'must be within [0, $resultCount)',
      );
    }
    switch (action) {
      case actionFirst:
        return 0;
      case actionPrevious:
        return selectedIndex > 0 ? selectedIndex - 1 : 0;
      case actionNext:
        return selectedIndex < resultCount - 1
            ? selectedIndex + 1
            : resultCount - 1;
      case actionLast:
        return resultCount - 1;
      default:
        throw ArgumentError.value(
          action,
          'action',
          'unknown navigation action',
        );
    }
  }
}

/// A named, persisted-by-contract (JSON only; D-SCHEMA-01 OPEN) saved
/// encyclopedia search.
class SavedEncyclopediaSearch {
  SavedEncyclopediaSearch._({
    required this.searchId,
    required this.label,
    required this.query,
  });

  factory SavedEncyclopediaSearch.validated({
    required String searchId,
    required String label,
    required EncyclopediaSearchQuery query,
  }) {
    return SavedEncyclopediaSearch._(
      searchId: _normalizedToken(searchId, 'searchId'),
      label: label.trim().isEmpty
          ? (throw ArgumentError.value(label, 'label', 'label cannot be empty'))
          : label.trim(),
      query: query,
    );
  }

  factory SavedEncyclopediaSearch.fromJson(Map<String, Object?> json) {
    final query = json['query'];
    if (query is! Map) {
      throw ArgumentError.value(query, 'query', 'must be an object');
    }
    return SavedEncyclopediaSearch.validated(
      searchId: json['searchId'] is String
          ? json['searchId'] as String
          : (throw ArgumentError.value(
              json['searchId'],
              'searchId',
              'must be a string',
            )),
      label: json['label'] is String
          ? json['label'] as String
          : (throw ArgumentError.value(
              json['label'],
              'label',
              'must be a string',
            )),
      query: EncyclopediaSearchQuery.fromJson(query.cast<String, Object?>()),
    );
  }

  final String searchId;
  final String label;
  final EncyclopediaSearchQuery query;

  Map<String, Object?> toJson() => <String, Object?>{
    'searchId': searchId,
    'label': label,
    'query': query.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedEncyclopediaSearch &&
          other.searchId == searchId &&
          other.label == label &&
          other.query == query);

  @override
  int get hashCode => Object.hash(searchId, label, query);

  @override
  String toString() => 'SavedEncyclopediaSearch($searchId, $label)';
}

/// In-memory registry of saved encyclopedia searches. Stable ordering is
/// by searchId ascending; duplicate ids are rejected on every mutation
/// path. No persistence layer is introduced (D-SCHEMA-01 remains OPEN).
class SavedSearchRegistry {
  SavedSearchRegistry._(List<SavedEncyclopediaSearch> entries)
    : _entries = <String, SavedEncyclopediaSearch>{
        for (final entry in entries) entry.searchId: entry,
      };

  factory SavedSearchRegistry.empty() => SavedSearchRegistry._(const []);

  factory SavedSearchRegistry.withEntries(
    List<SavedEncyclopediaSearch> entries,
  ) {
    final registry = SavedSearchRegistry._(const []);
    for (final entry in entries) {
      registry.add(entry);
    }
    return registry;
  }

  factory SavedSearchRegistry.fromJson(Map<String, Object?> json) {
    final rawEntries = json['entries'];
    if (rawEntries is! List) {
      throw ArgumentError.value(rawEntries, 'entries', 'must be a list');
    }
    final entries = <SavedEncyclopediaSearch>[];
    for (final raw in rawEntries) {
      if (raw is! Map) {
        throw ArgumentError.value(
          raw,
          'entries',
          'saved search entries must be objects',
        );
      }
      entries.add(
        SavedEncyclopediaSearch.fromJson(raw.cast<String, Object?>()),
      );
    }
    return SavedSearchRegistry.withEntries(entries);
  }

  final Map<String, SavedEncyclopediaSearch> _entries;

  int get count => _entries.length;

  List<SavedEncyclopediaSearch> get entries {
    final ids = _entries.keys.toList()..sort();
    return List.unmodifiable(ids.map((id) => _entries[id]!));
  }

  SavedEncyclopediaSearch? entryFor(String searchId) {
    final key = searchId.trim();
    return key.isEmpty ? null : _entries[key];
  }

  void add(SavedEncyclopediaSearch saved) {
    if (_entries.containsKey(saved.searchId)) {
      throw StateError('duplicate searchId: ${saved.searchId}');
    }
    _entries[saved.searchId] = saved;
  }

  bool remove(String searchId) => _entries.remove(searchId.trim()) != null;

  Map<String, Object?> toJson() => <String, Object?>{
    'entries': entries.map((e) => e.toJson()).toList(),
  };
}
