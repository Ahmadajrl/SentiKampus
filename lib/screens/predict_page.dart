import 'package:flutter/material.dart';

import '../controllers/predict_controller.dart';
import '../data/demo_weeks.dart';
import '../models/prediction_result.dart';
import '../widgets/sentiment_widgets.dart';

/// Halaman utama: form prediksi sentimen.
///
/// Mahasiswa melihat di sini bagaimana:
///   1. Input teks dikirim ke FastAPI (sama kontraknya dengan Streamlit Web).
///   2. Response JSON diurai menjadi widget — label, probabilitas, XAI.
///   3. State dikelola dengan ChangeNotifier tanpa library tambahan.
class PredictPage extends StatefulWidget {
  const PredictPage({super.key, required this.controller});

  final PredictController controller;

  @override
  State<PredictPage> createState() => _PredictPageState();
}

class _PredictPageState extends State<PredictPage> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController(
    text: 'Pelayanan akademik sangat membantu',
  );
  int _selectedWeek = 4;
  bool _includeXai = false;

  static const _examples = [
    ('Positif', 'Pelayanan akademik sangat membantu'),
    ('Negatif', 'Internet kampus sering terputus'),
    ('Netral', 'Kuliah dimulai pukul delapan'),
  ];

  PredictController get _ctrl => widget.controller;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onControllerChanged);
    // Periksa status API saat halaman pertama kali tampil.
    _ctrl.checkHealth();
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onControllerChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await _ctrl.predict(
      text: _textController.text,
      week: _selectedWeek,
      includeExplanation: _includeXai,
    );
  }

  @override
  Widget build(BuildContext context) {
    final week = demoWeeks.firstWhere(
      (w) => w.week == _selectedWeek,
      orElse: () => demoWeeks.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎓 SentiKampus'),
        centerTitle: false,
        actions: [
          // Indikator status API
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(
              _ctrl.isApiOnline ? Icons.cloud_done : Icons.cloud_off,
              color: _ctrl.isApiOnline ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Status API ---
            _ApiStatusBanner(
              isOnline: _ctrl.isApiOnline,
              version: _ctrl.apiVersion,
            ),
            const SizedBox(height: 12),

            // --- Banner pertemuan ---
            WeekBanner(
              week: week.week,
              title: week.title,
              level: week.level,
            ),
            const SizedBox(height: 16),

            // --- Form input ---
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Contoh cepat
                  const Text(
                    'Contoh cepat:',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: _examples.map((e) {
                      return ActionChip(
                        label: Text(e.$1),
                        onPressed: () {
                          _textController.text = e.$2;
                          _ctrl.reset();
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Input teks
                  TextFormField(
                    controller: _textController,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      labelText: 'Masukan mahasiswa',
                      hintText: 'Contoh: Dosen menjelaskan materi dengan sangat jelas',
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length < 3) {
                        return 'Teks minimal tiga karakter bermakna.';
                      }
                      return null;
                    },
                    onChanged: (_) => _ctrl.reset(),
                  ),
                  const SizedBox(height: 12),

                  // Pilih pertemuan
                  DropdownButtonFormField<int>(
                    value: _selectedWeek,
                    decoration: const InputDecoration(
                      labelText: 'Pertemuan',
                      helperText: 'XAI aktif otomatis mulai P7',
                    ),
                    items: List.generate(
                      16,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text('P${i + 1}'),
                      ),
                    ),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedWeek = val;
                          _includeXai = val >= 7;
                        });
                        _ctrl.reset();
                      }
                    },
                  ),
                  const SizedBox(height: 8),

                  // Checkbox XAI
                  CheckboxListTile(
                    title: const Text('Tampilkan penjelasan XAI'),
                    subtitle: const Text(
                      'Kata yang paling memengaruhi prediksi',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _includeXai || _selectedWeek >= 7,
                    onChanged: _selectedWeek >= 7
                        ? null // aktif otomatis, tidak bisa dimatikan
                        : (val) => setState(() => _includeXai = val ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),

                  // Tombol Analisis
                  FilledButton.icon(
                    icon: _ctrl.state == PredictState.loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.psychology_alt),
                    label: const Text('Analisis Sentimen'),
                    onPressed: _ctrl.state == PredictState.loading || !_ctrl.isApiOnline
                        ? null
                        : _submit,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- Hasil ---
            if (_ctrl.state == PredictState.error)
              _ErrorCard(message: _ctrl.errorMessage),

            if (_ctrl.state == PredictState.success && _ctrl.result != null)
              _ResultSection(result: _ctrl.result!, week: _selectedWeek),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget internal
// ---------------------------------------------------------------------------

class _ApiStatusBanner extends StatelessWidget {
  const _ApiStatusBanner({required this.isOnline, required this.version});

  final bool isOnline;
  final String version;

  @override
  Widget build(BuildContext context) {
    if (isOnline) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'API terhubung · Model: $version',
                style: const TextStyle(fontSize: 13, color: Colors.green),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'API tidak terhubung. Pastikan server FastAPI sudah berjalan '
              '(Android Emulator → 10.0.2.2:8000).',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({required this.result, required this.week});

  final PredictionResult result;
  final int week;

  @override
  Widget build(BuildContext context) {
    final showXai = result.explanation.isNotEmpty &&
        (result.capabilities.contains('xai') || week >= 7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Label + confidence
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SentimentBadge(label: result.label),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: result.score,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                Text(
                  'Keyakinan model: ${result.confidencePercent}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Distribusi probabilitas
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Distribusi Probabilitas',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 10),
                ...result.probabilities.entries.map(
                  (e) => ProbabilityBar(label: e.key, probability: e.value),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // XAI (jika tersedia)
        if (showXai) XaiCard(items: result.explanation),
        if (showXai) const SizedBox(height: 10),

        // Metadata teknis
        ExpansionTile(
          title: const Text(
            'Detail teknis',
            style: TextStyle(fontSize: 14),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Colors.black12),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(1),
                  1: FlexColumnWidth(2),
                },
                children: [
                  _tableRow('Latensi', '${result.latencyMs.toStringAsFixed(1)} ms'),
                  _tableRow('Model', result.modelVersion),
                  _tableRow('Pertemuan', 'P$week'),
                  _tableRow('Trace ID', result.traceId.length > 8
                      ? '${result.traceId.substring(0, 8)}…'
                      : result.traceId),
                  _tableRow('Kapabilitas', result.capabilities.join(', ')),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  static TableRow _tableRow(String label, String value) => TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(value, style: const TextStyle(fontSize: 12)),
          ),
        ],
      );
}
