import 'package:flutter/material.dart';

/// Central sizing contract for the Character Overview composition.
///
/// Change these values to tune every overview card from one place. The layout
/// uses the available desktop panel height without scaling the UI itself.
class CharacterDesignSheetLayoutSpec {
  const CharacterDesignSheetLayoutSpec({
    this.desktopBreakpoint = 820,
    // The reference sheet gives the technical canvas roughly 67% width and
    // the portrait rail roughly 33%, with a dominant portrait panel.
    this.leftColumnFlex = 2,
    this.rightColumnFlex = 1,
    this.columnGap = 10,
    this.cardGap = 8,
    this.summaryFlex = 20,
    this.turnaroundFlex = 48,
    this.detailsFlex = 32,
    this.portraitFlex = 80,
    this.closeUpFlex = 20,
    this.referencesFlex = 2,
  });

  /// Default Overview density. This is the single customization point for
  /// authors who want a different balance between the visible result cards.
  static const overview = CharacterDesignSheetLayoutSpec();

  final double desktopBreakpoint;
  final int leftColumnFlex;
  final int rightColumnFlex;
  final double columnGap;
  final double cardGap;
  final int summaryFlex;
  final int turnaroundFlex;
  final int detailsFlex;
  final int portraitFlex;
  final int closeUpFlex;
  final int referencesFlex;
}

/// Content-width breakpoint excludes the shell's Explorer and Inspector.
class CharacterDesignSheetLayout extends StatelessWidget {
  const CharacterDesignSheetLayout({
    super.key,
    required this.summary,
    required this.turnaround,
    required this.details,
    required this.portrait,
    this.closeUpDetail,
    this.references,
    this.spec = CharacterDesignSheetLayoutSpec.overview,
  });

  final Widget summary, turnaround, details, portrait;
  final Widget? closeUpDetail;
  final Widget? references;
  final CharacterDesignSheetLayoutSpec spec;

  Widget _naturalStack(List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) SizedBox(height: spec.cardGap),
        children[i],
      ],
    ],
  );

  Widget _boundedStack(List<(Widget, int)> regions) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < regions.length; i++) ...[
        if (i > 0) SizedBox(height: spec.cardGap),
        Expanded(flex: regions[i].$2, child: regions[i].$1),
      ],
    ],
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final largeText = MediaQuery.textScalerOf(context).scale(14) > 21;
      final narrow = constraints.maxWidth < spec.desktopBreakpoint || largeText;
      if (narrow) {
        return _naturalStack([
          summary,
          portrait,
          if (closeUpDetail != null) closeUpDetail!,
          turnaround,
          details,
          if (references != null) references!,
        ]);
      }

      final left = [
        (summary, spec.summaryFlex),
        (turnaround, spec.turnaroundFlex),
        (details, spec.detailsFlex),
      ];
      final right = [
        (portrait, spec.portraitFlex),
        if (closeUpDetail != null) (closeUpDetail!, spec.closeUpFlex),
        if (references != null) (references!, spec.referencesFlex),
      ];
      final hasBoundedHeight = constraints.hasBoundedHeight;

      return Row(
        crossAxisAlignment: hasBoundedHeight
            ? CrossAxisAlignment.stretch
            : CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: spec.leftColumnFlex,
            child: hasBoundedHeight
                ? _boundedStack(left)
                : _naturalStack([for (final region in left) region.$1]),
          ),
          SizedBox(width: spec.columnGap),
          Expanded(
            flex: spec.rightColumnFlex,
            child: hasBoundedHeight
                ? _boundedStack(right)
                : _naturalStack([for (final region in right) region.$1]),
          ),
        ],
      );
    },
  );
}
