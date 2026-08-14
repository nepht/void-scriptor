import '../../../core/commands/app_command.dart';
import '../../project_resilience/application/command_history_repository.dart';
import 'create_timeline_service.dart';

class MoveTimelineClipCommand extends BaseCommand {
  MoveTimelineClipCommand({
    required super.id,
    required super.projectId,
    required this.timelineService,
    required this.clipId,
    required this.oldStartSeconds,
    required this.newStartSeconds,
    required this.durationSeconds,
  }) : super(label: 'Move Timeline Clip');

  factory MoveTimelineClipCommand.fromRecord(
    CommandHistoryRecord record,
    CreateTimelineService timelineService,
  ) {
    return MoveTimelineClipCommand(
      id: record.id,
      projectId: record.projectId,
      timelineService: timelineService,
      clipId: record.payload['clipId']! as String,
      oldStartSeconds: (record.payload['oldStartSeconds']! as num).toDouble(),
      newStartSeconds: (record.payload['newStartSeconds']! as num).toDouble(),
      durationSeconds: (record.payload['durationSeconds']! as num).toDouble(),
    );
  }

  final CreateTimelineService timelineService;
  final String clipId;
  final double oldStartSeconds;
  final double newStartSeconds;
  final double durationSeconds;

  @override
  String get commandType => 'timeline.clip.move';

  @override
  Map<String, Object?> get payload => {
    'clipId': clipId,
    'oldStartSeconds': oldStartSeconds,
    'newStartSeconds': newStartSeconds,
    'durationSeconds': durationSeconds,
  };

  @override
  Map<String, Object?> get undoPayload => {
    'clipId': clipId,
    'startSeconds': oldStartSeconds,
    'durationSeconds': durationSeconds,
  };

  @override
  Future<void> execute() => _apply(newStartSeconds);

  @override
  Future<void> undo() => _apply(oldStartSeconds);

  @override
  Future<void> redo() => _apply(newStartSeconds);

  Future<void> _apply(double startSeconds) async {
    if (startSeconds < 0 || durationSeconds <= 0) {
      throw StateError('Timeline clip timing must be positive');
    }
    await timelineService.updateClipTiming(
      clipId,
      startSeconds: startSeconds,
      durationSeconds: durationSeconds,
    );
  }
}
