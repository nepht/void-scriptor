# Adversarial Bug Hunt Report: Studio Domain (`vs-hunt-20260913-studio`)

---
**STU-BUG-01** | Severity: Critical | Points: 10
- **File:** lib/features/studio/domain/production_pipeline.dart
- **Line(s):** 40-50
- **Category:** error-handling
- **Claim:** ProductionBreakdown.isBlocked and related methods use firstWhere without an orElse handler, causing uncaught StateError crashes when querying non-existent task IDs or missing dependency IDs.
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
---

---
**STU-BUG-02** | Severity: Critical | Points: 10
- **File:** lib/features/studio/domain/autopilot_governance.dart
- **Line(s):** 8-9
- **Category:** security
- **Claim:** AutopilotControl.canExecute performs a case-sensitive inequality check against 'delete', allowing uppercase or mixed-case deletion commands (e.g. 'DELETE') to bypass autopilot safety controls.
- **Evidence:**
```dart
  bool canExecute(String command) =>
      isRunning && mode != AutopilotMode.dryRun && command != 'delete';
```
---

---
**STU-BUG-03** | Severity: Medium | Points: 5
- **File:** lib/features/studio/domain/organization_agent.dart
- **Line(s):** 122-133
- **Category:** data-integrity
- **Claim:** InMemoryDepartmentLeadRepository uses a simple map keyed by departmentId (_leads[lead.departmentId] = lead), overwriting previous department leads on every save call and discarding lifecycle history.
- **Evidence:**
```dart
class InMemoryDepartmentLeadRepository implements DepartmentLeadRepository {
  final Map<String, DepartmentLead> _leads = <String, DepartmentLead>{};

  @override
  Future<void> save(DepartmentLead lead) async {
    _leads[lead.departmentId] = lead;
  }
```
---

---
**STU-BUG-04** | Severity: Medium | Points: 5
- **File:** lib/features/studio/domain/operations_safety.dart
- **Line(s):** 48-54
- **Category:** security
- **Claim:** PromptInjectionBoundary.accept uses basic substring matching (contains('ignore previous')), which fails to detect prompt injection attempts using extra spacing, alternative phrasings, or obfuscation.
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
---

---
**STU-BUG-05** | Severity: Medium | Points: 5
- **File:** lib/features/studio/domain/studio_communication.dart
- **Line(s):** 15-23
- **Category:** logic
- **Claim:** StudioMessageChannel.send explicitly rejects messages of type StudioMessageType.chat, preventing chat messages from being transmitted through the communication channel.
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
---

---
**STU-BUG-06** | Severity: Low | Points: 1
- **File:** lib/features/studio/domain/agent_memory_resilience.dart
- **Line(s):** 45-55
- **Category:** logic
- **Claim:** EvaluationMetrics.composite calculates the mean of quality, safety, and latency without scaling latency (e.g. in milliseconds vs 0-1 scores), distorting the composite evaluation metric.
- **Evidence:**
```dart
  final double quality;
  final double safety;
  final double latency;
  double get composite => (quality + safety + latency) / 3;
```
---

---
**STU-BUG-07** | Severity: Low | Points: 1
- **File:** lib/features/studio/domain/review_governance.dart
- **Line(s):** 7-15
- **Category:** performance
- **Claim:** AttentionQueue.next() re-sorts all items by priority on every retrieval call instead of maintaining a sorted order or heap, causing unnecessary O(N log N) overhead.
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
---

---
**STU-BUG-08** | Severity: Low | Points: 1
- **File:** lib/features/studio/domain/agent_memory_resilience.dart
- **Line(s):** 57-65
- **Category:** edge-case
- **Claim:** ModelRouter.select uses a case-sensitive .contains('local') check, failing to recognize local models registered with uppercase or mixed-case names.
- **Evidence:**
```dart
  String? select({required bool preferLocal}) {
    if (_models.isEmpty) return null;
    if (preferLocal && _models.contains('local')) return 'local';
    return _models.first;
  }
```
---

**TOTAL FINDINGS:** 8
**TOTAL SCORE:** 38
