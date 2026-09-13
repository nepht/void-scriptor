# Adversarial Bug Hunt Skeptic Report: Studio Domain (`vs-hunt-20260913-studio`)

---
**STU-BUG-01** | Original: 10 pts
- **Counter-argument:** `ProductionBreakdown.isBlocked` and `complete` use `firstWhere` without an `orElse` handler. If an invalid task ID or missing dependency ID is queried, it throws an uncaught `StateError`.
- **Evidence:** 
```dart
  bool isBlocked(String id) {
    final task = _tasks.firstWhere((item) => item.id == id);
    final dependency = task.dependsOn;
    if (dependency == null) return false;
    return _tasks.firstWhere((item) => item.id == dependency).status !=
        ProductionTaskStatus.completed;
  }
```
- **Reachability:** Zero production callers outside domain classes and unit tests.
- **Confidence:** 95%
- **Risk calc:** EV = (95% x 10) - (5% x 2 x 10) = 9.5 - 1.0 = +8.5
- **Decision:** ACCEPT
---

---
**STU-BUG-02** | Original: 10 pts
- **Counter-argument:** `AutopilotControl.canExecute` performs a case-sensitive inequality check against `'delete'`, allowing uppercase/mixed-case commands like `'DELETE'` to bypass safety controls.
- **Evidence:**
```dart
  bool canExecute(String command) =>
      isRunning && mode != AutopilotMode.dryRun && command != 'delete';
```
- **Reachability:** Zero production callers outside domain classes and unit tests.
- **Confidence:** 95%
- **Risk calc:** EV = (95% x 10) - (5% x 2 x 10) = 9.5 - 1.0 = +8.5
- **Decision:** ACCEPT
---

---
**STU-BUG-03** | Original: 5 pts
- **Counter-argument:** `InMemoryDepartmentLeadRepository` stores leads in a Map keyed by `departmentId`, overwriting previous leads on every `save` call and discarding lifecycle history.
- **Evidence:**
```dart
class InMemoryDepartmentLeadRepository implements DepartmentLeadRepository {
  final Map<String, DepartmentLead> _leads = <String, DepartmentLead>{};

  @override
  Future<void> save(DepartmentLead lead) async {
    _leads[lead.departmentId] = lead;
  }
```
- **Reachability:** Zero production callers outside domain classes and unit tests.
- **Confidence:** 90%
- **Risk calc:** EV = (90% x 5) - (10% x 2 x 5) = 4.5 - 1.0 = +3.5
- **Decision:** ACCEPT
---

---
**STU-BUG-04** | Original: 5 pts
- **Counter-argument:** The prompt injection boundary implementation is deliberate design for a lightweight heuristic check, and is explicitly tested and pinned by unit tests in `operations_safety_test.dart`.
- **Evidence:**
```dart
class PromptInjectionBoundary {
  const PromptInjectionBoundary();
  bool accept(String input) {
    final normalized = input.toLowerCase();
    return !normalized.contains('ignore previous') &&
        !normalized.contains('disregard instructions');
  }
}
```
- **Reachability:** Zero production callers outside domain classes and unit tests.
- **Confidence:** 85%
- **Risk calc:** EV = (85% x 5) - (15% x 2 x 5) = 4.25 - 1.5 = +2.75
- **Decision:** DISPROVE
---

---
**STU-BUG-05** | Original: 5 pts
- **Counter-argument:** Rejecting `StudioMessageType.chat` in `StudioMessageChannel` is deliberate design enforcing structured task/status/decision communication over free-form chat, explicitly verified and pinned by `studio_communication_test.dart`.
- **Evidence:**
```dart
  bool send(StudioMessage message) {
    if (message.type == StudioMessageType.chat ||
        _messages.length >= maxMessages ||
        message.body.trim().isEmpty) {
      return false;
    }
    _messages.add(message);
    return true;
  }
```
- **Reachability:** Zero production callers outside domain classes and unit tests.
- **Confidence:** 90%
- **Risk calc:** EV = (90% x 5) - (10% x 2 x 5) = 4.5 - 1.0 = +3.5
- **Decision:** DISPROVE
---

---
**STU-BUG-06** | Original: 1 pt
- **Counter-argument:** `EvaluationMetrics.composite` sums quality, safety, and latency without normalization or scaling, which distorts the composite metric when latency is in milliseconds.
- **Evidence:**
```dart
  final double quality;
  final double safety;
  final double latency;
  double get composite => (quality + safety + latency) / 3;
```
- **Reachability:** Zero production callers outside domain classes and unit tests.
- **Confidence:** 90%
- **Risk calc:** EV = (90% x 1) - (10% x 2 x 1) = 0.9 - 0.2 = +0.7
- **Decision:** ACCEPT
---

---
**STU-BUG-07** | Original: 1 pt
- **Counter-argument:** `AttentionQueue.next()` re-sorts all items by priority on every retrieval call (`O(N log N)`), which is an algorithmic efficiency/performance issue.
- **Evidence:**
```dart
class AttentionQueue {
  final List<AttentionItem> _items = [];
  void add(AttentionItem item) => _items.add(item);
  AttentionItem? next() {
    if (_items.isEmpty) return null;
    _items.sort((a, b) => b.priority.compareTo(a.priority));
    return _items.removeAt(0);
  }
}
```
- **Reachability:** Zero production callers outside domain classes and unit tests.
- **Confidence:** 80%
- **Risk calc:** EV = (80% x 1) - (20% x 2 x 1) = 0.8 - 0.4 = +0.4
- **Decision:** ACCEPT
---

---
**STU-BUG-08** | Original: 1 pt
- **Counter-argument:** `ModelRouter.select` uses an exact and case-sensitive `.contains('local')` check on the model list, failing to match uppercase/mixed-case names or substring matches properly.
- **Evidence:**
```dart
  String? select({required bool preferLocal}) {
    if (_models.isEmpty) return null;
    if (preferLocal && _models.contains('local')) return 'local';
    return _models.first;
  }
```
- **Reachability:** Zero production callers outside domain classes and unit tests.
- **Confidence:** 90%
- **Risk calc:** EV = (90% x 1) - (10% x 2 x 1) = 0.9 - 0.2 = +0.7
- **Decision:** ACCEPT
---

**SUMMARY:**
- Bugs disproved: 2 (total points claimed: 10)
- Bugs accepted as real: 6
- Your final score: +10 points (disproved points claimed)

**ACCEPTED BUG LIST:**
- STU-BUG-01 (Critical, 10 pts)
- STU-BUG-02 (Critical, 10 pts)
- STU-BUG-03 (Medium, 5 pts)
- STU-BUG-06 (Low, 1 pt)
- STU-BUG-07 (Low, 1 pt)
- STU-BUG-08 (Low, 1 pt)
