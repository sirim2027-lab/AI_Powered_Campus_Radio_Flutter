import 'package:flutter/material.dart';

class StudentRadioArchiveScreen extends StatelessWidget {
  const StudentRadioArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Radio Archive'), backgroundColor: const Color(0xFF312E81), foregroundColor: Colors.white),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.inventory_2_outlined, size: 52, color: Color(0xFF9CA3AF)),
              SizedBox(height: 14),
              Text('Radio archive is unavailable', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              SizedBox(height: 8),
              Text('No archive records or audio sources are configured in the current backend.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF6B7280), height: 1.5)),
            ]),
          ),
        ),
      );
}
