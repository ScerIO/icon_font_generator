import 'package:icon_font_generator/icon_font_generator.dart';
import 'package:test/test.dart';

const _squareSvg =
    '<svg viewBox="0 0 24 24"><rect x="3" y="3" width="18" height="18"/></svg>';

void main() {
  test('svgToOtf honours explicit charCodes', () {
    final result = svgToOtf(
      svgMap: {'square': _squareSvg},
      charCodes: {'square': 0xF123},
    );
    final glyph =
        result.glyphList.firstWhere((g) => g.metadata.name == 'square');
    expect(glyph.metadata.charCode, 0xF123);
  });

  test('svgToOtf sorts glyphs by explicit codepoint', () {
    final result = svgToOtf(
      svgMap: {'b': _squareSvg, 'a': _squareSvg},
      charCodes: {'b': 0xF002, 'a': 0xF001},
    );
    final codes = result.glyphList.map((g) => g.metadata.charCode).toList();
    expect(codes, orderedEquals(<int>[0xF001, 0xF002]));
  });

  test('svgToOtf rejects a glyph missing from charCodes', () {
    expect(
      () => svgToOtf(
        svgMap: {'square': _squareSvg},
        charCodes: {'other': 0xF001},
      ),
      throwsArgumentError,
    );
  });

  test('svgToOtf rejects duplicate codepoints', () {
    expect(
      () => svgToOtf(
        svgMap: {'a': _squareSvg, 'b': _squareSvg},
        charCodes: {'a': 0xF001, 'b': 0xF001},
      ),
      throwsArgumentError,
    );
  });

  test('svgToOtf rejects non-BMP codepoints', () {
    expect(
      () => svgToOtf(
        svgMap: {'square': _squareSvg},
        charCodes: {'square': 0xF1234},
      ),
      throwsArgumentError,
    );
  });

  test('svgToOtf rejects surrogate codepoints', () {
    expect(
      () => svgToOtf(
        svgMap: {'square': _squareSvg},
        charCodes: {'square': 0xD800},
      ),
      throwsArgumentError,
    );
  });
}
