import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

class UserRoleService {
  UserRoleService._();

  static final instance = UserRoleService._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<AppUser> signInAndLoadProfile({
    required String email,
    required String password,
  }) async {
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;
    try {
      final profile = await _firestore.collection('users').doc(uid).get();
      if (!profile.exists || profile.data() == null) {
        await FirebaseAuth.instance.signOut();
        throw const MissingProfileException();
      }
      final user = AppUser.fromFirestore(uid, profile.data()!);
      if (user.role == UserRole.unknown) {
        await FirebaseAuth.instance.signOut();
        throw const MissingRoleException();
      }
      return user;
    } on FirebaseException {
      await FirebaseAuth.instance.signOut();
      rethrow;
    }
  }

  Future<AppUser> loadProfileForUid(String uid) async {
    final profile = await _firestore.collection('users').doc(uid).get();
    if (!profile.exists || profile.data() == null) {
      throw const MissingProfileException();
    }
    final user = AppUser.fromFirestore(uid, profile.data()!);
    if (user.role == UserRole.unknown) {
      throw const MissingRoleException();
    }
    return user;
  }
}

class MissingProfileException implements Exception {
  const MissingProfileException();
}

class MissingRoleException implements Exception {
  const MissingRoleException();
}
