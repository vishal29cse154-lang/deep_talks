import 'package:cloud_firestore/cloud_firestore.dart';

enum MediaType { text, photo, video, voice, gif }

class MessageModel {
  final String messageId;
  final String senderId;
  final String text;
  final String mediaUrl;
  final MediaType mediaType;
  final bool isViewOnce;
  final bool isOpened;
  final String status; // 'sent', 'delivered', 'seen'
  final String? replyToMessageId;
  final String? replyToText;
  final String? replyToSenderName;
  final int? audioDuration;
  final bool isDeleted;
  final List<String> deletedBy;
  final DateTime timestamp;

  MessageModel({
    required this.messageId,
    required this.senderId,
    this.text = '',
    this.mediaUrl = '',
    this.mediaType = MediaType.text,
    this.isViewOnce = false,
    this.isOpened = false,
    this.status = 'sent',
    this.replyToMessageId,
    this.replyToText,
    this.replyToSenderName,
    this.audioDuration,
    this.isDeleted = false,
    this.deletedBy = const [],
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      messageId: map['messageId'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      mediaUrl: map['mediaUrl'] ?? '',
      mediaType: MediaType.values.firstWhere(
        (e) => e.name == (map['mediaType'] ?? 'text'),
        orElse: () => MediaType.text,
      ),
      isViewOnce: map['isViewOnce'] ?? false,
      isOpened: map['isOpened'] ?? false,
      status: map['status'] ?? 'sent',
      replyToMessageId: map['replyToMessageId'],
      replyToText: map['replyToText'],
      replyToSenderName: map['replyToSenderName'],
      audioDuration: map['audioDuration'],
      isDeleted: map['isDeleted'] ?? false,
      deletedBy: List<String>.from(map['deletedBy'] ?? []),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'text': text,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType.name,
      'isViewOnce': isViewOnce,
      'isOpened': isOpened,
      'status': status,
      'replyToMessageId': replyToMessageId,
      'replyToText': replyToText,
      'replyToSenderName': replyToSenderName,
      'audioDuration': audioDuration,
      'isDeleted': isDeleted,
      'deletedBy': deletedBy,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
