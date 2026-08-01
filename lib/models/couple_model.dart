import 'package:cloud_firestore/cloud_firestore.dart';

class CoupleModel {
  final String coupleId;
  final String user1Id;
  final String user2Id;
  final DateTime? anniversaryDate;
  final DateTime createdAt;

  CoupleModel({
    required this.coupleId,
    required this.user1Id,
    required this.user2Id,
    this.anniversaryDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory CoupleModel.fromMap(Map<String, dynamic> map) {
    return CoupleModel(
      coupleId: map['coupleId'] ?? '',
      user1Id: map['user1Id'] ?? '',
      user2Id: map['user2Id'] ?? '',
      anniversaryDate: (map['anniversaryDate'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'coupleId': coupleId,
      'user1Id': user1Id,
      'user2Id': user2Id,
      'anniversaryDate': anniversaryDate != null
          ? Timestamp.fromDate(anniversaryDate!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
