import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

import '../models/story_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';
import '../theme/app_theme.dart';

class IntimateStoriesPage extends StatefulWidget {
  final String coupleId;

  const IntimateStoriesPage({Key? key, required this.coupleId})
      : super(key: key);

  @override
  State<IntimateStoriesPage> createState() => _IntimateStoriesPageState();
}

class _IntimateStoriesPageState extends State<IntimateStoriesPage> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  final _cloudinaryService = CloudinaryService();
  final _uuid = const Uuid();
  bool _isUploading = false;

  String get _myUid => _authService.currentUser?.uid ?? '';

  Future<void> _uploadStory() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _isUploading = true);
    try {
      final url = await _cloudinaryService.uploadMedia(picked.path);
      if (url == null) throw Exception("Upload failed");

      final story = StoryModel(
        id: _uuid.v4(),
        uploaderId: _myUid,
        videoUrl: url,
        createdAt: DateTime.now(),
      );

      await _firestoreService.addIntimateStory(widget.coupleId, story);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload story: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spicy Stories 🔒'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
      ),
      body: Stack(
        children: [
          StreamBuilder<List<StoryModel>>(
            stream: _firestoreService.intimateStoriesStream(widget.coupleId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: AppTheme.accent));
              }

              final stories = snapshot.data ?? [];
              if (stories.isEmpty) {
                return const Center(
                  child: Text(
                    'No spicy stories yet.\nBe the first to share! 🔥',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                  ),
                );
              }

              return PageView.builder(
                scrollDirection: Axis.vertical,
                itemCount: stories.length,
                itemBuilder: (context, index) {
                  return StoryPlayerWidget(
                    story: stories[index],
                    coupleId: widget.coupleId,
                    myUid: _myUid,
                  );
                },
              );
            },
          ),
          if (_isUploading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.accent),
                    SizedBox(height: 16),
                    Text('Uploading spicy story...',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isUploading ? null : _uploadStory,
        backgroundColor: AppTheme.accent,
        child: const Icon(Icons.add_a_photo, color: Colors.white),
      ),
    );
  }
}

class StoryPlayerWidget extends StatefulWidget {
  final StoryModel story;
  final String coupleId;
  final String myUid;

  const StoryPlayerWidget({
    Key? key,
    required this.story,
    required this.coupleId,
    required this.myUid,
  }) : super(key: key);

  @override
  State<StoryPlayerWidget> createState() => _StoryPlayerWidgetState();
}

class _StoryPlayerWidgetState extends State<StoryPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _secureScreen();
    _initializePlayer();
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

  Future<void> _initializePlayer() async {
    _videoPlayerController =
        VideoPlayerController.networkUrl(Uri.parse(widget.story.videoUrl));
    await _videoPlayerController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: true,
      showControls: false,
      aspectRatio: _videoPlayerController.value.aspectRatio,
    );

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    _unsecureScreen();
    super.dispose();
  }

  Future<void> _toggleReaction() async {
    final isLiked = widget.story.likedBy.contains(widget.myUid);
    final firestoreService = FirestoreService();
    await firestoreService.toggleStoryReaction(
      widget.coupleId,
      widget.story.id,
      widget.myUid,
      !isLiked,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = widget.story.likedBy.contains(widget.myUid);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isInitialized && _chewieController != null)
            GestureDetector(
              onTap: () {
                if (_videoPlayerController.value.isPlaying) {
                  _videoPlayerController.pause();
                } else {
                  _videoPlayerController.play();
                }
              },
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoPlayerController.value.size.width,
                  height: _videoPlayerController.value.size.height,
                  child: Chewie(controller: _chewieController!),
                ),
              ),
            )
          else
            const Center(
                child: CircularProgressIndicator(color: AppTheme.accent)),
          Positioned(
            right: 16,
            bottom: 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FutureBuilder<UserModel?>(
                  future: FirestoreService().getUser(widget.story.uploaderId),
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    return CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.surfaceDark,
                      backgroundImage: (user?.photoUrl.isNotEmpty == true)
                          ? NetworkImage(user!.photoUrl)
                          : null,
                      child: (user?.photoUrl.isEmpty ?? true)
                          ? Text(
                              user?.displayName.isNotEmpty == true
                                  ? user!.displayName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  color: AppTheme.accent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            )
                          : null,
                    );
                  },
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _toggleReaction,
                  child: Column(
                    children: [
                      Icon(
                        isLiked
                            ? Icons.local_fire_department
                            : Icons.local_fire_department_outlined,
                        color: isLiked ? Colors.orange : Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.story.likedBy.length}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
