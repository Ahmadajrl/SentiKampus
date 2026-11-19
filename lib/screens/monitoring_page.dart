import 'package:flutter/material.dart';

import '../services/api_service.dart';

/// Halaman Monitoring — snapshot metrik dari GET /api/v1/metrics.
///
/// Hanya tampil penuh mulai Pertemuan 7 (sesuai kurikulum).
class MonitoringPage extends StatefulWidget {
  const MonitoringPage({super.key, required this.api, required this.week});

  final ApiService api;
  final int week;

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  Map<String, dynamic>? _metrics;
  bool _loading = false;
  String _error = '';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final m = await widget.api.fetchMetrics();
      setState(() => _metrics = m);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _reset() async {
    try {
      await widget.api.resetMetrics();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Metrik berhasil direset.')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = widget.week < 7;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring API'),
        actions: [
          if (!locked)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _load,
              tooltip: 'Muat Metrik',
            ),
        ],
      ),
      body: locked
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 48, color: Colors.black38),
                    SizedBox(height: 12),
                    Text(
                      'Monitoring dibuka mulai Pertemuan 7.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                    Text(
                      'Bangun alur prediksi terlebih dahulu.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            )
          : _MetricsBody(
              metrics: _metrics,
              loading: _loading,
              error: _error,
              onLoad: _load,
              onReset: _reset,
            ),
    );
  }
}

class _MetricsBody extends StatelessWidget {
  const _MetricsBody({
    required this.metrics,
    required this.loading,
    required this.error,
    required this.onLoad,
    required this.onReset,
  });

  final Map<String, dynamic>? metrics;
  final bool loading;
  final String error;
  final VoidCallback onLoad;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 12),
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                onPressed: onLoad,
              ),
            ],
          ),
        ),
      );
    }

    if (metrics == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bar_chart, size: 48, color: Colors.black38),
            const SizedBox(height: 12),
            const Text('Tekan tombol untuk memuat metrik.'),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Muat Metrik'),
              onPressed: onLoad,
            ),
          ],
        ),
      );
    }

    final m = metrics!;
    final latency = m['latency_ms'] as Map<String, dynamic>? ?? {};
    final dist = m['label_distribution'] as Map<String, dynamic>? ?? {};
    final totalPreds = dist.values
        .fold<num>(0, (sum, v) => sum + (v as num));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Ringkasan
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'Total Request',
                value: '${m['total_requests'] ?? 0}',
              ),
            ),
            Expanded(
              child: _MetricTile(
                label: 'Error Rate',
                value: '${((m['error_rate'] as num? ?? 0) * 100).toStringAsFixed(1)}%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'P50 Latency',
                value: '${(latency['p50'] as num? ?? 0).toStringAsFixed(1)} ms',
              ),
            ),
            Expanded(
              child: _MetricTile(
                label: 'P95 Latency',
                value: '${(latency['p95'] as num? ?? 0).toStringAsFixed(1)} ms',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Distribusi label
        if (dist.isNotEmpty) ...[
          const Text(
            'Distribusi Label',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 8),
          ...dist.entries.map((e) {
            final count = (e.value as num).toInt();
            final ratio = totalPreds > 0 ? count / totalPreds : 0.0;
            final color = switch (e.key) {
              'positif' => const Color(0xFF2E7D32),
              'negatif' => const Color(0xFFC62828),
              'netral'  => const Color(0xFFE65100),
              _          => Colors.grey,
            };
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: Text(e.key, style: const TextStyle(fontSize: 13)),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        backgroundColor: color.withAlpha(26),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$count',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
        ],

        // Reset
        OutlinedButton.icon(
          icon: const Icon(Icons.delete_sweep),
          label: const Text('Reset Metrik'),
          onPressed: onReset,
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
