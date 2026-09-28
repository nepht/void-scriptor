import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_brand_visual_accessibility_gate.dart';

const int _now = 1700000100000;

/// A visual regression baseline captured a day before the reference clock is
/// comfortably inside the freshness window, so a fixture that is healthy for
/// ordinary reasons does not fail on age alone.
const int _captured = _now - 86400000;

void main() {
  group('116.47 Brand, Visual & Accessibility Gate', () {
    test('locks the seven evidence areas the canonical step demands', () {
      expect(Sprint116BrandVisualContract.requiredAreas, <String>[
        'icon_review',
        'visual_regression',
        'breakpoints',
        'fallbacks',
        'keyboard',
        'screen_reader',
        'chart_alternatives',
      ]);
      expect(Sprint116BrandVisualContract.canonicalStep, '116.47');
      expect(Sprint116BrandVisualContract.externalGates, 'DEFERRED-EXTERNAL');
      expect(
        Sprint116BrandVisualContract.manifestPath,
        'docs/planning/v1.2/sprint_116_brand_visual_accessibility_gate.json',
      );
      expect(Sprint116BrandVisualContract.supportedSources, <String>[
        'synthetic_local',
        'live',
      ]);
      expect(Sprint116BrandVisualContract.knownThemes, <String>[
        'light',
        'dark',
      ]);
      expect(Sprint116BrandVisualContract.knownIconOrigins, <String>[
        'official',
        'approved_fallback',
      ]);
      expect(Sprint116BrandVisualContract.knownChartAlternatives, <String>[
        'table',
        'text_summary',
      ]);
      expect(Sprint116BrandVisualContract.minimumRenderedSizePx, 16);
      expect(Sprint116BrandVisualContract.requiredContrastRatio, 4.5);
      expect(Sprint116BrandVisualContract.maxEvidenceAgeDays, 180);
    });

    test('an icon smaller than a readable size cannot certify as brand', () {
      final report = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(icons: <Sprint116IconAsset>[_icon()]),
        asOfEpochMs: _now,
        requireCoverage: true,
      );
      expect(report.state, Sprint116BrandVisualGateStatus.pass);
      expect(report.invalidRecords, isEmpty);

      final tiny = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(
          icons: <Sprint116IconAsset>[
            _icon(renderedSizePx: 12, declaredSizesPx: <int>[12]),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(tiny.state, Sprint116BrandVisualGateStatus.fail);
      expect(tiny.invalidRecords, contains('icon_review:icon_openai'));
    });

    test('declaring sizes the UI never renders is a real defect', () {
      // The 32px tile people actually see was never captured; a checklist that
      // only walks the declared list certifies a size nobody ships.
      final report = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(
          icons: <Sprint116IconAsset>[
            _icon(renderedSizePx: 40, declaredSizesPx: <int>[16, 24, 32, 48]),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BrandVisualGateStatus.fail);
      expect(report.invalidRecords, contains('icon_review:icon_openai'));
    });

    test(
      'a placeholder is not a brand pass and needs no official reference',
      () {
        final report = Sprint116BrandVisualAccessibilityGate().certify(
          controls: _controls(
            icons: <Sprint116IconAsset>[
              _icon(isPlaceholder: true, officialReference: ''),
            ],
          ),
          asOfEpochMs: _now,
        );
        expect(report.state, Sprint116BrandVisualGateStatus.fail);
        expect(report.invalidRecords, contains('icon_review:icon_openai'));
      },
    );

    test('an approved fallback must name who approved it and why', () {
      final report = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(
          icons: <Sprint116IconAsset>[
            _icon(
              iconOrigin: 'approved_fallback',
              officialReference: '',
              fallbackApprovedBy: '',
              fallbackReason: 'no official mark published',
            ),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BrandVisualGateStatus.fail);
      expect(report.invalidRecords, contains('icon_review:icon_openai'));

      final approved = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(
          icons: <Sprint116IconAsset>[
            _icon(
              iconOrigin: 'approved_fallback',
              officialReference: '',
              fallbackApprovedBy: 'brand-owner',
              fallbackReason: 'provider publishes no icon for this tier',
            ),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(approved.state, Sprint116BrandVisualGateStatus.pass);
    });

    test('an unknown icon origin never certifies', () {
      final report = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(
          icons: <Sprint116IconAsset>[_icon(iconOrigin: 'whatever')],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BrandVisualGateStatus.fail);
      expect(report.invalidRecords, contains('icon_review:icon_openai'));
    });

    test('two providers sharing one official asset is not a brand system', () {
      final report = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(
          icons: <Sprint116IconAsset>[
            _icon(),
            _icon(
              iconId: 'icon_google',
              providerId: 'google',
              assetSha256: _icon().assetSha256,
            ),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BrandVisualGateStatus.fail);
      expect(
        report.invalidRecords.any(
          (entry) => entry.startsWith('icon_distinctness:'),
        ),
        isTrue,
      );
    });

    test(
      'an unreviewed visual diff is a regression, a reviewed one is not',
      () {
        final unreviewed = Sprint116BrandVisualAccessibilityGate().certify(
          controls: _controls(
            visuals: <Sprint116VisualRegressionCheck>[
              _visual(baselineSha256: 'aaaa', currentSha256: 'bbbb'),
            ],
          ),
          asOfEpochMs: _now,
        );
        expect(unreviewed.state, Sprint116BrandVisualGateStatus.fail);
        // The identity is `surface:theme` because the same surface is captured
        // under both themes; a bare surface id could not say which one drifted.
        expect(
          unreviewed.invalidRecords,
          contains('visual_regression:ui_home:dark'),
        );

        final reviewed = Sprint116BrandVisualAccessibilityGate().certify(
          controls: _controls(
            visuals: <Sprint116VisualRegressionCheck>[
              _visual(
                baselineSha256: 'aaaa',
                currentSha256: 'bbbb',
                diffReviewed: true,
                diffReviewedBy: 'qa-reviewer',
              ),
            ],
          ),
          asOfEpochMs: _now,
        );
        expect(reviewed.state, Sprint116BrandVisualGateStatus.pass);
      },
    );

    test('a visual diff nobody signed off on is treated as unreviewed', () {
      final report = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(
          visuals: <Sprint116VisualRegressionCheck>[
            _visual(
              baselineSha256: 'aaaa',
              currentSha256: 'bbbb',
              diffReviewed: true,
              diffReviewedBy: '',
            ),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BrandVisualGateStatus.fail);
      expect(report.invalidRecords, contains('visual_regression:ui_home:dark'));
    });

    test('hardcoded colors and unreadable contrast fail the theme review', () {
      final hardcoded = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(
          visuals: <Sprint116VisualRegressionCheck>[
            _visual(hardcodedColorCount: 3),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(hardcoded.state, Sprint116BrandVisualGateStatus.fail);
      expect(
        hardcoded.invalidRecords,
        contains('visual_regression:ui_home:dark'),
      );

      final dim = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(
          visuals: <Sprint116VisualRegressionCheck>[
            _visual(contrastRatio: 3.2),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(dim.state, Sprint116BrandVisualGateStatus.fail);
      expect(dim.invalidRecords, contains('visual_regression:ui_home:dark'));
    });

    test('an unknown theme is not a certified theme', () {
      final report = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(
          visuals: <Sprint116VisualRegressionCheck>[_visual(theme: 'sepia')],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BrandVisualGateStatus.fail);
      expect(
        report.invalidRecords,
        contains('visual_regression:ui_home:sepia'),
      );
    });

    test('a baseline older than the freshness window certifies nothing', () {
      final report = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(
          visuals: <Sprint116VisualRegressionCheck>[
            _visual(capturedAtEpochMs: _now - 400 * 86400000),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BrandVisualGateStatus.fail);
      expect(report.invalidRecords, contains('visual_regression:ui_home:dark'));
    });

    test('overflow, clipping and a failed render all fail the layout', () {
      final overflow = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(
          breakpoints: <Sprint116BreakpointCheck>[
            _breakpoint(widthPx: 360, overflowDetected: true),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(overflow.state, Sprint116BrandVisualGateStatus.fail);
      expect(overflow.invalidRecords, contains('breakpoints:ui_home'));

      final clipped = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(
          breakpoints: <Sprint116BreakpointCheck>[
            _breakpoint(widthPx: 360, clippedContent: true),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(clipped.state, Sprint116BrandVisualGateStatus.fail);
      expect(clipped.invalidRecords, contains('breakpoints:ui_home'));

      final notRendered = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(
          breakpoints: <Sprint116BreakpointCheck>[
            _breakpoint(widthPx: 360, renderSucceeded: false),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(notRendered.state, Sprint116BrandVisualGateStatus.fail);
      expect(notRendered.invalidRecords, contains('breakpoints:ui_home'));
    });

    test('testing one width proves nothing about responsiveness', () {
      // A single capture at the narrow width is the classic way this gate
      // certifies a layout that only ever broke past 1280.
      final report = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(
          breakpoints: <Sprint116BreakpointCheck>[_breakpoint(widthPx: 360)],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BrandVisualGateStatus.fail);
      expect(
        report.invalidRecords.contains('breakpoint_min_coverage:ui_home'),
        isTrue,
      );
    });

    test(
      'the narrowest capture must be the width the app claims to support',
      () {
        final report = Sprint116BrandVisualAccessibilityGate().certify(
          controls: _controls(
            breakpoints: <Sprint116BreakpointCheck>[
              _breakpoint(widthPx: 360, minSupportedWidthPx: 1024),
              _breakpoint(widthPx: 1440),
            ],
          ),
          asOfEpochMs: _now,
        );
        expect(report.state, Sprint116BrandVisualGateStatus.fail);
        expect(
          report.invalidRecords.contains('breakpoint_min_coverage:ui_home'),
          isTrue,
        );
      },
    );

    test('a fallback that is the primary asset is not a fallback', () {
      final report = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(
          fallbacks: <Sprint116FallbackCheck>[
            _fallback(declaredFallback: 'icon_openai.png'),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BrandVisualGateStatus.fail);
      expect(report.invalidRecords, contains('fallbacks:fb_openai'));
    });

    test('a missing asset with no declared error state is a blank box', () {
      final report = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(
          fallbacks: <Sprint116FallbackCheck>[
            _fallback(assetMissingAtRuntime: true, errorStateDeclared: false),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BrandVisualGateStatus.fail);
      expect(report.invalidRecords, contains('fallbacks:fb_openai'));
    });

    test('every shipped icon must carry a fallback decision', () {
      // The icon can pass its own review and still have no answer for the
      // machine that cannot draw it. The one fallback in play covers
      // icon_openai, so this second mark is the one left undecided.
      final report = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(
          icons: <Sprint116IconAsset>[
            _icon(),
            _icon(iconId: 'icon_google', providerId: 'google'),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BrandVisualGateStatus.fail);
      // icon_openai has a declared fallback, so the gap is the second mark.
      expect(
        report.invalidRecords.contains('fallback_coverage:icon_google'),
        isTrue,
      );
      expect(
        report.invalidRecords.contains('fallback_coverage:icon_openai'),
        isFalse,
      );
    });

    test('a control the keyboard cannot reach is a mouse-only control', () {
      final report = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(
          keyboard: <Sprint116KeyboardCheck>[
            _keyboard(focusableControls: 12, reachableControls: 11),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BrandVisualGateStatus.fail);
      expect(report.invalidRecords, contains('keyboard:ui_home'));
    });

    test('a focus trap, an invisible focus ring and a shuffled order fail', () {
      final trap = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(
          keyboard: <Sprint116KeyboardCheck>[_keyboard(keyboardTrap: true)],
        ),
        asOfEpochMs: _now,
      );
      expect(trap.state, Sprint116BrandVisualGateStatus.fail);
      expect(trap.invalidRecords, contains('keyboard:ui_home'));

      final invisible = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(
          keyboard: <Sprint116KeyboardCheck>[_keyboard(focusVisible: false)],
        ),
        asOfEpochMs: _now,
      );
      expect(invisible.state, Sprint116BrandVisualGateStatus.fail);
      expect(invisible.invalidRecords, contains('keyboard:ui_home'));

      final shuffled = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(
          keyboard: <Sprint116KeyboardCheck>[
            _keyboard(focusOrderMatchesVisualOrder: false),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(shuffled.state, Sprint116BrandVisualGateStatus.fail);
      expect(shuffled.invalidRecords, contains('keyboard:ui_home'));
    });

    test('a dismissible surface that ignores Escape stays open forever', () {
      final report = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(
          keyboard: <Sprint116KeyboardCheck>[
            _keyboard(dismissible: true, escapeCloses: false),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BrandVisualGateStatus.fail);
      expect(report.invalidRecords, contains('keyboard:ui_home'));
    });

    test('an unnamed control is invisible to a screen reader', () {
      final report = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(
          screenReader: <Sprint116ScreenReaderCheck>[
            _screenReader(semanticLabel: ''),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BrandVisualGateStatus.fail);
      expect(report.invalidRecords, contains('screen_reader:ui_home'));
    });

    test('status carried by colour alone is not status', () {
      final report = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(
          screenReader: <Sprint116ScreenReaderCheck>[
            _screenReader(colorOnlyEncoding: true),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BrandVisualGateStatus.fail);
      expect(report.invalidRecords, contains('screen_reader:ui_home'));
    });

    test('a live status change nobody announces is invisible', () {
      final report = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(
          screenReader: <Sprint116ScreenReaderCheck>[
            _screenReader(dynamicStatus: true, statusInLiveRegion: false),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BrandVisualGateStatus.fail);
      expect(report.invalidRecords, contains('screen_reader:ui_home'));
    });

    test(
      'a visible label the reader calls something else fails voice control',
      () {
        final report = Sprint116BrandVisualAccessibilityGate().certify(
          controls: _controls(
            screenReader: <Sprint116ScreenReaderCheck>[
              _screenReader(labelMatchesVisibleText: false),
            ],
          ),
          asOfEpochMs: _now,
        );
        expect(report.state, Sprint116BrandVisualGateStatus.fail);
        expect(report.invalidRecords, contains('screen_reader:ui_home'));
      },
    );

    test('a surface nobody audited for the keyboard or the reader is a gap', () {
      // Both walks target another surface, so `ui_home` ships with no keyboard
      // or reader evidence at all. A gate that only asks "was any walk run?"
      // would call this covered.
      final noKeyboard = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(
          keyboard: <Sprint116KeyboardCheck>[
            _keyboard(surfaceId: 'ui_settings'),
          ],
          screenReader: <Sprint116ScreenReaderCheck>[
            _screenReader(surfaceId: 'ui_settings'),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(noKeyboard.state, Sprint116BrandVisualGateStatus.fail);
      expect(
        noKeyboard.invalidRecords.contains('keyboard_coverage:ui_home'),
        isTrue,
      );
      expect(
        noKeyboard.invalidRecords.contains('screen_reader_coverage:ui_home'),
        isTrue,
      );
    });

    test('a chart with no text alternative is invisible content', () {
      final report = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(charts: <Sprint116ChartAlternative>[_chart()]),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BrandVisualGateStatus.pass);
      expect(report.invalidRecords, isEmpty);

      final bare = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(
          charts: <Sprint116ChartAlternative>[
            _chart(alternativeKind: 'none', alternativeCoversAllPoints: false),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(bare.state, Sprint116BrandVisualGateStatus.fail);
      expect(bare.invalidRecords, contains('chart_alternatives:chart_usage'));
    });

    test('an alternative that drops data points is not an equivalent', () {
      final report = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(
          charts: <Sprint116ChartAlternative>[
            _chart(dataPointCount: 12, alternativeCoversAllPoints: false),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BrandVisualGateStatus.fail);
      expect(report.invalidRecords, contains('chart_alternatives:chart_usage'));
    });

    test('an empty chart with no empty state renders a void', () {
      final report = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(
          charts: <Sprint116ChartAlternative>[
            _chart(
              dataPointCount: 0,
              alternativeKind: 'none',
              alternativeCoversAllPoints: false,
              emptyStateDeclared: false,
            ),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BrandVisualGateStatus.fail);
      expect(report.invalidRecords, contains('chart_alternatives:chart_usage'));
    });

    test('a surface that ships a chart must have that chart audited', () {
      // The audited chart sits on another surface, so `ui_home` ships a chart
      // nobody ever checked the alternative for.
      final report = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(
          breakpoints: <Sprint116BreakpointCheck>[
            _breakpoint(widthPx: 360, containsChart: true),
            _breakpoint(widthPx: 1440),
          ],
          charts: <Sprint116ChartAlternative>[
            _chart(chartId: 'chart_billing', surfaceId: 'ui_settings'),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BrandVisualGateStatus.fail);
      expect(report.invalidRecords.contains('chart_coverage:ui_home'), isTrue);
    });

    test('an unrun area is blocked, never a pass', () {
      final report = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(icons: const <Sprint116IconAsset>[]),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BrandVisualGateStatus.blocked);
      expect(report.invalidRecords, <String>['icon_review']);
    });

    test('a missing reference clock blocks instead of guessing', () {
      final report = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(),
      );
      expect(report.state, Sprint116BrandVisualGateStatus.blocked);
      expect(report.invalidRecords, <String>['as_of_epoch_ms']);
    });

    test('a record with no identity cannot be attributed', () {
      final report = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(icons: <Sprint116IconAsset>[_icon(iconId: '')]),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116BrandVisualGateStatus.fail);
      expect(report.invalidRecords, contains('record_id:icon:0'));
    });

    test('live claims need a reference and invented sources fail', () {
      final live = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(
          icons: <Sprint116IconAsset>[_icon(source: 'live', evidenceRef: '')],
        ),
        asOfEpochMs: _now,
      );
      expect(live.state, Sprint116BrandVisualGateStatus.fail);
      expect(live.invalidRecords, contains('no_mock_values:icon_openai'));

      final invented = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(
          icons: <Sprint116IconAsset>[_icon(source: 'vibes')],
        ),
        asOfEpochMs: _now,
      );
      expect(invented.state, Sprint116BrandVisualGateStatus.fail);
      expect(invented.invalidRecords, contains('no_mock_values:icon_openai'));
    });

    test('an area with no positive evidence fails the coverage demand', () {
      // Every record is present and clean, but not one of them certifies: the
      // chart is empty with no empty state, so the area never produced
      // positive evidence. Requiring coverage has to notice that the walk ran
      // without once proving anything.
      final report = Sprint116BrandVisualAccessibilityGate().certify(
        controls: _controls(
          charts: <Sprint116ChartAlternative>[
            _chart(
              dataPointCount: 0,
              alternativeKind: 'none',
              alternativeCoversAllPoints: false,
              emptyStateDeclared: false,
            ),
          ],
        ),
        asOfEpochMs: _now,
        requireCoverage: true,
      );
      expect(report.state, Sprint116BrandVisualGateStatus.fail);
      expect(
        report.invalidRecords,
        contains('area_coverage:chart_alternatives'),
      );
    });

    test('the local manifest is UNVERIFIED and free of secrets', () {
      final gate = Sprint116BrandVisualAccessibilityGate();
      final report = gate.certify();
      expect(report.state, Sprint116BrandVisualGateStatus.pass);
      expect(report.invalidRecords, isEmpty);
      expect(report.toJson()['live_visual_verification'], isFalse);
      expect(report.toJson()['canonical_step'], '116.47');

      final raw = File(
        Sprint116BrandVisualContract.manifestPath,
      ).readAsStringSync();
      final manifest = jsonDecode(raw) as Map<String, dynamic>;
      expect(manifest['status'], 'UNVERIFIED');
      expect(manifest['live_visual_verification'], isFalse);
      expect(manifest['as_of_epoch_ms'], _now);
      expect(manifest['acceptance_areas'], <String>[
        'icon_review',
        'visual_regression',
        'breakpoints',
        'fallbacks',
        'keyboard',
        'screen_reader',
        'chart_alternatives',
      ]);
      expect(
        manifest['acceptance_areas'],
        Sprint116BrandVisualContract.requiredAreas,
      );
      // Key names are inspected, not raw prose: the limitations sentence says
      // "secret-free" on purpose, and a substring scan would flag that
      // disclaimer as the very leak it denies.
      for (final secret in <String>[
        'api_key',
        'apikey',
        'access_token',
        'bearer',
        'client_secret',
        'password',
      ]) {
        bool carriesSecret(Object? node) {
          if (node is Map) {
            for (final entry in node.entries) {
              if (entry.key.toString().toLowerCase().contains(secret)) {
                return true;
              }
              if (carriesSecret(entry.value)) return true;
            }
            return false;
          }
          if (node is List) return node.any(carriesSecret);
          return node.toString().toLowerCase().contains(secret);
        }

        expect(
          carriesSecret(manifest),
          isFalse,
          reason: 'manifest must not carry $secret',
        );
      }
    });
  });
}

Sprint116IconAsset _icon({
  String iconId = 'icon_openai',
  String providerId = 'openai',
  String iconOrigin = 'official',
  String officialReference = 'https://brand.openai.example/icon.png',
  String fallbackApprovedBy = 'brand-owner',
  String fallbackReason = 'no official mark published',
  List<int> declaredSizesPx = const <int>[16, 24, 32, 48],
  int renderedSizePx = 32,
  int assetWidthPx = 512,
  int assetHeightPx = 512,
  String assetSha256 = 'aa11bb22cc33dd44',
  bool isPlaceholder = false,
  String source = 'synthetic_local',
  String evidenceRef = '',
}) {
  return Sprint116IconAsset(
    iconId: iconId,
    providerId: providerId,
    iconOrigin: iconOrigin,
    officialReference: officialReference,
    fallbackApprovedBy: fallbackApprovedBy,
    fallbackReason: fallbackReason,
    declaredSizesPx: declaredSizesPx,
    renderedSizePx: renderedSizePx,
    assetWidthPx: assetWidthPx,
    assetHeightPx: assetHeightPx,
    assetSha256: assetSha256,
    isPlaceholder: isPlaceholder,
    source: source,
    evidenceRef: evidenceRef,
  );
}

Sprint116VisualRegressionCheck _visual({
  String surfaceId = 'ui_home',
  String theme = 'dark',
  String baselineSha256 = 'aaaa1111',
  String currentSha256 = 'aaaa1111',
  bool baselineExists = true,
  bool diffReviewed = false,
  String diffReviewedBy = '',
  int hardcodedColorCount = 0,
  double contrastRatio = 7.2,
  int capturedAtEpochMs = _captured,
  String source = 'synthetic_local',
}) {
  return Sprint116VisualRegressionCheck(
    surfaceId: surfaceId,
    theme: theme,
    baselineSha256: baselineSha256,
    currentSha256: currentSha256,
    baselineExists: baselineExists,
    diffReviewed: diffReviewed,
    diffReviewedBy: diffReviewedBy,
    hardcodedColorCount: hardcodedColorCount,
    contrastRatio: contrastRatio,
    capturedAtEpochMs: capturedAtEpochMs,
    source: source,
  );
}

Sprint116BreakpointCheck _breakpoint({
  String surfaceId = 'ui_home',
  int widthPx = 360,
  int minSupportedWidthPx = 360,
  bool renderSucceeded = true,
  bool overflowDetected = false,
  bool clippedContent = false,
  bool containsChart = false,
  String source = 'synthetic_local',
}) {
  return Sprint116BreakpointCheck(
    surfaceId: surfaceId,
    widthPx: widthPx,
    minSupportedWidthPx: minSupportedWidthPx,
    renderSucceeded: renderSucceeded,
    overflowDetected: overflowDetected,
    clippedContent: clippedContent,
    containsChart: containsChart,
    source: source,
  );
}

Sprint116FallbackCheck _fallback({
  String assetId = 'fb_openai',
  String assetKind = 'icon',
  String coversId = 'icon_openai',
  String primaryAsset = 'icon_openai.png',
  String declaredFallback = 'icon_openai_fallback.svg',
  String fallbackAssetSha256 = 'ff99ee88dd77cc66',
  bool fallbackVerified = true,
  bool assetMissingAtRuntime = false,
  bool errorStateDeclared = true,
  String source = 'synthetic_local',
}) {
  return Sprint116FallbackCheck(
    assetId: assetId,
    assetKind: assetKind,
    coversId: coversId,
    primaryAsset: primaryAsset,
    declaredFallback: declaredFallback,
    fallbackAssetSha256: fallbackAssetSha256,
    fallbackVerified: fallbackVerified,
    assetMissingAtRuntime: assetMissingAtRuntime,
    errorStateDeclared: errorStateDeclared,
    source: source,
  );
}

Sprint116KeyboardCheck _keyboard({
  String surfaceId = 'ui_home',
  int focusableControls = 12,
  int reachableControls = 12,
  bool keyboardTrap = false,
  bool focusVisible = true,
  bool focusOrderMatchesVisualOrder = true,
  bool dismissible = false,
  bool escapeCloses = true,
  bool requiresSpaceActivation = false,
  bool activatedByEnter = true,
  bool activatedBySpace = false,
  String source = 'synthetic_local',
}) {
  return Sprint116KeyboardCheck(
    surfaceId: surfaceId,
    focusableControls: focusableControls,
    reachableControls: reachableControls,
    keyboardTrap: keyboardTrap,
    focusVisible: focusVisible,
    focusOrderMatchesVisualOrder: focusOrderMatchesVisualOrder,
    dismissible: dismissible,
    escapeCloses: escapeCloses,
    requiresSpaceActivation: requiresSpaceActivation,
    activatedByEnter: activatedByEnter,
    activatedBySpace: activatedBySpace,
    source: source,
  );
}

Sprint116ScreenReaderCheck _screenReader({
  String surfaceId = 'ui_home',
  String readerName = 'nvda',
  bool readerTested = true,
  String semanticLabel = 'Connect OpenAI',
  bool labelMatchesVisibleText = true,
  String controlRole = 'button',
  bool dynamicStatus = true,
  bool statusInLiveRegion = true,
  bool colorOnlyEncoding = false,
  String source = 'synthetic_local',
}) {
  return Sprint116ScreenReaderCheck(
    surfaceId: surfaceId,
    readerName: readerName,
    readerTested: readerTested,
    semanticLabel: semanticLabel,
    labelMatchesVisibleText: labelMatchesVisibleText,
    controlRole: controlRole,
    dynamicStatus: dynamicStatus,
    statusInLiveRegion: statusInLiveRegion,
    colorOnlyEncoding: colorOnlyEncoding,
    source: source,
  );
}

Sprint116ChartAlternative _chart({
  String chartId = 'chart_usage',
  String surfaceId = 'ui_home',
  String chartKind = 'bar',
  int dataPointCount = 12,
  String alternativeKind = 'table',
  bool alternativeCoversAllPoints = true,
  bool alternativeUpToDate = true,
  bool emptyStateDeclared = true,
  bool colorOnlyLegend = false,
  String source = 'synthetic_local',
}) {
  return Sprint116ChartAlternative(
    chartId: chartId,
    surfaceId: surfaceId,
    chartKind: chartKind,
    dataPointCount: dataPointCount,
    alternativeKind: alternativeKind,
    alternativeCoversAllPoints: alternativeCoversAllPoints,
    alternativeUpToDate: alternativeUpToDate,
    emptyStateDeclared: emptyStateDeclared,
    colorOnlyLegend: colorOnlyLegend,
    source: source,
  );
}

/// A complete, internally coherent control set: every area has real records.
///
/// A `null` list means "use the healthy default"; an **empty** list is passed
/// through untouched, so a test can state that an area has no records at all
/// rather than silently receiving a fixture.
Sprint116BrandVisualControlSet _controls({
  List<Sprint116IconAsset>? icons,
  List<Sprint116VisualRegressionCheck>? visuals,
  List<Sprint116BreakpointCheck>? breakpoints,
  List<Sprint116FallbackCheck>? fallbacks,
  List<Sprint116KeyboardCheck>? keyboard,
  List<Sprint116ScreenReaderCheck>? screenReader,
  List<Sprint116ChartAlternative>? charts,
}) {
  return Sprint116BrandVisualControlSet(
    icons: icons ?? <Sprint116IconAsset>[_icon()],
    visuals:
        visuals ??
        <Sprint116VisualRegressionCheck>[
          _visual(theme: 'light'),
          _visual(theme: 'dark'),
        ],
    breakpoints:
        breakpoints ??
        <Sprint116BreakpointCheck>[
          _breakpoint(widthPx: 360, containsChart: true),
          _breakpoint(widthPx: 1024, containsChart: true),
        ],
    fallbacks: fallbacks ?? <Sprint116FallbackCheck>[_fallback()],
    keyboard: keyboard ?? <Sprint116KeyboardCheck>[_keyboard()],
    screenReader: screenReader ?? <Sprint116ScreenReaderCheck>[_screenReader()],
    charts: charts ?? <Sprint116ChartAlternative>[_chart()],
  );
}
