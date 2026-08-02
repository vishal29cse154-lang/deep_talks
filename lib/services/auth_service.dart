import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        '132566369368-og5dnktbcltj78q8i7cjuovab4uhig7t.apps.googleusercontent.com',
  );
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Auth State Stream ──────────────────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ─── Generate 6-char Invite Code ───────────────────────────────
  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  // ─── Create/Update Firestore User Doc ──────────────────────────
  Future<void> _createUserDocument(User user,
      {String? overrideDisplayName}) async {
    final doc = _db.collection('users').doc(user.uid);
    final snapshot = await doc.get();

    if (!snapshot.exists) {
      final inviteCode = _generateInviteCode();
      final userModel = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: overrideDisplayName ?? user.displayName ?? '',
        photoUrl: user.photoURL ?? '',
        inviteCode: inviteCode,
      );
      await doc.set(userModel.toMap());
    } else {
      // Sync potentially new profilePic or name on every sign in!
      await doc.set({
        'displayName': user.displayName ?? '',
        'photoUrl': user.photoURL ?? '',
      }, SetOptions(merge: true));
    }
  }

  // ─── Email/Password Sign Up ────────────────────────────────────
  Future<UserCredential> signUp({
    required String email,
    required String password,
    String displayName = '',
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (displayName.isNotEmpty) {
      await cred.user?.updateDisplayName(displayName);
    }
    if (cred.user != null) {
      await _createUserDocument(cred.user!,
          overrideDisplayName: displayName.isNotEmpty ? displayName : null);
    }
    return cred;
  }

  // ─── Email/Password Sign In ────────────────────────────────────
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ─── Google Sign In ────────────────────────────────────────────
  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign-in aborted');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final cred = await _auth.signInWithCredential(credential);
    if (cred.user != null) {
      await _createUserDocument(cred.user!);
    }
    return cred;
  }

  // ─── Get User Model ────────────────────────────────────────────
  Future<UserModel?> getUserModel(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  // ─── Sign Out ──────────────────────────────────────────────────
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
