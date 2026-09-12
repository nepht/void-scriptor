import 'dart:convert';

/// Evidence tag attached to every proposed trait value.
enum TraitEvidenceTag { explicit, inferred }

/// One chapter-anchored quote backing a proposal.
class TraitCitation {
  const TraitCitation({required this.chapter, required this.quote});
  final int chapter;
  final String quote;
}

/// A single proposed field value with its citations and evidence tag.
class TraitProposal {
  const TraitProposal({
    required this.field,
    required this.value,
    required this.tag,
    required this.citations,
  });
  final String field;
  final String value;
  final TraitEvidenceTag tag;
  final List<TraitCitation> citations;
}

/// Whole parsed proposal set: field proposals plus honestly-unknown fields.
class TraitProposalResult {
  const TraitProposalResult({
    required this.traits,
    required this.unknownFields,
  });
  final List<TraitProposal> traits;
  final List<String> unknownFields;
}

/// Parses the strict JSON contract for manuscript trait extraction.
///
/// Pure domain logic: no file or network access, no mutation. The UI applies
/// proposals only after the user explicitly ticks them, so nothing here ever
/// overwrites character descriptions.
abstract final class CharacterTraitExtractor {
  /// Whitelist of character profile fields the extraction may propose.
  static const List<String> profileFields = [
    'gender',
    'age',
    'heightCm',
    'hair',
    'eyes',
    'skin',
    'voice',
    'personality',
  ];

  static const int _maxManuscriptChars = 24000;

  /// Builds the extraction prompt embedding [manuscript] excerpt.
  ///
  /// Throws [ArgumentError] when the manuscript is blank: sending an empty
  /// prompt would waste API budget and produce hallucinated citations.
  static String buildExtractionPrompt({
    required String characterName,
    required String manuscript,
  }) {
    if (manuscript.trim().isEmpty) {
      throw ArgumentError.value(
        manuscript,
        'manuscript',
        'Manuscript excerpt must not be empty.',
      );
    }
    final excerpt = manuscript.length > _maxManuscriptChars
        ? '${manuscript.substring(0, _maxManuscriptChars)}\n[...]'
        : manuscript;
    return 'You are extracting physical and personality traits of the '
        'character "$characterName" from the manuscript excerpt below.\n'
        'Respond ONLY with a JSON object, no prose.\n'
        'Schema: {"traits":[{"field":"...","value":"...","tag":'
        '"explicit"|"inferred","citations":[{"chapter":N,"quote":"..."}]}],'
        '"unknown":["field",...]}\n'
        'Allowed field names: ${profileFields.join(', ')}.\n'
        'Every trait MUST carry at least one citation quoting the manuscript '
        'verbatim with its chapter number. Use tag "explicit" only when the '
        'text states the trait directly; otherwise "inferred". List fields '
        'the text never mentions under "unknown" instead of guessing.\n\n'
        'MANUSCRIPT:\n$excerpt';
  }

  /// Parses provider output into proposals, rejecting schema violations.
  ///
  /// Throws [FormatException] when the payload is not the strict object,
  /// a trait lacks citations, or a field is outside [profileFields].
  static TraitProposalResult parseProposals(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      final firstBreak = text.indexOf('\n');
      final fenceEnd = text.lastIndexOf('```');
      if (firstBreak > 0 && fenceEnd > firstBreak) {
        text = text.substring(firstBreak + 1, fenceEnd).trim();
      }
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      throw const FormatException('Provider reply is not valid JSON.');
    }
    if (decoded is! Map<String, Object?>) {
      throw const FormatException(
        'Provider reply must be a JSON object with traits/unknown.',
      );
    }
    final rawTraits = decoded['traits'];
    if (rawTraits is! List) {
      throw const FormatException('Missing "traits" array in reply.');
    }
    final traits = <TraitProposal>[];
    for (final entry in rawTraits) {
      if (entry is! Map<String, Object?>) {
        throw const FormatException('Trait entry must be an object.');
      }
      final field = entry['field'] as String?;
      final value = entry['value'] as String?;
      if (field == null || value == null || !profileFields.contains(field)) {
        throw FormatException('Trait field "$field" is not a profile field.');
      }
      if (value.trim().isEmpty) {
        throw FormatException('Trait "$field" has an empty value.');
      }
      final citationsRaw = entry['citations'];
      if (citationsRaw is! List || citationsRaw.isEmpty) {
        throw FormatException(
          'Trait "$field" has no citations; proposals must be quoted.',
        );
      }
      final citations = <TraitCitation>[];
      for (final citation in citationsRaw) {
        if (citation is! Map<String, Object?>) {
          throw const FormatException('Citation must be an object.');
        }
        final chapter = citation['chapter'];
        final quote = citation['quote'] as String?;
        if (chapter is! num || quote == null || quote.trim().isEmpty) {
          throw const FormatException(
            'Citation needs a numeric chapter and a non-empty quote.',
          );
        }
        citations.add(
          TraitCitation(chapter: chapter.toInt(), quote: quote.trim()),
        );
      }
      traits.add(
        TraitProposal(
          field: field,
          value: value.trim(),
          tag: entry['tag'] == 'explicit'
              ? TraitEvidenceTag.explicit
              : TraitEvidenceTag.inferred,
          citations: List.unmodifiable(citations),
        ),
      );
    }
    final unknownRaw = decoded['unknown'];
    final unknown = unknownRaw is List
        ? unknownRaw.whereType<String>().toList(growable: false)
        : const <String>[];
    return TraitProposalResult(
      traits: List.unmodifiable(traits),
      unknownFields: unknown,
    );
  }
}
