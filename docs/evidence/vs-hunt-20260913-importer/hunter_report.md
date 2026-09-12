# Hunter report — vs-hunt-20260913-importer
# repo: D:\VoidScriptor\void_scriptor_multiplatform, branch master, HEAD 50c6221badd04ae4b162736ea8b13d13b80fcb2d
# scope: 9 lib + 3 test files (importer/thumbnail/reference/binder vertical), all clean in git status

**BUG-1** | Severity: Critical | Points: 10
- File: `lib/features/character/application/character_reference_binder.dart`
- Line(s): 78-102
- Category: data-integrity
- Claim: `CharacterReferenceBinder` deletes existing reference database records and files prior to adding the new reference, resulting in permanent data loss of the previous reference if `repo.addReference` fails.
- Evidence:
```dart
      await repo.removeReference(row.id);
      if (p.canonicalize(p.dirname(row.filePath)) ==
          p.canonicalize(directory.path)) {
        try {
          await File(row.filePath).delete();
        } on FileSystemException {}
      }
    }

    await repo.addReference(
      CharacterReferencesCompanion.insert(
        id: const Uuid().v4,
        characterId: characterId,
        type: slotLabel.trim(),
        filePath: target.path,
        priority: Value(existing.length),
        primaryReference: const Value(false),
      ),
    );
```

**BUG-2** | Severity: Critical | Points: 10
- File: `lib/features/references/application/reference_bulk_importer.dart`
- Line(s): 158-160
- Category: security
- Claim: `ReferenceBulkImporter` uses `assetId` directly in `p.join` without path sanitization, allowing path traversal attacks if `assetId` contains directory traversal sequences (`..`).
- Evidence:
```dart
      final targetDir = Directory(
        p.join(assetsDirectory.path, 'references', assetId),
      );
```

**BUG-3** | Severity: Medium | Points: 5
- File: `lib/features/bible/application/timeline_era_image_importer.dart`
- Line(s): 72-74
- Category: error-handling
- Claim: `TimelineEraImageImporter` copies the source image file before updating the database but fails to clean up the copied file if `repo.saveEra` throws an exception, leaving an orphaned file.
- Evidence:
```dart
    await source.copy(target.path);

    await repo.saveEra(era.copyWith(imagePath: target.path));
```

**BUG-4** | Severity: Medium | Points: 5
- File: `lib/features/assets/application/asset_thumbnail_importer.dart`
- Line(s): 73-76
- Category: error-handling
- Claim: `AssetThumbnailImporter` copies the source image file before updating the database but does not delete the copied target file if `database.assetDao.setThumbnail` throws an exception.
- Evidence:
```dart
    await source.copy(target.path);

    final superseded = asset.thumbnailPath;
    await database.assetDao.setThumbnail(assetId, target.path);
```

**BUG-5** | Severity: Medium | Points: 5
- File: `lib/features/references/application/reference_bulk_importer.dart`
- Line(s): 186-201
- Category: error-handling
- Claim: `ReferenceBulkImporter` writes physical reference files and inserts database records in a loop without rollback or cleanup of newly written files if a subsequent write or database insertion fails mid-batch.
- Evidence:
```dart
        await target.writeAsBytes(bytes);

        final reference = ReferenceModel(...);
        await database.referenceDao.insertReference(reference: reference);
```

**BUG-6** | Severity: Medium | Points: 5
- File: `lib/features/bible/application/timeline_era_image_importer.dart`
- Line(s): 70
- Category: security
- Claim: Entity identifiers (`eraId`, `assetId`, `characterId`) are interpolated directly into target filename paths without sanitization against path traversal characters, permitting potential file writing outside intended namespace directories.
- Evidence:
```dart
    final target = File(p.join(directory.path, '${eraId}_$stamp$extension'));
```

TOTAL FINDINGS: 6
TOTAL SCORE: 40
