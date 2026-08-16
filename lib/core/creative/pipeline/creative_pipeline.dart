enum PipelineStage { idea, outline, draft, polish }

/// Creative pipeline state machine (Step 40.10–40.12).
class CreativePipeline {
  PipelineStage _stage = PipelineStage.idea;

  PipelineStage get currentStage => _stage;

  void advance() {
    if (_stage.index < PipelineStage.values.length - 1) {
      _stage = PipelineStage.values[_stage.index + 1];
    }
  }
}
