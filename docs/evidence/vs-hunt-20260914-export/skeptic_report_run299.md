# Skeptic Adjudication Report: Export Domain Region (Sprint 109)

Target Repository: `D:\VoidScriptor\void_scriptor_multiplatform`
Scope: 4 Dart files (`clean_export.dart`, `export_preflight.dart`, `export_profiles.dart`, `export_protection.dart`)

---

**BUG-01** | Original: 1 pts
- **Counter-argument:** `ExportPresetBook` is a simple in-memory `Map<String, ExportProfile>` wrapper. In Dart, maps permit any `String` as a key, including empty or whitespace strings. There is no domain requirement or validation rule specifying that preset names must be non-empty or non-whitespace.
- **Evidence:** `final Map<String, ExportProfile> _presets = <String, ExportProfile>{};`
- **Confidence:** 85%
- **Risk calc:** EV = (85% x 1) - (15% x 2 x 1) = 0.85 - 0.30 = +0.55
- **Decision:** DISPROVE
---

**BUG-02** | Original: 1 pts
- **Counter-argument:** `_requireMarker` explicitly checks `marker.isEmpty`, which is the documented contract for rejecting uninitialized or zero-length markers. Allowing whitespace is valid as authors may use spacing or custom blank markers.
- **Evidence:** `if (marker.isEmpty) { throw ArgumentError('scene break marker cannot be empty'); }`
- **Confidence:** 80%
- **Risk calc:** EV = (80% x 1) - (20% x 2 x 1) = 0.80 - 0.40 = +0.40
- **Decision:** DISPROVE
---

**BUG-03** | Original: 1 pts
- **Counter-argument:** The fingerprint is an internal content hash (`contentFingerprint`) used solely for change detection and manifest verification within the Dart application runtime. Using `text.codeUnits` is fully deterministic, allocation-free, and stable across Dart processes for the same string content, fulfilling its intended purpose without requiring external UTF-8 encoding interoperability.
- **Evidence:** `for (final byte in text.codeUnits) { hash ^= byte; ... }`
- **Confidence:** 75%
- **Risk calc:** EV = (75% x 1) - (25% x 2 x 1) = 0.75 - 0.50 = +0.25
- **Decision:** DISPROVE
---

**BUG-04** | Original: 1 pts
- **Counter-argument:** The hunter is correct. The `_preview` method uses UTF-16 code unit indices via `text.substring(0, limit - 1)`, which can split multi-byte surrogate pairs (e.g., emojis or supplementary Unicode characters) when truncating text. This produces malformed UTF-16 strings containing orphan surrogates.
- **Evidence:** `return '${text.substring(0, limit - 1)}…';`
- **Confidence:** 95%
- **Risk calc:** EV = (95% x 1) - (5% x 2 x 1) = 0.95 - 0.10 = +0.85
- **Decision:** ACCEPT
---

**SUMMARY:**
- Bugs disproved: 3 (total points claimed: 3)
- Bugs accepted as real: 1
- Your final score: +3

**ACCEPTED BUG LIST:**
- BUG-04
