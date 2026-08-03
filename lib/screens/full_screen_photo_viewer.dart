import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FullScreenPhotoViewer extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const FullScreenPhotoViewer({
    super.key,
    required this.imageUrl,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Photo'),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Hero(
            tag: heroTag,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.broken_image, color: Colors.white, size: 50),
            ),
          ),
        ),
      ),
    );
  }
}
