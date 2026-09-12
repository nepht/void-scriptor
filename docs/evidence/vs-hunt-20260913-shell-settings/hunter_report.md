# Adversarial Bug Hunt Report: Shell & Settings Region (vs-hunt-20260913-shell-settings)

---
**BUG-01** | Severity: Medium | Points: 5
- **File:** lib/app/shell/desktop/void_desktop_shell.dart
- **Line(s):** 74-91
- **Category:** concurrency
- **Claim:** Keyboard shortcut action callbacks capture stale `runtime` and `session` instances from initial build scope rather than evaluating the latest provider state.
- **Evidence:**
```dart
UndoMutationIntent: CallbackAction<UndoMutationIntent>(
  onInvoke: (_) {
    unawaited(runtime?.bus.undo());
    return null;
  },
),
```
---

---
**BUG-02** | Severity: Medium | Points: 5
- **File:** lib/app/shell/desktop/void_desktop_shell.dart
- **Line(s):** 128-153
- **Category:** logic
- **Claim:** Shell top navigation uses `context.push` instead of `context.go`, pushing duplicate route instances onto the navigation stack on repeated tab clicks.
- **Evidence:**
```dart
final route = switch (menu) {
  'dashboard' => AppRoutes.dashboard,
  'novels' => AppRoutes.projects,
  'write' => AppRoutes.workspace,
  ...
};
if (route != null) context.push(route);
```
---

---
**BUG-03** | Severity: Low | Points: 1
- **File:** lib/app/shell/desktop/void_desktop_shell.dart
- **Line(s):** 203-207
- **Category:** logic
- **Claim:** The `VoidStatusBar` omits `cloudConnected` and `aiConnected` parameters when instantiated in the desktop shell, leaving cloud and AI status indicators permanently inactive.
- **Evidence:**
```dart
VoidStatusBar(
  dirty: state?.isDirty ?? false,
  canUndo: runtime?.bus.canUndo ?? false,
  canRedo: runtime?.bus.canRedo ?? false,
)
```
---

---
**BUG-04** | Severity: Medium | Points: 5
- **File:** lib/features/settings/presentation/settings_hub_screen.dart
- **Line(s):** 33-47
- **Category:** logic
- **Claim:** The General settings section in `SettingsHubScreen` displays static placeholder text for UI language without rendering the available `LanguageSwitcher` widget.
- **Evidence:**
```dart
const ExpansionTile(
  key: ValueKey('settings-hub-general'),
  title: Text('General'),
  children: [
    ListTile(
      leading: Icon(Icons.language_outlined),
      title: Text('Bahasa UI'),
      subtitle: Text(
        'Indonesia (beta). Paket lokalisasi bahasa lain masih '
        'direncanakan; pengaturan bahasa akan aktif ketika '
        'lokalisasi tersedia.',
      ),
    ),
  ],
),
```
---

---
**BUG-05** | Severity: Low | Points: 1
- **File:** lib/features/settings/presentation/settings_hub_screen.dart
- **Line(s):** 170-173
- **Category:** edge-case
- **Claim:** `_StorageDiagnosticsRowState` initializes `_resolved` using `didChangeDependencies` rather than `initState`.
- **Evidence:**
```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  _resolved ??= BootstrapDirectories.resolve();
}
```
---

---
**BUG-06** | Severity: Low | Points: 1
- **File:** lib/features/settings/presentation/storage_locations_screen.dart
- **Line(s):** 75, 106
- **Category:** edge-case
- **Claim:** Mutation success and failure snackbars use an extremely short duration of 300 milliseconds, causing them to disappear almost instantly before users can read them.
- **Evidence:**
```dart
messenger.showSnackBar(
  SnackBar(
    content: Text('$label berhasil.'),
    duration: const Duration(milliseconds: 300),
  ),
);
```
---

---
**BUG-07** | Severity: Low | Points: 1
- **File:** lib/features/settings/presentation/storage_locations_screen.dart
- **Line(s):** 90-121
- **Category:** other
- **Claim:** `_submitRelink` duplicates the entire async try-catch-busy-messenger logic of `_mutate` with slight state modifications.
- **Evidence:**
```dart
Future<void> _submitRelink() async {
  if (_busy) return;
  setState(() => _busy = true);
  final messenger = ScaffoldMessenger.of(context);
  try { ... }
}
```
---

---
**BUG-08** | Severity: Medium | Points: 5
- **File:** lib/app/navigation/app_navigation_registry.dart
- **Line(s):** 184-188
- **Category:** error-handling
- **Claim:** `navigationDestinationForKey` uses `firstWhere` without an `orElse` clause, causing an unhandled `StateError` crash when an unknown key is passed.
- **Evidence:**
```dart
AppNavigationDestination navigationDestinationForKey(String key) => [
  ...coreNavigationDestinations,
  ...mobilePrimaryDestinations,
  ...optionalNavigationDestinations,
].firstWhere((item) => item.key == key);
```
---

---
**BUG-09** | Severity: Low | Points: 1
- **File:** lib/app/shell/desktop/void_top_bar.dart
- **Line(s):** 392-398
- **Category:** logic
- **Claim:** `_OptionalToolsMenu` intercepts the `'donate'` key to show a custom dialog instead of delegating to `onMenuSelected` like other optional tools, bypassing centralized routing.
- **Evidence:**
```dart
onSelected: (key) {
  if (key == 'donate') {
    _showDonationDialog(context);
  } else {
    onMenuSelected(key);
  }
},
```
---

---
**BUG-10** | Severity: Low | Points: 1
- **File:** lib/app/shell/desktop/void_top_bar.dart
- **Line(s):** 540-547
- **Category:** error-handling
- **Claim:** `_showDonationDialog` calls `ScaffoldMessenger.of(context).showSnackBar` across asynchronous boundary / after dialog pop without verifying context mounted state.
- **Evidence:**
```dart
onTap: () {
  Navigator.of(ctx).pop();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Metode ${m.label} dipilih (belum terkonfigurasi).',
      ),
    ),
  );
},
```
---

**TOTAL FINDINGS:** 10
**TOTAL SCORE:** 26
