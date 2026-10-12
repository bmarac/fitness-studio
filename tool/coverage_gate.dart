import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

const _backendRoot = 'api/FitnessStudio.Api/';
const _flutterRoot = 'mobile/fitness_studio_mobile/';

void main(List<String> arguments) async {
  final options = _Options.parse(arguments);
  final baselineFile = File(options.baselinePath);
  final baseline = _Baseline.fromJson(
    jsonDecode(await baselineFile.readAsString()) as Map<String, dynamic>,
  );

  final backend = _CoverageReport.parse(
    await File(options.backendPath).readAsLines(),
    _normalizeBackendPath,
  ).where(_isBackendInScope);
  final flutter = _CoverageReport.parse(
    await File(options.flutterPath).readAsLines(),
    _normalizeFlutterPath,
  ).where(_isFlutterInScope);

  if (backend.executableLines == 0 || flutter.executableLines == 0) {
    stderr.writeln('Coverage report is empty after applying source filters.');
    exitCode = 1;
    return;
  }

  final backendRate = _floorToTenth(backend.lineRate);
  final flutterRate = _floorToTenth(flutter.lineRate);
  final diff = await _loadDiff(options.baseRef);
  final backendChanged = _changedCoverage(backend, diff, _isBackendInScope);
  final flutterChanged = _changedCoverage(flutter, diff, _isFlutterInScope);
  final failures = <String>[];

  var effectiveBaseline = baseline;
  if (options.updateBaseline) {
    effectiveBaseline = baseline.copyWith(
      backendLine: math.max(baseline.backendLine, backendRate),
      flutterLine: math.max(baseline.flutterLine, flutterRate),
    );
    await baselineFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(effectiveBaseline.toJson()) +
          '\n',
    );
  } else {
    _checkBaseline('Backend', backendRate, baseline.backendLine, failures);
    _checkBaseline('Flutter', flutterRate, baseline.flutterLine, failures);
  }

  _checkChanged('Backend', backendChanged, baseline.changedLine, failures);
  _checkChanged('Flutter', flutterChanged, baseline.changedLine, failures);

  final summary = _buildSummary(
    backend: backend,
    flutter: flutter,
    backendRate: backendRate,
    flutterRate: flutterRate,
    backendChanged: backendChanged,
    flutterChanged: flutterChanged,
    baseline: effectiveBaseline,
    baseRef: diff.baseLabel,
    failures: failures,
  );
  await File(options.summaryPath).parent.create(recursive: true);
  await File(options.summaryPath).writeAsString(summary);
  stdout.write(summary);

  if (failures.isNotEmpty) {
    exitCode = 1;
  }
}

void _checkBaseline(
  String label,
  double current,
  double baseline,
  List<String> failures,
) {
  if (current < baseline) {
    failures.add(
      '$label line coverage $current% is below the $baseline% baseline.',
    );
  } else if (current >= baseline + 0.1) {
    failures.add(
      '$label coverage improved from $baseline% to $current%. '
      'Run ./scripts/check-coverage.sh --update-baseline.',
    );
  }
}

void _checkChanged(
  String label,
  _ChangedCoverage changed,
  double threshold,
  List<String> failures,
) {
  if (changed.missingFiles.isNotEmpty) {
    failures.add(
      '$label changed files have no coverage data: '
      '${changed.missingFiles.join(', ')}.',
    );
  }
  if (changed.executableLines > 0 && changed.lineRate < threshold) {
    failures.add(
      '$label changed-line coverage is '
      '${changed.lineRate.toStringAsFixed(1)}%, below $threshold%.',
    );
  }
}

String _buildSummary({
  required _CoverageReport backend,
  required _CoverageReport flutter,
  required double backendRate,
  required double flutterRate,
  required _ChangedCoverage backendChanged,
  required _ChangedCoverage flutterChanged,
  required _Baseline baseline,
  required String baseRef,
  required List<String> failures,
}) {
  final buffer = StringBuffer()
    ..writeln('# Coverage summary')
    ..writeln()
    ..writeln('| Scope | Covered lines | Line coverage | Baseline | Target |')
    ..writeln('| --- | ---: | ---: | ---: | ---: |')
    ..writeln(
      '| Backend | ${backend.coveredLines}/${backend.executableLines} | '
      '${backendRate.toStringAsFixed(1)}% | '
      '${baseline.backendLine.toStringAsFixed(1)}% | '
      '${baseline.targetLine.toStringAsFixed(1)}% |',
    )
    ..writeln(
      '| Flutter | ${flutter.coveredLines}/${flutter.executableLines} | '
      '${flutterRate.toStringAsFixed(1)}% | '
      '${baseline.flutterLine.toStringAsFixed(1)}% | '
      '${baseline.targetLine.toStringAsFixed(1)}% |',
    )
    ..writeln()
    ..writeln('Changed lines compared with `$baseRef`:')
    ..writeln()
    ..writeln('| Scope | Covered lines | Coverage | Required |')
    ..writeln('| --- | ---: | ---: | ---: |')
    ..writeln(_changedRow('Backend', backendChanged, baseline.changedLine))
    ..writeln(_changedRow('Flutter', flutterChanged, baseline.changedLine))
    ..writeln()
    ..writeln('## Lowest-covered files')
    ..writeln()
    ..writeln('### Backend')
    ..writeln()
    ..writeln(_lowestFiles(backend))
    ..writeln()
    ..writeln('### Flutter')
    ..writeln()
    ..writeln(_lowestFiles(flutter));

  if (failures.isEmpty) {
    buffer
      ..writeln()
      ..writeln('Coverage gate passed.');
  } else {
    buffer
      ..writeln()
      ..writeln('## Failures')
      ..writeln();
    for (final failure in failures) {
      buffer.writeln('- $failure');
    }
  }
  return buffer.toString();
}

String _changedRow(String label, _ChangedCoverage changed, double threshold) {
  final coverage = changed.executableLines == 0
      ? 'N/A'
      : '${changed.lineRate.toStringAsFixed(1)}%';
  return '| $label | ${changed.coveredLines}/${changed.executableLines} | '
      '$coverage | ${threshold.toStringAsFixed(1)}% |';
}

String _lowestFiles(_CoverageReport report) {
  final entries = report.files.entries.toList()
    ..sort((left, right) {
      final rateComparison = _fileRate(
        left.value,
      ).compareTo(_fileRate(right.value));
      return rateComparison != 0
          ? rateComparison
          : left.key.compareTo(right.key);
    });
  return entries
      .take(10)
      .map((entry) {
        final covered = entry.value.values.where((hits) => hits > 0).length;
        final total = entry.value.length;
        return '- `${entry.key}`: $covered/$total '
            '(${_fileRate(entry.value).toStringAsFixed(1)}%)';
      })
      .join('\n');
}

double _fileRate(Map<int, int> lines) {
  if (lines.isEmpty) return 100;
  return lines.values.where((hits) => hits > 0).length * 100 / lines.length;
}

double _floorToTenth(double value) => (value * 10).floor() / 10;

String _normalizeBackendPath(String path) =>
    _normalizeAtMarker(path, _backendRoot);

String _normalizeFlutterPath(String path) {
  final normalized = path.replaceAll('\\', '/');
  if (normalized.startsWith('lib/')) return '$_flutterRoot$normalized';
  return _normalizeAtMarker(normalized, '${_flutterRoot}lib/');
}

String _normalizeAtMarker(String path, String marker) {
  final normalized = path.replaceAll('\\', '/');
  final index = normalized.indexOf(marker);
  return index < 0 ? normalized : normalized.substring(index);
}

bool _isBackendInScope(String path) {
  if (!path.startsWith(_backendRoot)) return false;
  final relative = path.substring(_backendRoot.length);
  return relative == 'Program.cs' ||
      relative == 'Data/DevelopmentAuthSeeder.cs' ||
      relative.startsWith('Controllers/') ||
      relative.startsWith('Services/') ||
      relative.startsWith('Domain/') ||
      relative.startsWith('Validation/') ||
      relative.startsWith('Extensions/');
}

bool _isFlutterInScope(String path) {
  if (!path.startsWith('${_flutterRoot}lib/') || !path.endsWith('.dart')) {
    return false;
  }
  final relative = path.substring(_flutterRoot.length);
  return !RegExp(
    r'^lib/l10n/app_localizations(?:_[a-z]+)?\.dart$',
  ).hasMatch(relative);
}

Future<_Diff> _loadDiff(String? requestedBaseRef) async {
  String? baseRef = requestedBaseRef;
  var workingTree = false;

  if (baseRef == null || baseRef.isEmpty) {
    final status = await Process.run('git', ['status', '--porcelain']);
    if ((status.stdout as String).trim().isNotEmpty) {
      workingTree = true;
    } else {
      final originMain = await Process.run('git', [
        'rev-parse',
        '--verify',
        '--quiet',
        'origin/main',
      ]);
      if (originMain.exitCode == 0) baseRef = 'origin/main';
    }
  }

  if (!workingTree && (baseRef == null || baseRef.isEmpty)) {
    return const _Diff('no base ref', {});
  }

  final arguments = <String>['diff', '--unified=0', '--diff-filter=AMCR'];
  if (workingTree) {
    arguments.add('HEAD');
  } else {
    arguments.add('$baseRef...HEAD');
  }
  arguments.add('--');

  final result = await Process.run('git', arguments);
  if (result.exitCode != 0) {
    throw StateError('git diff failed: ${result.stderr}');
  }
  return _Diff.parse(
    result.stdout as String,
    workingTree ? 'working tree' : baseRef!,
  );
}

_ChangedCoverage _changedCoverage(
  _CoverageReport report,
  _Diff diff,
  bool Function(String) inScope,
) {
  var covered = 0;
  var executable = 0;
  final missingFiles = <String>[];

  for (final entry in diff.changedLines.entries) {
    final path = entry.key;
    if (!inScope(path)) continue;
    final coverageLines = report.files[path];
    if (coverageLines == null) {
      missingFiles.add(path);
      continue;
    }
    for (final line in entry.value) {
      final hits = coverageLines[line];
      if (hits == null) continue;
      executable++;
      if (hits > 0) covered++;
    }
  }

  return _ChangedCoverage(
    coveredLines: covered,
    executableLines: executable,
    missingFiles: missingFiles,
  );
}

class _CoverageReport {
  const _CoverageReport(this.files);

  final Map<String, Map<int, int>> files;

  int get executableLines =>
      files.values.fold(0, (sum, lines) => sum + lines.length);

  int get coveredLines => files.values.fold(
    0,
    (sum, lines) => sum + lines.values.where((hits) => hits > 0).length,
  );

  double get lineRate => coveredLines * 100 / executableLines;

  _CoverageReport where(bool Function(String) predicate) => _CoverageReport({
    for (final entry in files.entries)
      if (predicate(entry.key)) entry.key: entry.value,
  });

  static _CoverageReport parse(
    List<String> input,
    String Function(String) normalizePath,
  ) {
    final files = <String, Map<int, int>>{};
    String? currentFile;
    for (final line in input) {
      if (line.startsWith('SF:')) {
        currentFile = normalizePath(line.substring(3));
        files.putIfAbsent(currentFile, () => <int, int>{});
      } else if (line.startsWith('DA:') && currentFile != null) {
        final parts = line.substring(3).split(',');
        if (parts.length < 2) continue;
        final number = int.tryParse(parts[0]);
        final hits = int.tryParse(parts[1]);
        if (number == null || hits == null) continue;
        final existing = files[currentFile]![number] ?? 0;
        files[currentFile]![number] = math.max(existing, hits);
      } else if (line == 'end_of_record') {
        currentFile = null;
      }
    }
    return _CoverageReport(files);
  }
}

class _ChangedCoverage {
  const _ChangedCoverage({
    required this.coveredLines,
    required this.executableLines,
    required this.missingFiles,
  });

  final int coveredLines;
  final int executableLines;
  final List<String> missingFiles;

  double get lineRate =>
      executableLines == 0 ? 100 : coveredLines * 100 / executableLines;
}

class _Diff {
  const _Diff(this.baseLabel, this.changedLines);

  final String baseLabel;
  final Map<String, Set<int>> changedLines;

  static _Diff parse(String input, String baseLabel) {
    final changedLines = <String, Set<int>>{};
    String? currentFile;
    final hunkPattern = RegExp(r'^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@');

    for (final line in const LineSplitter().convert(input)) {
      if (line.startsWith('+++ b/')) {
        currentFile = line.substring(6);
        changedLines.putIfAbsent(currentFile, () => <int>{});
        continue;
      }
      final match = hunkPattern.firstMatch(line);
      if (match == null || currentFile == null) continue;
      final start = int.parse(match.group(1)!);
      final count = int.tryParse(match.group(2) ?? '1') ?? 1;
      for (var offset = 0; offset < count; offset++) {
        changedLines[currentFile]!.add(start + offset);
      }
    }
    return _Diff(baseLabel, changedLines);
  }
}

class _Baseline {
  const _Baseline({
    required this.backendLine,
    required this.flutterLine,
    required this.changedLine,
    required this.targetLine,
  });

  final double backendLine;
  final double flutterLine;
  final double changedLine;
  final double targetLine;

  factory _Baseline.fromJson(Map<String, dynamic> json) => _Baseline(
    backendLine: (json['backendLine'] as num).toDouble(),
    flutterLine: (json['flutterLine'] as num).toDouble(),
    changedLine: (json['changedLine'] as num).toDouble(),
    targetLine: (json['targetLine'] as num).toDouble(),
  );

  _Baseline copyWith({double? backendLine, double? flutterLine}) => _Baseline(
    backendLine: backendLine ?? this.backendLine,
    flutterLine: flutterLine ?? this.flutterLine,
    changedLine: changedLine,
    targetLine: targetLine,
  );

  Map<String, dynamic> toJson() => {
    'backendLine': backendLine,
    'flutterLine': flutterLine,
    'changedLine': changedLine,
    'targetLine': targetLine,
  };
}

class _Options {
  const _Options({
    required this.backendPath,
    required this.flutterPath,
    required this.baselinePath,
    required this.summaryPath,
    required this.baseRef,
    required this.updateBaseline,
  });

  final String backendPath;
  final String flutterPath;
  final String baselinePath;
  final String summaryPath;
  final String? baseRef;
  final bool updateBaseline;

  static _Options parse(List<String> arguments) {
    final values = <String, String>{};
    var updateBaseline = false;
    for (var index = 0; index < arguments.length; index++) {
      final argument = arguments[index];
      if (argument == '--update-baseline') {
        updateBaseline = true;
        continue;
      }
      if (!argument.startsWith('--') || index + 1 >= arguments.length) {
        throw ArgumentError('Invalid coverage gate argument: $argument');
      }
      values[argument] = arguments[++index];
    }

    String required(String name) =>
        values[name] ??
        (throw ArgumentError('Missing required coverage gate argument: $name'));

    return _Options(
      backendPath: required('--backend'),
      flutterPath: required('--flutter'),
      baselinePath: required('--baseline'),
      summaryPath: required('--summary'),
      baseRef: values['--base-ref'],
      updateBaseline: updateBaseline,
    );
  }
}
