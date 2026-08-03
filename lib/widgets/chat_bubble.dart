import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:swipe_to/swipe_to.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/message_model.dart';
import '../theme/app_theme.dart';
import 'audio_bubble_widget.dart';
import '../screens/full_screen_photo_viewer.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final VoidCallback? onViewOnce;
  final VoidCallback? onLongPress;
  final VoidCallback? onSwipeRight;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onViewOnce,
    this.onLongPress,
    this.onSwipeRight,
  });

  Widget _buildStatusIcon() {
    if (!isMe) return const SizedBox.shrink();
    if (message.status == 'seen') {
      return const Icon(Icons.done_all, color: Colors.blue, size: 14);
    } else if (message.status == 'delivered') {
      return const Icon(Icons.done_all, color: Colors.grey, size: 14);
    }
    return const Icon(Icons.done, color: Colors.grey, size: 14);
  }

  BoxDecoration _bubbleDecoration() {
    return BoxDecoration(
      color: isMe ? AppTheme.accent.withValues(alpha: 0.15) : AppTheme.cardDark,
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(20),
        topRight: const Radius.circular(20),
        bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
        bottomRight:
            isMe ? const Radius.circular(4) : const Radius.circular(20),
      ),
      border: Border.all(
        color: isMe
            ? AppTheme.accent.withValues(alpha: 0.2)
            : AppTheme.dividerColor.withValues(alpha: 0.5),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildQuotedReply() {
    if (message.replyToMessageId == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2), // Translucent background
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: AppTheme.accent, // rose/crimson colored accent bar
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.replyToSenderName ?? 'Reply',
            style: const TextStyle(
              color: AppTheme.accent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message.replyToText ?? 'Original message',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeAndStatus() {
    final timeStr = DateFormat('h:mm a').format(message.timestamp);
    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            timeStr,
            style: TextStyle(
              color: AppTheme.textSecondary.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          _buildStatusIcon(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ─── Deleted Message ─────────────────────────────────────────
    if (message.isDeleted) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: _bubbleDecoration(),
          child: const Text(
            '🚫 This message was deleted',
            style: TextStyle(
                color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    Widget contentWidget;

    // ─── GIF Media Bubble ─────────────────────────────────────────
    if (message.mediaType == MediaType.gif && message.mediaUrl.isNotEmpty) {
      contentWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildQuotedReply(),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenPhotoViewer(
                        imageUrl: message.mediaUrl,
                        heroTag: 'gif_${message.messageId}',
                      ),
                    ));
              },
              child: Hero(
                tag: 'gif_${message.messageId}',
                child: CachedNetworkImage(
                  imageUrl: message.mediaUrl,
                  fit: BoxFit.cover,
                  width: 200,
                  placeholder: (context, url) => Container(
                    width: 200,
                    height: 150,
                    color: AppTheme.surfaceDark,
                    child: const Center(
                      child: CircularProgressIndicator(color: AppTheme.accent),
                    ),
                  ),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.broken_image),
                ),
              ),
            ),
          ),
          if (message.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 2),
              child: Text(
                message.text,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          _buildTimeAndStatus(),
        ],
      );
    }
    // ─── Regular Image/Video Bubble ──────────────────────────────
    else if ((message.mediaType == MediaType.photo ||
            message.mediaType == MediaType.video) &&
        message.mediaUrl.isNotEmpty) {
      if (message.isViewOnce) {
        contentWidget = message.isOpened
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility_off,
                      color: AppTheme.textSecondary, size: 18),
                  const SizedBox(width: 8),
                  const Text('Expired Media',
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          fontStyle: FontStyle.italic)),
                ],
              )
            : InkWell(
                onTap: onViewOnce,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_circle_outline,
                        color: AppTheme.accent, size: 22),
                    const SizedBox(width: 8),
                    const Text('Tap to View Once',
                        style: TextStyle(
                            color: AppTheme.accent,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              );
      } else {
        contentWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildQuotedReply(),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullScreenPhotoViewer(
                          imageUrl: message.mediaUrl,
                          heroTag: 'img_${message.messageId}',
                        ),
                      ));
                },
                child: Hero(
                  tag: 'img_${message.messageId}',
                  child: Image.network(
                    message.mediaUrl,
                    width: 260,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 260,
                      height: 100,
                      color: AppTheme.surfaceDark,
                      child: const Center(
                        child: Icon(Icons.broken_image,
                            color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (message.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 2),
                child: Text(
                  message.text,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 15, height: 1.4),
                ),
              ),
            _buildTimeAndStatus(),
          ],
        );
      }
    }
    // ─── Voice Note Bubble ───────────────────────────────────────
    else if (message.mediaType == MediaType.voice &&
        message.mediaUrl.isNotEmpty) {
      contentWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildQuotedReply(),
          AudioBubbleWidget(message: message, isMe: isMe),
          _buildTimeAndStatus(),
        ],
      );
    }
    // ─── Text Bubble ─────────────────────────────────────────────
    else {
      contentWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildQuotedReply(),
          Text(
            message.text,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          _buildTimeAndStatus(),
        ],
      );
    }

    return SwipeTo(
      onRightSwipe: onSwipeRight != null ? (details) => onSwipeRight!() : null,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: const BoxConstraints(maxWidth: 280),
            decoration: _bubbleDecoration(),
            child: contentWidget,
          ),
        ),
      ),
    );
  }
}
