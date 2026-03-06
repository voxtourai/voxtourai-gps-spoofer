import 'dart:io';

Future<void> main(List<String> args) async {
  final flutterExecutable = _resolveFlutterExecutable();
  if (flutterExecutable == null) {
    stderr.writeln(
      'Unable to locate Flutter. Configure the Flutter SDK in IntelliJ or add Flutter to PATH.',
    );
    exitCode = 1;
    return;
  }

  final projectRoot = Directory.fromUri(Platform.script).parent.parent.path;
  final process = await Process.start(
    flutterExecutable,
    <String>['analyze', ...args],
    workingDirectory: projectRoot,
    runInShell: true,
  );

  await stdout.addStream(process.stdout);
  await stderr.addStream(process.stderr);
  exitCode = await process.exitCode;
}

String? _resolveFlutterExecutable() {
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
  final result = Process.runSync(locator, <String>[executableName], runInShell: true);
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
