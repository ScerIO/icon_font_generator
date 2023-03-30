import 'package:args/args.dart';

import 'arguments.dart';

void defineOptions(ArgParser argParser) {
  argParser
    ..addSeparator('Flutter class options:')
    ..addOption(
      kOptionNames[CliArgument.classFile]!,
      abbr: 'o',
      help:
          'Output path for Flutter-compatible class that contains identifiers for the icons.',
      valueHelp: 'path',
    )
    ..addOption(
      kOptionNames[CliArgument.className]!,
      abbr: 'c',
      help: 'Name for a generated class.',
      valueHelp: 'name',
    )
    ..addOption(
      kOptionNames[CliArgument.fontPackage]!,
      abbr: 'f',
      help:
          'Name of a package that provides a font. Used to provide a font through package dependency.',
      valueHelp: 'name',
    )
    ..addFlag(
      kOptionNames[CliArgument.format]!,
      help: 'Formate dart generated code.',
      defaultsTo: kDefaultFormat,
    )
    ..addSeparator('Font options:')
    ..addOption(
      kOptionNames[CliArgument.fontName]!,
      abbr: 'n',
      help: 'Name for a generated font.',
      valueHelp: 'name',
    )
    ..addFlag(
      kOptionNames[CliArgument.normalize]!,
      help:
          'Enables glyph normalization for the font. Disable this if every icon has the same size and positioning.',
      defaultsTo: true,
    )
    ..addFlag(
      kOptionNames[CliArgument.ignoreShapes]!,
      help: 'Disables SVG shape-to-path conversion (circle, rect, etc.).',
      defaultsTo: true,
    )
    ..addSeparator('Other options:')
    ..addOption(
      kOptionNames[CliArgument.configFile]!,
      abbr: 'z',
      help:
          'Path to icon_font_generator yaml configuration file. pubspec.yaml and icon_font_generator.yaml files are used by default.',
      valueHelp: 'path',
    )
    ..addFlag(
      kOptionNames[CliArgument.recursive]!,
      abbr: 'r',
      help: 'Recursively look for .svg files.',
      defaultsTo: kDefaultRecursive,
      negatable: false,
    )
    ..addFlag(
      kOptionNames[CliArgument.verbose]!,
      abbr: 'v',
      help: 'Display every logging message.',
      defaultsTo: kDefaultVerbose,
      negatable: false,
    )
    ..addFlag(
      kOptionNames[CliArgument.help]!,
      abbr: 'h',
      help: 'Shows this usage information.',
      negatable: false,
    );
}
