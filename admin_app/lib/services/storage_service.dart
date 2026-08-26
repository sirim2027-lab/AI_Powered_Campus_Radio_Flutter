import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService._();
  static final instance = StorageService._();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadAnnouncementAttachment({
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) async {
    final safeName = filename.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final objectName = '${DateTime.now().microsecondsSinceEpoch}_$safeName';
    final reference = _storage.ref('announcements/$objectName');
    await reference.putData(bytes, SettableMetadata(contentType: contentType));
    return reference.getDownloadURL();
  }
}
