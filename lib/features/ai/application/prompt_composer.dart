export '../domain/prompt_target.dart';
import '../domain/ai_context.dart';
import '../domain/prompt_target.dart';

class AiContextOptions {
  const AiContextOptions({
    this.includeCharacter = true,
    this.includeMode = true,
    this.includeIdentity = true,
    this.includeWardrobe = true,
    this.includeWeapons = true,
    this.includeEnvironment = true,
    this.includeTimeline = true,
    this.includeContinuity = true,
  });
  final bool includeCharacter;
  final bool includeMode;
  final bool includeIdentity;
  final bool includeWardrobe;
  final bool includeWeapons;
  final bool includeEnvironment;
  final bool includeTimeline;
  final bool includeContinuity;
}

class PromptSection {
  const PromptSection({
    required this.id,
    required this.title,
    required this.content,
    required this.order,
    this.enabled = true,
  });
  final String id;
  final String title;
  final String content;
  final int order;
  final bool enabled;
}

class PromptDocument {
  const PromptDocument({
    required this.id,
    required this.projectId,
    required this.target,
    required this.title,
    required this.sections,
    required this.createdAt,
    this.negativePrompt = '',
  });
  final String id;
  final String projectId;
  final PromptTarget target;
  final String title;
  final List<PromptSection> sections;
  final String negativePrompt;
  final DateTime createdAt;
}

class PromptComposer {
  PromptDocument compose({
    required AiContext context,
    required PromptTarget target,
    AiContextOptions options = const AiContextOptions(),
  }) {
    final sections = <PromptSection>[];
    var order = 0;
    void add(String title, String content) {
      if (content.trim().isNotEmpty) {
        sections.add(
          PromptSection(
            id: 'section-${order + 1}',
            title: title,
            content: content.trim(),
            order: order++,
          ),
        );
      }
    }

    if (context.sceneContext != null) {
      final scene = context.sceneContext!;
      add(
        'SCENE',
        '${scene.title}\nDuration: ${scene.durationSeconds.toStringAsFixed(1)} seconds\n${scene.beats.map((beat) => '${beat.type}: ${beat.content}').join('\n')}',
      );
    }
    if (options.includeCharacter) {
      for (final character in context.characterContexts) {
        final lines = <String>[
          if (options.includeMode && character.modeName != null)
            'Mode: ${character.modeName}',
          if (options.includeIdentity) character.identityDescription,
          if (options.includeWardrobe)
            'Wardrobe: ${character.wardrobeDescription}',
          if (options.includeWeapons) 'Weapons: ${character.weaponDescription}',
          if (options.includeIdentity) ...character.preservationRules,
        ];
        add('CHARACTER — ${character.name.toUpperCase()}', lines.join('\n'));
      }
    }
    if (context.sceneAssetContexts.isNotEmpty) {
      add(
        'SCENE ASSETS',
        context.sceneAssetContexts
            .map(
              (asset) => [
                '${asset.type.toUpperCase()} — ${asset.name}',
                if (asset.state != null) 'State: ${asset.state}',
                'Priority: ${asset.priority}',
                if (asset.references.isNotEmpty)
                  'References: ${asset.references.join(', ')}',
              ].join('\n'),
            )
            .join('\n\n'),
      );
    }
    if (options.includeEnvironment && context.environmentContext != null) {
      final environment = context.environmentContext!;
      add(
        'ENVIRONMENT',
        [
          environment.name,
          environment.zone,
          environment.timeOfDay,
          environment.weather,
          environment.lighting,
          if (options.includeContinuity) environment.continuity,
        ].whereType<String>().join('\n'),
      );
    }
    if (options.includeTimeline && context.timelineContext != null) {
      add(
        'TIMELINE',
        context.timelineContext!.sections
            .map(
              (section) =>
                  '${section.start.toStringAsFixed(1)}–${section.end.toStringAsFixed(1)} sec\n${section.entries.join('\n')}',
            )
            .join('\n\n'),
      );
    }
    return PromptDocument(
      id: 'prompt-${DateTime.now().microsecondsSinceEpoch}',
      projectId: context.projectId,
      target: target,
      title: 'Generated Prompt',
      sections: sections,
      createdAt: DateTime.now(),
    );
  }
}
