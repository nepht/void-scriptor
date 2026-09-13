# Referee Report: Export Domain Region (Sprint 109 Adversarial Bug Hunt)

Target Repository: `D:\VoidScriptor\void_scriptor_multiplatform`
Scope: Export domain region (`clean_export.dart`, `export_preflight.dart`, `export_profiles.dart`)

---

## Evaluation of Findings

### **BUG-01**
- **Hunter's claim:** `ExportPresetBook` methods accept empty or whitespace-only preset names without input validation.
- **Skeptic's response:** DISPROVE. `ExportPresetBook` is a simple in-memory `Map<String, ExportProfile>` wrapper. Maps permit any `String` as a key. No domain requirement or validation rule specifies preset names must be non-empty or non-whitespace.
- **Your analysis:** Examination of `ExportPresetBook` in `export_profiles.dart` shows it wraps an unconstrained `Map<String, ExportProfile>`. Unlike scene break markers which have an explicit `_requireMarker` validation rule and test coverage (`expect(..., throwsArgumentError)`), preset management has no validation contract requiring non-empty names. Dart maps naturally handle any string key. The Skeptic is correct.
- **VERDICT:** NOT A BUG
- **Confidence:** High
- **True severity:** N/A
- **Suggested fix:** N/A

---

### **BUG-02**
- **Hunter's claim:** `ExportProfile` constructor accepts whitespace-only scene break markers because `_requireMarker` only checks for empty strings.
- **Skeptic's response:** DISPROVE. `_requireMarker` explicitly checks `marker.isEmpty`, which is the documented contract for rejecting uninitialized or zero-length markers. Allowing whitespace is valid as authors may use spacing or custom blank markers.
- **Your analysis:** Reviewing `ExportProfile._requireMarker` in `export_profiles.dart`:
  ```dart
  static String _requireMarker(String marker) {
    if (marker.isEmpty) {
      throw ArgumentError('scene break marker cannot be empty');
    }
    return marker;
  }
  ```
  The implementation and doc comment specify checking `isEmpty`. There is no specification requiring `trim().isNotEmpty`. Furthermore, authors might intentionally use spacing or custom formatting characters as separators. The Skeptic is correct.
- **VERDICT:** NOT A BUG
- **Confidence:** High
- **True severity:** N/A
- **Suggested fix:** N/A

---

### **BUG-03**
- **Hunter's claim:** `CleanExportTransformer._fnv1a64` iterates over UTF-16 `codeUnits` instead of UTF-8 encoded bytes, causing divergence for non-ASCII characters.
- **Skeptic's response:** DISPROVE. The fingerprint is an internal content hash (`contentFingerprint`) used solely for change detection and manifest verification within the Dart application runtime. Using `text.codeUnits` is fully deterministic, allocation-free, and stable across Dart processes for the same string content, fulfilling its intended purpose without requiring external UTF-8 interoperability.
- **Your analysis:** Checking `CleanExportTransformer._fnv1a64` in `clean_export.dart`, the hash is used purely internally for `ExportManifest.contentFingerprint`. It is not transmitted to an external spec requiring UTF-8 byte-stream representation. `text.codeUnits` provides a deterministic, fast, allocation-free hash over the string's UTF-16 code units. The Skeptic is correct.
- **VERDICT:** NOT A BUG
- **Confidence:** High
- **True severity:** N/A
- **Suggested fix:** N/A

---

### **BUG-04**
- **Hunter's claim:** `_preview` slices strings using UTF-16 code unit indices via `substring`, which can split multi-byte surrogate pairs when truncating Unicode text.
- **Skeptic's response:** ACCEPT. The `_preview` method uses UTF-16 code unit indices via `text.substring(0, limit - 1)`, which can split multi-byte surrogate pairs (e.g., emojis or supplementary Unicode characters) when truncating text. This produces malformed UTF-16 strings containing orphan surrogates.
- **Your analysis:** Examining `ExportPreflightValidator._preview` in `export_preflight.dart`:
  ```dart
  static String _preview(String text, int limit) {
    if (text.length <= limit) return text;
    return '${text.substring(0, limit - 1)}…';
  }
  ```
  Dart strings are sequences of UTF-16 code units. If a multi-byte surrogate pair (such as an emoji or non-BMP character) sits at the boundary of `limit - 1`, `substring` splits the pair, resulting in an orphan high surrogate. This is a real correctness issue for text containing supplementary Unicode characters. The Skeptic and Hunter are correct.
- **VERDICT:** REAL BUG
- **Confidence:** High
- **True severity:** Low
- **Suggested fix:** Use rune-aware slicing or the `characters` package (e.g., `Characters(text).take(limit - 1).toString()`) to truncate by grapheme clusters / runes rather than raw UTF-16 code units.

---

## Final Report

**VERIFIED BUG REPORT**

Stats:
- Total reported by Hunter: 4
- Dismissed as false positives: 3
- Confirmed as real bugs: 1
- Critical: 0 | Medium: 0 | Low: 1

Confirmed bugs (ordered by severity):

| # | Severity | File | Line(s) | Description | Suggested Fix |
|---|----------|------|---------|-------------|---------------|
| BUG-04 | Low | lib/features/export/domain/export_preflight.dart | 280-283 | `_preview` slices strings using raw UTF-16 `codeUnits`/`substring`, risking split surrogate pairs on Unicode text. | Use `Characters(text).take(limit - 1).toString()` or rune-aware truncation. |

Low-confidence items (flagged for manual review):
None.
