import 'dart:convert';
import 'dart:io';

Future<int> runFlutterCommand({
  required List<String> args,
  required String projectRoot,
}) async {
  final flutterExecutable = resolveFlutterExecutable();
  if (flutterExecutable == null) {
    stderr.writeln(
      'Unable to locate Flutter. Configure the Flutter SDK in IntelliJ or add Flutter to PATH.',
    );
    return 1;
  }

  final process = await Process.start(
    flutterExecutable,
    args,
    workingDirectory: projectRoot,
    runInShell: true,
  );

  await stdout.addStream(process.stdout);
  await stderr.addStream(process.stderr);
  return await process.exitCode;
}

Future<String?> resolvePreferredAndroidDeviceId({
  required String projectRoot,
}) async {
  final flutterExecutable = resolveFlutterExecutable();
  if (flutterExecutable == null) {
    return null;
  }

  final machineResult = await Process.run(
    flutterExecutable,
    const <String>['devices', '--machine'],
    workingDirectory: projectRoot,
    runInShell: true,
  );
  final fromMachine = _parsePreferredAndroidDeviceId(machineResult.stdout);
  if (fromMachine != null) {
    return fromMachine;
  }

  final textResult = await Process.run(
    flutterExecutable,
    const <String>['devices'],
    workingDirectory: projectRoot,
    runInShell: true,
  );
  return _parsePreferredAndroidDeviceIdFromText(textResult.stdout);
}

String projectRootFromScript(Uri scriptUri) {
  return Directory.fromUri(scriptUri).parent.parent.path;
}

String? resolveFlutterExecutable() {
  final fromFlutterSdkDart = _flutterFromResolvedDart();
  if (fromFlutterSdkDart != null) {
    return fromFlutterSdkDart;
  }

  final fromFlutterRoot = _flutterFromEnv();
  if (fromFlutterRoot != null) {
    return fromFlutterRoot;
  }

  return _flutterFromPath();
}

String? _parsePreferredAndroidDeviceId(Object? stdoutValue) {
  if (stdoutValue is! String || stdoutValue.trim().isEmpty) {
    return null;
  }

  final dynamic decoded;
  try {
    decoded = jsonDecode(stdoutValue);
  } catch (_) {
    return null;
  }
  if (decoded is! List) {
    return null;
  }

  final devices = decoded
      .whereType<Map>()
      .map((rawDevice) {
        final device = rawDevice.map(
          (key, value) => MapEntry(key.toString(), value?.toString()),
        );
        return (
          id: device['id'],
          name: device['name'] ?? '',
          targetPlatform:
              device['targetPlatform'] ?? device['platformType'] ?? '',
        );
      })
      .where((device) => device.id != null);

  final androidDevices = devices
      .where(
        (device) => device.targetPlatform.toLowerCase().contains('android'),
      )
      .toList();
  if (androidDevices.isEmpty) {
    return null;
  }

  final physicalDevice = androidDevices.firstWhere(
    (device) =>
        !device.name.toLowerCase().contains('emulator') &&
        !device.name.toLowerCase().contains('sdk'),
    orElse: () => androidDevices.first,
  );
  return physicalDevice.id;
}

String? _parsePreferredAndroidDeviceIdFromText(Object? stdoutValue) {
  if (stdoutValue is! String || stdoutValue.trim().isEmpty) {
    return null;
  }

  final lines = stdoutValue.split(RegExp(r'\r?\n'));
  for (final line in lines) {
    if (!line.contains('•') || !line.toLowerCase().contains('android')) {
      continue;
    }

    final parts = line.split('•').map((part) => part.trim()).toList();
    if (parts.length < 3) {
      continue;
    }
    final id = parts[1];
    if (id.isNotEmpty) {
      return id;
    }
  }

  return null;
}

String? _flutterFromResolvedDart() {
  final dartBinDir = File(Platform.resolvedExecutable).parent;
  final flutterBinDir = dartBinDir.parent.parent.parent;
  return _existingFlutterBinary(flutterBinDir.path);
}

String? _flutterFromEnv() {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null || flutterRoot.trim().isEmpty) {
    return null;
  }

  return _existingFlutterBinary(flutterRoot);
}

String? _flutterFromPath() {
  final locator = Platform.isWindows ? 'where.exe' : 'which';
  final executableName = Platform.isWindows ? 'flutter.bat' : 'flutter';
  final result = Process.runSync(locator, <String>[
    executableName,
  ], runInShell: true);
  if (result.exitCode != 0) {
    return null;
  }

  final output = result.stdout;
  if (output is! String) {
    return null;
  }

  for (final line in output.split(RegExp(r'\r?\n'))) {
    final trimmed = line.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
  }

  return null;
}

String? _existingFlutterBinary(String rootOrBinPath) {
  final separator = Platform.pathSeparator;
  final flutterPath = Platform.isWindows
      ? '$rootOrBinPath${rootOrBinPath.endsWith(separator) ? '' : separator}bin${separator}flutter.bat'
      : '$rootOrBinPath${rootOrBinPath.endsWith(separator) ? '' : separator}bin${separator}flutter';

  final directFlutterPath = Platform.isWindows
      ? '$rootOrBinPath${rootOrBinPath.endsWith(separator) ? '' : separator}flutter.bat'
      : '$rootOrBinPath${rootOrBinPath.endsWith(separator) ? '' : separator}flutter';

  if (File(flutterPath).existsSync()) {
    return flutterPath;
  }
  if (File(directFlutterPath).existsSync()) {
    return directFlutterPath;
  }
  return null;
}
