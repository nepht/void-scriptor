import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/workflow/workflow_bindings.dart';
import 'package:void_scriptor/workflow/workflow_definition.dart';

/// Sprint 103 / 103.9-103.11 — typed command/input/output binding resolution.
void main() {
  group('InputBindingResolver (103.10)', () {
    test('resolves declared workflow input', () {
      final values = InputBindingResolver().resolve(
        inputBindings: const [WorkflowBinding('project', 'in.projectPath')],
        inputs: const {'projectPath': '/tmp/p'},
        outputsByStep: const {},
      );
      expect(values['project'], '/tmp/p');
    });

    test('resolves output of an earlier step', () {
      final values = InputBindingResolver().resolve(
        inputBindings: const [WorkflowBinding('mid', 'step.s1.count')],
        inputs: const {},
        outputsByStep: const {
          's1': {'count': 7},
        },
      );
      expect(values['mid'], 7);
    });

    test('rejects implicit global state (undeclared source)', () {
      expect(
        () => InputBindingResolver().resolve(
          inputBindings: const [WorkflowBinding('x', 'globals.magic')],
          inputs: const {},
          outputsByStep: const {},
        ),
        throwsA(isA<UnresolvedBindingException>()),
      );
    });
  });

  group('OutputCapture (103.11)', () {
    test('captures typed value with provenance', () {
      final capture = OutputCapture.capture(
        stepId: 's1',
        bindings: const [WorkflowBinding('count', 'out.count')],
        producedValues: {'count': 7},
      );
      expect(capture.byStep['s1']!['count'], 7);
      expect(capture.provenance.single.stepId, 's1');
      expect(capture.provenance.single.reference, 'out.count');
    });

    test('rejects undeclared output names (schema required)', () {
      expect(
        () => OutputCapture.capture(
          stepId: 's1',
          bindings: const [WorkflowBinding('count', 'out.count')],
          producedValues: {'typo': 1},
        ),
        throwsA(isA<UndeclaredOutputException>()),
      );
    });
  });

  group('CommandBinding (103.9)', () {
    test('accepts registered compatible commands', () {
      const binding = CommandBindingValidator(
        knownCommands: {'asset.rename'},
        commandCapabilities: {
          'asset.rename': {'fs.read'},
        },
      );
      expect(
        binding.validate(
          commandType: 'asset.rename',
          allowedCapabilities: const {'fs.read'},
        ),
        isTrue,
      );
    });

    test('rejects unknown or capability-incompatible commands', () {
      const binding = CommandBindingValidator(
        knownCommands: {'asset.rename'},
        commandCapabilities: {
          'asset.rename': {'net.write'},
        },
      );
      expect(
        binding.validate(
          commandType: 'ghost.cmd',
          allowedCapabilities: const {'net.write'},
        ),
        isFalse,
      );
      expect(
        binding.validate(
          commandType: 'asset.rename',
          allowedCapabilities: const {'fs.read'},
        ),
        isFalse,
      );
    });
  });
}
