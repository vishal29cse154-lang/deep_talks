import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import '../models/message_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class ViewOnceScreen extends StatefulWidget {
  final MessageModel message;
  final String coupleId;

  const ViewOnceScreen(
      {Key? key, required this.message, required this.coupleId})
      : super(key: key);

  @override
  State<ViewOnceScreen> createState() => _ViewOnceScreenState();
}

class _ViewOnceScreenState extends State<ViewOnceScreen> {
  final _firestoreService = FirestoreService();
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _secureScreen();
    if (widget.message.mediaType == MediaType.video) {
      _initVideo();
    }
  }

  Future<void> _secureScreen() async {
    if (!kIsWeb) {
      if (Theme.of(context).platform == TargetPlatform.android) {
        await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
      }
    }
  }

  Future<void> _unsecureScreen() async {
    if (!kIsWeb) {
      if (Theme.of(context).platform == TargetPlatform.android) {
        await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
      }
    }
  }

  Future<void> _initVideo() async {
    try {
      _videoPlayerController =
          VideoPlayerController.networkUrl(Uri.parse(widget.message.mediaUrl));
      await _videoPlayerController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
      );
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _unsecureScreen();
    // Mark as opened ONLY upon leaving the screen
    _firestoreService.markMessageOpened(
        widget.coupleId, widget.message.messageId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.message.mediaType == MediaType.photo)
            InteractiveViewer(
              child: Image.network(
                widget.message.mediaUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Center(child: Icon(Icons.error, color: Colors.white)),
              ),
            )
          else if (widget.message.mediaType == MediaType.video)
            _chewieController != null
                ? Chewie(controller: _chewieController!)
                : _isError
                    ? const Center(
                        child: Text("Error loading video",
                            style: TextStyle(color: Colors.white)))
                    : const Center(
                        child:
                            CircularProgressIndicator(color: AppTheme.accent)),
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'View-Once Media\nScreen recording blocked.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
