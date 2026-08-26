import 'package:flutter/material.dart';

class StudentDepartmentAudioScreen extends StatelessWidget {
  const StudentDepartmentAudioScreen({super.key, required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(backgroundColor: const Color(0xFF0EA5E9), foregroundColor: Colors.white, title: Text(name)),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.graphic_eq_outlined, size: 64, color: Color(0xFF0284C7)),
              SizedBox(height: 18),
              Text('Department audio is unavailable', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              SizedBox(height: 8),
              Text('No verified department audio source, playback service, or audio metadata is configured.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF6B7280), height: 1.5)),
            ]),
          ),
        ),
      );
}
