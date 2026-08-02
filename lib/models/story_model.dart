import 'package:cloud_firestore/cloud_firestore.dart';

class StoryModel {
  final String id;
  final String uploaderId;
  final String videoUrl;
  final String thumbnailUrl; // Optional, can use it later if needed
  final DateTime createdAt;
  final List<String> likedBy;

  StoryModel({
    required this.id,
    required this.uploaderId,
    required this.videoUrl,
    this.thumbnailUrl = '',
    DateTime? createdAt,
    this.likedBy = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  factory StoryModel.fromMap(Map<String, dynamic> map, String id) {
    return StoryModel(
      id: id,
      uploaderId: map['uploaderId'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      likedBy: List<String>.from(map['likedBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uploaderId': uploaderId,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'likedBy': likedBy,
    };
  }
}
