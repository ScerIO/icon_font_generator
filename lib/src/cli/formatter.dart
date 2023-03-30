import 'dart:io';

import 'arguments.dart';

typedef CliArgumentFormatter = Object Function(String arg);

const _kArgumentFormatters = <CliArgument, CliArgumentFormatter>{
  CliArgument.svgDir: Directory.new,
  CliArgument.fontFile: File.new,
  CliArgument.classFile: File.new,
  CliArgument.configFile: File.new,
};

/// Formats arguments.
Map<CliArgument, Object?> formatArguments(Map<CliArgument, Object?> args) {
  return args.map<CliArgument, Object?>((k, v) {
    final formatter = _kArgumentFormatters[k];

    if (formatter == null || v == null) {
      return MapEntry<CliArgument, Object?>(k, v);
    }

    return MapEntry<CliArgument, Object?>(k, formatter(v.toString()));
  });
}
