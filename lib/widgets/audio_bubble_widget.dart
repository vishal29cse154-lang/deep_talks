import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/message_model.dart';
import '../theme/app_theme.dart';

class AudioBubbleWidget extends StatefulWidget {
  final MessageModel message;
  final bool isMe;

  // Single global notifier to enforce one voice note at a time
  static final ValueNotifier<String?> currentlyPlayingId = ValueNotifier(null);

  const AudioBubbleWidget(
      {super.key, required this.message, required this.isMe});

  @override
  State<AudioBubbleWidget> createState() => _AudioBubbleWidgetState();
}

class _AudioBubbleWidgetState extends State<AudioBubbleWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.message.audioDuration != null) {
      _duration = Duration(seconds: widget.message.audioDuration!);
    }

    AudioBubbleWidget.currentlyPlayingId.addListener(_onGlobalPlayChanged);

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() => _duration = newDuration);
      }
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() => _position = newPosition);
      }
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  void _onGlobalPlayChanged() {
    if (AudioBubbleWidget.currentlyPlayingId.value !=
            widget.message.messageId &&
        _isPlaying) {
      _audioPlayer.pause();
    }
  }

  @override
  void dispose() {
    AudioBubbleWidget.currentlyPlayingId.removeListener(_onGlobalPlayChanged);
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      AudioBubbleWidget.currentlyPlayingId.value = widget.message.messageId;
      await _audioPlayer.play(UrlSource(widget.message.mediaUrl));
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _togglePlay,
          child: CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.accent,
            child: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 2.0,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 12.0),
                  activeTrackColor: AppTheme.accent,
                  inactiveTrackColor:
                      AppTheme.textSecondary.withValues(alpha: 0.3),
                  thumbColor: AppTheme.accent,
                ),
                child: Slider(
                  min: 0.0,
                  max: _duration.inMilliseconds.toDouble() > 0
                      ? _duration.inMilliseconds.toDouble()
                      : 1.0,
                  value: _position.inMilliseconds.toDouble().clamp(
                      0.0,
                      _duration.inMilliseconds.toDouble() > 0
                          ? _duration.inMilliseconds.toDouble()
                          : 1.0),
                  onChanged: (value) async {
                    final position = Duration(milliseconds: value.toInt());
                    await _audioPlayer.seek(position);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 10),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
