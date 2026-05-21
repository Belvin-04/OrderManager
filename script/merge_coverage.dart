// ignore_for_file: avoid_print

import 'dart:io';

void main() async {
  final unit = File('coverage/unit_lcov.info');
  final integration = File('coverage/integration_lcov.info');
  final output = File('coverage/lcov.info');

  final merged = StringBuffer();

  if (await unit.exists()) {
    merged.writeln(await unit.readAsString());
  }

  if (await integration.exists()) {
    merged.writeln(await integration.readAsString());
  }

  await output.writeAsString(merged.toString());

  print('Merged coverage written to coverage/lcov.info');
}
