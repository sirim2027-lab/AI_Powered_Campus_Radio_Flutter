import 'package:flutter/material.dart';
import '../models/student_query.dart';

class StudentQueryDetailScreen extends StatelessWidget {
  const StudentQueryDetailScreen({super.key, required this.query});
  final StudentQuery query;

  @override
  Widget build(BuildContext context) {
    final color = query.statusColor == ColorStatus.green ? const Color(0xFF10B981) : query.statusColor == ColorStatus.blue ? const Color(0xFF3B82F6) : const Color(0xFFF59E0B);
    return Scaffold(backgroundColor: const Color(0xFFF6F7FB), appBar: AppBar(backgroundColor: const Color(0xFF312E81), foregroundColor: Colors.white), body: ListView(padding: const EdgeInsets.all(16), children: [
      Text('ID: ${query.id}', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)), const SizedBox(height: 8), Text(query.subject, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)), const SizedBox(height: 12), Chip(label: Text(query.statusLabel), backgroundColor: color.withValues(alpha: .12), labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700), side: BorderSide.none), const SizedBox(height: 12),
      _card('Query Information', [_row('Submitted', query.createdAt == null ? 'Recently' : '${query.createdAt!.day}/${query.createdAt!.month}/${query.createdAt!.year}'), _row('Status', query.statusLabel), _row('Category', 'Not specified')]), const SizedBox(height: 16),
      _card('My Query', [Text(query.message.isEmpty ? 'No description was provided.' : query.message, style: const TextStyle(color: Color(0xFF6B7280), height: 1.65))]), const SizedBox(height: 16),
      _card('Status Timeline', [_step('Query submitted', 'Your query was received', color, true), _step('Under review', query.statusLabel, color, query.status.toLowerCase() != 'open'), _step('Response sent', 'Pending department response', const Color(0xFF9CA3AF), false)]),
    ]));
  }

  Widget _card(String title, List<Widget> children) => Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x11000000))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 12), ...children]));
  Widget _row(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [Text(label, style: const TextStyle(color: Color(0xFF6B7280))), const Spacer(), Text(value, style: const TextStyle(fontWeight: FontWeight.w700))]));
  Widget _step(String title, String detail, Color color, bool active) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(children: [CircleAvatar(radius: 14, backgroundColor: color.withValues(alpha: active ? .15 : .07), child: Icon(active ? Icons.check : Icons.more_horiz, size: 15, color: color)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), Text(detail, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))]))]));
}
