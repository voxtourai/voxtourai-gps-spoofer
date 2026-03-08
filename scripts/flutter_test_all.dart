import 'dart:io';

import 'flutter_test_runner.dart';

Future<void> main(List<String> args) async {
  final projectRoot = projectRootFromScript(Platform.script);
  exitCode = await runFlutterCommand(
    args: <String>['test', 'test', ...args],
    projectRoot: projectRoot,
  );
}
