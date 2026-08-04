import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';
import '../services/notification_alert_service.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/profile_photo_viewer.dart';
import '../theme/app_theme.dart';
import 'view_once_screen.dart';
import 'call_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import '../widgets/spicy_gif_picker.dart';

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
  final _scrollController = AutoScrollController();
  final _uuid = const Uuid();
  late final Stream<List<MessageModel>> _messagesStream;
  final _picker = ImagePicker();

  bool _isViewOnce = false;
  bool _sending = false;
  MessageModel? _replyingTo;
  String _partnerId = '';
  bool _showScrollToBottom = false;

  bool _isSearching = false;
  String _searchQuery = '';
  List<int> _searchMatchIndices = [];
  int _currentSearchIndex = -1;
  List<MessageModel> _currentMessages = [];

  String get _myUid => _authService.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    NotificationAlertService.isChatScreenActive = true;
    NotificationAlertService.activeCoupleId = widget.coupleId;
    _messagesStream = _firestoreService.messagesStream(widget.coupleId);
    _fetchPartnerId();
    _scrollController.addListener(() {
      if (_scrollController.offset > 300 && !_showScrollToBottom) {
        setState(() => _showScrollToBottom = true);
      } else if (_scrollController.offset <= 300 && _showScrollToBottom) {
        setState(() => _showScrollToBottom = false);
      }
    });
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
    NotificationAlertService.isChatScreenActive = false;
    NotificationAlertService.activeCoupleId = '';
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _scrollToReply(String messageId, List<MessageModel> messages) {
    final index = messages.indexWhere((m) => m.messageId == messageId);
    if (index != -1) {
      _scrollController.scrollToIndex(index,
          preferPosition: AutoScrollPosition.middle);
      _scrollController.highlight(index);
    }
  }

  void _onSearchQueryChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _searchMatchIndices.clear();
      _currentSearchIndex = -1;

      if (_searchQuery.isNotEmpty) {
        for (int i = 0; i < _currentMessages.length; i++) {
          if (_currentMessages[i].text.toLowerCase().contains(_searchQuery)) {
            _searchMatchIndices.add(i);
          }
        }
        if (_searchMatchIndices.isNotEmpty) {
          _currentSearchIndex = 0;
          _scrollToSearchIndex();
        }
      }
    });
  }

  void _scrollToSearchIndex() {
    if (_searchMatchIndices.isEmpty || _currentSearchIndex < 0) return;
    int index = _searchMatchIndices[_currentSearchIndex];
    _scrollController.scrollToIndex(index,
        preferPosition: AutoScrollPosition.middle);
    _scrollController.highlight(index,
        highlightDuration: const Duration(seconds: 1));
  }

  void _nextSearchMatchUp() {
    if (_searchMatchIndices.isEmpty)
      return; // Up visually = older message = higher index
    setState(() {
      _currentSearchIndex =
          (_currentSearchIndex + 1) % _searchMatchIndices.length;
    });
    _scrollToSearchIndex();
  }

  void _prevSearchMatchDown() {
    if (_searchMatchIndices.isEmpty)
      return; // Down visually = newer message = lower index
    setState(() {
      _currentSearchIndex =
          (_currentSearchIndex - 1 + _searchMatchIndices.length) %
              _searchMatchIndices.length;
    });
    _scrollToSearchIndex();
  }

  void _onReplyTriggered(MessageModel selectedMessage) {
    setState(() {
      _replyingTo = selectedMessage;
    });
  }

  Future<void> _sendTextMessage(String text) async {
    if (text.isEmpty) return;

    String? replyText;
    String? replySenderName;
    if (_replyingTo != null) {
      replyText =
          _replyingTo!.mediaUrl.isNotEmpty ? '📷 Media' : _replyingTo!.text;
      replySenderName = _replyingTo!.senderId == _myUid ? 'You' : 'Partner';
    }

    final msg = MessageModel(
      messageId: _uuid.v4(),
      senderId: _myUid,
      text: text,
      mediaType: MediaType.text,
      replyToMessageId: _replyingTo?.messageId,
      replyToText: replyText,
      replyToSenderName: replySenderName,
      replyToType: _replyingTo?.mediaType.name,
      replyToMediaUrl: _replyingTo?.mediaUrl,
      isViewOnce: false,
    );

    setState(() => _replyingTo = null);
    await _firestoreService.sendMessage(widget.coupleId, msg);
    _scrollToBottom();
  }

  Future<void> _sendVoiceMessage(String path, int durationSeconds) async {
    setState(() => _sending = true);
    try {
      final url = await _cloudinaryService.uploadMedia(path);
      if (url == null) throw Exception('Upload failed');

      String? replyText;
      String? replySenderName;
      if (_replyingTo != null) {
        replyText = _replyingTo!.mediaType == MediaType.voice
            ? '🎤 Voice Message'
            : _replyingTo!.mediaUrl.isNotEmpty
                ? '📷 Media'
                : _replyingTo!.text;
        replySenderName = _replyingTo!.senderId == _myUid ? 'You' : 'Partner';
      }

      final msg = MessageModel(
        messageId: _uuid.v4(),
        senderId: _myUid,
        mediaUrl: url,
        mediaType: MediaType.voice,
        replyToMessageId: _replyingTo?.messageId,
        replyToText: replyText,
        replyToSenderName: replySenderName,
        replyToType: _replyingTo?.mediaType.name,
        replyToMediaUrl: _replyingTo?.mediaUrl,
        audioDuration: durationSeconds,
      );

      await _firestoreService.sendMessage(widget.coupleId, msg);
      setState(() {
        _replyingTo = null;
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send voice: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendMediaMessage(
    MediaType type, {
    bool isViewOnce = false,
  }) async {
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

      String? replyText;
      String? replySenderName;
      if (_replyingTo != null) {
        replyText =
            _replyingTo!.mediaUrl.isNotEmpty ? '📷 Media' : _replyingTo!.text;
        replySenderName = _replyingTo!.senderId == _myUid ? 'You' : 'Partner';
      }

      final msg = MessageModel(
        messageId: _uuid.v4(),
        senderId: _myUid,
        mediaUrl: url,
        mediaType: type,
        replyToMessageId: _replyingTo?.messageId,
        replyToText: replyText,
        replyToSenderName: replySenderName,
        replyToType: _replyingTo?.mediaType.name,
        replyToMediaUrl: _replyingTo?.mediaUrl,
        isViewOnce: isViewOnce,
      );

      await _firestoreService.sendMessage(widget.coupleId, msg);
      setState(() {
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

  Future<void> _sendGifMessage(String gifUrl) async {
    final msg = MessageModel(
      messageId: _uuid.v4(),
      senderId: _myUid,
      mediaUrl: gifUrl,
      mediaType: MediaType.gif,
    );
    await _firestoreService.sendMessage(widget.coupleId, msg);
    _scrollToBottom();
  }

  Future<void> _sendGifBytes(Uint8List bytes, String mimeType) async {
    setState(() => _sending = true);
    try {
      final dir = await getTemporaryDirectory();
      String ext = '.gif';
      if (mimeType == 'image/png') {
        ext = '.png';
      } else if (mimeType == 'image/jpeg')
        ext = '.jpg';
      else if (mimeType == 'image/webp') ext = '.webp';

      final file = File(
          '${dir.path}/gboard_media_${DateTime.now().millisecondsSinceEpoch}$ext');
      await file.writeAsBytes(bytes);

      final url = await _cloudinaryService.uploadMedia(file.path);
      if (url == null) throw Exception('Upload failed');

      final msg = MessageModel(
        messageId: _uuid.v4(),
        senderId: _myUid,
        mediaUrl: url,
        mediaType: MediaType.gif,
      );

      await _firestoreService.sendMessage(widget.coupleId, msg);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send Gboard media: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _handleViewOnce(MessageModel msg) async {
    if (msg.mediaUrl.isNotEmpty && !msg.isOpened) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ViewOnceScreen(message: msg, coupleId: widget.coupleId),
        ),
      );
    }
  }

  void _showDeleteMenu(MessageModel msg) {
    final emojis = [
      '❤️',
      '🔥',
      '😆',
      '😮',
      '😢',
      '👍',
      '💋',
      '💦',
      '😈',
      '👀',
      '💯',
      '✨',
      '💔'
    ];

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
            // Reactions Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: emojis.map((emoji) {
                    final isSelected = msg.reactions?[_myUid] == emoji;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: GestureDetector(
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _firestoreService.toggleMessageReaction(
                              widget.coupleId, msg.messageId, _myUid, emoji);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: isSelected
                              ? BoxDecoration(
                                  color: AppTheme.accent.withValues(alpha: 0.2),
                                  shape: BoxShape.circle)
                              : null,
                          child:
                              Text(emoji, style: const TextStyle(fontSize: 28)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Divider(color: AppTheme.dividerColor.withValues(alpha: 0.5)),

            if (msg.text.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.copy, color: Colors.blueAccent),
                title: const Text(
                  'Copy text',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Clipboard.setData(ClipboardData(text: msg.text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied into clipboard!')),
                  );
                },
              ),
            if (msg.mediaUrl.isNotEmpty) // allow copying the raw link if needed
              ListTile(
                leading: const Icon(Icons.link, color: Colors.blueAccent),
                title: const Text(
                  'Copy media URL',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Clipboard.setData(ClipboardData(text: msg.mediaUrl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied into clipboard!')),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.grey),
              title: const Text(
                'Delete for me',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await _firestoreService.deleteMessageForMe(
                  widget.coupleId,
                  msg.messageId,
                  _myUid,
                );
              },
            ),
            if (msg.senderId == _myUid)
              ListTile(
                leading: const Icon(
                  Icons.delete_forever,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Delete for everyone',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _firestoreService.deleteMessageForEveryone(
                    widget.coupleId,
                    msg.messageId,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateDivider(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(date.year, date.month, date.day);

    String dateText;
    if (msgDate == today) {
      dateText = 'Today';
    } else if (msgDate == yesterday) {
      dateText = 'Yesterday';
    } else {
      dateText = DateFormat('dd MMM yyyy').format(date);
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.cardDark.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Text(
          dateText,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
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
    if (_isSearching) {
      return Row(
        children: [
          Expanded(
            child: TextField(
              autofocus: true,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: TextStyle(
                    color: AppTheme.textSecondary.withValues(alpha: 0.7)),
                border: InputBorder.none,
              ),
              onChanged: _onSearchQueryChanged,
            ),
          ),
          if (_searchMatchIndices.isNotEmpty)
            Text(
              '${_currentSearchIndex + 1}/${_searchMatchIndices.length}',
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
        ],
      );
    }

    if (_partnerId.isEmpty) {
      return const Text('Private Chat');
    }
    return StreamBuilder<UserModel?>(
      stream: _firestoreService.userStream(_partnerId),
      builder: (context, snapshot) {
        final partner = snapshot.data;
        if (partner == null) return const Text('Private Chat');

        final bool isActuallyOnline = partner.isOnline &&
            DateTime.now().difference(partner.lastSeen).inMinutes <= 5;

        return Row(
          children: [
            GestureDetector(
              onTap: () {
                if (partner.photoUrl.isNotEmpty) {
                  ProfilePhotoViewer.show(
                    context: context,
                    heroTag: 'chat_avatar_${partner.uid}',
                    photoUrl: partner.photoUrl,
                    displayName: partner.safeDisplayName,
                  );
                }
              },
              child: Hero(
                tag: 'chat_avatar_${partner.uid}',
                child: CircleAvatar(
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
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.accent,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partner.safeDisplayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isActuallyOnline
                      ? 'Online ❤️'
                      : 'Last seen ${_formatLastSeen(partner.lastSeen)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.accent.withValues(alpha: 0.8),
                  ),
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
          if (_isSearching) ...[
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_up, color: AppTheme.accent),
              onPressed: _nextSearchMatchUp,
            ),
            IconButton(
              icon:
                  const Icon(Icons.keyboard_arrow_down, color: AppTheme.accent),
              onPressed: _prevSearchMatchDown,
            ),
            IconButton(
              icon: const Icon(Icons.close, color: AppTheme.accent),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchMatchIndices.clear();
                  _currentSearchIndex = -1;
                });
              },
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.search, color: AppTheme.accent),
              tooltip: 'Search Messages',
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
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
                    title: const Text(
                      'Clear Chat',
                      style: TextStyle(color: AppTheme.textPrimary),
                    ),
                    content: const Text(
                      'Are you sure you want to clear your chat history?',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: AppTheme.accent),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text(
                          'Clear',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _firestoreService.clearChat(widget.coupleId, _myUid);
                }
              },
            ),
          ]
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.cardGradient),
        ),
      ),
      body: Column(
        children: [
          // ─── Messages List ───────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                StreamBuilder<List<MessageModel>>(
                  stream: _messagesStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.accent,
                        ),
                      );
                    }

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _firestoreService.markMessagesAsSeen(
                          widget.coupleId,
                          _myUid,
                        );
                      }
                    });

                    final messages = snapshot.data ?? [];
                    _currentMessages = messages; // Save ref for search

                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: AppTheme.textSecondary.withValues(
                                alpha: 0.5,
                              ),
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

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        top: 24,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];

                        // Skip rendering if I deleted it for myself
                        if (msg.deletedBy.contains(_myUid)) {
                          return const SizedBox.shrink();
                        }

                        final isMe = msg.senderId == _myUid;

                        Widget bubble = ChatBubble(
                          message: msg,
                          isMe: isMe,
                          onViewOnce: () => _handleViewOnce(msg),
                          onLongPress: () => _showDeleteMenu(msg),
                          onSwipeRight: () => _onReplyTriggered(msg),
                          onReplyTap: msg.replyToMessageId != null
                              ? () => _scrollToReply(
                                  msg.replyToMessageId!, messages)
                              : null,
                        );

                        // Date Dividers
                        // Compare with the NEXT message in the list (which is chronologically OLDER because reverse: true)
                        bool showDivider = false;
                        if (index == messages.length - 1) {
                          showDivider = true; // Oldest message
                        } else {
                          final prevMsg = messages[index + 1];
                          if (msg.timestamp.day != prevMsg.timestamp.day ||
                              msg.timestamp.month != prevMsg.timestamp.month ||
                              msg.timestamp.year != prevMsg.timestamp.year) {
                            showDivider = true;
                          }
                        }

                        Widget finalBubble = bubble;
                        if (showDivider) {
                          finalBubble = Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildDateDivider(msg.timestamp),
                              bubble,
                            ],
                          );
                        }

                        return AutoScrollTag(
                          key: ValueKey(msg.messageId),
                          controller: _scrollController,
                          index: index,
                          highlightColor:
                              AppTheme.accent.withValues(alpha: 0.2),
                          child: finalBubble,
                        );
                      },
                    );
                  },
                ),
                if (_showScrollToBottom)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: _scrollToBottom,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark.withValues(alpha: 0.95),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppTheme.accent,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
              ],
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
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: AppTheme.cardDark,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _replyingTo!.senderId == _myUid
                                  ? 'Replying to yourself'
                                  : 'Replying to partner',
                              style: const TextStyle(
                                color: AppTheme.accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _replyingTo!.mediaUrl.isNotEmpty
                                  ? '📷 Media Message'
                                  : _replyingTo!.text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_replyingTo!.mediaType == MediaType.photo ||
                          _replyingTo!.mediaType == MediaType.gif)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: 40,
                          height: 40,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: CachedNetworkImage(
                              imageUrl: _replyingTo!.mediaUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      else if (_replyingTo!.mediaType == MediaType.voice)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          child: const Icon(Icons.mic, color: AppTheme.accent),
                        ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AppTheme.textSecondary,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _replyingTo = null),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ─── Input Area ──────────────────────────────────────────
          ChatInputBar(
            onSendText: _sendTextMessage,
            onSendVoice: _sendVoiceMessage,
            onShowMediaPicker: _showMediaPicker,
            onSendGif: _sendGifMessage,
            onSendGifBytes: _sendGifBytes,
            isSending: _sending,
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
          _attachmentOption(
            Icons.image_rounded,
            'Photo',
            Colors.purpleAccent,
            () {
              Navigator.pop(context);
              _sendMediaMessage(MediaType.photo);
            },
          ),
          _attachmentOption(
            Icons.videocam_rounded,
            'Video',
            Colors.pinkAccent,
            () {
              Navigator.pop(context);
              _sendMediaMessage(MediaType.video);
            },
          ),
          _attachmentOption(
            Icons.timer_rounded,
            'View Once 🔒',
            AppTheme.accent,
            () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppTheme.surfaceDark,
                  title: const Text(
                    'Send View Once',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    'Pick media type to send securely.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _sendMediaMessage(MediaType.photo, isViewOnce: true);
                      },
                      child: const Text(
                        'Photo 📷',
                        style: TextStyle(color: AppTheme.accent),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _sendMediaMessage(MediaType.video, isViewOnce: true);
                      },
                      child: const Text(
                        'Video 🎥',
                        style: TextStyle(color: AppTheme.accent),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
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
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
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
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class ChatInputBar extends StatefulWidget {
  final VoidCallback onShowMediaPicker;
  final bool isSending;
  final Function(String) onSendText;
  final Function(String, int) onSendVoice;
  final Function(String) onSendGif;
  final Function(Uint8List, String) onSendGifBytes;

  const ChatInputBar({
    super.key,
    required this.onShowMediaPicker,
    required this.isSending,
    required this.onSendText,
    required this.onSendVoice,
    required this.onSendGif,
    required this.onSendGifBytes,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _textController = TextEditingController();
  final AudioRecorder _audioRecorder = AudioRecorder();

  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _timer;

  void _showSpicyGifPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SpicyGifPickerSheet(
        onEmojiSelected: (emoji) {
          setState(() {
            _textController.text += emoji;
          });
        },
        onGifSelected: (gifUrl) {
          Navigator.pop(ctx);
          widget.onSendGif(gifUrl);
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _recordDuration = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (mounted) {
        setState(() => _recordDuration++);
      }
    });
  }

  Future<void> _startRecording() async {
    try {
      if (kIsWeb) {
        if (!await _audioRecorder.hasPermission()) {
          return;
        }
      } else {
        var status = await Permission.microphone.request();
        if (status != PermissionStatus.granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Microphone permission required.')),
            );
          }
          return;
        }
      }

      String path = '';
      if (!kIsWeb) {
        final dir = await getApplicationDocumentsDirectory();
        path =
            '${dir.path}/temp_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      }

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );

      setState(() {
        _isRecording = true;
      });
      _startTimer();
    } catch (e) {
      debugPrint("Record error: $e");
    }
  }

  Future<void> _stopRecording({bool cancel = false}) async {
    _timer?.cancel();

    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });

      if (!cancel && path != null) {
        widget.onSendVoice(path, _recordDuration);
      }
    } catch (e) {
      debugPrint("Stop record error: $e");
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
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
    final bool canSend = _textController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 24, top: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withValues(alpha: 0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attachments Button (hide if recording)
          if (!_isRecording)
            Container(
              margin: const EdgeInsets.only(bottom: 6, right: 8),
              child: IconButton(
                icon: const Icon(
                  Icons.add_circle,
                  color: AppTheme.textSecondary,
                  size: 28,
                ),
                onPressed: widget.onShowMediaPicker,
              ),
            ),

          // Emoji / GIF Button
          if (!_isRecording)
            Container(
              margin: const EdgeInsets.only(bottom: 6, right: 8),
              child: IconButton(
                icon: const Icon(
                  Icons.emoji_emotions_outlined,
                  color: AppTheme.textSecondary,
                  size: 28,
                ),
                onPressed: _showSpicyGifPicker,
              ),
            ),

          // Text Field or Recording Indicator
          Expanded(
            child: _isRecording
                ? Container(
                    height: 50,
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppTheme.accent.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.mic, color: AppTheme.accent),
                            const SizedBox(width: 8),
                            Text(
                              'Recording ${_formatDuration(_recordDuration)}... 🔴',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _stopRecording(cancel: true),
                        ),
                      ],
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            textCapitalization: TextCapitalization.sentences,
                            minLines: 1,
                            maxLines: 5,
                            onChanged: (text) => setState(() {}),
                            contentInsertionConfiguration:
                                ContentInsertionConfiguration(
                              allowedMimeTypes: const <String>[
                                'image/gif',
                                'image/png',
                                'image/jpeg',
                                'image/webp'
                              ],
                              onContentInserted:
                                  (KeyboardInsertedContent content) async {
                                if (content.data != null) {
                                  widget.onSendGifBytes(
                                      content.data!, content.mimeType);
                                }
                              },
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Message your love...',
                              hintStyle: TextStyle(
                                color: AppTheme.textSecondary,
                              ),
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(width: 8),

          // Send / Mic Button
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: widget.isSending
                ? IconButton(
                    icon: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    onPressed: null,
                  )
                : _isRecording
                    ? IconButton(
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => _stopRecording(),
                      )
                    : IconButton(
                        icon: Icon(
                          canSend ? Icons.send_rounded : Icons.mic,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: canSend ? _handleSend : _startRecording,
                      ),
          ),
        ],
      ),
    );
  }
}
