import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

/// Thrown for any non-2xx response or network failure. [message] is already
/// worded for the UI (the server sends `{"error": "..."}` for every failure),
/// so screens can show it directly.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// The one HTTP entry point for the app. It adds the headers every request
/// needs (`X-Device-Id`, `X-API-Key`), decodes JSON, and turns failures into
/// an [ApiException] carrying a message fit to show a farmer, instead of
/// leaking a raw `ClientException` into the UI.
class ApiClient {
  ApiClient({http.Client? client, required Future<String> Function() deviceId})
      : _client = client ?? http.Client(),
        _deviceId = deviceId; // ignore: prefer_initializing_formals (named param, private field)

  final http.Client _client;
  final Future<String> Function() _deviceId;

  static const _timeout = Duration(seconds: 20);

  Uri _uri(String path, [Map<String, String?>? query]) {
    final params = <String, String>{
      for (final e in (query ?? const <String, String?>{}).entries)
        if (e.value != null && e.value!.isNotEmpty) e.key: e.value!,
    };
    return Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: params.isEmpty ? null : params);
  }

  Future<Map<String, String>> _headers({bool json = false}) async => {
        'X-Device-Id': await _deviceId(),
        if (ApiConfig.apiKey.isNotEmpty) 'X-API-Key': ApiConfig.apiKey,
        if (json) 'Content-Type': 'application/json',
      };

  /// Decoded JSON body of a GET.
  Future<dynamic> get(String path, {Map<String, String?>? query}) async {
    final headers = await _headers();
    return _decode(await _guard(() => _client.get(_uri(path, query), headers: headers).timeout(_timeout)));
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final headers = await _headers(json: true);
    return _decode(await _guard(() => _client
        .post(_uri(path), headers: headers, body: body == null ? null : jsonEncode(body))
        .timeout(_timeout)));
  }

  Future<dynamic> put(String path, {Object? body}) async {
    final headers = await _headers(json: true);
    return _decode(await _guard(() => _client
        .put(_uri(path), headers: headers, body: body == null ? null : jsonEncode(body))
        .timeout(_timeout)));
  }

  /// Multipart upload (the soil-scan photo).
  Future<dynamic> postMultipart(
    String path, {
    required Map<String, String> fields,
    required List<http.MultipartFile> files,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path))
      ..fields.addAll(fields)
      ..files.addAll(files)
      ..headers.addAll(await _headers());
    return _decode(await _guard(() async {
      final streamed = await _client.send(request).timeout(const Duration(seconds: 30));
      return http.Response.fromStream(streamed);
    }));
  }

  Future<http.Response> _guard(Future<http.Response> Function() request) async {
    try {
      return await request();
    } on http.ClientException {
      throw ApiException(
        "Couldn't reach the server at ${ApiConfig.baseUrl}. Check your internet connection. "
        "On a phone, API_BASE_URL must be your computer's or server's address, not localhost.",
      );
    } on TimeoutException {
      throw ApiException('The server took too long to respond. Please try again.');
    }
  }

  dynamic _decode(http.Response response) {
    final body = response.body.isEmpty ? null : jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body is Map && body['error'] is String
          ? body['error'] as String
          : 'Server returned ${response.statusCode}.';
      throw ApiException(message, statusCode: response.statusCode);
    }
    return body;
  }
}
