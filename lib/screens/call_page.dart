import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../services/call_service.dart';
import '../theme/app_theme.dart';

class CallPage extends StatefulWidget {
  final String coupleId;
  final bool isVideo;

  const CallPage({super.key, required this.coupleId, this.isVideo = true});

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final CallService _callService = CallService();
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = true;
  bool _joined = false;
  int? _remoteUid;

  @override
  void initState() {
    super.initState();
    _initCall();
  }

  Future<void> _initCall() async {
    await _callService.initialize();

    // Register event handlers
    _callService.engine?.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          if (mounted) setState(() => _joined = true);
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          if (mounted) setState(() => _remoteUid = remoteUid);
        },
        onUserOffline: (connection, remoteUid, reason) {
          if (mounted) setState(() => _remoteUid = null);
        },
      ),
    );

    // Join the call
    if (widget.isVideo) {
      await _callService.joinVideoCall(channelName: widget.coupleId, uid: 0);
    } else {
      await _callService.joinVoiceCall(channelName: widget.coupleId, uid: 0);
    }
  }

  Future<void> _endCall() async {
    await _callService.dispose();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _callService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Stack(
        children: [
          // ─── Remote Video / Voice Placeholder ──────────────────
          if (widget.isVideo && _remoteUid != null)
            AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: _callService.engine!,
                canvas: VideoCanvas(uid: _remoteUid),
                connection: RtcConnection(channelId: widget.coupleId),
              ),
            )
          else
            _buildCallPlaceholder(),

          // ─── Local Video (Small PiP) ───────────────────────────
          if (widget.isVideo && _joined && !_isCameraOff)
            Positioned(
              top: 60,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 120,
                  height: 160,
                  child: AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _callService.engine!,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  ),
                ),
              ),
            ),

          // ─── Call Controls ─────────────────────────────────────
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: SafeArea(child: _buildControls()),
          ),

          // ─── Back Button ───────────────────────────────────────
          Positioned(
            top: 50,
            left: 16,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: _endCall,
              ),
            ),
          ),

          // ─── Connection Status ─────────────────────────────────
          if (!_joined)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.accent),
                  SizedBox(height: 20),
                  Text(
                    'Connecting...',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCallPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkBg,
            AppTheme.purple.withValues(alpha: 0.2),
            AppTheme.darkBg,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.isVideo ? Icons.videocam_rounded : Icons.phone_rounded,
              color: AppTheme.accent,
              size: 60,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.isVideo ? 'Video Call' : 'Voice Call',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _remoteUid == null ? 'Waiting for partner...' : 'Connected 💕',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Mute
        _controlButton(
          icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
          label: _isMuted ? 'Unmute' : 'Mute',
          color: _isMuted ? Colors.redAccent : AppTheme.textSecondary,
          onTap: () {
            setState(() => _isMuted = !_isMuted);
            _callService.toggleMute(_isMuted);
          },
        ),
        const SizedBox(width: 20),

        // End Call
        GestureDetector(
          onTap: _endCall,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red,
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.call_end_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
        const SizedBox(width: 20),

        if (widget.isVideo) ...[
          // Camera toggle
          _controlButton(
            icon: _isCameraOff
                ? Icons.videocam_off_rounded
                : Icons.videocam_rounded,
            label: _isCameraOff ? 'Camera On' : 'Camera Off',
            color: _isCameraOff ? Colors.redAccent : AppTheme.textSecondary,
            onTap: () {
              setState(() => _isCameraOff = !_isCameraOff);
              _callService.toggleCamera(!_isCameraOff);
            },
          ),
          const SizedBox(width: 20),
          // Flip camera
          _controlButton(
            icon: Icons.flip_camera_ios_rounded,
            label: 'Flip',
            color: AppTheme.textSecondary,
            onTap: () => _callService.switchCamera(),
          ),
        ] else ...[
          // Speaker toggle
          _controlButton(
            icon: _isSpeakerOn
                ? Icons.volume_up_rounded
                : Icons.volume_off_rounded,
            label: _isSpeakerOn ? 'Speaker' : 'Earpiece',
            color: AppTheme.textSecondary,
            onTap: () {
              setState(() => _isSpeakerOn = !_isSpeakerOn);
              _callService.toggleSpeaker(_isSpeakerOn);
            },
          ),
        ],
      ],
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}
