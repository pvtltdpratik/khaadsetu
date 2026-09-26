import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:khaadsetu_version1/core/device/device_id_provider.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';
import 'package:khaadsetu_version1/core/update/update_controller.dart';
import 'package:khaadsetu_version1/core/update/update_gate.dart';
import 'package:khaadsetu_version1/core/update/update_platform.dart';
import 'package:khaadsetu_version1/core/update/update_service.dart';

class FakePlatform implements UpdatePlatform {
  FakePlatform({this.allowed = true, this.code = 1});

  bool allowed;
  int code;
  final installed = <String>[];
  int settingsOpened = 0;

  @override
  bool get supported => true;
  @override
  Future<({int code, String name})> installedVersion() async => (code: code, name: '1.0');
  @override
  Future<bool> canInstall() async => allowed;
  @override
  Future<void> openInstallSettings() async => settingsOpened++;
  @override
  Future<void> install(String apkPath) async => installed.add(apkPath);
}

UpdateInfo infoFor(List<int> bytes, {int code = 2, bool mandatory = false}) => UpdateInfo(
      versionCode: code, versionName: '1.0.$code', notes: 'Faster orders', sha256: sha256.convert(bytes).toString(), sizeBytes: bytes.length, downloadPath: '/app/download/rel-1', mandatory: mandatory);

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('upd'));
  tearDown(() => dir.deleteSync(recursive: true));

  final apk = List<int>.generate(5000, (i) => i % 251);

  test('check reads the offer, or nothing when there is none', () async {
    final asked = <Uri>[];
    final service = UpdateService(
      baseUrl: 'https://x.test',
      client: MockClient((req) async {
        asked.add(req.url);
        return http.Response(jsonEncode(req.url.queryParameters['versionCode'] == '1' ? {'updateAvailable': true, 'mandatory': false, 'versionCode': 2, 'versionName': '1.0.2', 'notes': 'n', 'sha256': 'ab', 'sizeBytes': 10, 'downloadPath': '/app/download/r'} : {'updateAvailable': false}), 200);
      }),
    );
    final offer = await service.check(flavor: 'farmer', versionCode: 1, deviceId: 'd');
    expect(offer!.versionName, '1.0.2');
    expect(asked.single.queryParameters, {'flavor': 'farmer', 'versionCode': '1'});
    expect(await service.check(flavor: 'farmer', versionCode: 2, deviceId: 'd'), isNull);
  });

  test('download keeps the file only when its hash is the announced one', () async {
    final info = infoFor(apk);
    final service = UpdateService(baseUrl: 'https://x.test', client: MockClient.streaming((req, _) async => http.StreamedResponse(Stream.value(apk), 200)));
    final progress = <double>[];
    final file = await service.download(info, dir, onProgress: progress.add);
    expect(await file.readAsBytes(), apk);
    expect(progress.last, 1.0);

    final bad = UpdateService(baseUrl: 'https://x.test', client: MockClient.streaming((req, _) async => http.StreamedResponse(Stream.value(List.filled(5000, 9)), 200)));
    final dir2 = Directory('${dir.path}/two');
    await expectLater(bad.download(infoFor(apk, code: 3), dir2), throwsA(isA<UpdateException>()));
    expect(File('${UpdateService.finalFile(dir2, infoFor(apk, code: 3)).path}.part').existsSync(), isFalse);
  });

  test('a broken download resumes from where it stopped', () async {
    final info = infoFor(apk);
    File('${UpdateService.finalFile(dir, info).path}.part').writeAsBytesSync(apk.sublist(0, 2000));
    String? range;
    final service = UpdateService(
      baseUrl: 'https://x.test',
      client: MockClient.streaming((req, _) async {
        range = req.headers['range'];
        return http.StreamedResponse(Stream.value(apk.sublist(2000)), 206);
      }),
    );
    final file = await service.download(info, dir);
    expect(range, 'bytes=2000-');
    expect(await file.readAsBytes(), apk);
  });

  group('the controller and the restart prompt', () {
    late FakePlatform platform;
    late UpdateInfo info;

    Future<ProviderContainer> start(WidgetTester tester, {bool mandatory = false, int installedCode = 1}) async {
      platform = FakePlatform(code: installedCode);
      info = infoFor(apk, mandatory: mandatory);
      final service = UpdateService(
        baseUrl: 'https://x.test',
        client: MockClient.streaming((req, _) async {
          if (req.url.path == '/app/update') {
            return http.StreamedResponse(Stream.value(utf8.encode(jsonEncode({
              'updateAvailable': installedCode < info.versionCode, 'mandatory': mandatory, 'versionCode': info.versionCode, 'versionName': info.versionName,
              'notes': info.notes, 'sha256': info.sha256, 'sizeBytes': info.sizeBytes, 'downloadPath': info.downloadPath,
            }))), 200);
          }
          return http.StreamedResponse(Stream.value(apk), 200);
        }),
      );
      final List<Override> overrides = [
        updatePlatformProvider.overrideWithValue(platform),
        updateServiceProvider.overrideWithValue(service),
        updateDirectoryProvider.overrideWithValue(() async => dir),
        deviceIdProvider.overrideWith((ref) async => 'phone'),
      ];
      final container = ProviderContainer(overrides: overrides);
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.light, home: const UpdateGate(child: Scaffold(body: Text('the app')))),
      ));
      // The download does real file work: let real time pass, and pump so the app's own async steps can continue.
      for (var i = 0; i < 100; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
        await tester.pump();
        final p = container.read(updateControllerProvider).phase;
        if (p == UpdatePhase.ready || p == UpdatePhase.failed || (p == UpdatePhase.idle && i > 15)) break;
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      return container;
    }

    testWidgets('a newer version downloads by itself, then asks to restart; Restart now installs it', (tester) async {
      await start(tester);
      expect(find.text('the app'), findsOneWidget);
      expect(find.text('Restart required'), findsOneWidget);
      expect(find.text('Version 1.0.2 is ready.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('update-restart')));
      await tester.pumpAndSettle();
      expect(platform.installed.single, endsWith('update-2.apk'));
    });

    testWidgets('Later puts the prompt away; a forced update has no Later', (tester) async {
      await start(tester);
      await tester.tap(find.byKey(const Key('update-later')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('update-card')), findsNothing);
    });

    testWidgets('a forced update cannot be put off', (tester) async {
      await start(tester, mandatory: true);
      expect(find.byKey(const Key('update-restart')), findsOneWidget);
      expect(find.byKey(const Key('update-later')), findsNothing);
    });

    testWidgets('when Android does not yet allow installing, the person is sent to that setting', (tester) async {
      final container = await start(tester);
      platform.allowed = false;
      await tester.tap(find.byKey(const Key('update-restart')));
      await tester.pumpAndSettle();
      expect(platform.settingsOpened, 1);
      expect(platform.installed, isEmpty);
      expect(container.read(updateControllerProvider).phase, UpdatePhase.needsPermission);
      expect(find.textContaining('Allow this app to install updates'), findsOneWidget);
      platform.allowed = true;
      await container.read(updateControllerProvider.notifier).resumed();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('update-restart')));
      await tester.pumpAndSettle();
      expect(platform.installed, hasLength(1));
    });

    testWidgets('an up to date app shows nothing', (tester) async {
      await start(tester, installedCode: 2);
      expect(find.byKey(const Key('update-card')), findsNothing);
    });
  });
}
