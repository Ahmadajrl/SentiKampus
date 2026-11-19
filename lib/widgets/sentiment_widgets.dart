import 'package:flutter/material.dart';

import '../models/prediction_result.dart';

/// Badge warna yang menampilkan label sentimen.
class SentimentBadge extends StatelessWidget {
  const SentimentBadge({super.key, required this.label});

  final String label;

  static Color _colorFor(String label) {
    return switch (label) {
      'positif' => const Color(0xFF2E7D32),
      'negatif' => const Color(0xFFC62828),
      'netral'  => const Color(0xFFE65100),
      _          => Colors.grey,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

/// Bar tunggal untuk menampilkan probabilitas satu kelas.
class ProbabilityBar extends StatelessWidget {
  const ProbabilityBar({
    super.key,
    required this.label,
    required this.probability,
  });

  final String label;
  final double probability;

  static Color _colorFor(String label) {
    return switch (label) {
      'positif' => const Color(0xFF2E7D32),
      'negatif' => const Color(0xFFC62828),
      'netral'  => const Color(0xFFE65100),
      _          => Colors.grey,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(label);
    final pct = '${(probability * 100).toStringAsFixed(1)}%';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 68,
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: probability,
                backgroundColor: color.withAlpha(26),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 46,
            child: Text(
              pct,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

/// Kartu XAI — daftar fitur yang paling memengaruhi prediksi.
class XaiCard extends StatelessWidget {
  const XaiCard({super.key, required this.items});

  final List<ExplanationItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final maxAbs = items
        .map((e) => e.contribution.abs())
        .fold(0.0, (a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mengapa hasil ini? (XAI)',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 4),
            const Text(
              'Kata atau frasa yang paling memengaruhi kelas terpilih '
              '(penjelasan model linear, bukan makna psikologis).',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            ...items.map((item) {
              final norm = maxAbs > 0 ? item.contribution.abs() / maxAbs : 0.0;
              final isPositive = item.contribution >= 0;
              final color = isPositive
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFC62828);
              final sign = isPositive ? '+' : '−';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        item.term,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: norm,
                          backgroundColor: color.withAlpha(26),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$sign${item.contribution.abs().toStringAsFixed(4)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

/// Banner kecil yang menampilkan pertemuan saat ini beserta judul dan levelnya.
class WeekBanner extends StatelessWidget {
  const WeekBanner({
    super.key,
    required this.week,
    required this.title,
    required this.level,
  });

  final int week;
  final String title;
  final String level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.primary.withAlpha(60),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              'P$week',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  level,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
