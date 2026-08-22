import 'package:flutter/material.dart';
import '../models/student_announcement.dart';
import 'student_pdf_viewer_screen.dart';

class StudentAnnouncementDetailScreen extends StatelessWidget {
  const StudentAnnouncementDetailScreen({super.key, required this.announcement}); final StudentAnnouncement announcement;
  @override Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFFF6F7FB), body: CustomScrollView(slivers: [
    SliverAppBar(expandedHeight: 200, pinned: true, backgroundColor: const Color(0xFF312E81), flexibleSpace: FlexibleSpaceBar(background: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF4F46E5)])), child: Center(child: announcement.posterUrl == null ? const Icon(Icons.campaign_outlined, color: Colors.white, size: 62) : Image.network(announcement.posterUrl!, fit: BoxFit.cover, width: double.infinity)))), actions: const [Icon(Icons.bookmark_border), SizedBox(width: 8), Icon(Icons.share), SizedBox(width: 12)]),
    SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Chip(label: Text(announcement.category), backgroundColor: const Color(0xFFEEF2FF), labelStyle: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w700), side: BorderSide.none), const SizedBox(height: 8), Text(announcement.title, style: const TextStyle(fontSize: 25, height: 1.2, fontWeight: FontWeight.w500)), const SizedBox(height: 18),
      _card('Announcement details', [ _row('Department', announcement.department), _row('Posted', announcement.timeLabel), _row('Priority', announcement.priority.toUpperCase()) ]), const SizedBox(height: 16),
      _card('Description', [Text(announcement.summary.isEmpty ? 'No additional description was provided.' : announcement.summary, style: const TextStyle(color: Color(0xFF6B7280), height: 1.65))]),
      if (announcement.attachmentUrl != null && _isPdf(announcement.attachmentUrl!)) Padding(padding: const EdgeInsets.only(top: 16), child: FilledButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StudentPdfViewerScreen(title: announcement.title, url: announcement.attachmentUrl!))), icon: const Icon(Icons.picture_as_pdf_outlined), label: const Text('View PDF attachment'))),
      if (announcement.attachmentUrl != null && !_isPdf(announcement.attachmentUrl!)) const Padding(padding: EdgeInsets.only(top: 16), child: Text('An attachment is available, but its file type is not confirmed as PDF.', style: TextStyle(color: Color(0xFF6B7280), fontSize: 12))),
    ])))
  ]);
  Widget _card(String title, List<Widget> children) => Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0x11000000))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 12), ...children]));
  Widget _row(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [Text(label, style: const TextStyle(color: Color(0xFF6B7280))), const Spacer(), Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w700)))]));
  bool _isPdf(String url) => Uri.tryParse(url)?.path.toLowerCase().endsWith('.pdf') ?? false;
}
