import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfilePhotoViewer extends StatelessWidget {
  final String heroTag;
  final String photoUrl;
  final String displayName;

  const ProfilePhotoViewer({
    super.key,
    required this.heroTag,
    required this.photoUrl,
    required this.displayName,
  });

  static void show({
    required BuildContext context,
    required String heroTag,
    required String photoUrl,
    required String displayName,
  }) {
    if (photoUrl.isEmpty) return; // Don't show if no photo available
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.8),
        pageBuilder: (context, _, __) => ProfilePhotoViewer(
          heroTag: heroTag,
          photoUrl: photoUrl,
          displayName: displayName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          displayName,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Hero(
              tag: heroTag,
              child: CachedNetworkImage(
                imageUrl: photoUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.error, color: Colors.white, size: 40),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
