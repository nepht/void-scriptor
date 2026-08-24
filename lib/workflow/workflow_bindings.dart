import 'workflow_definition.dart';

/// Sprint 103 / 103.9-103.11 — typed command, input, and output binding.

/// Thrown when an input binding cannot be resolved from declared sources.
class UnresolvedBindingException implements Exception {
  UnresolvedBindingException(this.bindingName, this.reference);

  final String bindingName;
  final String reference;

  @override
  String toString() =>
      'UnresolvedBindingException: "$bindingName" -> "$reference"';
}

/// Resolves step input bindings strictly against declared sources:
/// workflow inputs and outputs of earlier steps. Implicit global state is
/// forbidden (103.10).
class InputBindingResolver {
  Map<String, Object?> resolve({
    required List<WorkflowBinding> inputBindings,
    required Map<String, Object?> inputs,
    required Map<String, Map<String, Object?>> outputsByStep,
  }) {
    final resolved = <String, Object?>{};
    for (final binding in inputBindings) {
      final ref = binding.reference;
      if (ref.startsWith('in.')) {
        final key = ref.substring(3);
        if (!inputs.containsKey(key)) {
          throw UnresolvedBindingException(binding.name, ref);
        }
        resolved[binding.name] = inputs[key];
      } else if (ref.startsWith('step.')) {
        final rest = ref.substring(5);
        final dot = rest.indexOf('.');
        final stepId = dot < 0 ? rest : rest.substring(0, dot);
        final outputKey = dot < 0 ? null : rest.substring(dot + 1);
        final outputs = outputsByStep[stepId];
        if (outputs == null || outputKey == null) {
          throw UnresolvedBindingException(binding.name, ref);
        }
        if (!outputs.containsKey(outputKey)) {
          throw UnresolvedBindingException(binding.name, ref);
        }
        resolved[binding.name] = outputs[outputKey];
      } else {
        throw UnresolvedBindingException(binding.name, ref);
      }
    }
    return Map.unmodifiable(resolved);
  }
}

/// Provenance record for one captured output value.
class OutputProvenance {
  const OutputProvenance({
    required this.stepId,
    required this.name,
    required this.reference,
  });

  final String stepId;
  final String name;
  final String reference;
}

/// Captures typed step outputs with provenance; undeclared names are
/// rejected so every stored value has a schema (103.11).
class OutputCapture {
  OutputCapture.capture({
    required String stepId,
    required List<WorkflowBinding> bindings,
    required Map<String, Object?> producedValues,
  }) {
    for (final b in bindings) {
      if (!b.reference.startsWith('out.')) {
        throw UndeclaredOutputException(stepId, b.reference);
      }
      final name = b.reference.substring(4);
      if (!producedValues.containsKey(name)) {
        throw UndeclaredOutputException(stepId, b.reference);
      }
      byStep.putIfAbsent(stepId, () => {})[name] = producedValues[name]!;
      provenance.add(
        OutputProvenance(stepId: stepId, name: name, reference: b.reference),
      );
    }
  }

  final Map<String, Map<String, Object?>> byStep = {};
  final List<OutputProvenance> provenance = [];
}

class UndeclaredOutputException implements Exception {
  UndeclaredOutputException(this.stepId, this.reference);

  final String stepId;
  final String reference;

  @override
  String toString() =>
      'UndeclaredOutputException: step "$stepId" has no declared output "$reference"';
}

/// Validates a command reference before execution: the command must be
/// registered AND its capability needs must fit the granted set
/// (deny-by-default downstream, 103.9/103.20).
class CommandBindingValidator {
  const CommandBindingValidator({
    this.knownCommands = const {},
    this.commandCapabilities = const {},
  });

  final Set<String> knownCommands;
  final Map<String, Set<String>> commandCapabilities;

  bool validate({
    required String commandType,
    required Set<String> allowedCapabilities,
  }) {
    if (!knownCommands.contains(commandType)) return false;
    final needed = commandCapabilities[commandType];
    if (needed == null) return true;
    return needed.every(allowedCapabilities.contains);
  }
}
