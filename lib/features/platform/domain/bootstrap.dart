/// Sprint 50 — Step 50.5–50.8 Composition Root, Bootstrap Service, Startup Order.
class BootstrapStep {
  const BootstrapStep({
    required this.id,
    required this.name,
    required this.order,
    required this.required,
    this.lazy = false,
  });

  final String id;
  final String name;
  final int order;
  final bool required;
  final bool lazy;

  bool get isOptional => !required && lazy;
}

class BootstrapPlan {
  const BootstrapPlan({required this.id, this.steps = const []});

  final String id;
  final List<BootstrapStep> steps;

  List<BootstrapStep> get orderedSteps {
    final sorted = [...steps]..sort((a, b) => a.order.compareTo(b.order));
    return sorted;
  }
}
