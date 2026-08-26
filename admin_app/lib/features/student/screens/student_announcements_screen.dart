import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../services/firestore_service.dart';
import '../models/student_announcement.dart';
import '../widgets/announcement_card.dart';
import 'student_announcement_detail_screen.dart';

class StudentAnnouncementsScreen extends StatefulWidget { const StudentAnnouncementsScreen({super.key}); @override State<StudentAnnouncementsScreen> createState() => _StudentAnnouncementsScreenState(); }
class _StudentAnnouncementsScreenState extends State<StudentAnnouncementsScreen> {
  static const categories = ['All', 'Academic', 'Placement', 'Hackathon', 'Cultural', 'Sports', 'Scholarship', 'Conference', 'Urgent'];
  var _category = 'All'; var _search = '';
  @override Widget build(BuildContext context) => Column(children: [
    Container(padding: const EdgeInsets.fromLTRB(20, 20, 20, 24), decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF312E81), Color(0xFF4F46E5)])), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Announcements', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w500)), const SizedBox(height: 16), TextField(onChanged: (v) => setState(() => _search = v), style: const TextStyle(color: Colors.white), decoration: const InputDecoration(prefixIcon: Icon(Icons.search, color: Color(0x99FFFFFF)), hintText: 'Search announcements…', hintStyle: TextStyle(color: Color(0x99FFFFFF)), filled: true, fillColor: Color(0x1FFFFFFF), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0x33FFFFFF)))))])),
    SizedBox(height: 52, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), children: categories.map((c) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(c), selected: c == _category, onSelected: (_) => setState(() => _category = c), selectedColor: const Color(0xFF4F46E5), labelStyle: TextStyle(color: c == _category ? Colors.white : const Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w600), side: BorderSide.none))).toList())),
    Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: FirestoreService.instance.collection('announcements'), builder: (_, snapshot) { if (snapshot.hasError) return const Center(child: Text('Announcements are unavailable right now.')); if (!snapshot.hasData) return const Center(child: CircularProgressIndicator()); final items = snapshot.data!.docs.map(StudentAnnouncement.fromDocument).where((a) => (_category == 'All' || (_category == 'Urgent' ? a.priority == 'urgent' : a.category.toLowerCase() == _category.toLowerCase())) && ('${a.title} ${a.summary}'.toLowerCase().contains(_search.toLowerCase()))).toList(); if (items.isEmpty) return const Center(child: Text('No announcements found.')); return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [Text('${items.length} announcements', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)), const SizedBox(height: 10), ...items.map((a) => AnnouncementCard(announcement: a, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StudentAnnouncementDetailScreen(announcement: a)))))]); }))
  ]);
}
