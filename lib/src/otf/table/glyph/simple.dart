import 'dart:math' as math;
import 'dart:typed_data';

import '../../../common/codable/binary.dart';
import '../../../utils/otf.dart';
import 'flag.dart';
import 'header.dart';

class SimpleGlyph implements BinaryCodable {
  SimpleGlyph(
    this.header,
    this.endPtsOfContours,
    this.instructions,
    this.flags,
    this.pointList,
  );

  factory SimpleGlyph.empty() {
    return SimpleGlyph(GlyphHeader(0, 0, 0, 0, 0), [], [], [], []);
  }

  factory SimpleGlyph.fromByteData(
      ByteData byteData, GlyphHeader header, int glyphOffset) {
    var offset = glyphOffset + header.size;

    final endPtsOfContours = [
      for (var i = 0; i < header.numberOfContours; i++)
        byteData.getUint16(offset + i * 2)
    ];
    offset += header.numberOfContours * 2;

    final instructionLength = byteData.getUint16(offset);
    offset += 2;

    final instructions = [
      for (var i = 0; i < instructionLength; i++) byteData.getUint8(offset + i)
    ];
    offset += instructionLength;

    final numberOfPoints = _getNumberOfPoints(endPtsOfContours);
    final flags = <SimpleGlyphFlag>[];

    for (var i = 0; i < numberOfPoints; i++) {
      final flag = SimpleGlyphFlag.fromByteData(byteData, offset);
      offset += flag.size;
      flags.add(flag);

      for (var j = 0; j < flag.repeatTimes; j++) {
        flags.add(flag);
      }

      i += flag.repeatTimes;
    }

    final xCoordinates = <int>[];

    for (var i = 0; i < numberOfPoints; i++) {
      final short = flags[i].xShortVector;
      final same = flags[i].xIsSameOrPositive;

      if (short) {
        xCoordinates.add((same ? 1 : -1) * byteData.getUint8(offset++));
      } else {
        if (same) {
          xCoordinates.add(0);
        } else {
          xCoordinates.add(byteData.getInt16(offset));
          offset += 2;
        }
      }
    }

    final yCoordinates = <int>[];

    for (var i = 0; i < numberOfPoints; i++) {
      final short = flags[i].yShortVector;
      final same = flags[i].yIsSameOrPositive;

      if (short) {
        yCoordinates.add((same ? 1 : -1) * byteData.getUint8(offset++));
      } else {
        if (same) {
          yCoordinates.add(0);
        } else {
          yCoordinates.add(byteData.getInt16(offset));
          offset += 2;
        }
      }
    }

    final xAbsCoordinates = relToAbsCoordinates(xCoordinates);
    final yAbsCoordinates = relToAbsCoordinates(yCoordinates);

    final points = [
      for (var i = 0; i < xAbsCoordinates.length; i++)
        math.Point<num>(xAbsCoordinates[i], yAbsCoordinates[i])
    ];

    return SimpleGlyph(
      header,
      endPtsOfContours,
      instructions,
      flags,
      points,
    );
  }

  final GlyphHeader header;
  final List<int> endPtsOfContours;
  final List<int> instructions;
  final List<SimpleGlyphFlag> flags;

  final List<math.Point<num>> pointList;

  bool get isEmpty => header.numberOfContours == 0;

  int get _coordinatesSize {
    var coordinatesSize = 0;

    for (var i = 0; i < flags.length; i++) {
      final xShort = flags[i].xShortVector;
      final yShort = flags[i].yShortVector;
      final xSame = flags[i].xIsSameOrPositive;
      final ySame = flags[i].yIsSameOrPositive;

      coordinatesSize += xShort ? 1 : (xSame ? 0 : 2);
      coordinatesSize += yShort ? 1 : (ySame ? 0 : 2);
    }

    return coordinatesSize;
  }

  int get _flagsSize {
    var flagsSize = 0;

    for (var i = 0; i < flags.length; i++) {
      final flag = flags[i];

      flagsSize += flag.size;

      if (flag.repeatTimes > 0) {
        i += flag.repeatTimes;
      }
    }

    return flagsSize;
  }

  int get _descriptionSize {
    final endPointsSize = endPtsOfContours.length * 2;
    final instructionsSize = 2 + instructions.length;

    return endPointsSize + instructionsSize + _flagsSize + _coordinatesSize;
  }

  @override
  int get size => isEmpty ? 0 : header.size + _descriptionSize;

  @override
  void encodeToBinary(ByteData byteData) {
    header.encodeToBinary(byteData);
    var offset = header.size;

    for (var i = 0; i < header.numberOfContours; i++) {
      byteData.setUint16(offset + i * 2, endPtsOfContours[i]);
    }
    offset += header.numberOfContours * 2;

    byteData.setUint16(offset, instructions.length);
    offset += 2;

    for (var i = 0; i < instructions.length; i++) {
      byteData.setUint8(offset + i, instructions[i]);
    }
    offset += instructions.length;

    final numberOfPoints = _getNumberOfPoints(endPtsOfContours);

    for (var i = 0; i < numberOfPoints; i++) {
      final flag = flags[i];
      flag.encodeToBinary(byteData.sublistView(offset, flag.size));

      offset += flag.size;
      i += flag.repeatTimes;
    }

    final xAbsCoordinates = pointList.map((e) => e.x.toInt()).toList();
    final yAbsCoordinates = pointList.map((e) => e.y.toInt()).toList();

    final xRelCoordinates = absToRelCoordinates(xAbsCoordinates);
    final yRelCoordinates = absToRelCoordinates(yAbsCoordinates);

    for (var i = 0; i < numberOfPoints; i++) {
      final short = flags[i].xShortVector;
      final same = flags[i].xIsSameOrPositive;

      if (short) {
        byteData.setUint8(offset++, xRelCoordinates[i].abs());
      } else {
        if (!same) {
          byteData.setInt16(offset, xRelCoordinates[i]);
          offset += 2;
        }
      }
    }

    for (var i = 0; i < numberOfPoints; i++) {
      final short = flags[i].yShortVector;
      final same = flags[i].yIsSameOrPositive;

      if (short) {
        byteData.setUint8(offset++, yRelCoordinates[i].abs());
      } else {
        if (!same) {
          byteData.setInt16(offset, yRelCoordinates[i]);
          offset += 2;
        }
      }
    }
  }

  static int _getNumberOfPoints(List<int> endPtsOfContours) =>
      endPtsOfContours.isNotEmpty ? endPtsOfContours.last + 1 : 0;
}
