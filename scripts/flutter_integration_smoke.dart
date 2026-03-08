import 'dart:io';

import 'flutter_test_runner.dart';

Future<void> main(List<String> args) async {
  final projectRoot = projectRootFromScript(Platform.script);
  final deviceId = await resolvePreferredAndroidDeviceId(
    projectRoot: projectRoot,
  );
  if (deviceId == null) {
    stderr.writeln(
      'No Android device found. Connect a phone or start an Android emulator, then retry.',
    );
    exitCode = 1;
    return;
  }

  exitCode = await runFlutterCommand(
    args: <String>[
      'test',
      'integration_test/app_smoke_test.dart',
      '-d',
      deviceId,
      ...args,
    ],
    projectRoot: projectRoot,
  );
}
