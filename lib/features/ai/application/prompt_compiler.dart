import 'package:uuid/uuid.dart';
import 'prompt_composer.dart';

class CompiledPrompt {
  const CompiledPrompt({
    required this.text,
    required this.characters,
    required this.sections,
  });
  final String text;
  final int characters;
  final int sections;
}

class PromptCompiler {
  CompiledPrompt compile(PromptDocument document) {
    final buffer = StringBuffer();
    final sections = [...document.sections]
      ..sort((a, b) => a.order.compareTo(b.order));
    for (final section in sections) {
      if (!section.enabled) {
        continue;
      }
      buffer
        ..writeln(section.title.toUpperCase())
        ..writeln()
        ..writeln(section.content)
        ..writeln();
    }
    if (document.negativePrompt.trim().isNotEmpty) {
      buffer
        ..writeln('NEGATIVE PROMPT')
        ..writeln(document.negativePrompt);
    }
    final text = buffer.toString().trim();
    return CompiledPrompt(
      text: text,
      characters: text.length,
      sections: sections.where((section) => section.enabled).length,
    );
  }
}

String newPromptId() => const Uuid().v4();
