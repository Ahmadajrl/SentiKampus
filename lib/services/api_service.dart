import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../models/demo_week.dart';
import '../models/prediction_result.dart';

/// Layanan HTTP untuk berkomunikasi dengan FastAPI backend SentiKampus.
///
/// Semua metode bersifat async dan melempar [ApiException] bila server
/// tidak dapat dihubungi atau mengembalikan status ≠ 2xx.
class ApiService {
  ApiService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  // -------------------------------------------------------------------------
  // Health
  // -------------------------------------------------------------------------

  /// Periksa status backend. Kembalikan null bila tidak terhubung.
  Future<Map<String, dynamic>?> checkHealth() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/health');
      final response = await _client.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // Prediksi sentimen
  // -------------------------------------------------------------------------

  /// Kirim POST /api/v1/predict. Melempar [ApiException] bila gagal.
  Future<PredictionResult> predict({
    required String text,
    required int week,
    bool includeExplanation = false,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/predict');
    final body = jsonEncode({
      'text': text,
      'week': week,
      'include_explanation': includeExplanation || week >= 7,
    });

    final http.Response response;
    try {
      response = await _client
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      throw ApiException('Tidak dapat terhubung ke server: $e');
    }

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return PredictionResult.fromJson({...json, 'source': 'api'});
    } else if (response.statusCode == 422) {
      throw ApiException('Input tidak valid (422). Periksa teks yang dikirim.');
    } else {
      throw ApiException(
        'Server mengembalikan HTTP ${response.statusCode}.',
      );
    }
  }

  // -------------------------------------------------------------------------
  // Metrik monitoring
  // -------------------------------------------------------------------------

  /// Ambil snapshot metrik dari GET /api/v1/metrics.
  Future<Map<String, dynamic>> fetchMetrics() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/metrics');
    final http.Response response;
    try {
      response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      throw ApiException('Gagal memuat metrik: $e');
    }
    if (response.statusCode != 200) {
      throw ApiException('HTTP ${response.statusCode} saat memuat metrik.');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Kirim POST /api/v1/metrics/reset.
  Future<void> resetMetrics() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/metrics/reset');
    try {
      await _client
          .post(uri, headers: {'Content-Type': 'application/json'}, body: '{}')
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      throw ApiException('Gagal mereset metrik: $e');
    }
  }

  // -------------------------------------------------------------------------
  // Pertemuan
  // -------------------------------------------------------------------------

  /// Ambil daftar 16 pertemuan dari GET /api/v1/course/weeks.
  Future<List<DemoWeek>> fetchCourseWeeks() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/course/weeks');
    final http.Response response;
    try {
      response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      throw ApiException('Gagal memuat data pertemuan: $e');
    }
    if (response.statusCode != 200) {
      throw ApiException('HTTP ${response.statusCode} saat memuat pertemuan.');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => DemoWeek.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// Exception yang dilempar oleh [ApiService] saat terjadi kesalahan.
class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => 'ApiException: $message';
}
