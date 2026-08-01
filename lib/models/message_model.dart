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
  final DateTime timestamp;

  MessageModel({
    required this.messageId,
    required this.senderId,
    this.text = '',
    this.mediaUrl = '',
    this.mediaType = MediaType.text,
    this.isViewOnce = false,
    this.isOpened = false,
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
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
