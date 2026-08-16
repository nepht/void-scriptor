import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/creative/pipeline/creative_pipeline.dart';

void main() {
  test('PipelineStage order', () {
    expect(PipelineStage.idea.index, 0);
    expect(PipelineStage.polish.index, 3);
  });

  test('CreativePipeline advances stages', () {
    final pipeline = CreativePipeline();
    expect(pipeline.currentStage, PipelineStage.idea);
    pipeline.advance();
    expect(pipeline.currentStage, PipelineStage.outline);
    pipeline.advance();
    pipeline.advance();
    expect(pipeline.currentStage, PipelineStage.polish);
  });

  test('CreativePipeline cannot advance past polish', () {
    final pipeline = CreativePipeline();
    for (var i = 0; i < 5; i++) {
      pipeline.advance();
    }
    expect(pipeline.currentStage, PipelineStage.polish);
  });
}
