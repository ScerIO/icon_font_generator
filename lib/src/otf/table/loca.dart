import 'dart:typed_data';

import '../../utils/otf.dart';
import 'abstract.dart';
import 'glyf.dart';
import 'table_record_entry.dart';

class IndexToLocationTable extends FontTable {
  IndexToLocationTable(
    super.entry,
    this.glyphOffsets,
    this._isShort,
  ) : super.fromTableRecordEntry();

  factory IndexToLocationTable.fromByteData(ByteData byteData,
      TableRecordEntry entry, int indexToLocFormat, int numGlyphs) {
    final isShort = indexToLocFormat == 0;

    final offsets = <int>[
      for (var i = 0; i < numGlyphs + 1; i++)
        isShort
            ? byteData.getUint16(entry.offset + 2 * i) * 2
            : byteData.getUint32(entry.offset + 4 * i)
    ];

    return IndexToLocationTable(entry, offsets, isShort);
  }

  factory IndexToLocationTable.create(
      int indexToLocFormat, GlyphDataTable glyf) {
    final isShort = indexToLocFormat == 0;
    final offsets = <int>[];

    var offset = 0;

    for (final glyph in glyf.glyphList) {
      offsets.add(offset);
      offset += getPaddedTableSize(glyph.size);
    }

    offsets.add(offset);

    return IndexToLocationTable(null, offsets, isShort);
  }

  final List<int> glyphOffsets;
  final bool _isShort;

  @override
  void encodeToBinary(ByteData byteData) {
    for (var i = 0; i < glyphOffsets.length; i++) {
      final offset = _isShort ? glyphOffsets[i] ~/ 2 : glyphOffsets[i];

      if (_isShort) {
        byteData.setUint16(2 * i, offset);
      } else {
        byteData.setUint32(4 * i, offset);
      }
    }
  }

  @override
  int get size => glyphOffsets.length * (_isShort ? 2 : 4);
}
