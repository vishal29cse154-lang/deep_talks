import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:uuid/uuid.dart';
import '../models/memory_model.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class MemoryVaultPage extends StatefulWidget {
  final String coupleId;
  const MemoryVaultPage({super.key, required this.coupleId});

  @override
  State<MemoryVaultPage> createState() => _MemoryVaultPageState();
}

class _MemoryVaultPageState extends State<MemoryVaultPage> {
  final _firestoreService = FirestoreService();
  final _cloudinaryService = CloudinaryService();
  final _authService = AuthService();
  final _uuid = const Uuid();
  final _picker = ImagePicker();

  bool _isUploading = false;

  Future<void> _uploadMemory() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final myUid = _authService.currentUser?.uid;
    if (myUid == null) return;

    setState(() => _isUploading = true);

    try {
      final url = await _cloudinaryService.uploadMedia(pickedFile.path);
      if (url != null) {
        final memory = MemoryModel(
          id: _uuid.v4(),
          url: url,
          uploaderId: myUid,
          createdAt: DateTime.now(),
        );
        await _firestoreService.addMemory(widget.coupleId, memory);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload memory: $e')),
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
        title: const Text('Memory Vault 📸'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadMemory,
        backgroundColor: AppTheme.accent,
        child: _isUploading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.add_a_photo_rounded, color: Colors.white),
      ),
      body: StreamBuilder<List<MemoryModel>>(
        stream: _firestoreService.memoriesStream(widget.coupleId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.accent));
          }

          final memories = snapshot.data ?? [];

          if (memories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.photo_library_rounded,
                      size: 80, color: AppTheme.accent),
                  const SizedBox(height: 16),
                  const Text(
                    'No memories yet',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload your first beautiful moment together!',
                    style: TextStyle(
                        color: AppTheme.textSecondary.withValues(alpha: 0.7),
                        fontSize: 14),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms);
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: memories.length,
            itemBuilder: (context, index) {
              final memory = memories[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: memory.url,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppTheme.cardDark,
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: AppTheme.accent, strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppTheme.cardDark,
                    child: const Icon(Icons.error, color: Colors.red),
                  ),
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: 50 * index));
            },
          );
        },
      ),
    );
  }
}
