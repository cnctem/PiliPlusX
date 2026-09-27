enum MediaControlButton {
  previous('上一集'),
  rewind('快退 10 秒'),
  playPause('播放/暂停'),
  fastForward('快进 10 秒'),
  next('下一集'),
  ;

  final String label;

  const MediaControlButton(this.label);
}

const defaultMediaControlButtons = <MediaControlButton>[
  MediaControlButton.previous,
  MediaControlButton.rewind,
  MediaControlButton.playPause,
  MediaControlButton.fastForward,
  MediaControlButton.next,
];

List<MediaControlButton> parseMediaControlButtons(Object? value) {
  if (value is! List) {
    return List.of(defaultMediaControlButtons);
  }

  final result = <MediaControlButton>[];
  for (final item in value) {
    final button = switch (item) {
      'previous' => MediaControlButton.previous,
      'rewind' => MediaControlButton.rewind,
      'playPause' => MediaControlButton.playPause,
      'fastForward' => MediaControlButton.fastForward,
      'next' => MediaControlButton.next,
      _ => null,
    };
    if (button != null && !result.contains(button)) {
      result.add(button);
    }
  }

  if (result.isEmpty) {
    return List.of(defaultMediaControlButtons);
  }
  if (!result.contains(MediaControlButton.playPause)) {
    result.insert(result.length ~/ 2, MediaControlButton.playPause);
  }
  return result;
}
