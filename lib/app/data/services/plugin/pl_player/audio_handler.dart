import 'package:audio_service/audio_service.dart';

import '../../../../components/plugin/pl_player/controller.dart';
import '../../../../components/plugin/pl_player/models/play_status.dart';
import '../../../providers/storage_provider.dart';

Future<VideoPlayerServiceHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => VideoPlayerServiceHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.iwrqk.app.audio',
      androidNotificationChannelName: 'Audio Service IwrQk',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      fastForwardInterval: Duration(seconds: 10),
      rewindInterval: Duration(seconds: 10),
      androidNotificationChannelDescription: 'Media notification channel',
      androidNotificationIcon: 'drawable/ic_notification_icon',
    ),
  );
}

class VideoPlayerServiceHandler extends BaseAudioHandler with SeekHandler {
  static final List<MediaItem> _item = [];
  GStorageConfig setting = StorageProvider.config;
  bool enableBackgroundPlay = false;

  VideoPlayerServiceHandler() {
    revalidateSetting();
  }

  void revalidateSetting() {
    enableBackgroundPlay = setting.get(PLPlayerConfigKey.enableBackgroundPlay,
        defaultValue: false);
  }

  @override
  Future<void> play() async {
    PlPlayerController.getInstance().play();
  }

  @override
  Future<void> pause() async {
    PlPlayerController.getInstance().pause();
  }

  @override
  Future<void> seek(Duration position) async {
    playbackState.add(playbackState.value.copyWith(
      updatePosition: position,
    ));
    await PlPlayerController.getInstance().seekTo(position);
  }

  Future<void> setMediaItem(MediaItem newMediaItem) async {
    if (!enableBackgroundPlay) return;
    mediaItem.add(newMediaItem);
  }

  Future<void> setPlaybackState(PlayerStatus status, bool isBuffering) async {
    if (!enableBackgroundPlay) return;

    final AudioProcessingState processingState;
    final playing = status == PlayerStatus.playing;
    if (status == PlayerStatus.completed) {
      processingState = AudioProcessingState.completed;
    } else if (isBuffering) {
      processingState = AudioProcessingState.buffering;
    } else {
      processingState = AudioProcessingState.ready;
    }

    playbackState.add(playbackState.value.copyWith(
      processingState:
          isBuffering ? AudioProcessingState.buffering : processingState,
      controls: [
        MediaControl.rewind,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.fastForward,
      ],
      playing: playing,
      systemActions: const {
        MediaAction.seek,
      },
    ));
  }

  void onStatusChange(PlayerStatus status, bool isBuffering) {
    if (!enableBackgroundPlay) return;

    if (_item.isEmpty) return;
    setPlaybackState(status, isBuffering);
  }

  void onVideoChange(Map data) {
    if (!enableBackgroundPlay) return;

    late MediaItem? mediaItem;
    mediaItem = MediaItem(
      id: data["id"],
      title: data["title"],
      artist: data["artist"],
      duration: Duration(seconds: data["duration"]),
      artUri: data.containsKey("cover") ? Uri.parse(data["cover"]) : null,
    );

    setMediaItem(mediaItem);
    _item.add(mediaItem);
  }

  void onVideoDetailDispose() {
    if (!enableBackgroundPlay) return;

    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.idle,
      playing: false,
    ));
    if (_item.isNotEmpty) {
      _item.removeLast();
      setMediaItem(_item.last);
    }
    if (_item.isEmpty) {
      playbackState
          .add(playbackState.value.copyWith(updatePosition: Duration.zero));
    }
    stop();
  }

  void clear() {
    if (!enableBackgroundPlay) return;

    mediaItem.add(null);
    playbackState.add(PlaybackState(
      processingState: AudioProcessingState.idle,
      playing: false,
    ));
    _item.clear();
    stop();
  }

  void onPositionChange(Duration position) {
    if (!enableBackgroundPlay) return;

    playbackState.add(playbackState.value.copyWith(
      updatePosition: position,
    ));
  }
}
