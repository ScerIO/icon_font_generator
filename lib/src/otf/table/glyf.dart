import 'dart:math' as math;
import 'dart:typed_data';

import '../../common/generic_glyph.dart';
import '../../utils/otf.dart';
import '../debugger.dart';
import 'abstract.dart';
import 'glyph/header.dart';
import 'glyph/simple.dart';
import 'loca.dart';
import 'table_record_entry.dart';

class GlyphDataTable extends FontTable {
  GlyphDataTable(
    super.entry,
    this.glyphList,
  ) : super.fromTableRecordEntry();

  factory GlyphDataTable.fromByteData(ByteData byteData, TableRecordEntry entry,
      IndexToLocationTable locationTable, int numGlyphs) {
    final glyphList = <SimpleGlyph>[];

    for (var i = 0; i < numGlyphs; i++) {
      final headerOffset = entry.offset + locationTable.glyphOffsets[i];
      final nextHeaderOffset = entry.offset + locationTable.glyphOffsets[i + 1];
      final isEmpty = headerOffset == nextHeaderOffset;

      final header = GlyphHeader.fromByteData(byteData, headerOffset);

      if (header.isComposite) {
        debugUnsupportedFeature(
            'Composite glyph (glyph header offset $headerOffset)');
      } else {
        final glyph = isEmpty
            ? SimpleGlyph.empty()
            : SimpleGlyph.fromByteData(byteData, header, headerOffset);
        glyphList.add(glyph);
      }
    }

    return GlyphDataTable(entry, glyphList);
  }

  factory GlyphDataTable.fromGlyphs(List<GenericGlyph> glyphList) {
    final glyphListCopy = glyphList.map((e) => e.copy());

    for (final glyph in glyphListCopy) {
      for (final outline in glyph.outlines) {
        if (!outline.hasQuadCurves) {
          // TODO: implement cubic -> quad approximation
          throw UnimplementedError(
              'Cubic to quadratic curve conversion not supported');
        }

        outline.compactImplicitPoints();
      }
    }

    final simpleGlyphList =
        glyphListCopy.map((e) => e.toSimpleTrueTypeGlyph()).toList();

    return GlyphDataTable(null, simpleGlyphList);
  }

  final List<SimpleGlyph> glyphList;

  @override
  int get size =>
      glyphList.fold<int>(0, (p, v) => p + getPaddedTableSize(v.size));

  int get maxPoints =>
      glyphList.fold<int>(0, (p, g) => math.max(p, g.pointList.length));

  int get maxContours =>
      glyphList.fold<int>(0, (p, g) => math.max(p, g.header.numberOfContours));

  int get maxSizeOfInstructions =>
      glyphList.fold<int>(0, (p, g) => math.max(p, g.instructions.length));

  @override
  void encodeToBinary(ByteData byteData) {
    var offset = 0;

    for (final glyph in glyphList) {
      if (glyph.isEmpty) {
        continue;
      }

      glyph.encodeToBinary(byteData.sublistView(offset, glyph.size));
      offset += getPaddedTableSize(glyph.size);
    }
  }
}
