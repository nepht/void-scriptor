import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/shell/void_app_shell.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

/// Sprint 145.42 (Data Safety Failure Matrix) - permukaan UI typed failure.
///
/// [ProjectDatabaseService] mengklasifikasikan kegagalan open database
/// menjadi empat keadaan bertipe (Locked / WriteFailed / Unavailable /
/// Unreadable). Shell harus menampilkan pesan pemulihan yang SPESIFIK
/// untuk tiap keadaan - bukan pesan generik "Periksa lokasi folder..." -
/// sehingga pengguna tahu tindakan berikutnya (bebakas ruang, pulihkan
/// izin tulis, pasang drive, atau pulihkan backup) tanpa salah mengira
/// database korut.
class ThrowingSession extends ProjectSessionController {
  ThrowingSession(this.error);
  final Object error;
  @override
  Future<ProjectSession?> build() async => null;
  @override
  Future<ProjectSession> openProject(
    String projectId, {
    ProjectOpenMode mode = ProjectOpenMode.readWrite,
  }) async {
    state = AsyncError(error, StackTrace.current);
    throw error;
  }
}

Widget _shell(ProjectSessionController controller) => ProviderScope(
  overrides: [projectSessionProvider.overrideWith(() => controller)],
  child: const MaterialApp(
    home: VoidAppShell(projectId: 'p1', content: Text('ready')),
  ),
);

void main() {
  testWidgets(
    'write-failure (read-only / disk full) shows storage recovery message',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _shell(
          ThrowingSession(
            ProjectDatabaseWriteFailedException('db', 'SQLITE_READONLY'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Proyek tidak dapat dibuka'), findsOneWidget);
      expect(
        find.textContaining('menolak penulisan'),
        findsOneWidget,
        reason: 'write-failure harus menampilkan arahan penyimpanan',
      );
      expect(find.textContaining('Periksa lokasi folder'), findsNothing);
      expect(find.text('ready'), findsNothing);
    },
  );

  testWidgets('unavailable (drive missing) shows storage access message', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _shell(
        ThrowingSession(
          ProjectDatabaseUnavailableException('db', 'SQLITE_CANTOPEN'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      find.textContaining('tidak dapat diakses'),
      findsOneWidget,
      reason: 'unavailable harus menampilkan arahan akses drive/lokasi',
    );
    expect(find.textContaining('Periksa lokasi folder'), findsNothing);
  });

  testWidgets('locked (another writer) shows busy-project message', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _shell(
        ThrowingSession(ProjectDatabaseLockedException('db', 'SQLITE_BUSY')),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      find.textContaining('dibuka aplikasi lain'),
      findsOneWidget,
      reason: 'locked harus menampilkan arahan tutup aplikasi lain',
    );
    expect(find.textContaining('Periksa lokasi folder'), findsNothing);
  });

  testWidgets(
    'unreadable (possible corruption) shows backup-recovery message',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _shell(
          ThrowingSession(
            ProjectDatabaseUnreadableException('db', 'SQLITE_NOTADB'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.textContaining('tidak dapat dibaca'),
        findsOneWidget,
        reason: 'unreadable harus menampilkan arahan pulihkan backup',
      );
      expect(find.textContaining('Periksa lokasi folder'), findsNothing);
    },
  );

  testWidgets('unclassified error keeps the generic recovery message', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_shell(ThrowingSession(Exception('unexpected'))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      find.textContaining('Periksa lokasi folder'),
      findsOneWidget,
      reason: 'error tak terklasifikasi tetap memakai pesan generik',
    );
  });
}
