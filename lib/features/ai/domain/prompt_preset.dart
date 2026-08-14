import 'prompt_target.dart';

class PromptPreset {
  const PromptPreset({
    required this.id,
    required this.name,
    required this.target,
    required this.baseInstructions,
  });
  final String id;
  final String name;
  final PromptTarget target;
  final List<String> baseInstructions;
}

class BuiltInPromptPresets {
  static const all = <PromptPreset>[
    PromptPreset(
      id: 'cinematic-live-action',
      name: 'Cinematic Live Action',
      target: PromptTarget.video,
      baseInstructions: [
        'cinematic composition',
        'physically coherent motion',
        'natural lighting',
      ],
    ),
    PromptPreset(
      id: 'anime-cinematic',
      name: 'Anime Cinematic',
      target: PromptTarget.video,
      baseInstructions: [
        'anime cinematic framing',
        'expressive motion',
        'stylized lighting',
      ],
    ),
    PromptPreset(
      id: 'character-detail-sheet',
      name: 'Character Detail Sheet',
      target: PromptTarget.characterConsistency,
      baseInstructions: [
        'front, side and back reference views',
        'consistent facial identity',
      ],
    ),
    PromptPreset(
      id: 'wardrobe-detail-sheet',
      name: 'Wardrobe Detail Sheet',
      target: PromptTarget.wardrobe,
      baseInstructions: [
        'standalone product view',
        'show construction and materials',
      ],
    ),
    PromptPreset(
      id: 'weapon-detail-sheet',
      name: 'Weapon Detail Sheet',
      target: PromptTarget.weapon,
      baseInstructions: [
        'standalone weapon reference',
        'show geometry and proportions',
      ],
    ),
    PromptPreset(
      id: 'creature-detail-sheet',
      name: 'Creature Detail Sheet',
      target: PromptTarget.creature,
      baseInstructions: [
        'front, side, back and three-quarter views',
        'head, eyes, body structure and scale comparison',
        'show material, skin, color palette and modes',
      ],
    ),
    PromptPreset(
      id: 'vehicle-technical-sheet',
      name: 'Vehicle Technical Detail Sheet',
      target: PromptTarget.vehicle,
      baseInstructions: [
        'orthographic exterior and three-quarter views',
        'interior, cockpit, propulsion and weapon mounts',
        'dimensions, materials and scale comparison',
      ],
    ),
    PromptPreset(
      id: 'prop-detail-sheet',
      name: 'Prop Detail Sheet',
      target: PromptTarget.prop,
      baseInstructions: [
        'orthographic and exploded views',
        'materials, dimensions, color palette and states',
        'include scale comparison',
      ],
    ),
    PromptPreset(
      id: 'vfx-design-sheet',
      name: 'VFX Design Sheet',
      target: PromptTarget.vfx,
      baseInstructions: [
        'show effect silhouette, behavior states, and light interaction',
        'preserve progression from opening to stable to dissipation',
      ],
    ),
    PromptPreset(
      id: 'audio-mood-brief',
      name: 'Audio Mood Brief',
      target: PromptTarget.audio,
      baseInstructions: [
        'describe instrumentation, texture, dynamics, and cinematic intent',
        'include transition points and restrained production direction',
      ],
    ),
    PromptPreset(
      id: 'dialogue-voice-direction',
      name: 'Dialogue Voice Direction',
      target: PromptTarget.dialogue,
      baseInstructions: [
        'describe vocal texture, emotional arc, pacing, and pronunciation',
        'preserve character identity and scene continuity',
      ],
    ),
    PromptPreset(
      id: 'storyboard',
      name: 'Storyboard',
      target: PromptTarget.story,
      baseInstructions: ['clear sequential storyboard beats'],
    ),
    PromptPreset(
      id: 'concept-art',
      name: 'Concept Art',
      target: PromptTarget.image,
      baseInstructions: ['high quality concept art'],
    ),
    PromptPreset(
      id: 'photorealistic-portrait',
      name: 'Photorealistic Portrait',
      target: PromptTarget.image,
      baseInstructions: ['photorealistic portrait lighting'],
    ),
  ];
}

enum AiContextPriority { critical, high, normal, optional }

class AiReferenceImage {
  const AiReferenceImage({
    required this.path,
    required this.role,
    required this.priority,
  });
  final String path;
  final String role;
  final int priority;
}
