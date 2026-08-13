class TerminologyEntryModel {
  const TerminologyEntryModel({
    required this.id,
    required this.projectId,
    required this.term,
    required this.definition,
    this.category = 'general',
    this.alternateTerms = '',
    this.caseSensitive = false,
  });

  final String id;
  final String projectId;
  final String term;
  final String definition;
  final String category;
  final String alternateTerms;
  final bool caseSensitive;
}
