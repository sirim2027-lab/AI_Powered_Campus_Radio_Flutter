import 'package:flutter/material.dart';

class StudentOnboardingScreen extends StatefulWidget {
  const StudentOnboardingScreen({super.key, required this.onComplete});
  final VoidCallback onComplete;
  @override
  State<StudentOnboardingScreen> createState() => _StudentOnboardingScreenState();
}

class _StudentOnboardingScreenState extends State<StudentOnboardingScreen> {
  int _page = 0;
  static const _slides = [
    _Slide('Smart Announcements', 'Never Miss an Important Update', 'All college announcements, events, and notices delivered instantly to your device — organized, searchable, and bookmarkable.', Color(0xFF4F46E5), Icons.campaign_outlined),
    _Slide('AI-Powered Extraction', 'AI Reads Posters So You Don’t Have To', 'Campus posters and PDFs can be transformed into clear event details, dates, venues, and deadlines.', Color(0xFF10B981), Icons.auto_awesome_outlined),
    _Slide('Instant Notifications', 'Real-Time Campus Intelligence', 'Priority alerts for exams, placements, scholarships, and urgent notices when they are posted.', Color(0xFFF59E0B), Icons.notifications_active_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_page];
    return Scaffold(
      backgroundColor: Color.lerp(Colors.white, slide.color, .10)!,
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
        child: Column(children: [
          Row(children: [Row(children: List.generate(_slides.length, (i) => AnimatedContainer(duration: const Duration(milliseconds: 200), margin: const EdgeInsets.only(right: 6), width: i == _page ? 24 : 6, height: 6, decoration: BoxDecoration(color: i == _page ? slide.color : const Color(0xFFD1D5DB), borderRadius: BorderRadius.circular(4))))), const Spacer(), TextButton(onPressed: widget.onComplete, child: const Text('Skip'))]),
          const Spacer(),
          Container(width: 190, height: 190, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: slide.color.withValues(alpha: .18), blurRadius: 32, spreadRadius: 8)]), child: Icon(slide.icon, color: slide.color, size: 82)),
          const Spacer(),
          Align(alignment: Alignment.centerLeft, child: Chip(label: Text(slide.tag), avatar: Icon(slide.icon, color: slide.color, size: 17), side: BorderSide.none, backgroundColor: slide.color.withValues(alpha: .12), labelStyle: TextStyle(color: slide.color, fontWeight: FontWeight.w700, fontSize: 11))),
          const SizedBox(height: 14),
          Text(slide.title, style: const TextStyle(fontSize: 27, height: 1.2, fontWeight: FontWeight.w500), textAlign: TextAlign.left),
          const SizedBox(height: 12),
          Text(slide.description, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14, height: 1.6), textAlign: TextAlign.left),
          const SizedBox(height: 28),
          Row(children: [if (_page > 0) OutlinedButton(onPressed: () => setState(() => _page--), child: const Icon(Icons.arrow_back)), if (_page > 0) const SizedBox(width: 12), Expanded(child: FilledButton(onPressed: _page == _slides.length - 1 ? widget.onComplete : () => setState(() => _page++), style: FilledButton.styleFrom(backgroundColor: slide.color, padding: const EdgeInsets.symmetric(vertical: 15)), child: Text(_page == _slides.length - 1 ? 'Get Started →' : 'Next →')))]),
        ]),
      )),
    );
  }
}

class _Slide {
  const _Slide(this.tag, this.title, this.description, this.color, this.icon);
  final String tag;
  final String title;
  final String description;
  final Color color;
  final IconData icon;
}
