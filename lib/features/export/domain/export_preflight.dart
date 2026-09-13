/// Export Preflight & Format Validation (Step 109.40).
library;

import 'clean_export.dart';
import 'export_profiles.dart';

enum ExportPreflightCheckKind {
  structure,
  assets,
  spoilers,
  specialCharacters,
  render,
}

enum ExportPreflightSeverity { warning, error }

class ExportAssetRef {
  const ExportAssetRef({
    required this.id,
    required this.path,
    required this.exists,
  });

  final String id;
  final String path;
  final bool exists;
}

class ExportPreflightRequest {
  const ExportPreflightRequest({
    required this.documentId,
    required this.sourceText,
    required this.profile,
    this.assets = const <ExportAssetRef>[],
    this.unresolvedSpoilerIds = const <String>[],
    this.previewCharacterLimit = 200,
  });

  final String documentId;
  final String sourceText;
  final ExportProfile profile;
  final List<ExportAssetRef> assets;
  final List<String> unresolvedSpoilerIds;
  final int previewCharacterLimit;
}

class ExportPreflightIssue {
  const ExportPreflightIssue({
    required this.kind,
    required this.severity,
    required this.code,
    required this.message,
  });

  final ExportPreflightCheckKind kind;
  final ExportPreflightSeverity severity;
  final String code;
  final String message;

  bool get isBlocking => severity == ExportPreflightSeverity.error;
}

class ExportPreflightCheck {
  const ExportPreflightCheck({required this.kind, required this.issues});

  final ExportPreflightCheckKind kind;
  final List<ExportPreflightIssue> issues;
}

class ExportManifest {
  const ExportManifest({
    required this.documentId,
    required this.format,
    required this.contentFingerprint,
    required this.assetPaths,
  });

  final String documentId;
  final ExportFormat format;
  final String contentFingerprint;
  final List<String> assetPaths;

  Map<String, Object?> toJson() => <String, Object?>{
    'documentId': documentId,
    'format': format.name,
    'contentFingerprint': contentFingerprint,
    'assetPaths': assetPaths,
  };

  @override
  bool operator ==(Object other) =>
      other is ExportManifest &&
      other.documentId == documentId &&
      other.format == format &&
      other.contentFingerprint == contentFingerprint &&
      _listEquals(other.assetPaths, assetPaths);

  @override
  int get hashCode => Object.hash(
    documentId,
    format,
    contentFingerprint,
    Object.hashAll(assetPaths),
  );

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class ExportPreflightReport {
  const ExportPreflightReport({
    required this.documentId,
    required this.checks,
    required this.preview,
    required this.manifest,
  });

  final String documentId;
  final List<ExportPreflightCheck> checks;
  final String preview;
  final ExportManifest manifest;

  List<ExportPreflightIssue> get issues => <ExportPreflightIssue>[
    for (final check in checks) ...check.issues,
  ];

  List<ExportPreflightIssue> get blockingErrors =>
      issues.where((issue) => issue.isBlocking).toList(growable: false);

  List<ExportPreflightIssue> get warnings =>
      issues.where((issue) => !issue.isBlocking).toList(growable: false);

  bool get isReady => blockingErrors.isEmpty;
}

class ExportPreflightValidator {
  const ExportPreflightValidator({
    this.cleaner = const CleanExportTransformer(),
  });

  final CleanExportTransformer cleaner;

  ExportPreflightReport validate(ExportPreflightRequest request) {
    if (request.previewCharacterLimit <= 0) {
      throw ArgumentError.value(
        request.previewCharacterLimit,
        'previewCharacterLimit',
        'must be positive',
      );
    }

    final cleaned = cleaner.transform(request.sourceText);
    final structure = <ExportPreflightIssue>[];
    final assets = <ExportPreflightIssue>[];
    final spoilers = <ExportPreflightIssue>[];
    final specialCharacters = <ExportPreflightIssue>[];
    final render = <ExportPreflightIssue>[];

    if (request.sourceText.trim().isEmpty) {
      structure.add(
        _error(
          ExportPreflightCheckKind.structure,
          'empty_document',
          'Manuscript is empty.',
        ),
      );
    }
    for (final asset in request.assets.where((asset) => !asset.exists)) {
      assets.add(
        _error(
          ExportPreflightCheckKind.assets,
          'missing_asset',
          'Missing asset: ${asset.path}',
        ),
      );
    }
    for (final id in request.unresolvedSpoilerIds.toSet().toList()..sort()) {
      spoilers.add(
        _warning(
          ExportPreflightCheckKind.spoilers,
          'unresolved_spoiler',
          'Unresolved spoiler: $id',
        ),
      );
    }
    if (_containsControlCharacter(cleaned.text)) {
      specialCharacters.add(
        _warning(
          ExportPreflightCheckKind.specialCharacters,
          'control_character',
          'Render contains a control character.',
        ),
      );
    }
    if (cleaned.text.trim().isEmpty) {
      render.add(
        _error(
          ExportPreflightCheckKind.render,
          'empty_render',
          'Clean render is empty.',
        ),
      );
    }

    final assetPaths =
        request.assets
            .where((asset) => asset.exists)
            .map((asset) => asset.path)
            .toSet()
            .toList()
          ..sort();
    return ExportPreflightReport(
      documentId: request.documentId,
      checks: <ExportPreflightCheck>[
        ExportPreflightCheck(
          kind: ExportPreflightCheckKind.structure,
          issues: structure,
        ),
        ExportPreflightCheck(
          kind: ExportPreflightCheckKind.assets,
          issues: assets,
        ),
        ExportPreflightCheck(
          kind: ExportPreflightCheckKind.spoilers,
          issues: spoilers,
        ),
        ExportPreflightCheck(
          kind: ExportPreflightCheckKind.specialCharacters,
          issues: specialCharacters,
        ),
        ExportPreflightCheck(
          kind: ExportPreflightCheckKind.render,
          issues: render,
        ),
      ],
      preview: _preview(cleaned.text, request.previewCharacterLimit),
      manifest: ExportManifest(
        documentId: request.documentId,
        format: request.profile.format,
        contentFingerprint: cleaned.fingerprint,
        assetPaths: List<String>.unmodifiable(assetPaths),
      ),
    );
  }

  static ExportPreflightIssue _error(
    ExportPreflightCheckKind kind,
    String code,
    String message,
  ) => ExportPreflightIssue(
    kind: kind,
    severity: ExportPreflightSeverity.error,
    code: code,
    message: message,
  );

  static ExportPreflightIssue _warning(
    ExportPreflightCheckKind kind,
    String code,
    String message,
  ) => ExportPreflightIssue(
    kind: kind,
    severity: ExportPreflightSeverity.warning,
    code: code,
    message: message,
  );

  static bool _containsControlCharacter(String text) {
    for (final code in text.codeUnits) {
      if (code < 32 && code != 9 && code != 10 && code != 13) return true;
    }
    return false;
  }

  static String _preview(String text, int limit) {
    if (text.length <= limit) return text;
    var end = limit - 1;
    // vs-hunt-20260914-export EXP-BUG-04: jangan membelah surrogate pair —
    // high surrogate sebagai unit terakhir yang disertakan pasti kehilangan
    // pasangannya (low ada di `end`, tidak ikut terpotong).
    if (end > 0) {
      final last = text.codeUnitAt(end - 1);
      if (last >= 0xD800 && last <= 0xDBFF) end -= 1;
    }
    return '${text.substring(0, end)}…';
  }
}
