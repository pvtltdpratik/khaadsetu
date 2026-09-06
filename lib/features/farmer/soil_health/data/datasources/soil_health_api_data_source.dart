import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../../../core/network/api_config.dart';
import '../../domain/entities/nutrient_reading.dart';
import '../../domain/entities/soil_scan_result.dart';

/// Talks to the real Soil Sense backend (`server/` — FastAPI). See that
/// project's README for the exact request/response contract this mirrors.
class SoilHealthApiDataSource {
  SoilHealthApiDataSource({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri get _analyzeUri => Uri.parse('${ApiConfig.soilSenseBaseUrl}/v1/analyze');
  Uri _historyUri(String deviceId) => Uri.parse(
        '${ApiConfig.soilSenseBaseUrl}/v1/history',
      ).replace(queryParameters: {'device_id': deviceId});

  Future<SoilScanResult> analyzeImage({
    required Uint8List imageBytes,
    required String filename,
    required String deviceId,
    String? cropType,
  }) async {
    final request = http.MultipartRequest('POST', _analyzeUri)
      ..fields['metadata_json'] = jsonEncode({
        'device_id': deviceId,
        if (cropType != null && cropType.isNotEmpty) 'crop_type': cropType,
      })
      ..files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: filename));

    final response = await _send(request);
    return _parseResult(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<SoilScanResult>> fetchHistory(String deviceId) async {
    final response = await _guardConnection(
      () => _client.get(_historyUri(deviceId)).timeout(const Duration(seconds: 20)),
    );
    _checkStatus(response);
    final decoded = jsonDecode(response.body);
    // Assumes the backend returns a plain JSON array of scan objects, per
    // its documented "fetch up to 5 scans" behavior. Adjust this if your
    // deployed server wraps the list in an envelope object instead.
    final list = decoded is List ? decoded : (decoded as Map<String, dynamic>)['history'] as List;
    return list.map((e) => _parseResult(e as Map<String, dynamic>)).toList();
  }

  Future<http.Response> _send(http.MultipartRequest request) async {
    final response = await _guardConnection(() async {
      final streamed = await _client.send(request).timeout(const Duration(seconds: 30));
      return http.Response.fromStream(streamed);
    });
    _checkStatus(response);
    return response;
  }

  /// Wraps low-level network failures (connection refused, DNS failure,
  /// timeout) — which surface as a raw `ClientException`/`TimeoutException`
  /// unhelpful to a non-technical user — into one clear message pointing at
  /// the likely cause, instead of leaking a stack-trace-looking string into
  /// the UI's error state.
  Future<http.Response> _guardConnection(Future<http.Response> Function() request) async {
    try {
      return await request();
    } on http.ClientException {
      throw SoilHealthApiException(
        "Couldn't reach the soil analysis server at ${ApiConfig.soilSenseBaseUrl}. "
        'Make sure it\'s running, and if you\'re on a phone rather than in the '
        'browser, check the API_BASE_URL override in core/network/api_config.dart.',
      );
    } on TimeoutException {
      throw SoilHealthApiException(
        'The soil analysis server took too long to respond. Please try again.',
      );
    }
  }

  void _checkStatus(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SoilHealthApiException(
        'Soil Sense backend returned ${response.statusCode}: ${response.body}',
      );
    }
  }

  SoilScanResult _parseResult(Map<String, dynamic> json) {
    final metadata = json['metadata'] as Map<String, dynamic>?;
    return SoilScanResult(
      id: json['id'] as String,
      scannedAt: DateTime.parse(json['created_at'] as String),
      overallScore: (json['health_score'] as num).toDouble(),
      soilMoisturePercent: (json['soil_moisture'] as num).toDouble(),
      nutrients: [
        NutrientReading.of(NutrientType.nitrogen, (json['nutrient_n'] as num).toDouble()),
        NutrientReading.of(NutrientType.phosphorus, (json['nutrient_p'] as num).toDouble()),
        NutrientReading.of(NutrientType.potassium, (json['nutrient_k'] as num).toDouble()),
      ],
      disease: json['disease'] as String,
      diseaseConfidencePercent: (json['disease_confidence'] as num).toDouble(),
      recommendations: (json['recommendations'] as List).cast<String>(),
      cropType: metadata?['crop_type'] as String?,
    );
  }
}

/// Thrown for any non-2xx response or network failure so the presentation
/// layer can show a real, specific message (e.g. "backend unreachable")
/// instead of a generic error.
class SoilHealthApiException implements Exception {
  SoilHealthApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
