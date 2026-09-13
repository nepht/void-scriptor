import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/project_resilience/application/durable_draft_journal.dart';

void main() {
  test(
    'publishes same-scene stages in request order when publication interleaves',
    () async {
      final root = await Directory.systemTemp.createTemp('journal-fifo-');
      addTearDown(() => root.delete(recursive: true));
      final dir = Directory('${root.path}/journal');
      final firstPublishReached = Completer<void>();
      final releaseFirstPublish = Completer<void>();
      final journal = DurableDraftJournal(
        dir: dir,
        beforePublish: (sceneId, content) async {
          if (content == 'A') {
            firstPublishReached.complete();
            await releaseFirstPublish.future;
          }
        },
      );

      final first = journal.stage(sceneId: 'scene', content: 'A');
      await firstPublishReached.future;
      final second = journal.stage(sceneId: 'scene', content: 'B');
      await Future<void>.delayed(Duration.zero);
      releaseFirstPublish.complete();
      await Future.wait<void>([first, second]);

      final pending = await journal.pendingEntries();
      expect(pending.single.content, 'B');
    },
  );
}
