import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('navigation calls use Routes helpers instead of raw path strings', () {
    final libDir = Directory('lib');
    final rawNavigationCall = RegExp(
      r"""\bcontext\.(?:go|push)\(\s*['"]/""",
    );
    final offenders = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (p.isWithin(p.join('lib', 'core', 'routing'), entity.path)) continue;

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (rawNavigationCall.hasMatch(lines[i])) {
          offenders.add('${entity.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Use Routes constants/builders for navigation paths outside routing.',
    );
  });
}
