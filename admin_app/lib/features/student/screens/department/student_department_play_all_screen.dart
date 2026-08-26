import 'package:flutter/material.dart';

class StudentDepartmentPlayAllScreen extends StatelessWidget {
  const StudentDepartmentPlayAllScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(backgroundColor: const Color(0xFF0F0C29), foregroundColor: Colors.white, title: const Text('Play All Departments')),
        body: const Center(child: Padding(padding: EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.playlist_remove_outlined, size: 56, color: Color(0xFF9CA3AF)), SizedBox(height: 14), Text('Play all is unavailable', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)), SizedBox(height: 8), Text('There are no verified department audio sources or playlist metadata in the current backend.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF6B7280), height: 1.5))]))),
      );
}
