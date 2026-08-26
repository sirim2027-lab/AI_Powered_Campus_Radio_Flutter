import 'package:cloud_firestore/cloud_firestore.dart';
class StudentQuery { const StudentQuery({required this.id, required this.subject, required this.message, required this.status, this.createdAt}); final String id, subject, message, status; final DateTime? createdAt;
  factory StudentQuery.fromDocument(QueryDocumentSnapshot<Map<String, dynamic>> doc) { final d = doc.data(); return StudentQuery(id: doc.id, subject: '${d['subject'] ?? 'Untitled query'}', message: '${d['message'] ?? ''}', status: '${d['status'] ?? 'open'}', createdAt: (d['createdAt'] as Timestamp?)?.toDate()); }
  String get statusLabel => switch (status.toLowerCase()) { 'open' || 'pending' => 'Pending', 'in-progress' || 'in_progress' => 'In Progress', 'resolved' => 'Resolved', 'closed' => 'Closed', _ => status };
  ColorStatus get statusColor => switch (status.toLowerCase()) { 'resolved' => ColorStatus.green, 'closed' => ColorStatus.grey, 'in-progress' || 'in_progress' => ColorStatus.blue, _ => ColorStatus.orange };
}
enum ColorStatus { orange, blue, green, grey }
