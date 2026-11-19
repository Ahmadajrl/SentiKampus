import 'package:flutter/material.dart';

import '../models/prediction_result.dart';
import '../services/api_service.dart';

/// Status proses prediksi.
enum PredictState { idle, loading, success, error }

/// Controller state management untuk PredictPage.
///
/// Menggunakan [ChangeNotifier] agar View merespons perubahan state
/// tanpa library tambahan (cocok untuk pembelajaran).
class PredictController extends ChangeNotifier {
  PredictController({required ApiService apiService})
      : _api = apiService;

  final ApiService _api;

  PredictState state = PredictState.idle;
  PredictionResult? result;
  String errorMessage = '';
  bool isApiOnline = false;
  String apiVersion = '';

  // -------------------------------------------------------------------------
  // Health check
  // -------------------------------------------------------------------------

  /// Periksa status API; panggil saat halaman pertama kali tampil.
  Future<void> checkHealth() async {
    final health = await _api.checkHealth();
    isApiOnline = health != null && (health['model_loaded'] as bool? ?? false);
    apiVersion = health?['model_version'] as String? ?? '';
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Prediksi
  // -------------------------------------------------------------------------

  /// Kirim prediksi ke API dan perbarui state.
  Future<void> predict({
    required String text,
    required int week,
    bool includeExplanation = false,
  }) async {
    if (text.trim().length < 3) {
      errorMessage = 'Teks minimal tiga karakter bermakna.';
      state = PredictState.error;
      notifyListeners();
      return;
    }

    state = PredictState.loading;
    errorMessage = '';
    notifyListeners();

    try {
      result = await _api.predict(
        text: text.trim(),
        week: week,
        includeExplanation: includeExplanation,
      );
      state = PredictState.success;
    } on ApiException catch (e) {
      errorMessage = e.message;
      state = PredictState.error;
    } catch (e) {
      errorMessage = 'Prediksi gagal: $e';
      state = PredictState.error;
    }

    notifyListeners();
  }

  /// Reset ke state awal.
  void reset() {
    state = PredictState.idle;
    result = null;
    errorMessage = '';
    notifyListeners();
  }
}
