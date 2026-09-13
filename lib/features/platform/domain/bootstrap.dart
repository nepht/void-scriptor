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
    // vs-hunt-20260914-platform PLAT-BUG-05: sort tunggal pada `order` tidak
    // deterministik untuk order kembar (List.sort Dart tidak stabil).
    // Tie-breaker `id` membuat urutan eksekusi bootstrap dapat direproduksi.
    final sorted = [...steps]
      ..sort((a, b) {
        final byOrder = a.order.compareTo(b.order);
        if (byOrder != 0) return byOrder;
        return a.id.compareTo(b.id);
      });
    return sorted;
  }
}
