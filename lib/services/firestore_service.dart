import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/couple_model.dart';
import '../models/message_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ═══════════════════════════════════════════════════════════════
  //  USERS
  // ═══════════════════════════════════════════════════════════════

  /// Get user document as a stream for real-time updates.
  Stream<UserModel?> userStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      if (snap.exists) return UserModel.fromMap(snap.data()!);
      return null;
    });
  }

  /// Get user document once.
  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) return UserModel.fromMap(doc.data()!);
    return null;
  }

  /// Find a user by their invite code.
  Future<UserModel?> findUserByInviteCode(String code) async {
    final query = await _db
        .collection('users')
        .where('inviteCode', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      return UserModel.fromMap(query.docs.first.data());
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════
  //  PARTNER LINKING
  // ═══════════════════════════════════════════════════════════════

  /// Link two users as a couple.
  Future<String> linkPartner({
    required String currentUserId,
    required String partnerUserId,
  }) async {
    final coupleId = _uuid.v4();
    final couple = CoupleModel(
      coupleId: coupleId,
      user1Id: currentUserId,
      user2Id: partnerUserId,
    );

    final batch = _db.batch();

    // Create couple document
    batch.set(_db.collection('couples').doc(coupleId), couple.toMap());

    // Update both users
    batch.update(_db.collection('users').doc(currentUserId), {
      'partnerId': partnerUserId,
      'coupleId': coupleId,
    });
    batch.update(_db.collection('users').doc(partnerUserId), {
      'partnerId': currentUserId,
      'coupleId': coupleId,
    });

    await batch.commit();
    return coupleId;
  }

  // ═══════════════════════════════════════════════════════════════
  //  COUPLE
  // ═══════════════════════════════════════════════════════════════

  /// Get couple document as a stream.
  Stream<CoupleModel?> coupleStream(String coupleId) {
    return _db.collection('couples').doc(coupleId).snapshots().map((snap) {
      if (snap.exists) return CoupleModel.fromMap(snap.data()!);
      return null;
    });
  }

  /// Update anniversary date for a couple.
  Future<void> updateAnniversaryDate(String coupleId, DateTime date) async {
    await _db.collection('couples').doc(coupleId).update({
      'anniversaryDate': Timestamp.fromDate(date),
    });
  }

  // ═══════════════════════════════════════════════════════════════
  //  MESSAGES
  // ═══════════════════════════════════════════════════════════════

  /// Get messages stream for a couple's chat, ordered by timestamp.
  Stream<List<MessageModel>> messagesStream(String coupleId) {
    return _db
        .collection('chats')
        .doc(coupleId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => MessageModel.fromMap(d.data())).toList(),
        );
  }

  /// Send a message to the couple's chat.
  Future<void> sendMessage(String coupleId, MessageModel message) async {
    await _db
        .collection('chats')
        .doc(coupleId)
        .collection('messages')
        .doc(message.messageId)
        .set(message.toMap());
  }

  /// Mark a view-once message as opened.
  Future<void> markMessageOpened(String coupleId, String messageId) async {
    await _db
        .collection('chats')
        .doc(coupleId)
        .collection('messages')
        .doc(messageId)
        .update({'isOpened': true});
  }

  // ═══════════════════════════════════════════════════════════════
  //  GAME SESSIONS
  // ═══════════════════════════════════════════════════════════════

  /// Get the active game session stream for a couple.
  Stream<Map<String, dynamic>?> gameSessionStream(String coupleId) {
    return _db
        .collection('couples')
        .doc(coupleId)
        .collection('activeGameSession')
        .doc('current')
        .snapshots()
        .map((snap) => snap.data());
  }

  /// Update (or create) the active game session.
  Future<void> updateGameSession(
    String coupleId,
    Map<String, dynamic> data,
  ) async {
    await _db
        .collection('couples')
        .doc(coupleId)
        .collection('activeGameSession')
        .doc('current')
        .set(data, SetOptions(merge: true));
  }
}
