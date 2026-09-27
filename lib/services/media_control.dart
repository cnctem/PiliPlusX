import 'package:PiliPlus/models/common/media_control_button.dart';

List<MediaControlButton> effectiveMediaControlButtons({
  required Iterable<MediaControlButton> configured,
  required bool isLive,
  required bool hasEpisodes,
}) {
  final result = <MediaControlButton>[];
  for (final button in configured) {
    if (result.contains(button)) continue;
    final visible = switch (button) {
      MediaControlButton.previous ||
      MediaControlButton.next => !isLive && hasEpisodes,
      MediaControlButton.rewind || MediaControlButton.fastForward => !isLive,
      MediaControlButton.playPause => true,
    };
    if (visible) result.add(button);
  }

  if (!result.contains(MediaControlButton.playPause)) {
    result.insert(result.length ~/ 2, MediaControlButton.playPause);
  }
  return result;
}

List<int> androidCompactActionIndices(
  List<MediaControlButton> controls,
) {
  final playPauseIndex = controls.indexOf(MediaControlButton.playPause);
  if (playPauseIndex == -1) return const [];

  final indices = <int>{playPauseIndex};
  for (
    var offset = 1;
    indices.length < 3 &&
        (playPauseIndex - offset >= 0 ||
            playPauseIndex + offset < controls.length);
    offset++
  ) {
    final previous = playPauseIndex - offset;
    if (previous >= 0) {
      indices.add(previous);
    }
    final next = playPauseIndex + offset;
    if (indices.length < 3 && next < controls.length) {
      indices.add(next);
    }
  }
  return indices.toList()..sort();
}
