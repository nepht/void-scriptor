---
**BUG-1** | Severity: Medium | Points: 5
- **File:** lib/features/references/application/reference_repository.dart
- **Line(s):** 397
- **Category:** error-handling
- **Claim:** The `replaceFile` method attempts to copy the current reference file to a version snapshot without verifying if the file exists on disk, causing unhandled `FileSystemException` crashes when replacing references whose underlying files are missing.
- **Evidence:** 
```dart
    await target.copy(snapshot.path);
```
---

---
**BUG-2** | Severity: Medium | Points: 5
- **File:** lib/features/references/presentation/reference_management_screen.dart
- **Line(s):** 73
- **Category:** logic
- **Claim:** Identity locks are rendered with `onChanged: null` inside `SwitchListTile`, permanently disabling the switch interaction and preventing users from toggling lock states in the management screen.
- **Evidence:**
```dart
              (lock) => SwitchListTile(
                value: lock.enabled,
                onChanged: null,
                title: Text(lock.type.name),
                subtitle: Text(lock.instruction),
                secondary: CircleAvatar(child: Text('${lock.priority}')),
              ),
```
---

---
**BUG-3** | Severity: Low | Points: 1
- **File:** lib/features/references/presentation/reference_import_dialog.dart
- **Line(s):** 99
- **Category:** edge-case
- **Claim:** The reference import dialog submission handler silently ignores empty required path or name fields without providing user feedback or error indication.
- **Evidence:**
```dart
  void _submit(BuildContext context) {
    if (path.text.trim().isEmpty || name.text.trim().isEmpty) return;
    Navigator.pop(
      context,
      ReferenceImportDraft(
```
---

**TOTAL FINDINGS:** 3
**TOTAL SCORE:** 11
