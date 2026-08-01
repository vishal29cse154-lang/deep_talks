import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final String inviteCode;
  final String partnerId;
  final String coupleId;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName = '',
    this.photoUrl = '',
    this.inviteCode = '',
    this.partnerId = '',
    this.coupleId = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      inviteCode: map['inviteCode'] ?? '',
      partnerId: map['partnerId'] ?? '',
      coupleId: map['coupleId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'inviteCode': inviteCode,
      'partnerId': partnerId,
      'coupleId': coupleId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    String? partnerId,
    String? coupleId,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      inviteCode: inviteCode,
      partnerId: partnerId ?? this.partnerId,
      coupleId: coupleId ?? this.coupleId,
      createdAt: createdAt,
    );
  }
}
