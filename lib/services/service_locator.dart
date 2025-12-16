import 'package:PiliPlus/services/audio_handler.dart';
import 'package:PiliPlus/services/audio_session.dart';
import 'package:PiliPlus/utils/utils.dart';

VideoPlayerServiceHandler? videoPlayerServiceHandler;
AudioSessionHandler? audioSessionHandler;

Future<void> setupServiceLocator() async {
  // HarmonyOS 暂不支持 audio_service/audio_session 的原生实现，使用本地空实现避免崩溃
  if (Utils.isHarmony) {
    videoPlayerServiceHandler = VideoPlayerServiceHandler.local();
    audioSessionHandler = null;
    return;
  }

  final audio = await initAudioService();
  videoPlayerServiceHandler = audio;
  audioSessionHandler = AudioSessionHandler();
}
