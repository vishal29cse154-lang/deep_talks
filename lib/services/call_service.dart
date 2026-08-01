import 'package:agora_rtc_engine/agora_rtc_engine.dart';

/// Replace with your actual Agora App ID.
const String agoraAppId = 'YOUR_AGORA_APP_ID_HERE';

class CallService {
  RtcEngine? _engine;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  RtcEngine? get engine => _engine;

  /// Initialize the Agora RTC engine.
  Future<void> initialize() async {
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(
      const RtcEngineContext(
        appId: agoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );
    _isInitialized = true;
  }

  /// Join a video call channel (channel name = coupleId).
  Future<void> joinVideoCall({
    required String channelName,
    required int uid,
  }) async {
    if (!_isInitialized) await initialize();

    await _engine!.enableVideo();
    await _engine!.startPreview();
    await _engine!.joinChannel(
      token: '', // Use token server in production
      channelId: channelName,
      uid: uid,
      options: const ChannelMediaOptions(
        autoSubscribeVideo: true,
        autoSubscribeAudio: true,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  /// Join a voice-only call channel.
  Future<void> joinVoiceCall({
    required String channelName,
    required int uid,
  }) async {
    if (!_isInitialized) await initialize();

    await _engine!.disableVideo();
    await _engine!.joinChannel(
      token: '',
      channelId: channelName,
      uid: uid,
      options: const ChannelMediaOptions(
        autoSubscribeAudio: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  /// Toggle local audio mute.
  Future<void> toggleMute(bool muted) async {
    await _engine?.muteLocalAudioStream(muted);
  }

  /// Toggle camera on/off.
  Future<void> toggleCamera(bool enabled) async {
    if (enabled) {
      await _engine?.enableVideo();
    } else {
      await _engine?.disableVideo();
    }
  }

  /// Switch between front and back camera.
  Future<void> switchCamera() async {
    await _engine?.switchCamera();
  }

  /// Toggle speaker.
  Future<void> toggleSpeaker(bool enabled) async {
    await _engine?.setEnableSpeakerphone(enabled);
  }

  /// Leave the channel and clean up.
  Future<void> leaveCall() async {
    await _engine?.leaveChannel();
    await _engine?.stopPreview();
  }

  /// Fully dispose of the engine.
  Future<void> dispose() async {
    await _engine?.leaveChannel();
    await _engine?.release();
    _engine = null;
    _isInitialized = false;
  }
}
