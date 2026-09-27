/// Sprint 115.52 — Visual Regression Matrix contract.
///
/// The canonical objective of step 115.52 asks the matrix to cover reference
/// sizes, breakpoints, density, themes, 200% scaling, long text, missing icons,
/// loading, and error states. The eleven canonical cells are transcribed here
/// in spec order and never invented:
///
/// `1536x1024`, `1440`, `1180`, `900`, `600`, `mobile`, `themes`,
/// `200_percent_scale`, `long_text`, `missing_icon`, `error_states`.
///
/// The contract is fail-closed like its siblings (115.49, 115.50, 115.51):
///
/// * a cell outside the canonical set is rejected with [ArgumentError];
/// * a canonical cell that was never recorded is rejected with [StateError];
/// * a cell that has no measurable assertion is rejected with
///   [ArgumentError] — a "pass" with no assertion would be a rubber stamp;
/// * a cell that is not passing must say why (`fail` and `blocked` both
///   require a note) and a `blocked` cell may never carry assertions or
///   measurements, so an external boundary cannot be dressed up as a local
///   pass;
/// * [AccountVisualRegressionReport.isPass] only turns true when the matrix is
///   complete and every canonical cell passed, and [verdict] must be repeated
///   verbatim in the committed manifest.
///
/// Viewport sizes are derived from live contracts instead of invented numbers:
/// the reference desktop geometry is `AccountCenterWideDesktopFrame` (which
/// transcribes `spec.layout.reference_desktop`), the five tiers come from
/// `AccountCenterLayoutTier` (which transcribes `spec.layout.breakpoints`),
/// the maximum text scale is `AccountCenterAccessibility` (115.7), and the
/// minimum touch target is the density token of step 115.5.
library;

import 'dart:ui' show Size;

import 'account_center_accessibility.dart';
import 'account_center_design_tokens.dart';
import 'account_center_responsive_grid.dart';
import 'account_center_wide_desktop_frame.dart';

/// Which surfaces a cell actually measured when it ran.
enum AccountVisualRegressionAssertion {
  /// The chrome rendered at the cell's viewport without an exception.
  renders,

  /// Layout geometry (bands, columns, summary placement) matched the plan.
  layout,

  /// A Void theme family repainted the chrome surface.
  theme,

  /// 200% text expansion kept the touch target and produced no overflow.
  scaling,

  /// Long labels ellipsized instead of forcing a RenderFlex overflow.
  longText,

  /// A provider id with no bundled mark resolved to a generic icon with a
  /// spoken fallback name.
  missingIcon,

  /// A loading or error provider rendered real copy instead of throwing.
  uiState,

  /// A degraded input degraded visibly instead of crashing the page.
  degradation,
}

/// Outcome of one canonical matrix cell run.
enum AccountVisualCellStatus {
  /// Every assertion of the cell held.
  pass,

  /// The cell ran and at least one assertion failed.
  fail,

  /// The cell cannot be evaluated locally (external boundary).
  blocked,

  /// Recorded as a target but not yet run.
  pending,
}

/// One recorded cell of the visual regression matrix.
final class AccountVisualRegressionCell {
  const AccountVisualRegressionCell({
    required this.cell,
    required this.status,
    required this.assertions,
    this.measurements = const <String>[],
    this.measured = 0,
    this.note = '',
  });

  /// Canonical cell name; must match its report key.
  final String cell;

  final AccountVisualCellStatus status;

  /// What the cell actually measured when it ran.
  final Set<AccountVisualRegressionAssertion> assertions;

  /// One entry per concrete measurement the run took.
  ///
  /// Keeping the list (not just a count) means a manifest cannot inflate its
  /// own numbers: the committed row must name what it actually measured.
  final List<String> measurements;

  /// Number of concrete measurements recorded by the run.
  final int measured;

  /// Why the cell is not passing, or a scope clarification for a passing one.
  final String note;

  Map<String, Object?> toPublicJson() => <String, Object?>{
    'cell': cell,
    'status': status.name,
    'assertions': assertions.map((value) => value.name).toList(growable: false),
    'measurements': measurements,
    'measured': measured,
    'note': note,
  };
}

/// The validated matrix for canonical step 115.52.
final class AccountVisualRegressionReport {
  AccountVisualRegressionReport._(this.results);

  /// Recorded cells in canonical order.
  final Map<String, AccountVisualRegressionCell> results;

  /// True when every canonical cell has a recorded, non-pending row.
  bool get isComplete => results.values.every(
    (row) => row.status != AccountVisualCellStatus.pending,
  );

  int get passCount => results.values
      .where((row) => row.status == AccountVisualCellStatus.pass)
      .length;

  bool get isPass =>
      isComplete &&
      passCount == AccountCenterVisualRegressionMatrix.requiredCells.length;

  String get verdict => !isComplete
      ? 'INCOMPLETE'
      : isPass
      ? 'ALL_PASS'
      : 'COMPLETE_${passCount}_OF_'
            '${AccountCenterVisualRegressionMatrix.requiredCells.length}_PASS';

  AccountVisualCellStatus statusOf(String cell) => results[cell]!.status;
}

/// Fail-closed Visual Regression Matrix for canonical step 115.52.
abstract final class AccountCenterVisualRegressionMatrix {
  /// Path of the committed evidence manifest.
  static const String manifestPath =
      'docs/planning/v1.2/sprint_115_visual_regression_matrix.json';

  /// `required_matrix` for canonical step 115.52, in spec order.
  static const List<String> requiredCells = <String>[
    '1536x1024',
    '1440',
    '1180',
    '900',
    '600',
    'mobile',
    'themes',
    '200_percent_scale',
    'long_text',
    'missing_icon',
    'error_states',
  ];

  /// Viewport used by the `mobile` cell.
  ///
  /// 390x844 is the iPhone 12/13/14 logical size. It is NOT a spec number, so
  /// it is named as a probe viewport and the tier assertion is the canonical
  /// one: any width under `AccountCenterLayoutTier.mobile.maxWidth` reaches
  /// the same chrome.
  static const Size mobileViewport = Size(390, 844);

  /// Viewport used by the `600` and `900` cells: tall enough that the whole
  /// shell is exercised instead of a single clipped screen.
  static const Size tallProbeViewport = Size(600, 1200);

  /// Viewport used by the `1180` cell.
  static const Size desktopProbeViewport = Size(1180, 900);

  /// Viewport used by the `1440` cell.
  static const Size wideDesktopProbeViewport = Size(1440, 900);

  /// The subset of [requiredCells] that names a viewport.
  ///
  /// `themes`, `200_percent_scale`, `long_text`, `missing_icon`, and
  /// `error_states` are cross-cutting conditions, not sizes, so asking
  /// [viewportFor] for one of them must fail rather than invent a number.
  static const List<String> sizeCells = <String>[
    '1536x1024',
    '1440',
    '1180',
    '900',
    '600',
    'mobile',
  ];

  /// Reference desktop viewport, derived from the 115.45 frame.
  static Size get referenceViewport => const Size(
    AccountCenterWideDesktopFrame.referenceWidth,
    AccountCenterWideDesktopFrame.referenceHeight,
  );

  /// The viewport a cell renders at.
  ///
  /// Throws [ArgumentError] for a non-viewport cell, so a caller cannot ask
  /// for a size for `themes` and receive a fabricated number.
  static Size viewportFor(String cell) => switch (cell) {
    '1536x1024' => referenceViewport,
    '1440' => wideDesktopProbeViewport,
    '1180' => desktopProbeViewport,
    '900' => const Size(900, 1200),
    '600' => tallProbeViewport,
    'mobile' => mobileViewport,
    _ => throw ArgumentError.value(
      cell,
      'cell',
      'Cell $cell has no viewport; it is not a size cell.',
    ),
  };

  /// The layout tier a viewport cell must resolve to.
  static AccountCenterLayoutTier tierFor(String cell) =>
      AccountCenterResponsiveGrid.resolve(viewportFor(cell).width).tier;

  /// Text scale the `200_percent_scale` cell renders at.
  ///
  /// Read from the 115.7 accessibility contract, which itself transcribes
  /// `accessibility.requirements[5]` ("UI supports 200 percent scaling and text
  /// expansion") — so the number is not a local preference.
  static double get maximumTextScale =>
      AccountCenterAccessibility.maximumSupportedTextScale;

  /// Minimum touch target the scaling cell must preserve.
  static double get minimumTouchTarget =>
      AccountCenterDesignTokens.density.minimumTouchTarget;

  /// Validates a cell map against [requiredCells].
  static AccountVisualRegressionReport buildReport(
    Map<String, AccountVisualRegressionCell> results,
  ) {
    for (final key in results.keys) {
      if (!requiredCells.contains(key)) {
        throw ArgumentError.value(
          key,
          'results',
          'Cell outside the canonical required_matrix of step 115.52.',
        );
      }
    }
    final missing = requiredCells
        .where((cell) => !results.containsKey(cell))
        .toList(growable: false);
    if (missing.isNotEmpty) {
      throw StateError('Missing canonical cell(s): ${missing.join(', ')}.');
    }
    final ordered = <String, AccountVisualRegressionCell>{
      for (final cell in requiredCells) cell: results[cell]!,
    };
    for (final entry in ordered.entries) {
      _validate(entry.key, entry.value);
    }
    return AccountVisualRegressionReport._(Map.unmodifiable(ordered));
  }

  static void _validate(String key, AccountVisualRegressionCell row) {
    if (row.cell != key) {
      throw ArgumentError.value(
        row.cell,
        'results',
        'Row labelled ${row.cell} is stored under the canonical key $key.',
      );
    }
    if (row.measured < 0) {
      throw ArgumentError.value(
        row.measured,
        'results',
        'Cell $key reports a negative measurement count.',
      );
    }
    if (row.measured != row.measurements.length) {
      throw ArgumentError.value(
        row.measured,
        'results',
        'Cell $key claims ${row.measured} measurements but lists '
            '${row.measurements.length}.',
      );
    }
    for (final measurement in row.measurements) {
      if (measurement.trim().isEmpty) {
        throw ArgumentError.value(
          measurement,
          'results',
          'Cell $key has an unnamed measurement.',
        );
      }
    }
    switch (row.status) {
      case AccountVisualCellStatus.pass:
        if (row.assertions.isEmpty || row.measured == 0) {
          throw ArgumentError.value(
            row.assertions,
            'results',
            'Cell $key claims pass without a measured assertion.',
          );
        }
      case AccountVisualCellStatus.fail:
        if (row.note.trim().isEmpty) {
          throw ArgumentError.value(
            row.note,
            'results',
            'Cell $key must name the assertion that failed.',
          );
        }
      case AccountVisualCellStatus.blocked:
        if (row.note.trim().isEmpty) {
          throw ArgumentError.value(
            row.note,
            'results',
            'Cell $key must name the external boundary it is waiting on.',
          );
        }
        if (row.measured != 0 || row.assertions.isNotEmpty) {
          throw ArgumentError.value(
            row.measured,
            'results',
            'Cell $key is blocked and may not carry local measurements.',
          );
        }
      case AccountVisualCellStatus.pending:
        if (row.measured != 0 || row.assertions.isNotEmpty) {
          throw ArgumentError.value(
            row.measured,
            'results',
            'Cell $key is pending and may not claim a measured assertion.',
          );
        }
    }
  }
}
