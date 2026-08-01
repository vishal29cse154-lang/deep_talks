import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  /// Upload a file to chat media and return the download URL.
  Future<String> uploadChatMedia({
    required String coupleId,
    required File file,
    required String extension,
  }) async {
    final fileName = '${_uuid.v4()}.$extension';
    final ref = _storage.ref('chat_media/$coupleId/$fileName');

    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }

  /// Upload a profile photo and return the download URL.
  Future<String> uploadProfilePhoto({
    required String userId,
    required File file,
  }) async {
    final ref = _storage.ref('profile_photos/$userId/avatar.jpg');
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }
}
