import '../domain/bible_entry.dart';

class CanonPromptContextComposer {
  String compose(Iterable<BibleEntry> entries) {
    final selected = entries.toList(growable: false);
    if (selected.isEmpty) return '[RELEVANT CANON CONTEXT]\n(none)';
    final buffer = StringBuffer('[RELEVANT CANON CONTEXT]\n');
    buffer.writeln(
      'Use these canon facts as constraints. Do not invent facts.',
    );
    for (final entry in selected) {
      buffer
        ..writeln('- [${entry.type.name}/${entry.status.name}] ${entry.title}')
        ..writeln('  ${entry.content}');
    }
    return buffer.toString().trimRight();
  }
}
