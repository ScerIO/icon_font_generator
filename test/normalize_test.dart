import 'dart:io';

import 'package:icon_font_generator/src/common/generic_glyph.dart';
import 'package:icon_font_generator/src/otf/defaults.dart';
import 'package:icon_font_generator/src/otf/otf.dart';
import 'package:icon_font_generator/src/svg/svg.dart';
import 'package:test/test.dart';

import 'constant.dart';

const _kTestCompSvgPathList = [
  '$kTestAssetsDir/svg/comp_first.svg',
  '$kTestAssetsDir/svg/comp_second.svg',
  '$kTestAssetsDir/svg/comp_third.svg',
];

void main() {
  group('Normalization', () {
    List<GenericGlyph> createGlyphList() {
      final svgFileList = _kTestCompSvgPathList.map(File.new);
      final svgList =
          svgFileList.map((e) => Svg.parse(e.path, e.readAsStringSync()));
      return svgList.map(GenericGlyph.fromSvg).toList();
    }

    test('Metrics, normalization is off', () {
      final font = OpenTypeFont.createFromGlyphs(
          glyphList: createGlyphList(), normalize: false);
      final widthList = font.hmtx.hMetrics.map((e) => e.advanceWidth);
      const unitsPerEm = kDefaultOpenTypeUnitsPerEm;

      expect(widthList, [350, 333, unitsPerEm, unitsPerEm, unitsPerEm]);
      expect(font.hhea.ascender, 1000);
      expect(font.hhea.descender, 0);
    });

    test('Metrics, normalization is on', () {
      final font = OpenTypeFont.createFromGlyphs(
          glyphList: createGlyphList(), normalize: true);
      final widthList = font.hmtx.hMetrics.map((e) => e.advanceWidth);

      expect(widthList, [298, 333, 362, 270, 208]);
      expect(font.hhea.ascender, 850);
      expect(font.hhea.descender, -150);
    });
  });
}
