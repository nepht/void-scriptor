import 'package:flutter/material.dart';
import '../domain/timeline_model.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class TimelineWorkspaceScreen extends StatefulWidget {
  const TimelineWorkspaceScreen({
    super.key,
    required this.sceneId,
    required this.sceneTitle,
    required this.durationSeconds,
    this.clips = const [],
    this.onClipTimingChanged,
  });
  final String sceneId;
  final String sceneTitle;
  final double durationSeconds;
  final List<TimelineClipModel> clips;
  final Future<void> Function(
    TimelineClipModel previous,
    TimelineClipModel updated,
  )?
  onClipTimingChanged;
  @override
  State<TimelineWorkspaceScreen> createState() =>
      _TimelineWorkspaceScreenState();
}

class _TimelineWorkspaceScreenState extends State<TimelineWorkspaceScreen> {
  double _pixelsPerSecond = 80;
  double _currentTime = 0;
  bool _previewMode = false;
  final _tracks = TimelineTrackType.values;
  late List<TimelineClipModel> _clips = [...widget.clips];
  String? _selectedClipId;

  void _moveClip(TimelineClipModel clip, double deltaSeconds) {
    final maxStart = widget.durationSeconds - clip.durationSeconds;
    final start = snapSeconds(
      (clip.startSeconds + deltaSeconds).clamp(0.0, maxStart),
      TimelineSnapMode.tenthSecond,
      30,
    );
    final updated = TimelineClipModel(
      id: clip.id,
      trackId: clip.trackId,
      startSeconds: start,
      durationSeconds: clip.durationSeconds,
      label: clip.label,
      sourceId: clip.sourceId,
      clipType: clip.clipType,
      payload: clip.payload,
      sortOrder: clip.sortOrder,
    );
    setState(() {
      _clips = _clips
          .map((item) => item.id == clip.id ? updated : item)
          .toList();
      _selectedClipId = clip.id;
    });
    widget.onClipTimingChanged?.call(clip, updated);
  }

  @override
  Widget build(BuildContext context) {
    if (_previewMode) {
      return _PreviewPanel(
        title: widget.sceneTitle,
        time: _currentTime,
        onBack: () => setState(() => _previewMode = false),
      );
    }
    final scale = TimelineScale(pixelsPerSecond: _pixelsPerSecond);
    return ColoredBox(
      color: context.palette.background,
      child: Column(
        children: [
          TimelineHeader(
            sceneTitle: widget.sceneTitle,
            duration: widget.durationSeconds,
            currentTime: _currentTime,
            onPlay: () => setState(() => _previewMode = true),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Zoom',
                    style: TextStyle(color: context.palette.textSecondary),
                  ),
                  IconButton(
                    tooltip: 'Zoom out',
                    onPressed: () => setState(
                      () => _pixelsPerSecond = (_pixelsPerSecond / 2).clamp(
                        20,
                        160,
                      ),
                    ),
                    icon: const Icon(Icons.remove),
                  ),
                  Text(
                    '${_pixelsPerSecond.toInt()} px/sec',
                    style: TextStyle(color: context.palette.textSecondary),
                  ),
                  IconButton(
                    tooltip: 'Zoom in',
                    onPressed: () => setState(
                      () => _pixelsPerSecond = (_pixelsPerSecond * 2).clamp(
                        20,
                        160,
                      ),
                    ),
                    icon: const Icon(Icons.add),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _pixelsPerSecond = 80),
                    child: const Text('Fit Scene'),
                  ),
                  const SizedBox(width: 12),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Edit')),
                      ButtonSegment(value: true, label: Text('Preview')),
                    ],
                    selected: {_previewMode},
                    onSelectionChanged: (value) =>
                        setState(() => _previewMode = value.first),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 280 + scale.secondsToPixels(widget.durationSeconds),
                child: Column(
                  children: [
                    TimelineRuler(
                      duration: widget.durationSeconds,
                      pixelsPerSecond: _pixelsPerSecond,
                      currentTime: _currentTime,
                      onSeek: (value) => setState(() => _currentTime = value),
                    ),
                    ..._tracks.map(
                      (track) => _TrackRow(
                        track: track,
                        width: scale.secondsToPixels(widget.durationSeconds),
                        clips: _clips
                            .where((clip) => clip.trackId == track.name)
                            .toList(),
                        scale: scale,
                        selectedClipId: _selectedClipId,
                        onClipMoved: _moveClip,
                        onClipSelected: (clip) =>
                            setState(() => _selectedClipId = clip.id),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TimelineHeader extends StatelessWidget {
  const TimelineHeader({
    super.key,
    required this.sceneTitle,
    required this.duration,
    required this.currentTime,
    required this.onPlay,
  });
  final String sceneTitle;
  final double duration;
  final double currentTime;
  final VoidCallback onPlay;
  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    color: context.palette.panelSecondary,
    child: Row(
      children: [
        Icon(Icons.timeline_outlined, color: context.palette.primaryBright),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            sceneTitle,
            style: TextStyle(
              color: context.palette.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          '${duration.toStringAsFixed(1)} sec · ${currentTime.toStringAsFixed(1)}',
          style: TextStyle(color: context.palette.textSecondary),
        ),
        IconButton(
          tooltip: 'Play',
          onPressed: onPlay,
          icon: const Icon(Icons.play_arrow),
        ),
      ],
    ),
  );
}

class TimelineRuler extends StatelessWidget {
  const TimelineRuler({
    super.key,
    required this.duration,
    required this.pixelsPerSecond,
    required this.currentTime,
    required this.onSeek,
  });
  final double duration;
  final double pixelsPerSecond;
  final double currentTime;
  final ValueChanged<double> onSeek;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 34,
    child: Row(
      children: [
        const SizedBox(width: 120),
        GestureDetector(
          onTapDown: (details) => onSeek(
            (details.localPosition.dx / pixelsPerSecond).clamp(0, duration),
          ),
          child: SizedBox(
            width: duration * pixelsPerSecond,
            child: CustomPaint(
              painter: _RulerPainter(
                duration: duration,
                pixelsPerSecond: pixelsPerSecond,
                lineColor: context.palette.borderSoft,
                textColor: context.palette.textMuted,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class TimelineClip extends StatelessWidget {
  const TimelineClip({
    super.key,
    required this.clip,
    required this.width,
    required this.selected,
    required this.onTap,
  });
  final TimelineClipModel clip;
  final double width;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      width: width,
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: selected
            ? context.palette.primary.withValues(alpha: .25)
            : context.palette.surfaceElevated,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: selected ? context.palette.primary : context.palette.border,
        ),
      ),
      child: Text(
        clip.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: context.palette.textSecondary, fontSize: 11),
      ),
    ),
  );
}

class _TrackRow extends StatelessWidget {
  const _TrackRow({
    required this.track,
    required this.width,
    required this.clips,
    required this.scale,
    required this.selectedClipId,
    required this.onClipMoved,
    required this.onClipSelected,
  });
  final TimelineTrackType track;
  final double width;
  final List<TimelineClipModel> clips;
  final TimelineScale scale;
  final String? selectedClipId;
  final void Function(TimelineClipModel clip, double deltaSeconds) onClipMoved;
  final ValueChanged<TimelineClipModel> onClipSelected;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: Row(
      children: [
        SizedBox(
          width: 120,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              _label(track),
              style: TextStyle(
                color: context.palette.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ),
        Container(
          width: width,
          height: 44,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Stack(
            children: clips.map((clip) {
              var dragOriginPixels = 0.0;
              var dragDeltaPixels = 0.0;
              return Positioned(
                left: scale.secondsToPixels(clip.startSeconds),
                child: GestureDetector(
                  onHorizontalDragDown: (details) {
                    dragOriginPixels = details.globalPosition.dx;
                    dragDeltaPixels = 0;
                  },
                  onHorizontalDragUpdate: (details) {
                    dragDeltaPixels =
                        details.globalPosition.dx - dragOriginPixels;
                  },
                  onHorizontalDragCancel: () => dragDeltaPixels = 0,
                  onHorizontalDragEnd: (_) => onClipMoved(
                    clip,
                    dragDeltaPixels / scale.pixelsPerSecond,
                  ),
                  child: TimelineClip(
                    clip: clip,
                    width: scale.secondsToPixels(clip.durationSeconds),
                    selected: clip.id == selectedClipId,
                    onTap: () => onClipSelected(clip),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    ),
  );
  static String _label(TimelineTrackType type) => type == TimelineTrackType.vfx
      ? 'VFX'
      : '${type.name[0].toUpperCase()}${type.name.substring(1)}';
}

class _RulerPainter extends CustomPainter {
  const _RulerPainter({
    required this.duration,
    required this.pixelsPerSecond,
    required this.lineColor,
    required this.textColor,
  });
  final double duration;
  final double pixelsPerSecond;
  final Color lineColor;
  final Color textColor;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = lineColor;
    for (var second = 0.0; second <= duration; second += 1) {
      final x = second * pixelsPerSecond;
      canvas.drawLine(Offset(x, 15), Offset(x, 30), paint);
      TextPainter(
          text: TextSpan(
            text: second.toStringAsFixed(0),
            style: TextStyle(color: textColor, fontSize: 10),
          ),
          textDirection: TextDirection.ltr,
        )
        ..layout()
        ..paint(canvas, Offset(x + 2, 0));
    }
  }

  @override
  bool shouldRepaint(covariant _RulerPainter oldDelegate) =>
      oldDelegate.duration != duration ||
      oldDelegate.pixelsPerSecond != pixelsPerSecond;
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({
    required this.title,
    required this.time,
    required this.onBack,
  });
  final String title;
  final double time;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.palette.background,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.movie_creation_outlined,
            size: 64,
            color: context.palette.primaryBright,
          ),
          Text(
            title,
            style: TextStyle(color: context.palette.textPrimary, fontSize: 22),
          ),
          Text(
            'Preview · ${time.toStringAsFixed(1)} sec',
            style: TextStyle(color: context.palette.textSecondary),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.edit),
            label: const Text('Back to Edit'),
          ),
        ],
      ),
    ),
  );
}
