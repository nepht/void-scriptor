# Adversarial Bug Hunt Report: Export Domain Region (Sprint 109)

Target Repository: `D:\VoidScriptor\void_scriptor_multiplatform`
Scope: 4 Dart files (`clean_export.dart`, `export_preflight.dart`, `export_profiles.dart`, `export_protection.dart`)

---

**BUG-01** | Severity: Low | Points: 1
- **File:** lib/features/export/domain/export_profiles.dart
- **Line(s):** 145-164
- **Category:** edge-case
- **Claim:** `ExportPresetBook` methods accept empty or whitespace-only preset names without input validation.
- **Evidence:** 
```dart
  void save({required String name, required ExportProfile profile}) {
    _presets[name] = profile;
  }
```
---

**BUG-02** | Severity: Low | Points: 1
- **File:** lib/features/export/domain/export_profiles.dart
- **Line(s):** 67-72
- **Category:** edge-case
- **Claim:** `ExportProfile` constructor accepts whitespace-only scene break markers because `_requireMarker` only checks for empty strings.
- **Evidence:**
```dart
  static String _requireMarker(String marker) {
    if (marker.isEmpty) {
      throw ArgumentError('scene break marker cannot be empty');
    }
    return marker;
  }
```
---

**BUG-03** | Severity: Low | Points: 1
- **File:** lib/features/export/domain/clean_export.dart
- **Line(s):** 100-109
- **Category:** type-safety
- **Claim:** `CleanExportTransformer._fnv1a64` iterates over UTF-16 `codeUnits` instead of UTF-8 encoded bytes, causing divergence for non-ASCII characters.
- **Evidence:**
```dart
    for (final byte in text.codeUnits) {
      hash ^= byte;
      hash = (hash * prime) & mask;
    }
```
---

**BUG-04** | Severity: Low | Points: 1
- **File:** lib/features/export/domain/export_preflight.dart
- **Line(s):** 280-283
- **Category:** edge-case
- **Claim:** `_preview` slices strings using UTF-16 code unit indices via `substring`, which can split multi-byte surrogate pairs when truncating Unicode text.
- **Evidence:**
```dart
  static String _preview(String text, int limit) {
    if (text.length <= limit) return text;
    return '${text.substring(0, limit - 1)}…';
  }
```
---

**TOTAL FINDINGS:** 4
**TOTAL SCORE:** 4
