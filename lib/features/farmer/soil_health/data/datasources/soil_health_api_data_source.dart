import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../../../core/network/api_client.dart';
import '../../domain/entities/nutrient_reading.dart';
import '../../domain/entities/soil_scan_result.dart';

/// Soil-scan endpoints of the KHAAD Setu API — the only part of it that uses
/// snake_case (`POST /v1/analyze`, `GET /v1/history`, `GET /v1/scan/:id`).
class SoilHealthApiDataSource {
  const SoilHealthApiDataSource(this._api);

  final ApiClient _api;

  Future<SoilScanResult> analyzeImage({
    required Uint8List imageBytes,
    required String filename,
    required String deviceId,
    String? cropType,
  }) async {
    final json = await _api.postMultipart(
      '/v1/analyze',
      fields: {
        'metadata_json': jsonEncode({
          'device_id': deviceId,
          if (cropType != null && cropType.isNotEmpty) 'crop_type': cropType,
        }),
      },
      files: [
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: filename,
          contentType: _imageContentType(filename),
        ),
      ],
    ) as Map<String, dynamic>;
    return _parseResult(json);
  }

  /// Camera/gallery photos are jpeg in practice, so that is the fallback.
  MediaType _imageContentType(String filename) {
    return filename.toLowerCase().endsWith('.png')
        ? MediaType('image', 'png')
        : MediaType('image', 'jpeg');
  }

  Future<List<SoilScanResult>> fetchHistory(String deviceId) async {
    final list = await _api.get('/v1/history', query: {'device_id': deviceId}) as List;
    return list.map((e) => _parseResult(e as Map<String, dynamic>)).toList();
  }

  Future<SoilScanResult> fetchScan(String id) async {
    final json = await _api.get('/v1/scan/$id') as Map<String, dynamic>;
    return _parseResult(json);
  }

  /// Timestamps are ISO-8601 UTC; convert so a scan shows the farmer's local
  /// time rather than the server's.
  DateTime _parseServerTime(String raw) => DateTime.parse(raw).toLocal();

  SoilScanResult _parseResult(Map<String, dynamic> json) {
    final metadata = json['metadata'] as Map<String, dynamic>?;
    return SoilScanResult(
      id: json['id'] as String,
      scannedAt: _parseServerTime(json['created_at'] as String),
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
