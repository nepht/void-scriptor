import 'dart:convert';
import 'dart:io';

/// Outcome of the step 116.47 brand, visual and accessibility gate.
enum Sprint116BrandVisualGateStatus { pass, fail, blocked }

/// One connector icon as the product actually ships it.
///
/// The fields are deliberately the ones a reviewer can look at: where the
/// mark came from, how large it really renders, and whether the pixels on
/// disk are the pixels a user sees. A checklist that only walks the declared
/// size list certifies sizes nobody ships, so [renderedSizePx] is checked
/// against [declaredSizesPx] instead of the list alone.
class Sprint116IconAsset {
  const Sprint116IconAsset({
    required this.iconId,
    required this.providerId,
    required this.iconOrigin,
    required this.officialReference,
    required this.fallbackApprovedBy,
    required this.fallbackReason,
    required this.declaredSizesPx,
    required this.renderedSizePx,
    required this.assetWidthPx,
    required this.assetHeightPx,
    required this.assetSha256,
    required this.isPlaceholder,
    required this.source,
    this.evidenceRef,
  });

  final String iconId;
  final String providerId;

  /// `official` or `approved_fallback`; anything else is unproven branding.
  final String iconOrigin;
  final String officialReference;
  final String fallbackApprovedBy;
  final String fallbackReason;
  final List<int> declaredSizesPx;

  /// The size the UI really draws, in CSS pixels.
  final int renderedSizePx;
  final int assetWidthPx;
  final int assetHeightPx;
  final String assetSha256;

  /// A grey box standing in for a mark is not brand identity.
  final bool isPlaceholder;
  final String source;
  final String? evidenceRef;
}

/// One captured surface under one theme, compared against its baseline.
class Sprint116VisualRegressionCheck {
  const Sprint116VisualRegressionCheck({
    required this.surfaceId,
    required this.theme,
    required this.baselineSha256,
    required this.currentSha256,
    required this.baselineExists,
    required this.diffReviewed,
    required this.diffReviewedBy,
    required this.hardcodedColorCount,
    required this.contrastRatio,
    required this.capturedAtEpochMs,
    required this.source,
    this.evidenceRef,
  });

  final String surfaceId;
  final String theme;
  final String baselineSha256;
  final String currentSha256;

  /// Without a baseline there is nothing to regress against, so a green
  /// result would be an absence of evidence rather than a pass.
  final bool baselineExists;
  final bool diffReviewed;
  final String diffReviewedBy;
  final int hardcodedColorCount;
  final double contrastRatio;
  final int capturedAtEpochMs;
  final String source;
  final String? evidenceRef;
}

/// One surface rendered at one width.
class Sprint116BreakpointCheck {
  const Sprint116BreakpointCheck({
    required this.surfaceId,
    required this.widthPx,
    required this.minSupportedWidthPx,
    required this.renderSucceeded,
    required this.overflowDetected,
    required this.clippedContent,
    required this.containsChart,
    required this.source,
    this.evidenceRef,
  });

  final String surfaceId;
  final int widthPx;

  /// The narrowest width the product claims to support.
  final int minSupportedWidthPx;
  final bool renderSucceeded;
  final bool overflowDetected;
  final bool clippedContent;
  final bool containsChart;
  final String source;
  final String? evidenceRef;
}

/// One asset paired with what the UI shows when that asset cannot load.
class Sprint116FallbackCheck {
  const Sprint116FallbackCheck({
    required this.assetId,
    required this.assetKind,
    required this.coversId,
    required this.primaryAsset,
    required this.declaredFallback,
    required this.fallbackAssetSha256,
    required this.fallbackVerified,
    required this.assetMissingAtRuntime,
    required this.errorStateDeclared,
    required this.source,
    this.evidenceRef,
  });

  final String assetId;
  final String assetKind;

  /// The shipped asset this decision is about, e.g. `icon_openai`.
  final String coversId;
  final String primaryAsset;
  final String declaredFallback;
  final String fallbackAssetSha256;
  final bool fallbackVerified;
  final bool assetMissingAtRuntime;
  final bool errorStateDeclared;
  final String source;
  final String? evidenceRef;
}

/// One keyboard walk over one surface.
class Sprint116KeyboardCheck {
  const Sprint116KeyboardCheck({
    required this.surfaceId,
    required this.focusableControls,
    required this.reachableControls,
    required this.keyboardTrap,
    required this.focusVisible,
    required this.focusOrderMatchesVisualOrder,
    required this.dismissible,
    required this.escapeCloses,
    required this.requiresSpaceActivation,
    required this.activatedByEnter,
    required this.activatedBySpace,
    required this.source,
    this.evidenceRef,
  });

  final String surfaceId;
  final int focusableControls;

  /// How many of the focusable controls a keyboard could actually reach.
  final int reachableControls;
  final bool keyboardTrap;
  final bool focusVisible;
  final bool focusOrderMatchesVisualOrder;
  final bool dismissible;
  final bool escapeCloses;
  final bool requiresSpaceActivation;
  final bool activatedByEnter;
  final bool activatedBySpace;
  final String source;
  final String? evidenceRef;
}

/// One surface exercised with one screen reader.
class Sprint116ScreenReaderCheck {
  const Sprint116ScreenReaderCheck({
    required this.surfaceId,
    required this.readerName,
    required this.readerTested,
    required this.semanticLabel,
    required this.labelMatchesVisibleText,
    required this.controlRole,
    required this.dynamicStatus,
    required this.statusInLiveRegion,
    required this.colorOnlyEncoding,
    required this.source,
    this.evidenceRef,
  });

  final String surfaceId;
  final String readerName;
  final bool readerTested;
  final String semanticLabel;

  /// Voice control speaks the visible label, so a label that disagrees with
  /// the pixels breaks the spoken name as well as the announced name.
  final bool labelMatchesVisibleText;
  final String controlRole;
  final bool dynamicStatus;
  final bool statusInLiveRegion;

  /// A red dot that only reads as "failed" by hue conveys nothing to a
  /// reader and nothing to a colour-blind user.
  final bool colorOnlyEncoding;
  final String source;
  final String? evidenceRef;
}

/// One chart and the text route to the same information.
class Sprint116ChartAlternative {
  const Sprint116ChartAlternative({
    required this.chartId,
    required this.surfaceId,
    required this.chartKind,
    required this.dataPointCount,
    required this.alternativeKind,
    required this.alternativeCoversAllPoints,
    required this.alternativeUpToDate,
    required this.emptyStateDeclared,
    required this.colorOnlyLegend,
    required this.source,
    this.evidenceRef,
  });

  final String chartId;
  final String surfaceId;
  final String chartKind;
  final int dataPointCount;

  /// `table` or `text_summary`; `none` is not an alternative.
  final String alternativeKind;
  final bool alternativeCoversAllPoints;
  final bool alternativeUpToDate;
  final bool emptyStateDeclared;
  final bool colorOnlyLegend;
  final String source;
  final String? evidenceRef;
}

/// The complete control set the gate certifies.
class Sprint116BrandVisualControlSet {
  Sprint116BrandVisualControlSet({
    required this.icons,
    required this.visuals,
    required this.breakpoints,
    required this.fallbacks,
    required this.keyboard,
    required this.screenReader,
    required this.charts,
  });

  final List<Sprint116IconAsset> icons;
  final List<Sprint116VisualRegressionCheck> visuals;
  final List<Sprint116BreakpointCheck> breakpoints;
  final List<Sprint116FallbackCheck> fallbacks;
  final List<Sprint116KeyboardCheck> keyboard;
  final List<Sprint116ScreenReaderCheck> screenReader;
  final List<Sprint116ChartAlternative> charts;
}

class Sprint116BrandVisualReport {
  Sprint116BrandVisualReport({
    required this.state,
    required this.invalidRecords,
    required this.coveredAreas,
    required this.unauditedSurfaces,
  });

  final Sprint116BrandVisualGateStatus state;
  final List<String> invalidRecords;
  final List<String> coveredAreas;

  /// Surfaces shipped somewhere but never walked by keyboard or reader.
  final List<String> unauditedSurfaces;

  String get externalGates => Sprint116BrandVisualContract.externalGates;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'canonical_step': Sprint116BrandVisualContract.canonicalStep,
      'state': state.name,
      'invalid_records': invalidRecords,
      'covered_areas': coveredAreas,
      'unaudited_surfaces': unauditedSurfaces,
      'live_visual_verification': false,
      'external_gates': externalGates,
    };
  }
}

abstract final class Sprint116BrandVisualContract {
  static const String canonicalStep = '116.47';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_brand_visual_accessibility_gate.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The seven evidence areas canonical step 116.47 requires.
  static const List<String> requiredAreas = <String>[
    'icon_review',
    'visual_regression',
    'breakpoints',
    'fallbacks',
    'keyboard',
    'screen_reader',
    'chart_alternatives',
  ];

  static const List<String> supportedSources = <String>[
    'synthetic_local',
    'live',
  ];

  static const List<String> knownThemes = <String>['light', 'dark'];

  /// Certification rule: official icon, or an approved fallback. Nothing else
  /// is a brand decision.
  static const List<String> knownIconOrigins = <String>[
    'official',
    'approved_fallback',
  ];

  /// The only alternatives that carry a chart's information in text.
  static const List<String> knownChartAlternatives = <String>[
    'table',
    'text_summary',
  ];

  /// Below this the mark is a texture, not an identity.
  static const int minimumRenderedSizePx = 16;

  /// WCAG AA for body text.
  static const double requiredContrastRatio = 4.5;

  /// A baseline older than this describes a product that no longer exists.
  static const int maxEvidenceAgeDays = 180;
}

class Sprint116BrandVisualAccessibilityGate {
  /// Certifies the seven brand, visual and accessibility areas of step 116.47.
  ///
  /// Manifest fixtures are consulted only when [controls] is omitted, so an
  /// explicit control set can never borrow fixture data to pass.
  Sprint116BrandVisualReport certify({
    Sprint116BrandVisualControlSet? controls,
    int? asOfEpochMs,
    bool requireCoverage = false,
  }) {
    // Borrowed only when the caller supplies nothing, so an explicit set can
    // never pass on fixture values it did not send.
    final usedManifest = controls == null;
    final manifest = _readManifest();
    final effective = controls ?? _controlsFromManifest(manifest);
    final effectiveAsOf =
        asOfEpochMs ?? (usedManifest ? _manifestAsOf(manifest) : null);

    if (effectiveAsOf == null || effectiveAsOf <= 0) {
      return _blocked('as_of_epoch_ms');
    }

    final emptySet = <String>[
      if (effective.icons.isEmpty) 'icon_review',
      if (effective.visuals.isEmpty) 'visual_regression',
      if (effective.breakpoints.isEmpty) 'breakpoints',
      if (effective.fallbacks.isEmpty) 'fallbacks',
      if (effective.keyboard.isEmpty) 'keyboard',
      if (effective.screenReader.isEmpty) 'screen_reader',
      if (effective.charts.isEmpty) 'chart_alternatives',
    ];
    if (emptySet.isNotEmpty) {
      // Absent checks are not passing checks; an unrun area is a gap.
      return _blocked(emptySet.first);
    }

    final invalid = <String>[];
    final covered = <String>[];

    void collect({
      required String group,
      required int index,
      required String identity,
      required Set<String> failed,
      required Set<String> evidence,
      required String source,
      String? evidenceRef,
    }) {
      if (identity.isEmpty) {
        // Without an identity the record cannot be attributed, so it is
        // rejected on identity alone rather than by guessing a key.
        invalid.add('record_id:$group:$index');
        return;
      }
      for (final area in failed) {
        invalid.add('$area:$identity');
      }
      for (final area in evidence) {
        if (!covered.contains(area)) covered.add(area);
      }
      if (!Sprint116BrandVisualContract.supportedSources.contains(source) ||
          (source == 'live' &&
              (evidenceRef == null || evidenceRef.trim().isEmpty))) {
        invalid.add('no_mock_values:$identity');
      }
    }

    for (var index = 0; index < effective.icons.length; index++) {
      final icon = effective.icons[index];
      final failed = <String>{};
      final evidence = <String>{};
      _certifyIcon(icon, failed, evidence);
      collect(
        group: 'icon',
        index: index,
        identity: icon.iconId.trim(),
        failed: failed,
        evidence: evidence,
        source: icon.source.trim(),
        evidenceRef: icon.evidenceRef,
      );
    }

    // Two providers sharing one file means the second is a re-skin, not a
    // distinct identity, so the asset hash has to be unique per mark.
    final byAsset = <String, List<String>>{};
    for (final icon in effective.icons) {
      final sha = icon.assetSha256.trim();
      if (sha.isEmpty) continue;
      byAsset.putIfAbsent(sha, () => <String>[]).add(icon.iconId.trim());
    }
    for (final entry in byAsset.entries) {
      if (entry.value.length > 1) {
        final sorted = entry.value.toList()..sort();
        invalid.add('icon_distinctness:${sorted.join('|')}');
      }
    }

    for (var index = 0; index < effective.visuals.length; index++) {
      final visual = effective.visuals[index];
      final failed = <String>{};
      final evidence = <String>{};
      _certifyVisual(visual, effectiveAsOf, failed, evidence);
      collect(
        group: 'visual',
        index: index,
        identity: _visualIdentity(visual),
        failed: failed,
        evidence: evidence,
        source: visual.source.trim(),
        evidenceRef: visual.evidenceRef,
      );
    }

    for (var index = 0; index < effective.breakpoints.length; index++) {
      final breakpoint = effective.breakpoints[index];
      final failed = <String>{};
      final evidence = <String>{};
      _certifyBreakpoint(breakpoint, failed, evidence);
      collect(
        group: 'breakpoint',
        index: index,
        identity: breakpoint.surfaceId.trim(),
        failed: failed,
        evidence: evidence,
        source: breakpoint.source.trim(),
        evidenceRef: breakpoint.evidenceRef,
      );
    }

    // One capture at one width is the classic way this gate certifies a
    // layout that only ever broke at another size, so the run has to show at
    // least two widths and every width the product claims to support.
    final widthsBySurface = <String, Set<int>>{};
    final claimedMinBySurface = <String, int>{};
    for (final breakpoint in effective.breakpoints) {
      final surface = breakpoint.surfaceId.trim();
      if (surface.isEmpty) continue;
      (widthsBySurface[surface] ??= <int>{}).add(breakpoint.widthPx);
      final claimed = claimedMinBySurface[surface];
      if (claimed == null || breakpoint.minSupportedWidthPx > claimed) {
        claimedMinBySurface[surface] = breakpoint.minSupportedWidthPx;
      }
    }
    for (final surface in claimedMinBySurface.keys) {
      final widths = widthsBySurface[surface] ?? const <int>{};
      final claimed = claimedMinBySurface[surface] ?? 0;
      if (widths.length < 2 || !widths.contains(claimed)) {
        invalid.add('breakpoint_min_coverage:$surface');
      }
    }

    for (var index = 0; index < effective.fallbacks.length; index++) {
      final fallback = effective.fallbacks[index];
      final failed = <String>{};
      final evidence = <String>{};
      _certifyFallback(fallback, failed, evidence);
      collect(
        group: 'fallback',
        index: index,
        identity: fallback.assetId.trim(),
        failed: failed,
        evidence: evidence,
        source: fallback.source.trim(),
        evidenceRef: fallback.evidenceRef,
      );
    }

    // An icon can pass its own review and still have no answer for the
    // machine that cannot draw it, so every shipped mark owes a decision.
    final fallbackCoveredIds = <String>{
      for (final fallback in effective.fallbacks)
        if (fallback.assetKind.trim() == 'icon') fallback.coversId.trim(),
    };
    for (final icon in effective.icons) {
      final iconId = icon.iconId.trim();
      if (iconId.isEmpty) continue;
      if (!fallbackCoveredIds.contains(iconId)) {
        invalid.add('fallback_coverage:$iconId');
      }
    }

    for (var index = 0; index < effective.keyboard.length; index++) {
      final check = effective.keyboard[index];
      final failed = <String>{};
      final evidence = <String>{};
      _certifyKeyboard(check, failed, evidence);
      collect(
        group: 'keyboard',
        index: index,
        identity: check.surfaceId.trim(),
        failed: failed,
        evidence: evidence,
        source: check.source.trim(),
        evidenceRef: check.evidenceRef,
      );
    }

    for (var index = 0; index < effective.screenReader.length; index++) {
      final check = effective.screenReader[index];
      final failed = <String>{};
      final evidence = <String>{};
      _certifyScreenReader(check, failed, evidence);
      collect(
        group: 'screen_reader',
        index: index,
        identity: check.surfaceId.trim(),
        failed: failed,
        evidence: evidence,
        source: check.source.trim(),
        evidenceRef: check.evidenceRef,
      );
    }

    for (var index = 0; index < effective.charts.length; index++) {
      final chart = effective.charts[index];
      final failed = <String>{};
      final evidence = <String>{};
      _certifyChart(chart, failed, evidence);
      collect(
        group: 'chart',
        index: index,
        identity: chart.chartId.trim(),
        failed: failed,
        evidence: evidence,
        source: chart.source.trim(),
        evidenceRef: chart.evidenceRef,
      );
    }

    // A surface can render perfectly and still be a mouse-only, unheard
    // surface, so the areas that talk about humans have to be walked for
    // every surface the product ships.
    final shippedSurfaces = <String>{
      for (final visual in effective.visuals) visual.surfaceId.trim(),
      for (final breakpoint in effective.breakpoints)
        breakpoint.surfaceId.trim(),
      for (final check in effective.keyboard) check.surfaceId.trim(),
      for (final check in effective.screenReader) check.surfaceId.trim(),
      for (final chart in effective.charts) chart.surfaceId.trim(),
    }..removeWhere((surface) => surface.isEmpty);

    final keyboardSurfaces = <String>{
      for (final check in effective.keyboard) check.surfaceId.trim(),
    };
    final screenReaderSurfaces = <String>{
      for (final check in effective.screenReader) check.surfaceId.trim(),
    };
    final chartSurfaces = <String>{
      for (final chart in effective.charts) chart.surfaceId.trim(),
    };

    final unaudited = <String>[];
    for (final surface in shippedSurfaces) {
      if (!keyboardSurfaces.contains(surface)) {
        invalid.add('keyboard_coverage:$surface');
        unaudited.add(surface);
      }
      if (!screenReaderSurfaces.contains(surface)) {
        invalid.add('screen_reader_coverage:$surface');
        if (!unaudited.contains(surface)) unaudited.add(surface);
      }
    }
    for (final breakpoint in effective.breakpoints) {
      final surface = breakpoint.surfaceId.trim();
      if (surface.isEmpty || !breakpoint.containsChart) continue;
      if (!chartSurfaces.contains(surface)) {
        invalid.add('chart_coverage:$surface');
      }
    }

    if (requireCoverage) {
      for (final area in Sprint116BrandVisualContract.requiredAreas) {
        if (!covered.contains(area)) {
          invalid.add('area_coverage:$area');
        }
      }
    }

    unaudited.sort();
    return Sprint116BrandVisualReport(
      state: invalid.isEmpty
          ? Sprint116BrandVisualGateStatus.pass
          : Sprint116BrandVisualGateStatus.fail,
      invalidRecords: invalid,
      coveredAreas: covered,
      unauditedSurfaces: unaudited,
    );
  }

  void _certifyIcon(
    Sprint116IconAsset icon,
    Set<String> failed,
    Set<String> evidence,
  ) {
    if (icon.providerId.trim().isEmpty) {
      failed.add('icon_review');
    }
    if (icon.assetSha256.trim().isEmpty ||
        icon.assetWidthPx <= 0 ||
        icon.assetHeightPx <= 0) {
      failed.add('icon_review');
    }
    if (!Sprint116BrandVisualContract.knownIconOrigins.contains(
      icon.iconOrigin.trim(),
    )) {
      failed.add('icon_review');
    }
    if (icon.isPlaceholder) {
      // A grey box standing in for a mark is a gap in the identity, not a
      // cosmetic detail.
      failed.add('icon_review');
    }
    if (icon.renderedSizePx <
        Sprint116BrandVisualContract.minimumRenderedSizePx) {
      failed.add('icon_review');
    }
    if (!icon.declaredSizesPx.contains(icon.renderedSizePx)) {
      // The size the UI draws was never reviewed, so the size list certifies
      // images nobody ever sees.
      failed.add('icon_review');
    }
    if (icon.iconOrigin.trim() == 'official') {
      if (icon.officialReference.trim().isEmpty) {
        failed.add('icon_review');
      }
    } else if (icon.iconOrigin.trim() == 'approved_fallback') {
      // A fallback is allowed, but only when someone owns the decision and
      // says why; an unnamed substitute is drift, not a fallback.
      if (icon.fallbackApprovedBy.trim().isEmpty ||
          icon.fallbackReason.trim().isEmpty) {
        failed.add('icon_review');
      }
    }
    if (failed.isEmpty) evidence.add('icon_review');
  }

  void _certifyVisual(
    Sprint116VisualRegressionCheck visual,
    int asOfEpochMs,
    Set<String> failed,
    Set<String> evidence,
  ) {
    if (!visual.baselineExists) {
      // No baseline means no comparison happened, which is not a clean result.
      failed.add('visual_regression');
    }
    if (!Sprint116BrandVisualContract.knownThemes.contains(
      visual.theme.trim(),
    )) {
      failed.add('visual_regression');
    }
    final baseline = visual.baselineSha256.trim();
    final current = visual.currentSha256.trim();
    if (baseline.isEmpty || current.isEmpty) {
      failed.add('visual_regression');
    } else if (baseline != current) {
      // A real pixel difference that nobody signed off on is exactly the
      // regression this gate exists to stop.
      if (!visual.diffReviewed || visual.diffReviewedBy.trim().isEmpty) {
        failed.add('visual_regression');
      }
    }
    if (visual.hardcodedColorCount > 0) {
      // A hardcoded colour cannot follow the theme the product ships.
      failed.add('visual_regression');
    }
    if (visual.contrastRatio <
        Sprint116BrandVisualContract.requiredContrastRatio) {
      failed.add('visual_regression');
    }
    final captured = visual.capturedAtEpochMs;
    if (captured <= 0 || captured > asOfEpochMs) {
      // A capture from the future is a clock story, not a screenshot.
      failed.add('visual_regression');
    } else {
      final ageDays = (asOfEpochMs - captured) ~/ 86400000;
      if (ageDays > Sprint116BrandVisualContract.maxEvidenceAgeDays) {
        failed.add('visual_regression');
      }
    }
    if (failed.isEmpty) evidence.add('visual_regression');
  }

  void _certifyBreakpoint(
    Sprint116BreakpointCheck breakpoint,
    Set<String> failed,
    Set<String> evidence,
  ) {
    if (breakpoint.widthPx <= 0 || breakpoint.minSupportedWidthPx <= 0) {
      failed.add('breakpoints');
    }
    if (!breakpoint.renderSucceeded) {
      failed.add('breakpoints');
    }
    if (breakpoint.overflowDetected || breakpoint.clippedContent) {
      failed.add('breakpoints');
    }
    if (failed.isEmpty) evidence.add('breakpoints');
  }

  void _certifyFallback(
    Sprint116FallbackCheck fallback,
    Set<String> failed,
    Set<String> evidence,
  ) {
    if (fallback.coversId.trim().isEmpty || fallback.assetKind.trim().isEmpty) {
      failed.add('fallbacks');
    }
    final declared = fallback.declaredFallback.trim();
    if (declared.isEmpty || fallback.fallbackAssetSha256.trim().isEmpty) {
      failed.add('fallbacks');
    }
    if (declared.isNotEmpty && declared == fallback.primaryAsset.trim()) {
      // Falling back to the asset that failed is the same blank box with an
      // extra file.
      failed.add('fallbacks');
    }
    if (!fallback.fallbackVerified) {
      failed.add('fallbacks');
    }
    if (fallback.assetMissingAtRuntime && !fallback.errorStateDeclared) {
      // A missing asset with no declared error state is a silent void.
      failed.add('fallbacks');
    }
    if (failed.isEmpty) evidence.add('fallbacks');
  }

  void _certifyKeyboard(
    Sprint116KeyboardCheck check,
    Set<String> failed,
    Set<String> evidence,
  ) {
    if (check.focusableControls <= 0) {
      failed.add('keyboard');
    }
    if (check.reachableControls < check.focusableControls) {
      // A control a keyboard cannot reach is a mouse-only control.
      failed.add('keyboard');
    }
    if (check.keyboardTrap) failed.add('keyboard');
    if (!check.focusVisible) failed.add('keyboard');
    if (!check.focusOrderMatchesVisualOrder) failed.add('keyboard');
    if (check.dismissible && !check.escapeCloses) {
      // A surface that declares itself dismissible and ignores Escape stays
      // open for anyone who cannot find a mouse.
      failed.add('keyboard');
    }
    if (check.requiresSpaceActivation &&
        (!check.activatedBySpace || !check.activatedByEnter)) {
      failed.add('keyboard');
    }
    if (failed.isEmpty) evidence.add('keyboard');
  }

  void _certifyScreenReader(
    Sprint116ScreenReaderCheck check,
    Set<String> failed,
    Set<String> evidence,
  ) {
    if (check.readerName.trim().isEmpty || !check.readerTested) {
      failed.add('screen_reader');
    }
    if (check.semanticLabel.trim().isEmpty ||
        check.controlRole.trim().isEmpty) {
      // An unnamed control is announced as nothing, which is invisible.
      failed.add('screen_reader');
    }
    if (!check.labelMatchesVisibleText) {
      failed.add('screen_reader');
    }
    if (check.dynamicStatus && !check.statusInLiveRegion) {
      // A status that changes silently is not announced at all.
      failed.add('screen_reader');
    }
    if (check.colorOnlyEncoding) {
      failed.add('screen_reader');
    }
    if (failed.isEmpty) evidence.add('screen_reader');
  }

  void _certifyChart(
    Sprint116ChartAlternative chart,
    Set<String> failed,
    Set<String> evidence,
  ) {
    if (chart.chartKind.trim().isEmpty ||
        chart.surfaceId.trim().isEmpty ||
        chart.dataPointCount < 0) {
      failed.add('chart_alternatives');
    }
    if (chart.dataPointCount == 0) {
      // An empty chart is a legitimate state, but it still has to say so
      // rather than render a void.
      if (!chart.emptyStateDeclared) {
        failed.add('chart_alternatives');
      }
    } else {
      if (!Sprint116BrandVisualContract.knownChartAlternatives.contains(
        chart.alternativeKind.trim(),
      )) {
        failed.add('chart_alternatives');
      }
      if (!chart.alternativeCoversAllPoints) {
        // An alternative that drops data points is a different chart, not an
        // equivalent description of the same one.
        failed.add('chart_alternatives');
      }
      if (!chart.alternativeUpToDate) {
        failed.add('chart_alternatives');
      }
    }
    if (chart.colorOnlyLegend) {
      failed.add('chart_alternatives');
    }
    if (failed.isEmpty) evidence.add('chart_alternatives');
  }

  String _visualIdentity(Sprint116VisualRegressionCheck visual) {
    final surface = visual.surfaceId.trim();
    if (surface.isEmpty) return '';
    return '$surface:${visual.theme.trim()}';
  }

  Sprint116BrandVisualReport _blocked(String reason) {
    return Sprint116BrandVisualReport(
      state: Sprint116BrandVisualGateStatus.blocked,
      invalidRecords: <String>[reason],
      coveredAreas: const <String>[],
      unauditedSurfaces: const <String>[],
    );
  }

  Map<String, dynamic>? _readManifest() {
    final file = File(Sprint116BrandVisualContract.manifestPath);
    if (!file.existsSync()) return null;
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  int? _manifestAsOf(Map<String, dynamic>? manifest) {
    final raw = manifest?['as_of_epoch_ms'];
    return raw is num ? raw.toInt() : null;
  }

  Sprint116BrandVisualControlSet _controlsFromManifest(
    Map<String, dynamic>? manifest,
  ) {
    return Sprint116BrandVisualControlSet(
      icons: _mapList(manifest, 'icons', _iconFromManifest),
      visuals: _mapList(manifest, 'visuals', _visualFromManifest),
      breakpoints: _mapList(manifest, 'breakpoints', _breakpointFromManifest),
      fallbacks: _mapList(manifest, 'fallbacks', _fallbackFromManifest),
      keyboard: _mapList(manifest, 'keyboard', _keyboardFromManifest),
      screenReader: _mapList(manifest, 'screen_readers', _readerFromManifest),
      charts: _mapList(manifest, 'charts', _chartFromManifest),
    );
  }

  List<T> _mapList<T>(
    Map<String, dynamic>? manifest,
    String key,
    T Function(Map<Object?, Object?> item) build,
  ) {
    if (manifest == null) return <T>[];
    final raw = manifest[key];
    if (raw is! List) return <T>[];
    return raw.whereType<Map>().map(build).toList(growable: false);
  }

  List<int> _intList(Object? raw) {
    if (raw is! List) return const <int>[];
    return raw
        .map((item) => (item as num?)?.toInt() ?? 0)
        .toList(growable: false);
  }

  int _int(Object? raw) => (raw as num?)?.toInt() ?? 0;

  double _double(Object? raw) => (raw as num?)?.toDouble() ?? 0;

  Sprint116IconAsset _iconFromManifest(Map<Object?, Object?> item) {
    return Sprint116IconAsset(
      iconId: item['icon_id']?.toString() ?? '',
      providerId: item['provider_id']?.toString() ?? '',
      iconOrigin: item['icon_origin']?.toString() ?? '',
      officialReference: item['official_reference']?.toString() ?? '',
      fallbackApprovedBy: item['fallback_approved_by']?.toString() ?? '',
      fallbackReason: item['fallback_reason']?.toString() ?? '',
      declaredSizesPx: _intList(item['declared_sizes_px']),
      renderedSizePx: _int(item['rendered_size_px']),
      assetWidthPx: _int(item['asset_width_px']),
      assetHeightPx: _int(item['asset_height_px']),
      assetSha256: item['asset_sha256']?.toString() ?? '',
      isPlaceholder: item['is_placeholder'] == true,
      source: item['source']?.toString() ?? '',
      evidenceRef: item['evidence_ref']?.toString(),
    );
  }

  Sprint116VisualRegressionCheck _visualFromManifest(
    Map<Object?, Object?> item,
  ) {
    return Sprint116VisualRegressionCheck(
      surfaceId: item['surface_id']?.toString() ?? '',
      theme: item['theme']?.toString() ?? '',
      baselineSha256: item['baseline_sha256']?.toString() ?? '',
      currentSha256: item['current_sha256']?.toString() ?? '',
      baselineExists: item['baseline_exists'] == true,
      diffReviewed: item['diff_reviewed'] == true,
      diffReviewedBy: item['diff_reviewed_by']?.toString() ?? '',
      hardcodedColorCount: _int(item['hardcoded_color_count']),
      contrastRatio: _double(item['contrast_ratio']),
      capturedAtEpochMs: _int(item['captured_at_epoch_ms']),
      source: item['source']?.toString() ?? '',
      evidenceRef: item['evidence_ref']?.toString(),
    );
  }

  Sprint116BreakpointCheck _breakpointFromManifest(Map<Object?, Object?> item) {
    return Sprint116BreakpointCheck(
      surfaceId: item['surface_id']?.toString() ?? '',
      widthPx: _int(item['width_px']),
      minSupportedWidthPx: _int(item['min_supported_width_px']),
      renderSucceeded: item['render_succeeded'] == true,
      overflowDetected: item['overflow_detected'] == true,
      clippedContent: item['clipped_content'] == true,
      containsChart: item['contains_chart'] == true,
      source: item['source']?.toString() ?? '',
      evidenceRef: item['evidence_ref']?.toString(),
    );
  }

  Sprint116FallbackCheck _fallbackFromManifest(Map<Object?, Object?> item) {
    return Sprint116FallbackCheck(
      assetId: item['asset_id']?.toString() ?? '',
      assetKind: item['asset_kind']?.toString() ?? '',
      coversId: item['covers_id']?.toString() ?? '',
      primaryAsset: item['primary_asset']?.toString() ?? '',
      declaredFallback: item['declared_fallback']?.toString() ?? '',
      fallbackAssetSha256: item['fallback_asset_sha256']?.toString() ?? '',
      fallbackVerified: item['fallback_verified'] == true,
      assetMissingAtRuntime: item['asset_missing_at_runtime'] == true,
      errorStateDeclared: item['error_state_declared'] == true,
      source: item['source']?.toString() ?? '',
      evidenceRef: item['evidence_ref']?.toString(),
    );
  }

  Sprint116KeyboardCheck _keyboardFromManifest(Map<Object?, Object?> item) {
    return Sprint116KeyboardCheck(
      surfaceId: item['surface_id']?.toString() ?? '',
      focusableControls: _int(item['focusable_controls']),
      reachableControls: _int(item['reachable_controls']),
      keyboardTrap: item['keyboard_trap'] == true,
      focusVisible: item['focus_visible'] == true,
      focusOrderMatchesVisualOrder:
          item['focus_order_matches_visual_order'] == true,
      dismissible: item['dismissible'] == true,
      escapeCloses: item['escape_closes'] == true,
      requiresSpaceActivation: item['requires_space_activation'] == true,
      activatedByEnter: item['activated_by_enter'] == true,
      activatedBySpace: item['activated_by_space'] == true,
      source: item['source']?.toString() ?? '',
      evidenceRef: item['evidence_ref']?.toString(),
    );
  }

  Sprint116ScreenReaderCheck _readerFromManifest(Map<Object?, Object?> item) {
    return Sprint116ScreenReaderCheck(
      surfaceId: item['surface_id']?.toString() ?? '',
      readerName: item['reader_name']?.toString() ?? '',
      readerTested: item['reader_tested'] == true,
      semanticLabel: item['semantic_label']?.toString() ?? '',
      labelMatchesVisibleText: item['label_matches_visible_text'] == true,
      controlRole: item['control_role']?.toString() ?? '',
      dynamicStatus: item['dynamic_status'] == true,
      statusInLiveRegion: item['status_in_live_region'] == true,
      colorOnlyEncoding: item['color_only_encoding'] == true,
      source: item['source']?.toString() ?? '',
      evidenceRef: item['evidence_ref']?.toString(),
    );
  }

  Sprint116ChartAlternative _chartFromManifest(Map<Object?, Object?> item) {
    return Sprint116ChartAlternative(
      chartId: item['chart_id']?.toString() ?? '',
      surfaceId: item['surface_id']?.toString() ?? '',
      chartKind: item['chart_kind']?.toString() ?? '',
      dataPointCount: _int(item['data_point_count']),
      alternativeKind: item['alternative_kind']?.toString() ?? '',
      alternativeCoversAllPoints: item['alternative_covers_all_points'] == true,
      alternativeUpToDate: item['alternative_up_to_date'] == true,
      emptyStateDeclared: item['empty_state_declared'] == true,
      colorOnlyLegend: item['color_only_legend'] == true,
      source: item['source']?.toString() ?? '',
      evidenceRef: item['evidence_ref']?.toString(),
    );
  }
}
