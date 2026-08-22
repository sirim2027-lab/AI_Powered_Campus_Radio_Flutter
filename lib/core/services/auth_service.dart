import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/app_user.dart';

/// The single entry point for Firebase Authentication and Firestore profiles.
///
/// A valid application session always has both a Firebase user and a valid
/// `users/{uid}` document with a supported role.
class AuthService {
  AuthService._();

  static final instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentFirebaseUser => _auth.currentUser;

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw StateError('Firebase did not return an authenticated user.');
    }

    try {
      return await loadProfileForUid(user.uid);
    } catch (_) {
      await signOut();
      rethrow;
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<AppUser?> loadCurrentProfile() async {
    final user = currentFirebaseUser;
    if (user == null) return null;
    return loadProfileForUid(user.uid);
  }

  Future<AppUser> loadProfileForUid(String uid) async {
    final snapshot = await _firestore.collection('users').doc(uid).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      throw const MissingProfileException();
    }

    final profile = AppUser.fromFirestore(uid, data);
    if (profile.role == UserRole.unknown) {
      throw const MissingRoleException();
    }
    return profile;
  }
}

class MissingProfileException implements Exception {
  const MissingProfileException();
}

class MissingRoleException implements Exception {
  const MissingRoleException();
}
