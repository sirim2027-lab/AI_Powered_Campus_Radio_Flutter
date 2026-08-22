import 'package:cloud_firestore/cloud_firestore.dart';

class StudentAnnouncement {
  const StudentAnnouncement({required this.id, required this.title, required this.summary, required this.category, required this.department, required this.timestamp, this.posterUrl, this.attachmentUrl, this.priority = 'normal'});
  final String id, title, summary, category, department, priority;
  final DateTime? timestamp;
  final String? posterUrl, attachmentUrl;

  factory StudentAnnouncement.fromDocument(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return StudentAnnouncement(
      id: doc.id,
      title: '${data['title'] ?? data['subject'] ?? 'Untitled announcement'}',
      summary: '${data['message'] ?? data['description'] ?? ''}',
      category: '${data['category'] ?? 'General'}',
      department: '${data['department'] ?? data['postedBy'] ?? 'Campus Radio'}',
      priority: '${data['priority'] ?? 'normal'}'.toLowerCase(),
      timestamp: (data['createdAt'] as Timestamp?)?.toDate(),
      posterUrl: data['posterUrl'] as String?,
      attachmentUrl: data['attachmentUrl'] as String?,
    );
  }

  String get timeLabel {
    if (timestamp == null) return 'Recently';
    final age = DateTime.now().difference(timestamp!);
    if (age.inMinutes < 60) return '${age.inMinutes.clamp(1, 59)} min ago';
    if (age.inHours < 24) return '${age.inHours} hrs ago';
    if (age.inDays == 1) return 'Yesterday';
    return '${age.inDays} days ago';
  }
}
