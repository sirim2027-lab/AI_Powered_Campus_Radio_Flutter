import 'package:flutter/material.dart';
import 'student_full_radio_player_screen.dart';

class StudentMorningBriefScreen extends StatelessWidget {
  const StudentMorningBriefScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(backgroundColor: const Color(0xFF0F0C29), foregroundColor: Colors.white, title: const Text('Campus Morning Brief')),
        body: Center(child: FilledButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentFullRadioPlayerScreen(title: 'Campus Morning Brief', subtitle: 'Campus updates'))), icon: const Icon(Icons.radio_outlined), label: const Text('View audio availability'))),
      );
}
