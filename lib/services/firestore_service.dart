import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/couple_model.dart';
import '../models/message_model.dart';
import '../models/memory_model.dart';
import '../models/story_model.dart';
import '../services/push_notification_sender.dart';

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
  //  PROFILE
  // ═══════════════════════════════════════════════════════════════

  /// Update user's profile picture
  Future<void> updateProfilePicture(String uid, String photoUrl) async {
    await _db.collection('users').doc(uid).update({'photoUrl': photoUrl});
  }

  /// Update user's mood
  Future<void> updateUserMood(String uid, String mood) async {
    await _db.collection('users').doc(uid).update({'mood': mood});
  }

  /// Update user's mood note
  Future<void> updateUserMoodNote(String uid, String moodNote) async {
    await _db.collection('users').doc(uid).update({'moodNote': moodNote});
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

  /// Update global presence status
  Future<void> updatePresence(String uid, bool isOnline) async {
    await _db.collection('users').doc(uid).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  /// Update a user's display name
  Future<void> updateUserDisplayName(String uid, String newName) async {
    await _db.collection('users').doc(uid).update({'displayName': newName});
    // Also try updating the underlying Firebase Auth profile for good measure
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser != null && authUser.uid == uid) {
      await authUser.updateDisplayName(newName);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  LOVE PULSE
  // ═══════════════════════════════════════════════════════════════

  /// Send a Love Pulse to a partner
  Future<void> sendLovePulse(String partnerId, String currentUserId) async {
    await _db.collection('users').doc(partnerId).collection('pulses').add({
      'senderId': currentUserId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Also keep updating lastPulseAt just in case any UI relies on it
    await _db.collection('users').doc(partnerId).update({
      'lastPulseAt': FieldValue.serverTimestamp(),
    });

    // Send Client-Side Push Notification
    final partnerDoc = await getUser(partnerId);
    final partnerToken = partnerDoc?.fcmToken;
    if (partnerToken != null && partnerToken.isNotEmpty) {
      PushNotificationSender.sendPush(
        fcmToken: partnerToken,
        title: '❤️ Love Pulse',
        body: 'Your partner sent you a Love Pulse!',
        type: 'love_pulse',
      );
    }
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
        .orderBy('timestamp', descending: true)
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

    // Send Client-Side Push Notification
    try {
      final coupleDoc = await _db.collection('couples').doc(coupleId).get();
      if (!coupleDoc.exists) return;
      final coupleObj = CoupleModel.fromMap(coupleDoc.data()!);
      final partnerId = coupleObj.user1Id == message.senderId
          ? coupleObj.user2Id
          : coupleObj.user1Id;

      final partnerDoc = await getUser(partnerId);
      final partnerToken = partnerDoc?.fcmToken;

      if (partnerToken != null && partnerToken.isNotEmpty) {
        final senderDoc = await getUser(message.senderId);
        String title = 'Your Partner';
        if (senderDoc != null && senderDoc.displayName.isNotEmpty) {
          title = senderDoc.displayName;
        }

        String body = message.text;
        if (message.mediaUrl.isNotEmpty) body = '📷 Sent an attachment';
        if (message.isViewOnce) body = '🤫 Sent a view-once message';

        PushNotificationSender.sendPush(
          fcmToken: partnerToken,
          title: title,
          body: body,
          type: 'chat_message',
          coupleId: coupleId,
        );
      }
    } catch (e) {
      print('Failed to send push: $e');
    }
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

  /// Delete a single message for everyone
  Future<void> deleteMessageForEveryone(
      String coupleId, String messageId) async {
    await _db
        .collection('chats')
        .doc(coupleId)
        .collection('messages')
        .doc(messageId)
        .update({'isDeleted': true});
  }

  /// Mark message as deleted by me
  Future<void> deleteMessageForMe(
      String coupleId, String messageId, String uid) async {
    await _db
        .collection('chats')
        .doc(coupleId)
        .collection('messages')
        .doc(messageId)
        .update({
      'deletedBy': FieldValue.arrayUnion([uid])
    });
  }

  /// Mark all received messages as seen
  Future<void> markMessagesAsSeen(String coupleId, String myUid) async {
    final batch = _db.batch();
    final msgs = await _db
        .collection('chats')
        .doc(coupleId)
        .collection('messages')
        .where('senderId', isNotEqualTo: myUid)
        .get();

    for (var doc in msgs.docs) {
      if (doc.data()['status'] != 'seen') {
        batch.update(doc.reference, {'status': 'seen'});
      }
    }
    await batch.commit();
  }

  /// Clear chat history for user
  Future<void> clearChat(String coupleId, String myUid) async {
    final batch = _db.batch();
    final msgs = await _db
        .collection('chats')
        .doc(coupleId)
        .collection('messages')
        .get();

    // Note: To avoid huge batches hitting limit (500), ideally partition.
    // Simplifying for this scope.
    for (var doc in msgs.docs) {
      batch.update(doc.reference, {
        'deletedBy': FieldValue.arrayUnion([myUid])
      });
    }
    if (msgs.docs.isNotEmpty) {
      await batch.commit();
    }
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

  // ═══════════════════════════════════════════════════════════════
  //  MEMORIES
  // ═══════════════════════════════════════════════════════════════

  /// Stream of memories for a couple.
  Stream<List<MemoryModel>> memoriesStream(String coupleId) {
    return _db
        .collection('couples')
        .doc(coupleId)
        .collection('memories')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => MemoryModel.fromMap(doc.data())).toList());
  }

  /// Add a new memory.
  Future<void> addMemory(String coupleId, MemoryModel memory) async {
    await _db
        .collection('couples')
        .doc(coupleId)
        .collection('memories')
        .doc(memory.id)
        .set(memory.toMap());
  }

  // ═══════════════════════════════════════════════════════════════
  //  INTIMATE STORIES
  // ═══════════════════════════════════════════════════════════════

  Stream<List<StoryModel>> intimateStoriesStream(String coupleId) {
    return _db
        .collection('couples')
        .doc(coupleId)
        .collection('intimate_stories')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => StoryModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> addIntimateStory(String coupleId, StoryModel story) async {
    await _db
        .collection('couples')
        .doc(coupleId)
        .collection('intimate_stories')
        .doc(story.id)
        .set(story.toMap());

    try {
      final coupleDoc = await _db.collection('couples').doc(coupleId).get();
      if (!coupleDoc.exists) return;
      final coupleObj = CoupleModel.fromMap(coupleDoc.data()!);
      final partnerId = coupleObj.user1Id == story.uploaderId
          ? coupleObj.user2Id
          : coupleObj.user1Id;

      final partnerDoc = await getUser(partnerId);
      final partnerToken = partnerDoc?.fcmToken;

      if (partnerToken != null && partnerToken.isNotEmpty) {
        final senderDoc = await getUser(story.uploaderId);
        String senderName = 'Your partner';
        if (senderDoc != null && senderDoc.displayName.isNotEmpty) {
          senderName = senderDoc.displayName;
        }

        PushNotificationSender.sendPush(
          fcmToken: partnerToken,
          title: '🔥 New Intimate Story',
          body: '$senderName added a new story for you!',
          type: 'intimate_story',
          coupleId: coupleId,
        );
      }
    } catch (e) {
      print('Failed to send push for story: $e');
    }
  }

  Future<void> toggleStoryReaction(
      String coupleId, String storyId, String uid, bool isLiked) async {
    final ref = _db
        .collection('couples')
        .doc(coupleId)
        .collection('intimate_stories')
        .doc(storyId);

    if (isLiked) {
      await ref.update({
        'likedBy': FieldValue.arrayUnion([uid])
      });
    } else {
      await ref.update({
        'likedBy': FieldValue.arrayRemove([uid])
      });
    }
  }
}
