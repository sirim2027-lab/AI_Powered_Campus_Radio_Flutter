import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService._();

  static final instance = FirestoreService._();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> collection(String name) =>
      _db.collection(name).snapshots();

  Stream<int> count(String name) => collection(name).map((snapshot) => snapshot.size);

  Stream<QuerySnapshot<Map<String, dynamic>>> studentQueriesFor(String uid) =>
      _db.collection('student_queries').where('studentUid', isEqualTo: uid).snapshots();

  Future<void> createStudentQuery({
    required String subject,
    required String message,
    required String uid,
  }) => _db.collection('student_queries').add({
        'subject': subject,
        'message': message,
        'studentUid': uid,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> createDocument(
    String collection,
    Map<String, dynamic> data,
  ) => _db.collection(collection).add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> updateDocument(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) => _db.collection(collection).doc(id).update(data);

  Future<void> deleteDocument(String collection, String id) =>
      _db.collection(collection).doc(id).delete();
}
