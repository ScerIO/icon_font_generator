import 'dart:convert';
import 'dart:io';

import 'package:icon_font_generator/templates/flutter_icons.dart' as template;
import 'package:recase/recase.dart';

class GenerateResult {
  GenerateResult(this.content, this.iconsCount);

  final String content;
  final int iconsCount;
}

Future<GenerateResult> generateFlutterClass({
  required File iconMap,
  required File? symlinksMap,
  required String className,
  required String? packageName,
  required String namingStrategy,
  String indent = '  ',
}) async {
  final Map<String, dynamic> icons = jsonDecode(await iconMap.readAsString());
  final Map<String, dynamic> symlinks =
      symlinksMap == null ? {} : jsonDecode(await symlinksMap.readAsString());

  for (var symlinkEntry in symlinks.entries) {
    final symlink = symlinkEntry.key;
    final target = symlinkEntry.value.toString();
    final targetEntry =
        icons.entries.singleWhere((entry) => entry.key == target);

    if (icons.keys.contains(symlink)) {
      print(
          '\x1B[33mWarning: "$symlink" icon already exists - symlink creation skipped\x1B[0m');
      continue;
    }

    icons.addAll({
      symlink: targetEntry.value,
    });
  }

  final dartIconsEntries = <String>{};
  final dartIconsValues = <String>{};

  for (final entry in icons.entries) {
    final name = namingStrategy == 'snake'
        ? ReCase(entry.key).snakeCase
        : ReCase(entry.key).camelCase;

    dartIconsEntries.add(someReplace(
      template.icon
          .replaceAll(
            '%ICON_NAME%',
            name,
          )
          .replaceFirst(
              '%ICON_CODE%', entry.value.toRadixString(16).toString()),
      className: className,
      indent: indent,
    ));

    dartIconsValues.add(someReplace(
      template.value.replaceAll('%ICON_NAME%', name),
      indent: indent,
      className: className,
    ));
  }

  return GenerateResult(
      someReplace(
        template.base
            .replaceFirst(
              '%PACKAGE%',
              packageName == null
                  ? ''
                  : someReplace(
                      template.package
                          .replaceFirst('%PACKAGE_NAME%', packageName),
                      className: className,
                      indent: indent,
                    ),
            )
            .replaceFirst('%CONTENT%', dartIconsEntries.join('\n'))
            .replaceFirst('%VALUES_MAP%', dartIconsValues.join('\n')),
        className: className,
        indent: indent,
      ),
      icons.length);
}

String someReplace(
  String template, {
  required String indent,
  required String className,
}) =>
    template
        .replaceAll('%INDENT%', indent)
        .replaceAll('%CLASS_NAME%', className);
