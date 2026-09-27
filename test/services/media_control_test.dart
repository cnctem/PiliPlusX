import 'package:PiliPlus/models/common/media_control_button.dart';
import 'package:PiliPlus/services/media_control.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseMediaControlButtons', () {
    test('uses the default order when no valid configuration exists', () {
      expect(
        parseMediaControlButtons(null),
        defaultMediaControlButtons,
      );
      expect(
        parseMediaControlButtons(['unknown']),
        defaultMediaControlButtons,
      );
    });

    test('keeps valid order, removes duplicates, and restores playPause', () {
      expect(
        parseMediaControlButtons([
          'next',
          'next',
          'rewind',
          'unknown',
        ]),
        [
          MediaControlButton.next,
          MediaControlButton.playPause,
          MediaControlButton.rewind,
        ],
      );
    });
  });

  group('effectiveMediaControlButtons', () {
    test('default configuration shows every control for episodic video', () {
      expect(
        effectiveMediaControlButtons(
          configured: defaultMediaControlButtons,
          isLive: false,
          hasEpisodes: true,
        ),
        defaultMediaControlButtons,
      );
    });

    test('hides episode controls when no episodes are available', () {
      expect(
        effectiveMediaControlButtons(
          configured: defaultMediaControlButtons,
          isLive: false,
          hasEpisodes: false,
        ),
        [
          MediaControlButton.rewind,
          MediaControlButton.playPause,
          MediaControlButton.fastForward,
        ],
      );
    });

    test('live playback only keeps playPause', () {
      expect(
        effectiveMediaControlButtons(
          configured: defaultMediaControlButtons,
          isLive: true,
          hasEpisodes: true,
        ),
        [MediaControlButton.playPause],
      );
    });

    test('preserves custom selection and order', () {
      expect(
        effectiveMediaControlButtons(
          configured: [
            MediaControlButton.next,
            MediaControlButton.rewind,
            MediaControlButton.playPause,
          ],
          isLive: false,
          hasEpisodes: true,
        ),
        [
          MediaControlButton.next,
          MediaControlButton.rewind,
          MediaControlButton.playPause,
        ],
      );
    });
  });

  group('androidCompactActionIndices', () {
    test('keeps playPause and its nearest controls in the compact view', () {
      expect(
        androidCompactActionIndices([
          MediaControlButton.previous,
          MediaControlButton.rewind,
          MediaControlButton.playPause,
          MediaControlButton.fastForward,
          MediaControlButton.next,
        ]),
        [1, 2, 3],
      );
    });

    test('returns valid indices when playPause is at an edge', () {
      expect(
        androidCompactActionIndices([
          MediaControlButton.playPause,
          MediaControlButton.rewind,
          MediaControlButton.fastForward,
        ]),
        [0, 1, 2],
      );
      expect(
        androidCompactActionIndices([MediaControlButton.playPause]),
        [0],
      );
    });
  });
}
