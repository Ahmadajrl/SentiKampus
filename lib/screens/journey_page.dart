import 'package:flutter/material.dart';

import '../data/demo_weeks.dart';
import '../models/demo_week.dart';

/// Halaman Journey — daftar 16 pertemuan dengan info lengkap.
///
/// Mahasiswa dapat menekan satu pertemuan untuk melihat:
///   - Fokus pembelajaran
///   - Langkah demo
///   - Bukti ketercapaian
///   - Kapabilitas yang diaktifkan
class JourneyPage extends StatelessWidget {
  const JourneyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perjalanan 16 Pertemuan'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: demoWeeks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final week = demoWeeks[index];
          return _WeekCard(week: week);
        },
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.week});

  final DemoWeek week;

  static Color _levelColor(String level) {
    if (level.contains('Dasar')) return const Color(0xFF1565C0);
    if (level.contains('Lanjut')) return const Color(0xFF6A1B9A);
    if (level.contains('Evaluasi')) return const Color(0xFFE65100);
    return const Color(0xFF2E7D32);
  }

  @override
  Widget build(BuildContext context) {
    final color = _levelColor(week.level);
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(26),
          child: Text(
            'P${week.week}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          week.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          week.level,
          style: TextStyle(fontSize: 12, color: color),
        ),
        shape: const RoundedRectangleBorder(),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel('Fokus'),
                Text(week.focus, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                _SectionLabel('Demo'),
                Text(week.demoAction, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                _SectionLabel('Bukti'),
                Text(week.evidence, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                _SectionLabel('Kapabilitas'),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: week.capabilities
                      .map(
                        (c) => Chip(
                          label: Text(c, style: const TextStyle(fontSize: 11)),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.black45,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
