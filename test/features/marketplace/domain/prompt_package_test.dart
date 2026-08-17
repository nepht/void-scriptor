import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/marketplace/domain/prompt_package.dart';

void main() {
  group('PromptPackage', () {
    test('holds prompt text and target', () {
      const pkg = PromptPackage(
        id: 'p1',
        title: 'Cinematic Character Description',
        promptText: 'Describe a character in a cinematic style...',
        target: 'text',
      );
      expect(pkg.title, 'Cinematic Character Description');
      expect(pkg.target, 'text');
      expect(pkg.promptText, contains('cinematic'));
      expect(pkg.tags, isEmpty);
    });
  });

  group('WorkflowPackage', () {
    test('holds ordered workflow steps', () {
      const workflow = WorkflowPackage(
        id: 'w1',
        title: 'Character Creation Pipeline',
        description: 'Generates character from concept to sheet',
        workflowSteps: [
          WorkflowStep(order: 1, action: 'generate-concept'),
          WorkflowStep(order: 2, action: 'design-outfit'),
        ],
      );
      expect(workflow.title, 'Character Creation Pipeline');
      expect(workflow.workflowSteps.length, 2);
      expect(workflow.workflowSteps.first.order, 1);
    });
  });
}
