import 'package:flutter/material.dart';

import 'content_loading_skeleton.dart';

/// Section error isolation (Step 26.95).
///
/// One broken section must not take down the whole workspace. This boundary
/// wraps a section's async data load: while loading it shows a skeleton, on
/// error it shows [fallback], and only on success does it build the real
/// content via [builder]. Flutter does not support React-style synchronous
/// build-error boundaries, so isolation happens at the async seam — which is
/// where this app's sections actually fail (repository/network/parse errors).
class SectionErrorBoundary<T> extends StatelessWidget {
  const SectionErrorBoundary({
    super.key,
    required this.future,
    required this.builder,
    required this.fallback,
    this.loading,
  });

  final Future<T> future;
  final Widget Function(T data) builder;
  final Widget fallback;
  final Widget? loading;

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.hasError) return fallback;
      if (snapshot.connectionState != ConnectionState.done) {
        return loading ?? const ContentLoadingSkeleton();
      }
      final data = snapshot.data;
      if (data == null) return fallback;
      return builder(data);
    },
  );
}
