import 'dart:convert';
import 'dart:io';
import 'package:meta/meta.dart';
import 'package:icon_font_generator/templates/flutter_icons.dart' as template;
import 'package:recase/recase.dart';

class GenerateResult {
  GenerateResult(this.content, this.iconsCount);

  final String content;
  final int iconsCount;
}

Future<GenerateResult> generateFlutterClass({
  required File iconMap,
  required String className,
  required String? packageName,
  String indent = '  ',
}) async {
  final Map<String, dynamic> icons = jsonDecode(await iconMap.readAsString());

  final dartIconsEntries = icons.entries.map(
    (entry) => someReplace(
      template.icon
          .replaceFirst('%ICON_NAME%', ReCase(entry.key).camelCase)
          .replaceFirst(
            '%ICON_CODE%',
            entry.value.toRadixString(16).toString()
          ),
      className: className,
      indent: indent,
    ),
  );

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
            .replaceFirst('%CONTENT%', dartIconsEntries.join('\n')),
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
