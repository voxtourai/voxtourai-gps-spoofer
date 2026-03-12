import 'dart:io';

void main() {
  final rootDir = Directory.current.path;
  final manifestFile = File('$rootDir/scripts/platform-secrets.manifest');
  if (!manifestFile.existsSync()) {
    stderr.writeln('Missing manifest ${manifestFile.path}');
    exit(1);
  }

  final generatedFiles = <String, String>{};

  for (final rawLine in manifestFile.readAsLinesSync()) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) {
      continue;
    }

    final fields = rawLine.split('|');
    if (fields.length != 5) {
      stderr.writeln('Invalid manifest entry: $rawLine');
      exit(1);
    }

    final relativePath = fields[0];
    final format = fields[1];
    final outputKey = fields[2];
    final envName = fields[3];
    final secretName = fields[4];

    if (format != 'properties') {
      stderr.writeln('Unsupported format $format in ${manifestFile.path}');
      exit(1);
    }

    final existingFormat = generatedFiles[relativePath];
    if (existingFormat != null && existingFormat != format) {
      stderr.writeln('Conflicting formats for $relativePath: $existingFormat and $format');
      exit(1);
    }

    final outputFile = File('$rootDir/$relativePath');
    if (existingFormat == null) {
      outputFile.parent.createSync(recursive: true);
      outputFile.writeAsStringSync('');
      generatedFiles[relativePath] = format;
    }

    final value = resolveSecret(envName, secretName);
    outputFile.writeAsStringSync('$outputKey=$value\n', mode: FileMode.append);
  }
}

String resolveSecret(String envName, String secretName) {
  final envValue = Platform.environment[envName];
  if (envValue != null && envValue.isNotEmpty) {
    return envValue;
  }

  final gcloudCommand = Platform.isWindows ? 'gcloud.cmd' : 'gcloud';

  try {
    final result = Process.runSync(
      gcloudCommand,
      ['secrets', 'versions', 'access', 'latest', '--secret=$secretName'],
      runInShell: Platform.isWindows,
    );
    if (result.exitCode != 0) {
      final output = '${result.stdout}${result.stderr}'.trim();
      stderr.writeln(
        'Unable to resolve $envName via gcloud secret $secretName.'
        '${output.isEmpty ? '' : '\n$output'}',
      );
      exit(result.exitCode);
    }

    final value = '${result.stdout}'.trim();
    if (value.isEmpty) {
      stderr.writeln('Secret $secretName resolved to an empty value.');
      exit(1);
    }

    return value;
  } on ProcessException {
    stderr.writeln(
      'Unable to resolve $envName. Set $envName or install gcloud to access secret $secretName.',
    );
    exit(1);
  }
}
