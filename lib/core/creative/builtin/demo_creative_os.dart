import '../brief/creative_brief.dart';
import '../idea/idea_bank.dart';
import '../pipeline/creative_pipeline.dart';

/// Built-in demo creative OS (Step 40.20).
class DemoCreativeOs {
  DemoCreativeOs._();

  static final IdeaBank ideaBank = IdeaBank()
    ..add(
      const Idea(
        id: 'i1',
        title: 'Void Warden rises',
        description: 'A warden awakens in the frozen north',
        tags: ['character', 'origin'],
      ),
    )
    ..add(
      const Idea(
        id: 'i2',
        title: 'The volcanic sea',
        description: 'A sea of fire at the equator',
        tags: ['location'],
      ),
    );

  static const CreativeBrief brief = CreativeBrief(
    id: 'b1',
    title: 'Void Cube Saga',
    genre: 'dark fantasy',
    tone: 'melancholic',
    goals: ['worldbuild', 'publish'],
  );

  static final CreativePipeline pipeline = CreativePipeline();
}
