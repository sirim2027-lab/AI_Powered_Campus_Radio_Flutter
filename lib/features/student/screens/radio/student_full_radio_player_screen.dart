import 'package:flutter/material.dart';

class StudentFullRadioPlayerScreen extends StatelessWidget {
  const StudentFullRadioPlayerScreen({super.key, this.title = 'Campus Radio', this.subtitle = 'Campus updates'});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF0F0C29),
        appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const CircleAvatar(radius: 62, backgroundColor: Color(0xFF4F46E5), child: Icon(Icons.radio_outlined, color: Colors.white, size: 58)),
              const SizedBox(height: 24),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Color(0x99FFFFFF))),
              const SizedBox(height: 28),
              const Icon(Icons.play_circle_outline, size: 58, color: Color(0x99FFFFFF)),
              const SizedBox(height: 12),
              const Text('Playback is unavailable', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('This project has no verified Campus Radio stream or audio URL, and no configured playback service.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xAAFFFFFF), height: 1.5)),
            ]),
          ),
        ),
      );
}
