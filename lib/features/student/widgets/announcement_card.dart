import 'package:flutter/material.dart';
import '../models/student_announcement.dart';

class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({super.key, required this.announcement, required this.onTap});
  final StudentAnnouncement announcement;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    elevation: 0, margin: const EdgeInsets.only(bottom: 14), clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0x11000000))),
    child: InkWell(onTap: onTap, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(height: 100, width: double.infinity, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF4338CA)])), child: Stack(children: [
        Center(child: announcement.posterUrl == null ? const Icon(Icons.campaign_outlined, size: 38, color: Colors.white) : Image.network(announcement.posterUrl!, fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, _, _) => const Icon(Icons.campaign_outlined, size: 38, color: Colors.white))),
        if (announcement.priority == 'urgent') const Positioned(top: 8, left: 8, child: Chip(label: Text('URGENT', style: TextStyle(color: Color(0xFFFBBF24), fontSize: 10, fontWeight: FontWeight.w800)), backgroundColor: Color(0x334F46E5), side: BorderSide.none, visualDensity: VisualDensity.compact)),
      ])),
      Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Chip(label: Text(announcement.category), visualDensity: VisualDensity.compact, backgroundColor: const Color(0xFFEEF2FF), labelStyle: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w700, fontSize: 10), side: BorderSide.none),
        Text(announcement.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)), const SizedBox(height: 6),
        Text(announcement.summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12, height: 1.4)), const SizedBox(height: 10),
        Row(children: [Expanded(child: Text('${announcement.department} · ${announcement.timeLabel}', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11))), const Text('Read more →', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w700, fontSize: 12))]),
      ])),
    ])),
  );
}
