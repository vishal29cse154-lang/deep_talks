import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final String inviteCode;
  final String partnerId;
  final String coupleId;
  final String fcmToken;
  final String? mood;
  final bool isOnline;
  final DateTime lastSeen;
  final DateTime createdAt;

  String get safeDisplayName =>
      displayName.isNotEmpty ? displayName : 'Partner';

  UserModel({
    required this.uid,
    required this.email,
    this.displayName = '',
    this.photoUrl = '',
    this.inviteCode = '',
    this.partnerId = '',
    this.coupleId = '',
    this.fcmToken = '',
    this.mood,
    this.isOnline = true,
    DateTime? lastSeen,
    DateTime? createdAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastSeen = lastSeen ?? DateTime.now();

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      inviteCode: map['inviteCode'] ?? '',
      partnerId: map['partnerId'] ?? '',
      coupleId: map['coupleId'] ?? '',
      fcmToken: map['fcmToken'] ?? '',
      mood: map['mood'],
      isOnline: map['isOnline'] ?? true,
      lastSeen: map['lastSeen'] != null
          ? (map['lastSeen'] as Timestamp).toDate()
          : DateTime.now(),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
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
      'fcmToken': fcmToken,
      'mood': mood,
      'isOnline': isOnline,
      'lastSeen': Timestamp.fromDate(lastSeen),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    String? partnerId,
    String? coupleId,
    String? fcmToken,
    String? mood,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      inviteCode: inviteCode,
      partnerId: partnerId ?? this.partnerId,
      coupleId: coupleId ?? this.coupleId,
      fcmToken: fcmToken ?? this.fcmToken,
      mood: mood ?? this.mood,
      createdAt: createdAt,
    );
  }
}
