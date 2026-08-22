import 'package:flutter/material.dart';

class StudentDepartmentAutoModeScreen extends StatelessWidget {
  const StudentDepartmentAutoModeScreen({super.key});

  @override
  Widget build(BuildContext context) => const _DepartmentAudioUnavailablePage(title: 'Department Auto Mode');
}

class _DepartmentAudioUnavailablePage extends StatelessWidget {
  const _DepartmentAudioUnavailablePage({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(backgroundColor: const Color(0xFF0F0C29), foregroundColor: Colors.white, title: Text(title)),
        body: const Center(child: Padding(padding: EdgeInsets.all(28), child: Text('Auto mode needs verified department audio and playback support. It is unavailable until those backend decisions are configured.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF6B7280), height: 1.5)))),
      );
}
