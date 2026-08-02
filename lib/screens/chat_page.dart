import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../widgets/chat_bubble.dart';
import '../theme/app_theme.dart';
import 'call_page.dart';

class ChatPage extends StatefulWidget {
  final String coupleId;
  const ChatPage({super.key, required this.coupleId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _cloudinaryService = CloudinaryService();
  final _scrollController = ScrollController();
  final _uuid = const Uuid();
  late final Stream<List<MessageModel>> _messagesStream;
  final _picker = ImagePicker();

  bool _isViewOnce = false;
  bool _sending = false;
  MessageModel? _replyingTo;
  String _partnerId = '';

  String get _myUid => _authService.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _messagesStream = _firestoreService.messagesStream(widget.coupleId);
    _fetchPartnerId();
  }

  Future<void> _fetchPartnerId() async {
    final myUser = await _firestoreService.getUser(_myUid);
    if (myUser != null && mounted) {
      setState(() {
        _partnerId = myUser.partnerId;
      });
    }
  }

  @override
  void dispose() {
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

  Future<void> _sendTextMessage(String text) async {
    if (text.isEmpty) return;

    final msg = MessageModel(
      messageId: _uuid.v4(),
      senderId: _myUid,
      text: text,
      mediaType: MediaType.text,
      replyToMessageId: _replyingTo?.messageId,
      isViewOnce: false,
    );

    setState(() => _replyingTo = null);
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
      final url = await _cloudinaryService.uploadMedia(picked.path);
      if (url == null) throw Exception('Upload failed');

      final msg = MessageModel(
        messageId: _uuid.v4(),
        senderId: _myUid,
        mediaUrl: url,
        mediaType: type,
        replyToMessageId: _replyingTo?.messageId,
        isViewOnce: _isViewOnce,
      );

      await _firestoreService.sendMessage(widget.coupleId, msg);
      setState(() {
        _isViewOnce = false;
        _replyingTo = null;
      });
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

  void _showDeleteMenu(MessageModel msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.grey),
              title: const Text('Delete for me',
                  style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () async {
                Navigator.pop(ctx);
                await _firestoreService.deleteMessageForMe(
                    widget.coupleId, msg.messageId, _myUid);
              },
            ),
            if (msg.senderId == _myUid)
              ListTile(
                leading:
                    const Icon(Icons.delete_forever, color: Colors.redAccent),
                title: const Text('Delete for everyone',
                    style: TextStyle(color: Colors.redAccent)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _firestoreService.deleteMessageForEveryone(
                      widget.coupleId, msg.messageId);
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatLastSeen(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';

    final hour =
        time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hour:${time.minute.toString().padLeft(2, '0')} $amPm';

    if (diff.inHours < 24 && now.day == time.day) {
      return 'today at $timeStr';
    } else if (diff.inHours < 48 &&
        (now.day - time.day == 1 || now.day - time.day == -30)) {
      return 'yesterday at $timeStr';
    } else {
      return '${time.month}/${time.day} at $timeStr';
    }
  }

  Widget _buildAppBarTitle() {
    if (_partnerId.isEmpty) {
      return const Text('Private Chat');
    }
    return StreamBuilder<UserModel?>(
      stream: _firestoreService.userStream(_partnerId),
      builder: (context, snapshot) {
        final partner = snapshot.data;
        if (partner == null) return const Text('Private Chat');

        return Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.cardDark,
              backgroundImage: partner.photoUrl.isNotEmpty
                  ? NetworkImage(partner.photoUrl)
                  : null,
              child: partner.photoUrl.isEmpty
                  ? Text(
                      partner.displayName.isNotEmpty
                          ? partner.displayName[0].toUpperCase()
                          : '?',
                      style:
                          const TextStyle(fontSize: 14, color: AppTheme.accent),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partner.safeDisplayName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  partner.isOnline
                      ? 'Online ❤️'
                      : 'Last seen ${_formatLastSeen(partner.lastSeen)}',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.accent.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildAppBarTitle(),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: AppTheme.accent),
            tooltip: 'Voice Call',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      CallPage(coupleId: widget.coupleId, isVideo: false),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam, color: AppTheme.accent),
            tooltip: 'Video Call',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      CallPage(coupleId: widget.coupleId, isVideo: true),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: AppTheme.accent),
            tooltip: 'Clear Chat',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppTheme.cardDark,
                  title: const Text('Clear Chat',
                      style: TextStyle(color: AppTheme.textPrimary)),
                  content: const Text(
                      'Are you sure you want to clear your chat history?',
                      style: TextStyle(color: AppTheme.textSecondary)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel',
                          style: TextStyle(color: AppTheme.accent)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Clear',
                          style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await _firestoreService.clearChat(widget.coupleId, _myUid);
              }
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.cardGradient),
        ),
      ),
      body: Column(
        children: [
          // ─── Messages List ───────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.accent),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _firestoreService.markMessagesAsSeen(
                        widget.coupleId, _myUid);
                  }
                });

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

                // Mark received messages as seen
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _firestoreService.markMessagesAsSeen(widget.coupleId, _myUid);
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];

                    // Skip rendering if I deleted it for myself
                    if (msg.deletedBy.contains(_myUid)) {
                      return const SizedBox.shrink();
                    }

                    final isMe = msg.senderId == _myUid;

                    return ChatBubble(
                      message: msg,
                      isMe: isMe,
                      onViewOnce: () => _handleViewOnce(msg),
                      onLongPress: () => _showDeleteMenu(msg),
                      onSwipeRight: () => setState(() => _replyingTo = msg),
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

          // ─── Replying Context Box ────────────────────────────────
          if (_replyingTo != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.cardDark,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _replyingTo!.senderId == _myUid
                              ? 'Replying to yourself'
                              : 'Replying to partner',
                          style: const TextStyle(
                              color: AppTheme.accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _replyingTo!.mediaUrl.isNotEmpty
                              ? '📷 Media Message'
                              : _replyingTo!.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: AppTheme.textSecondary, size: 20),
                    onPressed: () => setState(() => _replyingTo = null),
                  ),
                ],
              ),
            ),

          // ─── Input Area ──────────────────────────────────────────
          ChatInputBar(
            isSending: _sending,
            onShowMediaPicker: _showMediaPicker,
            onSendText: _sendTextMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentMenu(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _attachmentOption(Icons.image_rounded, 'Photo', Colors.purpleAccent,
              () {
            Navigator.pop(context);
            _sendMediaMessage(MediaType.photo);
          }),
          _attachmentOption(Icons.videocam_rounded, 'Video', Colors.pinkAccent,
              () {
            Navigator.pop(context);
            _sendMediaMessage(MediaType.video);
          }),
          _attachmentOption(Icons.timer_rounded, 'View Once', AppTheme.accent,
              () {
            Navigator.pop(context);
            setState(() => _isViewOnce = true);
          }),
        ],
      ),
    );
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildAttachmentMenu(ctx),
    );
  }

  Widget _attachmentOption(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

class ChatInputBar extends StatefulWidget {
  final Future<void> Function(String) onSendText;
  final VoidCallback onShowMediaPicker;
  final bool isSending;

  const ChatInputBar({
    Key? key,
    required this.onSendText,
    required this.onShowMediaPicker,
    required this.isSending,
  }) : super(key: key);

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isNotEmpty && !widget.isSending) {
      widget.onSendText(text);
      _textController.clear();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 24, top: 12),
      decoration: BoxDecoration(
          color: AppTheme.surfaceDark.withValues(alpha: 0.9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ]),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attachments Button
          Container(
            margin: const EdgeInsets.only(bottom: 6, right: 8),
            child: IconButton(
              icon: const Icon(Icons.add_circle,
                  color: AppTheme.textSecondary, size: 28),
              onPressed: widget.onShowMediaPicker,
            ),
          ),

          // Text Field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions_outlined,
                        color: AppTheme.textSecondary),
                    onPressed: () {}, // Future: Emoji picker
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 1,
                      maxLines: 5,
                      onChanged: (text) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Message your love...',
                        hintStyle: TextStyle(color: AppTheme.textSecondary),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (_textController.text.trim().isEmpty)
                    IconButton(
                      icon: const Icon(Icons.mic_none_rounded,
                          color: AppTheme.textSecondary),
                      onPressed: () {}, // Future: Voice recording
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send Button
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: widget.isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Icon(
                      _textController.text.trim().isEmpty
                          ? Icons.favorite
                          : Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
              onPressed: widget.isSending ? null : _handleSend,
            ),
          ),
        ],
      ),
    );
  }
}
