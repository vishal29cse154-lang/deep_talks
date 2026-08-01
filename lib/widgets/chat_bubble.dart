import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/message_model.dart';
import '../theme/app_theme.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final VoidCallback? onViewOnce;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onViewOnce,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('h:mm a').format(message.timestamp);

    // ─── View-Once Media ─────────────────────────────────────────
    if (message.isViewOnce) {
      return Align(
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
      );
    }

    // ─── Media Bubble ────────────────────────────────────────────
    if (message.mediaType != MediaType.text && message.mediaUrl.isNotEmpty) {
      return Align(
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
                child: Text(
                  timeStr,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ─── Text Bubble ─────────────────────────────────────────────
    return Align(
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
            bottomLeft: isMe
                ? const Radius.circular(18)
                : const Radius.circular(4),
            bottomRight: isMe
                ? const Radius.circular(4)
                : const Radius.circular(18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.text,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
