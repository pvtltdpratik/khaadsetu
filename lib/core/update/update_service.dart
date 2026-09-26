import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;

import '../network/api_config.dart';

/// A newer version the server offers this installation.
class UpdateInfo extends Equatable {
  const UpdateInfo({required this.versionCode, required this.versionName, required this.notes, required this.sha256, required this.sizeBytes, required this.downloadPath, required this.mandatory});

  factory UpdateInfo.fromJson(Map<String, dynamic> json) => UpdateInfo(
        versionCode: (json['versionCode'] as num).toInt(),
        versionName: '${json['versionName']}',
        notes: '${json['notes'] ?? ''}',
        sha256: '${json['sha256']}',
        sizeBytes: (json['sizeBytes'] as num).toInt(),
        downloadPath: '${json['downloadPath']}',
        mandatory: json['mandatory'] == true,
      );

  final int versionCode;
  final String versionName;
  final String notes;
  final String sha256;
  final int sizeBytes;
  final String downloadPath;
  final bool mandatory;

  @override
  List<Object?> get props => [versionCode, sha256];
}

class UpdateException implements Exception {
  const UpdateException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Asks the server whether there is a newer build, and downloads it safely: resumable, and only kept when its SHA-256
/// is the one the server announced (Android then also checks the signature before installing).
class UpdateService {
  UpdateService({http.Client? client, String? baseUrl}) : _client = client ?? http.Client(), _base = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _client;
  final String _base;

  Future<UpdateInfo?> check({required String flavor, required int versionCode, required String deviceId}) async {
    final uri = Uri.parse('$_base/app/update').replace(queryParameters: {'flavor': flavor, 'versionCode': '$versionCode'});
    final res = await _client.get(uri, headers: {'x-device-id': deviceId}).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return null;
    final json = _decode(res.body);
    return json['updateAvailable'] == true ? UpdateInfo.fromJson(json) : null;
  }

  static Map<String, dynamic> _decode(String body) {
    try {
      final v = jsonDecode(body);
      return v is Map ? v.cast<String, dynamic>() : const {};
    } catch (_) {
      return const {};
    }
  }

  /// Where the APK for [info] is kept once complete. Deleted after installing or when a newer one is downloaded.
  static File finalFile(Directory dir, UpdateInfo info) => File('${dir.path}${Platform.pathSeparator}update-${info.versionCode}.apk');

  /// Downloads (or finishes downloading) the update into [dir]. Returns the verified file. [onProgress] gets 0..1.
  Future<File> download(UpdateInfo info, Directory dir, {void Function(double progress)? onProgress}) async {
    await dir.create(recursive: true);
    final done = finalFile(dir, info);
    if (await done.exists() && await _matches(done, info)) return done;
    // A leftover of an older version is of no use.
    await for (final f in dir.list()) {
      if (f is File && f.path != done.path && f.path != '${done.path}.part') await f.delete();
    }
    final part = File('${done.path}.part');
    var have = await part.exists() ? await part.length() : 0;
    if (have > info.sizeBytes) {
      await part.delete();
      have = 0;
    }
    final request = http.Request('GET', Uri.parse('$_base${info.downloadPath}'));
    if (have > 0) request.headers['range'] = 'bytes=$have-';
    final response = await _client.send(request).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200 && response.statusCode != 206) throw const UpdateException('The update could not be downloaded. It will be tried again.');
    // A server that ignored the range sends everything again: start the file over.
    final append = response.statusCode == 206 && have > 0;
    if (!append) have = 0;
    final sink = part.openWrite(mode: append ? FileMode.append : FileMode.write);
    var received = have;
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call((received / info.sizeBytes).clamp(0.0, 1.0));
      }
    } finally {
      await sink.close();
    }
    if (!await _matches(part, info)) {
      await part.delete();
      throw const UpdateException('The downloaded update is damaged. It will be downloaded again.');
    }
    return part.rename(done.path);
  }

  Future<bool> _matches(File file, UpdateInfo info) async {
    if (await file.length() != info.sizeBytes) return false;
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString() == info.sha256.toLowerCase();
  }
}
