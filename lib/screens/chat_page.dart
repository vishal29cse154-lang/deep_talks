import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../models/message_model.dart';
import '../widgets/chat_bubble.dart';
import '../theme/app_theme.dart';
import 'dart:io';

class ChatPage extends StatefulWidget {
  final String coupleId;
  const ChatPage({super.key, required this.coupleId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _storageService = StorageService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _uuid = const Uuid();
  final _picker = ImagePicker();

  bool _isViewOnce = false;
  bool _sending = false;

  String get _myUid => _authService.currentUser?.uid ?? '';

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendTextMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final msg = MessageModel(
      messageId: _uuid.v4(),
      senderId: _myUid,
      text: text,
      mediaType: MediaType.text,
      isViewOnce: false,
    );

    _textController.clear();
    await _firestoreService.sendMessage(widget.coupleId, msg);
    _scrollToBottom();
  }

  Future<void> _sendMediaMessage(MediaType type) async {
    XFile? picked;
    if (type == MediaType.photo) {
      picked = await _picker.pickImage(source: ImageSource.gallery);
    } else if (type == MediaType.video) {
      picked = await _picker.pickVideo(source: ImageSource.gallery);
    }

    if (picked == null) return;
    setState(() => _sending = true);

    try {
      final ext = picked.path.split('.').last;
      final url = await _storageService.uploadChatMedia(
        coupleId: widget.coupleId,
        file: File(picked.path),
        extension: ext,
      );

      final msg = MessageModel(
        messageId: _uuid.v4(),
        senderId: _myUid,
        mediaUrl: url,
        mediaType: type,
        isViewOnce: _isViewOnce,
      );

      await _firestoreService.sendMessage(widget.coupleId, msg);
      setState(() => _isViewOnce = false);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _handleViewOnce(MessageModel msg) async {
    // Show the media in a dialog, then mark as opened
    if (msg.mediaUrl.isNotEmpty) {
      await showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              Center(
                child: msg.mediaType == MediaType.photo
                    ? Image.network(msg.mediaUrl)
                    : const Center(
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
              ),
              Positioned(
                top: 40,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              const Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'View-Once Media',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    await _firestoreService.markMessageOpened(widget.coupleId, msg.messageId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.lock_rounded, size: 16, color: AppTheme.accent),
            SizedBox(width: 8),
            Text('Private Chat'),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.cardGradient),
        ),
      ),
      body: Column(
        children: [
          // ─── Messages List ───────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _firestoreService.messagesStream(widget.coupleId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.accent),
                  );
                }

                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: AppTheme.textSecondary.withValues(alpha: 0.5),
                          size: 60,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet\nSay something sweet 💕',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == _myUid;

                    return ChatBubble(
                      message: msg,
                      isMe: isMe,
                      onViewOnce: () => _handleViewOnce(msg),
                    );
                  },
                );
              },
            ),
          ),

          // ─── View-Once Toggle ────────────────────────────────────
          if (_isViewOnce)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.accent.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(
                    Icons.timer_rounded,
                    color: AppTheme.accent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'View-Once enabled',
                    style: TextStyle(color: AppTheme.accent, fontSize: 13),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _isViewOnce = false),
                    child: const Icon(
                      Icons.close,
                      color: AppTheme.accent,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),

          // ─── Input Area ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceDark,
              border: Border(top: BorderSide(color: AppTheme.dividerColor)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Media button
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      color: AppTheme.accent,
                    ),
                    onPressed: () => _showMediaPicker(),
                  ),

                  // View-Once toggle
                  IconButton(
                    icon: Icon(
                      _isViewOnce
                          ? Icons.timer_rounded
                          : Icons.timer_off_outlined,
                      color: _isViewOnce
                          ? AppTheme.accent
                          : AppTheme.textSecondary,
                      size: 22,
                    ),
                    onPressed: () => setState(() => _isViewOnce = !_isViewOnce),
                  ),

                  // Text input
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _textController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendTextMessage(),
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: AppTheme.textSecondary),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send button
                  _sending
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: AppTheme.accent,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : Container(
                          decoration: const BoxDecoration(
                            gradient: AppTheme.accentGradient,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: _sendTextMessage,
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              _mediaOption(Icons.photo_rounded, 'Photo', () {
                Navigator.pop(ctx);
                _sendMediaMessage(MediaType.photo);
              }),
              _mediaOption(Icons.videocam_rounded, 'Video', () {
                Navigator.pop(ctx);
                _sendMediaMessage(MediaType.video);
              }),
              _mediaOption(Icons.camera_alt_rounded, 'Camera', () async {
                Navigator.pop(ctx);
                final picked = await _picker.pickImage(
                  source: ImageSource.camera,
                );
                if (picked != null) {
                  setState(() => _sending = true);
                  try {
                    final url = await _storageService.uploadChatMedia(
                      coupleId: widget.coupleId,
                      file: File(picked.path),
                      extension: 'jpg',
                    );
                    final msg = MessageModel(
                      messageId: _uuid.v4(),
                      senderId: _myUid,
                      mediaUrl: url,
                      mediaType: MediaType.photo,
                      isViewOnce: _isViewOnce,
                    );
                    await _firestoreService.sendMessage(widget.coupleId, msg);
                    setState(() => _isViewOnce = false);
                  } catch (e) {
                    // Handle error silently
                  } finally {
                    if (mounted) setState(() => _sending = false);
                  }
                }
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mediaOption(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.accent.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.accent),
      ),
      title: Text(label, style: const TextStyle(color: AppTheme.textPrimary)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
