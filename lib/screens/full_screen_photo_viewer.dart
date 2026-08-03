import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:screen_protector/screen_protector.dart';

class FullScreenPhotoViewer extends StatefulWidget {
  final String imageUrl;
  final String heroTag;
  final bool isViewOnce;

  const FullScreenPhotoViewer({
    super.key,
    required this.imageUrl,
    required this.heroTag,
    this.isViewOnce = false,
  });

  @override
  State<FullScreenPhotoViewer> createState() => _FullScreenPhotoViewerState();
}

class _FullScreenPhotoViewerState extends State<FullScreenPhotoViewer> {
  @override
  void initState() {
    super.initState();
    _secureScreen();
  }

  Future<void> _secureScreen() async {
    if (widget.isViewOnce && !kIsWeb) {
      if (Theme.of(context).platform == TargetPlatform.android) {
        await ScreenProtector.preventScreenshotOn();
      }
    }
  }

  Future<void> _unsecureScreen() async {
    if (widget.isViewOnce && !kIsWeb) {
      if (Theme.of(context).platform == TargetPlatform.android) {
        await ScreenProtector.preventScreenshotOff();
      }
    }
  }

  @override
  void dispose() {
    _unsecureScreen();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Photo'),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Hero(
                tag: widget.heroTag,
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 50),
                ),
              ),
            ),
          ),
          if (widget.isViewOnce)
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
