import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:swipe_to/swipe_to.dart';
import '../models/message_model.dart';
import '../theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('h:mm a').format(message.timestamp);

    // ─── Deleted Message ─────────────────────────────────────────
    if (message.isDeleted) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: AppTheme.textSecondary.withValues(alpha: 0.3)),
          ),
          child: const Text(
            '🚫 This message was deleted',
            style: TextStyle(
                color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    // ─── View-Once Media ─────────────────────────────────────────
    if (message.isViewOnce) {
      return SwipeTo(
        onRightSwipe:
            onSwipeRight != null ? (details) => onSwipeRight!() : null,
        child: GestureDetector(
          onLongPress: onLongPress,
          child: Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(14),
              constraints: const BoxConstraints(maxWidth: 260),
              decoration: BoxDecoration(
                color: isMe
                    ? AppTheme.accent.withValues(alpha: 0.15)
                    : AppTheme.cardDark,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppTheme.accent.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: message.isOpened
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.visibility_off,
                          color: AppTheme.textSecondary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Expired Media',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    )
                  : InkWell(
                      onTap: onViewOnce,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_circle_outline,
                            color: AppTheme.accent,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Tap to View Once',
                            style: TextStyle(
                              color: AppTheme.accent,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      );
    }

    // ─── Media Bubble ────────────────────────────────────────────
    if (message.mediaType != MediaType.text && message.mediaUrl.isNotEmpty) {
      return SwipeTo(
        onRightSwipe:
            onSwipeRight != null ? (details) => onSwipeRight!() : null,
        child: GestureDetector(
          onLongPress: onLongPress,
          child: Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              constraints: const BoxConstraints(maxWidth: 260),
              decoration: BoxDecoration(
                color: isMe
                    ? AppTheme.accent.withValues(alpha: 0.15)
                    : AppTheme.cardDark,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
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
                          child: Icon(
                            Icons.broken_image,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (message.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Text(
                        message.text,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12, bottom: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeStr,
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 11),
                        ),
                        const SizedBox(width: 4),
                        _buildStatusIcon(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ─── Text Bubble ─────────────────────────────────────────────
    return SwipeTo(
      onRightSwipe: onSwipeRight != null ? (details) => onSwipeRight!() : null,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            constraints: const BoxConstraints(maxWidth: 280),
            decoration: BoxDecoration(
              color: isMe
                  ? AppTheme.accent.withValues(alpha: 0.15)
                  : AppTheme.cardDark,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft:
                    isMe ? const Radius.circular(18) : const Radius.circular(4),
                bottomRight:
                    isMe ? const Radius.circular(4) : const Radius.circular(18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (message.replyToMessageId != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                          left: BorderSide(color: AppTheme.accent, width: 3)),
                    ),
                    child: const Text('Replied Message Here',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ),
                Text(
                  message.text,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeStr,
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11),
                    ),
                    const SizedBox(width: 4),
                    _buildStatusIcon(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
