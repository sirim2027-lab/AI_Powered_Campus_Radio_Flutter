import 'package:flutter/material.dart';

class StudentAudioScreen extends StatelessWidget {
  const StudentAudioScreen({
    super.key,
    required this.title,
    required this.department,
  });

  final String title;
  final String department;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Audio Announcement'),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(
                    Icons.headphones_outlined,
                    color: Colors.white,
                    size: 70,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  department,
                  style: const TextStyle(color: Color(0x99FFFFFF)),
                ),
                const SizedBox(height: 28),
                const Icon(
                  Icons.play_circle_outline,
                  color: Color(0x99FFFFFF),
                  size: 56,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Audio is unavailable',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'No configured audio URL, playback package, or audio service exists for this announcement.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xAAFFFFFF),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}