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
  String reCase(String data) {
    return namingStrategy == 'snake'
        ? ReCase(data).snakeCase
        : ReCase(data).camelCase;
  }

  final Map<String, dynamic> icons = jsonDecode(await iconMap.readAsString());
  final Map<String, dynamic> symlinks =
      symlinksMap == null ? {} : jsonDecode(await symlinksMap.readAsString());

  for (var symlinkEntry in symlinks.entries) {
    // Symlinks values are already correctly cased
    final symlink = symlinkEntry.key;
    final target = symlinkEntry.value.toString();
    final Iterable<String> reCasedIconKeys =
        icons.keys.map((key) => reCase(key));

    if (reCasedIconKeys.contains(symlink)) {
      print(
          '\x1B[33mWarning: symlink "$symlink" icon already exists - symlink creation skipped\x1B[0m');
      continue;
    } else if (symlinks.keys.contains(target)) {
      print(
          '\x1B[33mWarning: target "$target" icon is already a symlink - symlink creation skipped\x1B[0m');
      continue;
    } else if (!reCasedIconKeys.contains(target)) {
      print(
          '\x1B[33mWarning: target "$target" icon does not exist - symlink creation skipped\x1B[0m');
      continue;
    }

    final targetEntry =
        icons.entries.singleWhere((entry) => reCase(entry.key) == target);
    icons.addAll({
      symlink: targetEntry.value,
    });
  }

  final dartIconsEntries = <String>{};
  final dartIconsValues = <String>{};

  for (final entry in icons.entries) {
    final name = reCase(entry.key);

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
