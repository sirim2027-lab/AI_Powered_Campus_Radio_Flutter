import 'package:flutter/material.dart';

import '../models/student_query.dart';

class QueryCard extends StatelessWidget {
  const QueryCard({
    super.key,
    required this.query,
    this.onTap,
  });

  final StudentQuery query;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (query.statusColor) {
      ColorStatus.green => const Color(0xFF10B981),
      ColorStatus.blue => const Color(0xFF3B82F6),
      ColorStatus.grey => const Color(0xFF6B7280),
      _ => const Color(0xFFF59E0B),
    };

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0x11000000)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Chip(
                    label: Text('Query'),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Color(0xFFEEF2FF),
                    labelStyle: TextStyle(
                      color: Color(0xFF4F46E5),
                      fontSize: 10,
                    ),
                  ),
                  const Spacer(),
                  Chip(
                    label: Text(query.statusLabel),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: color.withValues(alpha: 0.12),
                    labelStyle: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Text(
                query.subject,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                query.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'ID: ${query.id}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    query.createdAt == null
                        ? 'Recently'
                        : '${query.createdAt!.day}/${query.createdAt!.month}/${query.createdAt!.year}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}