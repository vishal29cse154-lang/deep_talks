import 'package:cloud_firestore/cloud_firestore.dart';

class MemoryModel {
  final String id;
  final String url;
  final String uploaderId;
  final DateTime createdAt;

  MemoryModel({
    required this.id,
    required this.url,
    required this.uploaderId,
    required this.createdAt,
  });

  factory MemoryModel.fromMap(Map<String, dynamic> map) {
    return MemoryModel(
      id: map['id'] ?? '',
      url: map['url'] ?? '',
      uploaderId: map['uploaderId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'uploaderId': uploaderId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
