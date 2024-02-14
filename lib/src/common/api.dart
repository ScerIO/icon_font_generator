import '../otf.dart';
import '../svg.dart';
import '../utils/flutter_class_gen.dart';
import '../utils/logger.dart';
import 'generic_glyph.dart';

/// Result of svg-to-otf conversion.
///
/// Contains list of generated glyphs and created font.
class SvgToOtfResult {
  SvgToOtfResult._(this.glyphList, this.font);

  final List<GenericGlyph> glyphList;
  final OpenTypeFont font;
}

/// Converts SVG icons to OTF font.
///
/// * [svgMap] contains name (key) to data (value) SVG mapping. Required.
/// * If [ignoreShapes] is set to false, shapes (circle, rect, etc.) are converted into paths.
/// Defaults to true.
/// NOTE: Attributes like "fill" or "stroke" are ignored,
/// which means only shape's outline will be used.
/// * If [normalize] is set to true,
/// glyphs are resized and centered to fit in coordinates grid (unitsPerEm).
/// Defaults to true.
/// * If [sort] is set to true,
/// glyphs are sorted by name.
/// Defaults to false.
/// * [fontName] is a name for a generated font.
///
/// Returns an instance of [SvgToOtfResult] class containing glyphs and a font.
SvgToOtfResult svgToOtf({
  required Map<String, String> svgMap,
  bool? ignoreShapes,
  bool? normalize,
  String? fontName,
  bool? sort,
}) {
  normalize ??= true;
  sort ??= false;

  final svgList = [
    for (final e in svgMap.entries)
      Svg.parse(e.key, e.value, ignoreShapes: ignoreShapes)
  ];

  if (!normalize) {
    for (var i = 1; i < svgList.length; i++) {
      if (svgList[i - 1].viewBox.height != svgList[i].viewBox.height) {
        logger.logOnce(
            Level.warning,
            'Some SVG files contain different view box height, '
            'while normalization option is disabled. '
            'This is not recommended.');
        break;
      }
    }
  }
  if (sort) {
    svgList.sort((a, b) => a.name.compareTo(b.name));
  }

  final glyphList = svgList.map(GenericGlyph.fromSvg).toList();

  final font = OpenTypeFont.createFromGlyphs(
    glyphList: glyphList,
    fontName: fontName,
    normalize: normalize,
    useOpenType: true,
    usePostV2: true,
  );

  return SvgToOtfResult._(glyphList, font);
}

/// Generates a Flutter-compatible class for a list of glyphs.
///
/// * [glyphList] is a list of non-default glyphs.
/// * [className] is generated class' name (preferably, in PascalCase).
/// * [familyName] is font's family name to use in IconData.
/// * [package] is the name of a font package. Used to provide a font through package dependency.
/// * [fontFileName] is font file's name. Used in generated docs for class.
/// * [indent] is a number of spaces in leading indentation for class' members. Defaults to 2.
///
/// Returns content of a class file.
String generateFlutterClass({
  required List<GenericGlyph> glyphList,
  String? className,
  String? familyName,
  String? fontFileName,
  String? package,
  int? indent,
  bool? iconList,
}) {
  final generator = FlutterClassGenerator(
    glyphList,
    className: className,
    indent: indent,
    fontFileName: fontFileName,
    familyName: familyName,
    package: package,
    iconList: iconList,
  );

  return generator.generate();
}
