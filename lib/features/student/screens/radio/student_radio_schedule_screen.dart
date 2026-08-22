import 'package:flutter/material.dart';
import '../../voice/student_voice_home_screen.dart';
import 'student_career_placement_screen.dart';
import 'student_day_end_bulletin_screen.dart';
import 'student_morning_brief_screen.dart';

class StudentRadioScheduleScreen extends StatelessWidget {
  const StudentRadioScheduleScreen({super.key});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Radio Schedule'), backgroundColor: const Color(0xFF312E81), foregroundColor: Colors.white), body: ListView(padding: const EdgeInsets.all(16), children: [const Text('TODAY · THURSDAY', style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w800, fontSize: 11)), const SizedBox(height: 12), _item(context, '8:00 AM', 'Campus Morning Brief', '20 min', Icons.wb_sunny_outlined, () => _open(context, const StudentMorningBriefScreen())), _item(context, '11:00 AM', 'Student Voice', '45 min', Icons.mic_outlined, () => _open(context, const StudentVoiceHomeScreen())), _item(context, '4:00 PM', 'Career & Placement Hour', '60 min', Icons.business_center_outlined, () => _open(context, const StudentCareerPlacementScreen())), _item(context, '6:00 PM', 'Day-End Campus Bulletin', '30 min', Icons.nights_stay_outlined, () => _open(context, const StudentDayEndBulletinScreen()))]);
  void _open(BuildContext context, Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  Widget _item(BuildContext context, String time, String title, String duration, IconData icon, VoidCallback tap) => Card(child: ListTile(onTap: tap, leading: CircleAvatar(child: Icon(icon)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('$time · $duration'), trailing: const Icon(Icons.chevron_right)));
}
