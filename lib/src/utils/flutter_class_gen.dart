import 'package:path/path.dart' as p;
import 'package:recase/recase.dart';

import '../common/constant.dart';
import '../common/generic_glyph.dart';
import '../otf/defaults.dart';

const _kUnnamedIconName = 'unnamed';
const _kDefaultIndent = 2;
const _kDefaultClassName = 'UiIcons';
const _kDefaultFontFileName = 'icon_font_generator_icons.otf';

/// Removes any characters that are not valid for variable name.
///
/// Returns a new string.
String _getVarName(String string) {
  final replaced = string.replaceAll(RegExp(r'[^a-zA-Z0-9_$]'), '');
  return RegExp(r'^[a-zA-Z$].*').firstMatch(replaced)?.group(0) ?? '';
}

/// A helper for generating Flutter-compatible class with IconData objects for each icon.
class FlutterClassGenerator {
  /// * [glyphList] is a list of non-default glyphs.
  /// * [className] is generated class' name (preferably, in PascalCase).
  /// * [familyName] is font's family name to use in IconData.
  /// * [package] is the name of a font package. Used to provide a font through package dependency.
  /// * [fontFileName] is font file's name. Used in generated docs for class.
  /// * [indent] is a number of spaces in leading indentation for class' members. Defaults to 2.
  FlutterClassGenerator(
    this.glyphList, {
    String? className,
    String? familyName,
    String? fontFileName,
    String? package,
    int? indent,
  })  : _indent = ' ' * (indent ?? _kDefaultIndent),
        _className = _getVarName(className ?? _kDefaultClassName),
        _familyName = familyName ?? kDefaultFontFamily,
        _fontFileName = fontFileName ?? _kDefaultFontFileName,
        _iconVarNames = _generateVariableNames(glyphList),
        _package = package?.isEmpty ?? true ? null : package;

  final List<GenericGlyph> glyphList;
  final String _fontFileName;
  final String _className;
  final String _familyName;
  final String _indent;
  final String? _package;
  final List<String> _iconVarNames;

  static List<String> _generateVariableNames(List<GenericGlyph> glyphList) {
    final iconNameSet = <String>{};

    return glyphList.map((g) {
      final baseName =
          _getVarName(p.basenameWithoutExtension(g.metadata.name!)).camelCase;
      final usingDefaultName = baseName.isEmpty;

      var variableName = usingDefaultName ? _kUnnamedIconName : baseName;

      // Handling same names by adding numeration to them
      if (iconNameSet.contains(variableName)) {
        // If name already contains numeration, then splitting it
        final countMatch = RegExp(r'^(.*)_([0-9]+)$').firstMatch(variableName);

        var variableNameCount = 1;
        var variableWithoutCount = variableName;

        if (countMatch != null) {
          variableNameCount = int.parse(countMatch.group(2)!);
          variableWithoutCount = countMatch.group(1)!;
        }

        String variableNameWithCount;

        do {
          variableNameWithCount =
              '${variableWithoutCount}_${++variableNameCount}';
        } while (iconNameSet.contains(variableNameWithCount));

        variableName = variableNameWithCount;
      }

      iconNameSet.add(variableName);

      return variableName;
    }).toList();
  }

  bool get _hasPackage => _package != null;

  String get _fontFamilyConst =>
      "static const iconFontFamily = '$_familyName';";

  String get _fontPackageConst => "static const iconFontPackage = '$_package';";

  List<String> _generateIconConst(int index) {
    final glyphMeta = glyphList[index].metadata;

    final charCode = glyphMeta.charCode!;
    final iconName = glyphMeta.name!;

    final varName = _iconVarNames[index];
    final hexCode = charCode.toRadixString(16);

    final posParamList = [
      'fontFamily: iconFontFamily',
      if (_hasPackage) 'fontPackage: iconFontPackage'
    ];

    final posParamString = posParamList.join(', ');

    return [
      '',
      '/// Font icon named "__${iconName}__"',
      if (glyphMeta.preview != null) ...[
        '///',
        "/// <image width='32px' src='data:image/svg+xml;base64,${glyphMeta.preview}'>",
      ],
      'static const IconData $varName = IconData(0x$hexCode, $posParamString);'
    ];
  }

  /// Generates content for a class' file.
  String generate() {
    final classContent = [
      'const $_className._();',
      '',
      _fontFamilyConst,
      if (_hasPackage) _fontPackageConst,
      for (var i = 0; i < glyphList.length; i++) ..._generateIconConst(i),
    ];

    final classContentString =
        classContent.map((e) => e.isEmpty ? '' : '$_indent$e').join('\n');

    return '''// Generated code: do not hand-edit.

// Generated using $kVendorName.
// Copyright © ${DateTime.now().year} $kVendorName ($kVendorUrl).

import 'package:flutter/widgets.dart';

/// Identifiers for the icons.
///
/// Use with the [Icon] class to show specific icons.
///
/// Icons are identified by their name as listed below.
///
/// To use this class, make sure you declare the font in your
/// project's `pubspec.yaml` file in the `fonts` section. This ensures that
/// the "$_familyName" font is included in your application. This font is used to
/// display the icons. For example:
/// 
/// ```yaml
/// flutter:
///   fonts:
///     - family: $_familyName
///       fonts:
///         - asset: fonts/$_fontFileName
/// ```
class $_className {
$classContentString
}
''';
  }
}
